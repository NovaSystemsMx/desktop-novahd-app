// Verifica YtDlpEngine con una descarga real a TEMP.
// Uso: dart run tool/engine_check.dart
import 'dart:io';

import 'package:desktop_novadh_app/services/yt_dlp_engine.dart';

Future<void> main() async {
  final engine = YtDlpEngine();
  final ok = await engine.ensureAvailable();
  stdout.writeln('available: $ok');
  if (!ok) throw StateError('sin yt-dlp');
  final dir = await Directory.systemTemp.createTemp('novadh_engine');
  final out = '${dir.path}\\%(title)s.%(ext)s';
  final exit = await engine.downloadAudio(
    source: 'https://www.youtube.com/watch?v=4D7u5KF7SP8',
    outputTemplate: out,
    onProgress: (p) =>
        stdout.writeln('progress: ${(p * 100).toStringAsFixed(0)}%'),
  );
  stdout.writeln('exit: $exit');
  final before = <String>{};
  final mp3 = await YtDlpEngine.findNewMp3(dir, before);
  stdout.writeln('mp3: ${mp3?.path} (${await mp3?.length()} bytes)');
  if (exit != 0 || mp3 == null) throw StateError('FAIL');
  await dir.delete(recursive: true);
  stdout.writeln('OK');
}
