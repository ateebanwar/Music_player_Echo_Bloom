import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/core/types/pagination.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

/// Retrieves a paginated slice of tracks.
class GetTracksUseCase implements UseCase<PaginatedList<Track>, PageQuery> {
  final TrackRepository _repository;

  const GetTracksUseCase(this._repository);

  @override
  Future<Result<PaginatedList<Track>, Failure>> call(PageQuery params) {
    return _repository.getTracks(params);
  }
}
