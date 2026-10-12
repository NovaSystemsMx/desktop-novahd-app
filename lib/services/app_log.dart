import 'package:flutter/foundation.dart';

/// Niveles de bitácora de sesión.
enum LogLevel { info, warning, error }

/// Entrada de consola: `[Fuente] HH:MM:SS mensaje`.
class LogEntry {
  final DateTime time;
  final String source;
  final LogLevel level;
  final String message;

  LogEntry({
    required this.time,
    required this.source,
    required this.level,
    required this.message,
  });

  String get timeLabel {
    final t = time;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  /// Formato: `[Spotify] 14:32:10 mensaje`.
  String get line => '[$source] $timeLabel $message';
}

/// Bitácora de sesión (se destruye al cerrar la app).
///
/// Acceso global vía [AppLog.instance] para poder loguear desde
/// servicios sin contexto. La UI observa con Consumer.
class AppLog extends ChangeNotifier {
  AppLog._();

  static final AppLog instance = AppLog._();

  static const maxEntries = 500;

  final List<LogEntry> _entries = [];

  List<LogEntry> get entries => List.unmodifiable(_entries);

  void _add(String source, LogLevel level, String message) {
    _entries.add(LogEntry(
      time: DateTime.now(),
      source: source,
      level: level,
      message: message,
    ));
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    notifyListeners();
  }

  void info(String source, Object message) =>
      _add(source, LogLevel.info, message.toString());

  void warning(String source, Object message) =>
      _add(source, LogLevel.warning, message.toString());

  void error(String source, Object e) =>
      _add(source, LogLevel.error, e.toString().replaceFirst('Exception: ', ''));

  void clear() {
    _entries.clear();
    notifyListeners();
  }

  /// Texto plano listo para exportar como `.log`.
  String exportText() => _entries.map((e) => e.line).join('\n');
}
