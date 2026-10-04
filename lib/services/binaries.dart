import 'dart:io';

/// Localiza `yt-dlp` y `ffmpeg` sin depender del PATH heredado por el proceso.
///
/// La app puede arrancar con un PATH desactualizado (instalaciones de winget
/// posteriores al inicio de sesión), así que además del PATH se buscan los
/// paquetes de winget y rutas comunes por ruta absoluta.
class Binaries {
  static String? _ytDlpPath;
  static String? _ffmpegPath;

  static Future<String?> ytDlp() async =>
      _ytDlpPath ??= await _find(
        command: 'yt-dlp',
        exe: 'yt-dlp.exe',
        wingetPrefix: 'yt-dlp.yt-dlp_',
      );

  static Future<String?> ffmpeg() async =>
      _ffmpegPath ??= await _find(
        command: 'ffmpeg',
        exe: 'ffmpeg.exe',
        wingetPrefix: 'Gyan.FFmpeg_',
      );

  static void invalidate() {
    _ytDlpPath = null;
    _ffmpegPath = null;
  }

  static Future<String?> _find({
    required String command,
    required String exe,
    required String wingetPrefix,
  }) async {
    // 1) PATH del proceso (funciona si la sesión se abrió tras instalar).
    try {
      final w = await Process.run('where.exe', [command])
          .timeout(const Duration(seconds: 5));
      if (w.exitCode == 0) {
        final line = (w.stdout as String)
            .split(RegExp(r'\r?\n'))
            .map((s) => s.trim())
            .firstWhere(
                (s) => s.toLowerCase().endsWith('.exe'),
                orElse: () => '');
        if (line.isNotEmpty) {
          try {
            if (await File(line).exists()) return line;
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 2) Paquetes de winget (estable aunque el PATH esté desactualizado).
    try {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      if (localAppData != null && localAppData.isNotEmpty) {
        final pkgs =
            Directory('$localAppData\\Microsoft\\WinGet\\Packages');
        if (await pkgs.exists()) {
          await for (final d in pkgs.list()) {
            if (d is Directory &&
                d.path
                    .split(Platform.pathSeparator)
                    .last
                    .startsWith(wingetPrefix)) {
              final hit =
                  await _searchExe(Directory(d.path), exe, depth: 3);
              if (hit != null) return hit;
            }
          }
        }
      }
    } catch (_) {}

    // 3) Rutas comunes de instalación manual.
    final pf = Platform.environment['ProgramFiles'];
    final candidates = <String>[
      if (pf != null) '$pf\\yt-dlp\\$exe',
      if (command == 'ffmpeg' && pf != null) '$pf\\Gyan\\FFmpeg\\bin\\$exe',
    ];
    for (final c in candidates) {
      try {
        if (await File(c).exists()) return c;
      } catch (_) {}
    }
    return null;
  }

  static Future<String?> _searchExe(Directory dir, String exe,
      {required int depth}) async {
    if (depth < 0) return null;
    try {
      await for (final e in dir.list()) {
        if (e is File &&
            e.path.split(Platform.pathSeparator).last.toLowerCase() ==
                exe.toLowerCase()) {
          return e.path;
        }
      }
      if (depth > 0) {
        await for (final e in dir.list()) {
          if (e is Directory) {
            final hit = await _searchExe(e, exe, depth: depth - 1);
            if (hit != null) return hit;
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
