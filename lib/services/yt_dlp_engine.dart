import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../config/app_config.dart';
import 'binaries.dart';

/// Motor de procesos yt-dlp reutilizable por cualquier módulo
/// (audio hoy; video u otros mañana).
///
/// Sin dependencias de UI: reporta progreso por callbacks y expone
/// utilidades de archivos para identificar lo recién generado.
/// La política (reintentos, nombres, etiquetas) queda en cada servicio.
class YtDlpEngine {
  YtDlpEngine();

  String? _binaryPath;
  bool _checked = false;
  bool _available = false;

  Process? _activeProcess;

  /// Verifica el binario una sola vez (resultado cacheado).
  Future<bool> ensureAvailable() async {
    if (_checked) return _available;
    _checked = true;
    try {
      _binaryPath = await Binaries.ytDlp();
      if (_binaryPath == null) {
        _available = false;
        return false;
      }
      final r = await Process.run(_binaryPath!, ['--version']).timeout(
        AppConfig.binaryCheckTimeout,
      );
      _available = r.exitCode == 0;
    } catch (_) {
      _available = false;
    }
    return _available;
  }

  /// Descarga audio y lo convierte vía ffmpeg.
  /// Devuelve el código de salida. Lanza si no hay binario.
  Future<int> downloadAudio({
    required String source,
    required String outputTemplate,
    String audioFormat = 'mp3',
    String audioQuality = AppConfig.audioQuality,
    String format = 'bestaudio/best',
    List<String> extraArgs = const [],
    void Function(double progress)? onProgress,
  }) {
    return run(
      [
        source,
        '-x',
        '--audio-format', audioFormat,
        '--audio-quality', audioQuality,
        '--format', format,
        '--no-warnings',
        '--no-playlist',
        ...extraArgs,
        '--output', outputTemplate,
        '--newline',
        '--progress',
      ],
      onProgress: onProgress,
    );
  }

  /// Ejecuta yt-dlp con argumentos arbitrarios.
  /// Devuelve el código de salida. Lanza si no hay binario.
  Future<int> run(
    List<String> args, {
    void Function(double progress)? onProgress,
  }) async {
    final exe = await _requireBinary();
    final proc = await Process.start(exe, args);
    _activeProcess = proc;
    try {
      // La salida en consola Windows puede traer bytes no UTF-8
      // (tildes en títulos): se decodifica de forma tolerante.
      const decoder = Utf8Decoder(allowMalformed: true);
      proc.stdout.transform(decoder).listen((chunk) {
        if (onProgress == null) return;
        // yt-dlp imprime "[download]  45.2% ...": se extrae el porcentaje.
        final m = RegExp(r'(\d{1,3}(?:\.\d+)?)%').firstMatch(chunk);
        if (m == null) return;
        final pct = double.tryParse(m.group(1)!);
        if (pct != null) onProgress((pct / 100).clamp(0, 1));
      });
      proc.stderr.transform(decoder).listen((_) {});
      return await proc.exitCode;
    } finally {
      if (identical(_activeProcess, proc)) _activeProcess = null;
    }
  }

  /// Metadatos completos (`--dump-json`) de una URL.
  /// Reutilizable para enriquecer filas o inspeccionar medios.
  Future<Map<String, dynamic>> fetchJson(
    String url, {
    Duration timeout = AppConfig.metadataTimeout,
    List<String> extraArgs = const [],
  }) async {
    final exe = await _requireBinary();
    final res = await Process.run(exe, [
      '--dump-json',
      '--skip-download',
      '--no-playlist',
      '--no-check-formats',
      ...extraArgs,
      url,
    ]).timeout(timeout);
    if (res.exitCode != 0) throw Exception('dump-json falló');
    final lines = (res.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('{'))
        .toList();
    if (lines.isEmpty) throw Exception('dump-json vacío');
    return jsonDecode(lines.first) as Map<String, dynamic>;
  }

  /// Mata el proceso en curso y su árbol (ej. ffmpeg hijo).
  void killActive() {
    final proc = _activeProcess;
    _activeProcess = null;
    if (proc == null) return;
    try {
      proc.kill();
    } catch (_) {}
    if (Platform.isWindows) {
      try {
        Process.run('taskkill', ['/PID', '${proc.pid}', '/T', '/F'])
            .timeout(AppConfig.taskkillTimeout);
      } catch (_) {}
    }
  }

  /// Rutas de MP3 existentes (foto "antes" para detectar el nuevo).
  static Future<Set<String>> snapshotMp3Paths(Directory dir) async {
    final paths = <String>{};
    await for (final e in dir.list()) {
      if (e is File && e.path.toLowerCase().endsWith('.mp3')) {
        paths.add(e.path);
      }
    }
    return paths;
  }

  /// Rutas de TODOS los archivos (foto "antes" para limpiar al cancelar).
  static Future<Set<String>> snapshotAllPaths(Directory dir) async {
    final paths = <String>{};
    try {
      await for (final e in dir.list()) {
        if (e is File) paths.add(e.path);
      }
    } catch (_) {}
    return paths;
  }

  /// El MP3 nuevo (no estaba en [before]); respaldo: el más reciente.
  static Future<File?> findNewMp3(
      Directory dir, Set<String> before) async {
    File? newestNew;
    var newestNewTime = DateTime.fromMillisecondsSinceEpoch(0);
    File? newestAny;
    var newestAnyTime = DateTime.fromMillisecondsSinceEpoch(0);
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

  /// Borra archivos nuevos (parciales tras cancelar).
  static Future<void> deleteNewFiles(
      Directory dir, Set<String> beforeAll) async {
    try {
      await for (final e in dir.list()) {
        if (e is File && !beforeAll.contains(e.path)) {
          try {
            await e.delete();
          } catch (_) {}
        }
      }
    } catch (_) {}
  }

  Future<String> _requireBinary() async {
    final ok = await ensureAvailable();
    if (!ok || _binaryPath == null) {
      throw Exception('Motor yt-dlp no localizado.');
    }
    return _binaryPath!;
  }
}
