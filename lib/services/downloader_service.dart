import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/download_task.dart';
import '../models/track.dart';
import 'audio_tagger.dart';
import 'binaries.dart';
import 'ytmusic_service.dart';

/// Gestiona la cola de descargas con el pipeline híbrido:
///
/// 1. Metadatos: YouTube Music API (vía [YouTubeMusicService]) u opcional
///    Spotify API si hay credenciales.
/// 2. Audio: yt-dlp extrae el mejor audio y lo convierte a MP3 en máxima
///    calidad (`--audio-quality 0`, VBR ~320kbps) con ffmpeg.
/// 3. Etiquetado: [AudioTagger] incrusta título, artista, álbum y la mejor
///    carátula disponible sin Spotify API (player HD → thumb YTM →
///    maxres de YouTube) como etiquetas ID3v2.3 (equivale a `mutagen`).
/// 4. Destino: carpeta Descargas de Windows (%USERPROFILE%/Downloads).
class DownloaderService extends ChangeNotifier {
  /// Calidad MP3 máxima con libmp3lame (VBR ~320kbps).
  static const audioQuality = '0';
  final List<DownloadTask> _queue = [];
  bool _working = false;
  bool _ytDlpChecked = false;
  bool _ytDlpAvailable = false;

  List<DownloadTask> get queue => List.unmodifiable(_queue);

  String? _ytDlpPath;

  String? _notice;

  /// Aviso transitorio (ej. "Agregado a la cola") que muestra la status bar.
  String? get notice => _notice;

  void _setNotice(String message) {
    _notice = message;
    notifyListeners();
    Timer(const Duration(seconds: 4), () {
      _notice = null;
      notifyListeners();
    });
  }

  int get pendingCount => _queue
      .where((t) =>
          t.status == DownloadStatus.queued ||
          t.status == DownloadStatus.downloading)
      .length;

  int get downloadingCount => _queue
      .where((t) => t.status == DownloadStatus.downloading)
      .length;

  int get queuedCount =>
      _queue.where((t) => t.status == DownloadStatus.queued).length;

  int get completedCount =>
      _queue.where((t) => t.status == DownloadStatus.completed).length;

  int get failedCount =>
      _queue.where((t) => t.status == DownloadStatus.failed).length;

  Directory get downloadDir {
    final userProfile = Platform.environment['USERPROFILE'];
    final base = userProfile != null && userProfile.isNotEmpty
        ? Directory('$userProfile\\Downloads')
        : Directory(Directory.systemTemp.path);
    if (!base.existsSync()) base.createSync(recursive: true);
    return base;
  }

  void enqueue(Track track) {
    // Evita duplicados exactos en cola/activos.
    final exists = _queue.any((t) =>
        t.track.id == track.id &&
        (t.status == DownloadStatus.queued ||
            t.status == DownloadStatus.downloading));
    if (exists) return;
    _queue.insert(0, DownloadTask(
      id: '${track.id}_${DateTime.now().microsecondsSinceEpoch}',
      track: track,
    ));
    _setNotice(
        'Agregado a la cola: ${track.artistsLabel} - ${track.title}');
    notifyListeners();
    _processQueue();
  }

  void remove(String taskId) {
    _queue.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }

  void clearFinished() {
    _queue.removeWhere((t) =>
        t.status == DownloadStatus.completed ||
        t.status == DownloadStatus.failed);
    notifyListeners();
  }

  void retry(DownloadTask task) {
    task.status = DownloadStatus.queued;
    task.progress = 0;
    task.message = 'En cola';
    notifyListeners();
    _processQueue();
  }

  Future<void> openDownloadsFolder() async {
    final dir = downloadDir;
    if (Platform.isWindows) {
      await Process.run('explorer', [dir.path]);
    }
  }

