import 'track.dart';

enum DownloadStatus { queued, downloading, completed, failed }

class DownloadTask {
  final String id;
  final Track track;
  DownloadStatus status;
  double progress; // 0.0 - 1.0
  String message;
  String? filePath;

  /// Intentos de descarga consumidos (reintento progresivo).
  int attempts;

  DownloadTask({
    required this.id,
    required this.track,
    this.status = DownloadStatus.queued,
    this.progress = 0,
    this.message = 'En cola',
    this.filePath,
    this.attempts = 0,
  });
}
