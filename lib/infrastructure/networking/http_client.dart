import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';

/// Contract for future networking operations.
/// Completely abstracts HTTP libraries (e.g. Dio / http) from data sources and domain.
abstract class NetworkClient {
  Future<Result<Map<String, dynamic>, Failure>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
  });

  Future<Result<Map<String, dynamic>, Failure>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    Map<String, String>? headers,
  });
}