  Future<void> _processQueue() async {
    if (_working) return;
    _working = true;
    try {
      while (true) {
        DownloadTask? next;
        for (final t in _queue) {
          if (t.status == DownloadStatus.queued) {
            next = t;
            break;
          }
        }
        if (next == null) break;
        await _download(next);
      }
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  Future<bool> _hasYtDlp() async {
    if (_ytDlpChecked) return _ytDlpAvailable;
    _ytDlpChecked = true;
    try {
      _ytDlpPath = await Binaries.ytDlp();
      if (_ytDlpPath == null) {
        _ytDlpAvailable = false;
        return false;
      }
      final r = await Process.run(_ytDlpPath!, ['--version']).timeout(
        const Duration(seconds: 8),
      );
      _ytDlpAvailable = r.exitCode == 0;
    } catch (_) {
      _ytDlpAvailable = false;
    }
    return _ytDlpAvailable;
  }

  Future<void> _download(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task.progress = 0;
    task.message = 'Preparando…';
    notifyListeners();

    if (!await _hasYtDlp()) {
      _missingEngine(task);
      return;
    }
    try {
      await _downloadWithYtDlp(task);
    } catch (e) {
      task.status = DownloadStatus.failed;
      task.message = 'Error: $e';
      notifyListeners();
    }
  }

  /// Si el motor de descarga no está localizado, la tarea se marca como
  /// fallida con el motivo (no se finge una descarga).
  void _missingEngine(DownloadTask task) {
    task.status = DownloadStatus.failed;
    task.progress = 0;
    task.message = 'No se encontró yt-dlp en el equipo. Reinstálalo y reintenta.';
    notifyListeners();
  }

  /// Descarga real en máxima calidad MP3 + carátula máxima calidad.
  Future<void> _downloadWithYtDlp(DownloadTask task) async {
    final dir = downloadDir;
    final outTemplate = '${dir.path}\\%(title)s.%(ext)s';

    // 1) Audio con yt-dlp -> MP3 en máxima calidad vía ffmpeg.
    //    La carátula y etiquetas las pone AudioTagger después (como mutagen),
    //    así que no se usa --embed-thumbnail para evitar doble APIC.
    final source = task.track.youtubeUrl.isNotEmpty
        ? task.track.youtubeUrl
        : 'ytsearch1:${task.track.youtubeQuery}';
    final args = [
      source,
      '-x',
      '--audio-format',
      'mp3',
      '--audio-quality',
      audioQuality,
      '--format',
      'bestaudio/best',
      '--no-warnings',
      '--no-playlist',
      '--output',
      outTemplate,
      '--newline',
      '--progress',
    ];

    task.message = 'Descargando audio...';
    notifyListeners();

    // Foto de los mp3 existentes para identificar el recién generado.
    final before = await _listMp3Paths(dir);

    var exit = await _runYtDlp(args, task);
    if (exit != 0) {
      // YouTube a veces responde 403 al cliente web: reintento con el
      // cliente android antes de dar la descarga por fallida.
      task.message = 'Reintentando con cliente alternativo…';
      task.progress = 0;
      notifyListeners();
      exit = await _runYtDlp(
          [...args, '--extractor-args', 'youtube:player_client=android'],
          task);
    }
    if (exit != 0) {
      throw Exception('yt-dlp salió con código $exit');
    }

    // Localiza el mp3 recién generado (ignora los que ya existían).
    final mp3 = await _findNewMp3(dir, before);
    if (mp3 == null) throw Exception('No se encontró el MP3 generado');

    // 2) Renombra al formato "Artista - Título.mp3".
    final finalPath = '${dir.path}\\${task.track.safeFileName}.mp3';
    final finalFile =
        mp3.path == finalPath ? mp3 : await _safeRename(mp3, finalPath);

    // 3) Etiquetado ID3 (como mutagen): título, artista, álbum + carátula HD.
    task.message = 'Etiquetando MP3…';
    notifyListeners();
    await _tagMp3(finalFile.path, task.track);

    task.filePath = finalFile.path;
    task.progress = 1;
    task.status = DownloadStatus.completed;
    task.message = 'Completado';
    notifyListeners();
  }

  /// Ejecuta yt-dlp con [args] reportando el progreso en [task].
  /// Devuelve el código de salida.
  Future<int> _runYtDlp(List<String> args, DownloadTask task) async {
    final proc = await Process.start(_ytDlpPath ?? 'yt-dlp', args);

    proc.stdout.transform(utf8.decoder).listen((chunk) {
      // yt-dlp imprime "[download]  45.2% ..." — extraemos el porcentaje.
      final m = RegExp(r'(\d{1,3}(?:\.\d+)?)%').firstMatch(chunk);
      if (m != null) {
        final pct = double.tryParse(m.group(1)!);
        if (pct != null) {
          task.progress = (pct / 100).clamp(0, 1);
          task.message =
              'Descargando... ${pct.toStringAsFixed(0)}%';
          notifyListeners();
        }
      }
    });
    proc.stderr.transform(utf8.decoder).listen((_) {});

    return proc.exitCode;
  }

  Future<Set<String>> _listMp3Paths(Directory dir) async {
    final paths = <String>{};
    await for (final e in dir.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.mp3')) {
        paths.add(e.path);
      }
    }
    return paths;
  }

  /// Devuelve el MP3 nuevo (no estaba en [before]); si no hay ninguno nuevo,
  /// cae al más reciente como respaldo.
  Future<File?> _findNewMp3(Directory dir, Set<String> before) async {
    File? newestNew;
    DateTime newestNewTime = DateTime.fromMillisecondsSinceEpoch(0);
    File? newestAny;
    DateTime newestAnyTime = DateTime.fromMillisecondsSinceEpoch(0);
    await for (final e in dir.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.mp3')) {
        final stat = await e.stat();
        if (stat.modified.isAfter(newestAnyTime)) {
          newestAnyTime = stat.modified;
          newestAny = e;
        }
        if (!before.contains(e.path) &&
            stat.modified.isAfter(newestNewTime)) {
          newestNewTime = stat.modified;
          newestNew = e;
        }
      }
    }
    return newestNew ?? newestAny;
  }

