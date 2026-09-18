import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Contract for managing playback state, queue, and engine control.
abstract class PlaybackRepository {
  /// Stream emitting real-time playback state updates.
  Stream<PlaybackState> get playbackStateStream;

  /// Returns current playback snapshot.
  PlaybackState get currentState;

  /// Loads and plays a single track or queue of tracks starting at [startIndex].
  Future<Result<void, Failure>> playTrack(Track track);

  /// Sets the active queue and starts playing from [initialIndex].
  Future<Result<void, Failure>> setQueue(List<Track> queue, {int initialIndex = 0});

  /// Adds a track to the end of the active playback queue.
  Future<Result<void, Failure>> addToQueue(Track track);

  /// Inserts a track to be played immediately after the active track.
  Future<Result<void, Failure>> playNext(Track track);

  /// Resumes playback.
  Future<Result<void, Failure>> play();

  /// Pauses playback.
  Future<Result<void, Failure>> pause();

  /// Toggles between play and pause.
  Future<Result<void, Failure>> togglePlayPause();

  /// Stops playback and resets active position.
  Future<Result<void, Failure>> stop();

  /// Seeks to a specific [position].
  Future<Result<void, Failure>> seek(Duration position);

  /// Skips to the next track in the queue.
  Future<Result<void, Failure>> skipToNext();

  /// Skips to the previous track in the queue.
  Future<Result<void, Failure>> skipToPrevious();

  /// Sets the queue repeat mode.
  Future<Result<void, Failure>> setRepeatMode(RepeatMode mode);

  /// Toggles queue shuffle mode.
  Future<Result<void, Failure>> toggleShuffle();

  /// Adjusts output volume level (0.0 to 1.0).
  Future<Result<void, Failure>> setVolume(double volume);

  /// Adjusts playback speed (e.g. 0.5x to 2.0x).
  Future<Result<void, Failure>> setSpeed(double speed);
}
