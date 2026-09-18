import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

/// Initiates playback for a specific track.
class PlayTrackUseCase implements UseCase<void, Track> {
  final PlaybackRepository _playbackRepository;

  const PlayTrackUseCase(this._playbackRepository);

  @override
  Future<Result<void, Failure>> call(Track track) {
    return _playbackRepository.playTrack(track);
  }
}
