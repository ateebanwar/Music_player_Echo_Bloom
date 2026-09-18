import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

/// Retrieves a specific track by ID.
class GetTrackByIdUseCase implements UseCase<Track, String> {
  final TrackRepository _repository;

  const GetTrackByIdUseCase(this._repository);

  @override
  Future<Result<Track, Failure>> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const Result.err(ValidationFailure(message: 'Track ID cannot be empty')),
      );
    }
    return _repository.getTrackById(id);
  }
}
