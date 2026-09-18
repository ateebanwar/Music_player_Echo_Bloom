import 'package:equatable/equatable.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Playback execution status.
enum PlaybackStatus {
  idle,
  loading,
  buffering,
  playing,
  paused,
  completed,
  error,
}

/// Loop/Repeat modes for the playback queue.
enum RepeatMode {
  off,
  all,
  one,
}

/// Immutable state snapshot of the playback subsystem.
class PlaybackState extends Equatable {
  final PlaybackStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final Duration bufferedPosition;
  final double playbackSpeed;
  final double volume;
  final bool isMuted;
  final RepeatMode repeatMode;
  final bool isShuffleEnabled;
  final String? errorMessage;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.playbackSpeed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    this.repeatMode = RepeatMode.off,
    this.isShuffleEnabled = false,
    this.errorMessage,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get isLoading => status == PlaybackStatus.loading || status == PlaybackStatus.buffering;
  bool get hasActiveTrack => currentTrack != null;

  PlaybackState copyWith({
    PlaybackStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    Duration? bufferedPosition,
    double? playbackSpeed,
    double? volume,
    bool? isMuted,
    RepeatMode? repeatMode,
    bool? isShuffleEnabled,
    String? errorMessage,
    bool clearCurrentTrack = false,
    bool clearErrorMessage = false,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: clearCurrentTrack ? null : (currentTrack ?? this.currentTrack),
      position: position ?? this.position,
      duration: duration ?? this.duration,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        currentTrack,
        position,
        duration,
        bufferedPosition,
        playbackSpeed,
        volume,
        isMuted,
        repeatMode,
        isShuffleEnabled,
        errorMessage,
      ];
}
