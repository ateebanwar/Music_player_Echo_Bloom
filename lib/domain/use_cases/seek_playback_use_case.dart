import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/use_cases/use_case.dart';

/// Seeks current playback position to [Duration].
class SeekPlaybackUseCase implements UseCase<void, Duration> {
  final PlaybackRepository _playbackRepository;

  const SeekPlaybackUseCase(this._playbackRepository);

  @override
  Future<Result<void, Failure>> call(Duration position) {
    if (position.isNegative) {
      return Future.value(
        const Result.err(ValidationFailure(message: 'Seek position cannot be negative')),
      );
    }
    return _playbackRepository.seek(position);
  }
}
