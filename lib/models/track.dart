/// Modelo de pista devuelta por la búsqueda de Spotify.
class Track {
  final String id;
  final String title;
  final List<String> artists;
  final String album;
  final int durationMs;
  final String imageSmall; // ~300px
  final String imageLarge; // máxima calidad disponible (~640px)
  final String spotifyUrl;

  /// URL directa de YouTube cuando el resultado viene de yt-dlp.
  /// Si está vacía, el descargador usa [youtubeQuery] con ytsearch1.
  final String youtubeUrl;

  const Track({
    required this.id,
    required this.title,
    required this.artists,
    required this.album,
    required this.durationMs,
    required this.imageSmall,
    required this.imageLarge,
    required this.spotifyUrl,
    this.youtubeUrl = '',
  });

  String get artistsLabel => artists.join(', ');

  Track copyWith({
    String? title,
    List<String>? artists,
    String? album,
    int? durationMs,
    String? imageSmall,
    String? imageLarge,
  }) {
    return Track(
      id: id,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      durationMs: durationMs ?? this.durationMs,
      imageSmall: imageSmall ?? this.imageSmall,
      imageLarge: imageLarge ?? this.imageLarge,
      spotifyUrl: spotifyUrl,
      youtubeUrl: youtubeUrl,
    );
  }

  String get durationLabel {
    if (durationMs <= 0) return '—';
    final totalSec = durationMs ~/ 1000;
    final m = totalSec ~/ 60;
    final s = totalSec % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Nombre de archivo seguro para Windows.
  /// Quita caracteres ilegales y emojis (como el pipeline Python),
  /// conservando letras de cualquier idioma.
  String get safeFileName {
    final base = '$artistsLabel - $title';
    var cleaned = base.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '');
    cleaned = _stripEmojis(cleaned).trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.isEmpty) return 'track_$id';
    return cleaned.length > 120 ? cleaned.substring(0, 120).trim() : cleaned;
  }

  static final _emojiPattern = RegExp(
    '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}'
    '\u{FE00}-\u{FE0F}\u{200D}\u{20E3}\u{2190}-\u{21FF}'
    '\u{2300}-\u{23FF}\u{2C00}-\u{2C5F}\u{1F000}-\u{1F2FF}]',
    unicode: true,
  );

  static String _stripEmojis(String s) => s.replaceAll(_emojiPattern, '');

  /// Término de búsqueda para localizar el audio en YouTube.
  String get youtubeQuery => '$artistsLabel - $title audio';
}
