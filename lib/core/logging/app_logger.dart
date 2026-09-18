/// Severity levels for application logging.
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Abstract contract for logging across the application.
/// Isolates concrete logging implementations and prevents scattering print() calls.
abstract class AppLogger {
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace});
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace});
}
