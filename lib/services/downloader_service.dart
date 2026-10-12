import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/download_task.dart';
import '../models/track.dart';
import 'app_log.dart';
import 'audio_tagger.dart';
import 'auth_store.dart';
import 'binaries.dart';
import 'yt_dlp_engine.dart';
import 'ytmusic_service.dart';

/// Gestiona la cola de descargas con el pipeline híbrido:
///
/// 1. Metadatos: YouTube Music API (vía [YouTubeMusicService]).
/// 2. Audio: [YtDlpEngine] extrae el mejor audio y lo convierte a MP3 en
///    máxima calidad (`--audio-quality 0`, VBR ~320kbps) con ffmpeg.
/// 3. Etiquetado: [AudioTagger] incrusta título, artista, álbum y la mejor
///    carátula disponible (player HD → thumb YTM → maxres de YouTube)
///    como etiquetas ID3v2.3 (equivale a `mutagen`).
/// 4. Destino: carpeta Descargas de Windows (%USERPROFILE%/Downloads).
class DownloaderService extends ChangeNotifier {
  /// Calidad MP3: ver [AppConfig.audioQuality].

  /// Motor de procesos reutilizable (audio, JSON, futuros módulos).
  final YtDlpEngine engine = YtDlpEngine();

  /// Última autenticación usada (para el indicador de Ajustes).
  String lastAuthLabel = 'Sin auth';
  bool lastAuthOk = false;

  /// Índice de la opción de auth que funcionó (fija la que sirve).

  final List<DownloadTask> _queue = [];
  bool _working = false;

  List<DownloadTask> get queue => List.unmodifiable(_queue);

  /// Huella de la cola (ids + estados) para rebuilds granulares:
  /// solo cambia al encolar, quitar o cambiar de estado (no con el %).
  String get queueFingerprint =>
      _queue.map((t) => '${t.track.id}:${t.status.index}').join('|');

  /// Ids en cola o descargando (para marcar filas ya agregadas).
  Set<String> get queuedIds => _queue
      .where((t) =>
          t.status == DownloadStatus.queued ||
          t.status == DownloadStatus.downloading)
      .map((t) => t.track.id)
      .toSet();

  String? _notice;

  /// Aviso transitorio (ej. "Agregado a la cola") que muestra la status bar.
  String? get notice => _notice;

  void _setNotice(String message) {
    _notice = message;
    notifyListeners();
    Timer(AppConfig.noticeDuration, () {
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
    final wasActive = _queue.any((t) =>
        t.id == taskId && t.status == DownloadStatus.downloading);
    _queue.removeWhere((t) => t.id == taskId);
    if (wasActive) {
      engine.killActive();
      _setNotice('Descarga cancelada.');
    }
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
    task.attempts = 0;
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

  Future<bool> _hasYtDlp() => engine.ensureAvailable();

  Future<void> _download(DownloadTask task) async {
    task.status = DownloadStatus.downloading;
    task.progress = 0;
    task.attempts = 0;
    task.message = 'Preparando...';
    notifyListeners();

    if (!await _hasYtDlp()) {
      _missingEngine(task);
      return;
    }
    // Reintento progresivo ([AppConfig.maxAttempts] intentos con backoff).
    const backoffs = [AppConfig.backoffFirst, AppConfig.backoffSecond];
    while (true) {
      // Si el usuario quitó la tarea (canceló), no seguir.
      if (!_queue.any((t) => t.id == task.id)) return;
      task.attempts++;
      try {
        await _downloadWithYtDlp(task);
        return;
      } catch (e) {
        if (!_queue.any((t) => t.id == task.id)) return;
        if (task.attempts >= AppConfig.maxAttempts) {
          task.status = DownloadStatus.failed;
          task.progress = 0;
          task.message =
              'No se pudo descargar tras ${AppConfig.maxAttempts} intentos. Revisa tu conexión.';
          AppLog.instance.error(
              'Descarga', '${task.track.safeFileName}: $e');
          notifyListeners();
          return;
        }
        final wait = backoffs[(task.attempts - 1)
            .clamp(0, backoffs.length - 1)];
        task.message =
            'Reintentando en ${wait.inSeconds}s (intento ${task.attempts + 1}/${AppConfig.maxAttempts})...';
        notifyListeners();
        await Future.delayed(wait);
      }
    }
  }

  /// Si el motor de descarga no está localizado, la tarea se marca como
  /// fallida con el motivo (no se finge una descarga).
  void _missingEngine(DownloadTask task) {
    task.status = DownloadStatus.failed;
    task.progress = 0;
    task.message = 'No se encontro yt-dlp en el equipo. Reinstalalo y reintenta.';
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

    task.message = 'Descargando audio...';
    notifyListeners();

    // Fotos para identificar el recién generado y limpiar si se cancela.
    final before = await YtDlpEngine.snapshotMp3Paths(dir);
    final beforeAll = await YtDlpEngine.snapshotAllPaths(dir);

    // Auth por intento: guardadas (si hay) y luego plano.
    // Las guardadas se materializan a un temporal que se borra al final.
    final auth = AuthStore.instance;
    File? cookieFile;
    try {
      if (auth.hasStoredCookies) {
        cookieFile = await auth.materializeCookieFile();
      }
      final useStored = cookieFile != null;

      Future<int> attempt(List<String> baseArgs, {required bool stored}) async {
        lastAuthLabel = stored ? 'Guardadas' : 'Sin auth';
        notifyListeners();
        final exit = await engine.downloadAudio(
          source: source,
          outputTemplate: outTemplate,
          audioQuality: AppConfig.audioQuality,
          extraArgs: [...baseArgs, if (stored) ...['--cookiefile', cookieFile!.path]],
          onProgress: (p) {
            task.progress = p;
            task.message =
                'Descargando... ${(p * 100).toStringAsFixed(0)}%';
            notifyListeners();
          },
        );
        lastAuthOk = exit == 0;
        return exit;
      }

      var exit = await attempt(const [], stored: useStored);
      if (exit != 0 && useStored) {
        // Contingencia: una vez sin auth.
        task.message = 'Reintentando sin auth...';
        task.progress = 0;
        notifyListeners();
        exit = await attempt(const [], stored: false);
      }
      if (exit != 0) {
        // YouTube a veces responde 403 al cliente web: reintento con el
        // cliente android antes de dar la descarga por fallida.
        task.message = 'Reintentando con cliente alternativo...';
        task.progress = 0;
        notifyListeners();
        exit = await attempt(
            ['--extractor-args', 'youtube:player_client=android'], stored: useStored);
      }
      if (exit != 0) {
        throw Exception('yt-dlp fallo, codigo $exit');
      }
    } finally {
      await auth.discardCookieFile(cookieFile);
    }

    // Si se canceló mientras descargaba/convertía, no tocar nada más:
    // limpia parciales (.part, .webm/mp3 truncados, temporales) y sale.
    if (!_queue.any((t) => t.id == task.id)) {
      await YtDlpEngine.deleteNewFiles(dir, beforeAll);
      return;
    }

    // Localiza el mp3 recién generado (ignora los que ya existían).
    final mp3 = await YtDlpEngine.findNewMp3(dir, before);
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
      } catch (e) {
        AppLog.instance.warning('Etiquetado', 'Sin caratula HD: $e');
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
      } catch (e) {
        AppLog.instance.warning('Etiquetado', 'Fallo el tag propio: $e');
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
        AppConfig.ffmpegCheckTimeout,
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
    } catch (e) {
      AppLog.instance.warning('Reserva ffmpeg', e);
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
