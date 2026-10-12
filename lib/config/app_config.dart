/// Configuración central (evita números mágicos regados).
/// Tiempos, topes y calidades del pipeline en un solo lugar.
abstract class AppConfig {
  // Red (YouTube Music / yt-dlp).
  static const searchTimeout = Duration(seconds: 25);
  static const playerTimeout = Duration(seconds: 20);
  static const enrichTimeout = Duration(seconds: 30);
  static const durationFillTimeout = Duration(seconds: 12);
  static const metadataTimeout = Duration(seconds: 20);
  static const flatSearchTimeout = Duration(seconds: 40);
  static const binaryCheckTimeout = Duration(seconds: 8);
  static const taskkillTimeout = Duration(seconds: 5);

  // Búsqueda y cola.
  static const searchLimit = 15;
  static const maxAttempts = 3;
  static const backoffFirst = Duration(seconds: 5);
  static const backoffSecond = Duration(seconds: 15);

  // Audio.
  static const audioQuality = '0';

  // UI.
  static const noticeDuration = Duration(seconds: 4);

  // Localización de binarios en PATH.
  static const lookupTimeout = Duration(seconds: 5);

  // Verificación de ffmpeg para la reserva de carátula.
  static const ffmpegCheckTimeout = Duration(seconds: 6);
}
