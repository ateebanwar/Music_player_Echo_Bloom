import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';

/// Lightweight, production-safe logger implementation.
/// Formats output with tags, timestamps, and log levels.
/// Disables verbose debug logging in release builds to protect performance and privacy.
class ConsoleLogger implements AppLogger {
  final LogLevel minLevel;
  final bool enableInRelease;

  const ConsoleLogger({
    this.minLevel = kDebugMode ? LogLevel.debug : LogLevel.info,
    this.enableInRelease = false,
  });

  bool _shouldLog(LogLevel level) {
    if (kReleaseMode && !enableInRelease) {
      return level == LogLevel.error;
    }
    return level.index >= minLevel.index;
  }

  void _log(
    LogLevel level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_shouldLog(level)) return;

    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };

    final formattedTag = tag != null ? '[$tag] ' : '';
    final logMessage = '$prefix $formattedTag$message';

    if (kDebugMode) {
      developer.log(
        logMessage,
        name: tag ?? 'EchoBloom',
        error: error,
        stackTrace: stackTrace,
        level: switch (level) {
          LogLevel.debug => 500,
          LogLevel.info => 800,
          LogLevel.warning => 900,
          LogLevel.error => 1000,
        },
      );
    }
  }

  @override
  void debug(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.debug, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  @override
  void info(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.info, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  @override
  void warning(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.warning, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  @override
  void error(String message, {String? tag, Object? error, StackTrace? stackTrace}) {
    _log(LogLevel.error, message, tag: tag, error: error, stackTrace: stackTrace);
  }
}
