// Verificación del etiquetador ID3 (AudioTagger) de punta a punta.
// Uso: dart run tool/tag_check.dart <mp3_origen> <jpg_caratula> <mp3_salida>
import 'dart:io';

import 'package:desktop_novadh_app/services/audio_tagger.dart';

Future<void> main(List<String> args) async {
  if (args.length != 3) {
    stderr.writeln('Uso: dart run tool/tag_check.dart <in.mp3> <cover.jpg> <out.mp3>');
    exit(2);
  }
  final cover = await File(args[1]).readAsBytes();
  await File(args[0]).copy(args[2]);
  await AudioTagger.writeTags(
    mp3Path: args[2],
    title: 'Get Lucky (Tést ÁÉÍÓÚ ñ)',
    artist: 'Daft Punk, Pharrell Williams',
    album: 'Random Access Memories',
    coverBytes: cover,
  );
  stdout.writeln('OK tags escritos en ${args[2]}');
}
