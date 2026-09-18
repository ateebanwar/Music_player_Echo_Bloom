import 'package:equatable/equatable.dart';

/// Base abstract class for all domain-level failures.
/// Failures represent predictable, typed error states returned across boundaries.
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final Object? cause;

  const Failure({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  List<Object?> get props => [message, code, cause];

  @override
  String toString() => '$runtimeType(message: $message, code: $code)';
}

/// Storage or Database failures (e.g. read error, disk full, migration failure)
class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Audio playback failures (e.g. decode error, codec unsupported, engine init failure)
class AudioFailure extends Failure {
  const AudioFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// Permission failures (e.g. READ_MEDIA_AUDIO denied, permanently denied)
class PermissionFailure extends Failure {
  final bool isPermanentlyDenied;

  const PermissionFailure({
    required super.message,
    this.isPermanentlyDenied = false,
    super.code,
    super.cause,
  });

  @override
  List<Object?> get props => [...super.props, isPermanentlyDenied];
}

/// Media/File not found or corrupted
class MediaNotFoundFailure extends Failure {
  final String? pathOrUri;

  const MediaNotFoundFailure({
    required super.message,
    this.pathOrUri,
    super.code,
    super.cause,
  });

  @override
  List<Object?> get props => [...super.props, pathOrUri];
}

/// Network failures (future remote integration)
class NetworkFailure extends Failure {
  final int? statusCode;

  const NetworkFailure({
    required super.message,
    this.statusCode,
    super.code,
    super.cause,
  });

  @override
  List<Object?> get props => [...super.props, statusCode];
}

/// Validation failure (e.g. invalid playlist name, out of range seek)
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code,
    super.cause,
  });
}

/// General unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    required super.message,
    super.code,
    super.cause,
  });
}