  Future<File> _safeRename(File src, String destPath) async {
    var target = File(destPath);
    var n = 1;
    while (await target.exists()) {
      final withoutExt =
          destPath.substring(0, destPath.length - 4);
      target = File('$withoutExt ($n).mp3');
      n++;
    }
    return src.rename(target.path).then((_) => target);
  }

  /// Etiqueta el MP3 con título, artista, álbum y carátula HD
  /// (equivale a `mutagen` en el pipeline Python).
  /// Si el etiquetador propio falla, reserva incrustando solo la carátula
  /// con ffmpeg.
  Future<void> _tagMp3(String mp3Path, Track track) async {
    // Cadena de carátula de mayor a menor calidad (sin Spotify API):
    // 1) endpoint player de YTM (hasta 1280px),
    // 2) thumb mayor de la fila de búsqueda,
    // 3) maxres del video (1280px; en audios oficiales suele ser el artwork),
    // 4) thumb menor / hq del video.
    final videoId = _extractVideoId(track.youtubeUrl);
    var playerCover = '';
    if (videoId.isNotEmpty) {
      try {
        final details =
            await YouTubeMusicService().fetchVideoDetails(videoId);
        playerCover = details.cover;
      } catch (_) {
        // Se sigue con las carátulas del resultado de búsqueda.
      }
    }
    final candidates = [
      playerCover,
      track.imageLarge,
      if (videoId.isNotEmpty)
        'https://i.ytimg.com/vi/$videoId/maxresdefault.jpg',
      track.imageSmall,
      if (videoId.isNotEmpty) 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg',
    ];
    final cover = await AudioTagger.downloadCovers(candidates);
    if (cover != null && cover.isNotEmpty) {
      try {
        await AudioTagger.writeTags(
          mp3Path: mp3Path,
          title: track.title,
          artist: track.artistsLabel,
          album: track.album,
          coverBytes: cover,
        );
        return;
      } catch (_) {
        // Reserva con ffmpeg solo para la carátula.
      }
    } else {
      // Sin carátula descargable: al menos escribe las etiquetas de texto.
      try {
        await AudioTagger.writeTags(
          mp3Path: mp3Path,
          title: track.title,
          artist: track.artistsLabel,
          album: track.album,
          coverBytes: Uint8List(0),
        );
        return;
      } catch (_) {}
    }
    await _embedCoverWithFfmpeg(mp3Path, candidates);
  }

  /// Extrae el videoId de una URL de YouTube (watch?v=... o youtu.be/...).
  String _extractVideoId(String url) {
    if (url.isEmpty) return '';
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return '';
  }

  /// Reserva: incrusta la mejor carátula de [candidates] con ffmpeg.
  /// Si ffmpeg no existe, el MP3 queda con audio válido y sin carátula.
  Future<void> _embedCoverWithFfmpeg(
      String mp3Path, List<String> candidates) async {
    if (candidates.every((u) => u.isEmpty)) return;
    File? cover;
    try {
      http.Response? res;
      for (final url in candidates) {
        if (url.isEmpty) continue;
        try {
          final r = await http.get(Uri.parse(url));
          if (r.statusCode == 200 && r.bodyBytes.isNotEmpty) {
            res = r;
            break;
          }
        } catch (_) {}
      }
      if (res == null) return;
      cover = File('$mp3Path.cover.jpg');
      await cover.writeAsBytes(res.bodyBytes);
      final ffmpeg = await Binaries.ffmpeg();
      if (ffmpeg == null) return; // deja la miniatura de yt-dlp
      final r = await Process.run(ffmpeg, ['-version']).timeout(
        const Duration(seconds: 6),
      );
      if (r.exitCode != 0) return;
      final tmp = '$mp3Path.tmp.mp3';
      final emb = await Process.run(ffmpeg, [
        '-y',
        '-i', mp3Path,
        '-i', cover.path,
        '-map', '0:a',
        '-map', '1:v',
        '-c:a', 'copy',
        '-c:v', 'mjpeg',
        '-id3v2_version', '3',
        '-metadata:s:v', 'title=Album cover',
        '-metadata:s:v', 'comment=Cover (front)',
        tmp,
      ]);
      if (emb.exitCode == 0) {
        await File(tmp).rename(mp3Path);
      }
    } catch (_) {
      // No bloquea la descarga si falla la carátula.
    } finally {
      try {
        if (cover != null && await cover.exists()) {
          await cover.delete();
        }
        final tmp = File('$mp3Path.tmp.mp3');
        if (await tmp.exists()) {
          // Si quedó un temporal huérfano tras error, se elimina.
          if (await File(mp3Path).exists()) await tmp.delete();
        }
      } catch (_) {}
    }
  }
}
