import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

/// Toggles playback between play and pause.
class TogglePlaybackUseCase implements UseCase<void, NoParams> {
  final PlaybackRepository _playbackRepository;

  const TogglePlaybackUseCase(this._playbackRepository);

  @override
  Future<Result<void, Failure>> call(NoParams params) {
    return _playbackRepository.togglePlayPause();
  }
}
