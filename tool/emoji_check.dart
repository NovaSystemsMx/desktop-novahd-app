// Verifica safeFileName: quita ilegales y emojis, conserva idiomas.
// Uso: dart run tool/emoji_check.dart
import 'package:desktop_novadh_app/models/track.dart';

void main() {
  const t = Track(
    id: 'x1',
    title: 'Viernes \u{1F525} (Official \u{1F3B5}) ¿Qué? Música 日本語',
    artists: ['Daft Punk', 'Pharrell \u{2764}'],
    album: 'Random Access Memories',
    durationMs: 249000,
    imageSmall: '',
    imageLarge: '',
    spotifyUrl: '',
  );
  final name = t.safeFileName;
  print('SAFE: [$name]');
  final bad = RegExp(r'[<>:"/\\|?*]').hasMatch(name);
  final emoji = RegExp('[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]',
      unicode: true).hasMatch(name);
  print('ilegales: $bad, emojis: $emoji');
  if (bad || emoji) throw StateError('FAIL');
  for (final keep in ['Daft Punk', 'Música', '日本語']) {
    if (!name.contains(keep)) throw StateError('FAIL falta $keep');
  }
  print('OK');
}
