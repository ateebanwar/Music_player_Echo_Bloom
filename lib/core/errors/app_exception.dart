/// Base exception for low-level infrastructure exceptions.
/// Infrastructure exceptions are caught and converted into [Failure] objects
/// before crossing boundary into the domain layer.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final Object? originalException;
  final StackTrace? stackTrace;

  const AppException({
    required this.message,
    this.code,
    this.originalException,
    this.stackTrace,
  });

  @override
  String toString() => '$runtimeType: $message (code: $code)';
}

class AppDatabaseException extends AppException {
  const AppDatabaseException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class AudioEngineException extends AppException {
  const AudioEngineException({
    required super.message,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class FileSystemException extends AppException {
  final String? path;

  const FileSystemException({
    required super.message,
    this.path,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}

class PlatformPermissionException extends AppException {
  final bool permanentlyDenied;

  const PlatformPermissionException({
    required super.message,
    this.permanentlyDenied = false,
    super.code,
    super.originalException,
    super.stackTrace,
  });
}
