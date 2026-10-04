// Verificación del parser de YouTube Music contra el API real.
// Uso: dart run tool/ytm_check.dart "daft punk get lucky"
import 'dart:io';

import 'package:desktop_novadh_app/services/ytmusic_service.dart';

Future<void> main(List<String> args) async {
  final q = args.isEmpty ? 'daft punk get lucky' : args.join(' ');
  final tracks = await YouTubeMusicService().searchSongs(q);
  stdout.writeln('BASE: ${tracks.length}');
  final enriched =
      await YouTubeMusicService().enrichTracks(tracks.take(3).toList());
  stdout.writeln('ENRIQUECIDOS: ${enriched.length}');
  for (final t in enriched) {
    stdout.writeln(
        '- ${t.title} | ${t.artistsLabel} | ${t.album} | ${t.durationLabel} | ${t.imageLarge}');
  }
  if (enriched.isEmpty) exit(1);
}
