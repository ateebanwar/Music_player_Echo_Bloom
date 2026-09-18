import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';

/// Low-level audio engine event types.
enum AudioEngineEventType {
  statusChanged,
  positionDiscontinuity,
  trackEnded,
  error,
}

/// Event emitted by the underlying audio engine.
class AudioEngineEvent {
  final AudioEngineEventType type;
  final PlaybackStatus? status;
  final Duration? position;
  final Duration? duration;
  final String? errorMessage;

  const AudioEngineEvent({
    required this.type,
    this.status,
    this.position,
    this.duration,
    this.errorMessage,
  });
}

/// Abstract contract for low-level audio playback engines.
/// Decouples the application from any concrete audio package (e.g. just_audio,
/// audioplayers, flutter_soloud, platform channels).
abstract class AudioEngine {
  /// Stream of raw engine events.
  Stream<AudioEngineEvent> get events;

  /// Stream of current playback position.
  Stream<Duration> get positionStream;

  /// Stream of playback duration for the active media source.
  Stream<Duration> get durationStream;

  /// Stream of playback status (playing, paused, loading, etc.).
  Stream<PlaybackStatus> get statusStream;

  /// Current playback status.
  PlaybackStatus get currentStatus;

  /// Current position.
  Duration get currentPosition;

  /// Current duration.
  Duration get currentDuration;

  /// Loads and prepares a track for playback without starting automatically.
  Future<void> load(Track track);

  /// Starts or resumes playback.
  Future<void> play();

  /// Pauses playback.
  Future<void> pause();

  /// Stops playback and releases loaded media resources.
  Future<void> stop();

  /// Seeks to a specific [position].
  Future<void> seek(Duration position);

  /// Sets audio volume between 0.0 (silent) and 1.0 (maximum).
  Future<void> setVolume(double volume);

  /// Sets playback rate/speed multiplier (e.g. 1.0 = normal).
  Future<void> setSpeed(double speed);

  /// Sets frequency band gains in dB for the audio equalizer pipeline.
  Future<void> setEqualizerGains(List<double> bandGains);

  /// Enables or disables equalizer processing in the audio pipeline.
  Future<void> setEqualizerEnabled(bool enabled);

  /// Current active frequency band gains in dB.
  List<double> get currentEqualizerGains;

  /// Whether equalizer processing is currently active.
  bool get isEqualizerEnabled;

  /// Releases audio engine resources.
  Future<void> dispose();
}
