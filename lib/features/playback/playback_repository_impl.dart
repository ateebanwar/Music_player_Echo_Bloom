import 'dart:async';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/domain/repositories/history_repository.dart';
import 'package:sound_foundry/domain/repositories/playback_repository.dart';
import 'package:sound_foundry/domain/repositories/track_repository.dart';
import 'package:sound_foundry/features/playback/playback_queue.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine_impl.dart';

/// Concrete implementation of [PlaybackRepository].
/// Coordinates the [AudioEngine] abstraction, [PlaybackQueue], and [HistoryRepository].
class PlaybackRepositoryImpl implements PlaybackRepository {
  final AudioEngine _audioEngine;
  final HistoryRepository? _historyRepository;
  final TrackRepository? _trackRepository;
  final AppLogger? _logger;

  final StreamController<PlaybackState> _stateController =
      StreamController<PlaybackState>.broadcast();

  PlaybackState _currentState = const PlaybackState();
  PlaybackQueue _queue = const PlaybackQueue();
  bool _isInitiatingPlayback = false;

  StreamSubscription<AudioEngineEvent>? _eventSub;
  StreamSubscription<PlaybackStatus>? _statusSub;
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<Duration>? _durSub;

  PlaybackRepositoryImpl({
    required AudioEngine audioEngine,
    HistoryRepository? historyRepository,
    TrackRepository? trackRepository,
    AppLogger? logger,
  })  : _audioEngine = audioEngine,
        _historyRepository = historyRepository,
        _trackRepository = trackRepository,
        _logger = logger {
    _initEngineListeners();
    // Wire up media notification action callbacks (skip next/previous from notification)
    if (audioEngine is AudioEngineImpl) {
      audioEngine.onMediaAction = _handleMediaAction;
    }
  }

  void _handleMediaAction(String action) {
    switch (action) {
      case 'next':
        skipToNext();
        break;
      case 'previous':
        skipToPrevious();
        break;
    }
  }

  void _initEngineListeners() {
    _eventSub = _audioEngine.events.listen((event) {
      switch (event.type) {
        case AudioEngineEventType.trackEnded:
          _handleTrackEnded();
          break;
        case AudioEngineEventType.error:
          _currentState = _currentState.copyWith(
            status: PlaybackStatus.error,
            errorMessage: event.errorMessage ?? 'Playback error occurred',
          );
          _emitState();
          break;
        case AudioEngineEventType.statusChanged:
          if (event.status != null) {
            if (_isInitiatingPlayback && event.status == PlaybackStatus.paused) {
              break;
            }
            _currentState = _currentState.copyWith(status: event.status);
            _emitState();
          }
          break;
        case AudioEngineEventType.positionDiscontinuity:
          if (event.position != null) {
            _currentState = _currentState.copyWith(position: event.position);
            _emitState();
          }
          break;
      }
    });

    _statusSub = _audioEngine.statusStream.listen((status) {
      if (_isInitiatingPlayback && status == PlaybackStatus.paused) {
        return;
      }
      _currentState = _currentState.copyWith(status: status);
      _emitState();
    });

    _posSub = _audioEngine.positionStream.listen((position) {
      final prevSec = _currentState.position.inSeconds;
      _currentState = _currentState.copyWith(position: position);
      if (position.inSeconds != prevSec) {
        _emitState();
      }
    });

    _durSub = _audioEngine.durationStream.listen((duration) {
      _currentState = _currentState.copyWith(duration: duration);
      _emitState();
    });
  }

  Future<void> _handleTrackEnded() async {
    final finishedTrack = _currentState.currentTrack;
    if (finishedTrack != null && _historyRepository != null) {
      unawaited(_historyRepository.recordPlay(
        track: finishedTrack,
        playedDuration: finishedTrack.duration,
        completed: true,
      ));
    }

    if (_currentState.repeatMode == RepeatMode.one && finishedTrack != null) {
      await seek(Duration.zero);
      await play();
    } else if (_queue.hasNext) {
      await skipToNext();
    } else {
      await stop();
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  @override
  Stream<PlaybackState> get playbackStateStream => _stateController.stream;

  @override
  PlaybackState get currentState => _currentState;

  PlaybackQueue get currentQueue => _queue;

  @override
  Future<Result<void, Failure>> playTrack(Track track) async {
    try {
      Track trackToPlay = track;

      // Dynamically resolve stream URL for remote tracks if needed
      if (track.sourceType == TrackSourceType.remoteStream) {
        if (track.mediaUri.isEmpty || !track.mediaUri.startsWith('http')) {
          _currentState = _currentState.copyWith(
            currentTrack: track,
            status: PlaybackStatus.loading,
            clearErrorMessage: true,
          );
          _emitState();

          if (_trackRepository != null) {
            final resolvedUri = await _trackRepository.resolveStreamUri(
              track.mediaUri.isNotEmpty ? track.mediaUri : track.id,
              track,
            );
            if (resolvedUri.isNotEmpty &&
                (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://'))) {
              trackToPlay = track.copyWith(mediaUri: resolvedUri);
              unawaited(_trackRepository.upsertTracks([trackToPlay]));
            } else {
              _currentState = _currentState.copyWith(
                status: PlaybackStatus.error,
                errorMessage: 'Unable to play this song right now.',
              );
              _emitState();
              return const Result.err(AudioFailure(message: 'Unable to play this song right now.'));
            }
          }
        }
      }

      if (_queue.originalList.isEmpty || !_queue.originalList.any((t) => t.id == trackToPlay.id)) {
        _queue = _queue.setTracks([trackToPlay], initialIndex: 0);
      } else {
        final trackIdx = _queue.currentList.indexWhere((t) => t.id == trackToPlay.id);
        if (trackIdx >= 0) {
          _queue = _queue.copyWith(currentIndex: trackIdx);
        }
      }

      _currentState = _currentState.copyWith(
        currentTrack: trackToPlay,
        position: Duration.zero,
        duration: trackToPlay.duration > Duration.zero ? trackToPlay.duration : Duration.zero,
        status: PlaybackStatus.loading,
        clearErrorMessage: true,
      );
      _emitState();

      _isInitiatingPlayback = true;
      try {
        bool loadSucceeded = false;
        try {
          await _audioEngine.load(trackToPlay);
          loadSucceeded = true;
        } catch (e) {
          // If initial load failed for a remote track (e.g. expired CDN link), resolve a fresh stream URL
          if (trackToPlay.sourceType == TrackSourceType.remoteStream && _trackRepository != null) {
            _logger?.info('Initial remote stream load failed for "${trackToPlay.title}", resolving fresh stream...', tag: 'PlaybackRepository');
            final resolvedUri = await _trackRepository.resolveStreamUri(
              trackToPlay.remotePermaUrl ?? (trackToPlay.id.isNotEmpty ? trackToPlay.id : trackToPlay.title),
              trackToPlay,
            );
            if (resolvedUri.isNotEmpty &&
                (resolvedUri.startsWith('http://') || resolvedUri.startsWith('https://')) &&
                resolvedUri != trackToPlay.mediaUri) {
              trackToPlay = trackToPlay.copyWith(mediaUri: resolvedUri);
              unawaited(_trackRepository.upsertTracks([trackToPlay]));
              await _audioEngine.load(trackToPlay);
              loadSucceeded = true;
            }
          }
          if (!loadSucceeded) {
            rethrow;
          }
        }

        await _audioEngine.play();
        _currentState = _currentState.copyWith(
          status: PlaybackStatus.playing,
          currentTrack: trackToPlay,
        );
        _emitState();
      } finally {
        _isInitiatingPlayback = false;
      }

      if (_historyRepository != null) {
        unawaited(_historyRepository.recordPlay(
          track: track,
          playedDuration: Duration.zero,
          completed: false,
        ));
      }

      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to play track ${track.title}', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      _currentState = _currentState.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Playback error: $e',
      );
      _emitState();
      return Result.err(AudioFailure(message: 'Could not play track: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setQueue(List<Track> queue, {int initialIndex = 0}) async {
    try {
      if (queue.isEmpty) {
        await stop();
        _queue = const PlaybackQueue();
        return const Result.ok(null);
      }

      _queue = _queue.setTracks(queue, initialIndex: initialIndex);
      final active = _queue.currentTrack;
      if (active != null) {
        return await playTrack(active);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set playback queue', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set queue: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> addToQueue(Track track) async {
    try {
      _queue = _queue.addTrack(track);
      if (_currentState.currentTrack == null) {
        return await playTrack(track);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to add track to queue', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not add to queue: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> playNext(Track track) async {
    try {
      _queue = _queue.insertNext(track);
      if (_currentState.currentTrack == null) {
        return await playTrack(track);
      }
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to insert track next', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not play next: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> play() async {
    try {
      if (_currentState.currentTrack == null && _queue.currentTrack != null) {
        return await playTrack(_queue.currentTrack!);
      }
      await _audioEngine.play();
      _currentState = _currentState.copyWith(status: PlaybackStatus.playing);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to play', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not start playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> pause() async {
    try {
      await _audioEngine.pause();
      _currentState = _currentState.copyWith(status: PlaybackStatus.paused);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to pause', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not pause playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> togglePlayPause() async {
    if (_currentState.isPlaying) {
      return await pause();
    } else {
      return await play();
    }
  }

  @override
  Future<Result<void, Failure>> stop() async {
    try {
      await _audioEngine.stop();
      _currentState = _currentState.copyWith(
        status: PlaybackStatus.idle,
        position: Duration.zero,
      );
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to stop playback', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not stop playback: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> seek(Duration position) async {
    try {
      await _audioEngine.seek(position);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to seek', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not seek: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> skipToNext() async {
    if (_queue.isEmpty) {
      return const Result.ok(null);
    }

    if (!_queue.hasNext) {
      // End of queue reached with RepeatMode.off
      return const Result.ok(null);
    }

    _queue = _queue.next();
    final nextTrack = _queue.currentTrack;
    if (nextTrack != null) {
      return await playTrack(nextTrack);
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> skipToPrevious() async {
    if (_queue.isEmpty) {
      return const Result.ok(null);
    }

    // If we are more than 3 seconds into the track, restart from 0:00 (standard UX)
    if (_currentState.position > const Duration(seconds: 3)) {
      await seek(Duration.zero);
      return const Result.ok(null);
    }

    if (!_queue.hasPrevious) {
      // At the start of the queue with RepeatMode.off: restart from 0:00
      await seek(Duration.zero);
      return const Result.ok(null);
    }

    _queue = _queue.previous();
    final prevTrack = _queue.currentTrack;
    if (prevTrack != null) {
      return await playTrack(prevTrack);
    }
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setRepeatMode(RepeatMode mode) async {
    _queue = _queue.setRepeatMode(mode);
    _currentState = _currentState.copyWith(repeatMode: mode);
    _emitState();
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> toggleShuffle() async {
    _queue = _queue.toggleShuffle();
    _currentState = _currentState.copyWith(isShuffleEnabled: _queue.isShuffled);
    _emitState();
    return const Result.ok(null);
  }

  @override
  Future<Result<void, Failure>> setVolume(double volume) async {
    try {
      await _audioEngine.setVolume(volume);
      _currentState = _currentState.copyWith(volume: volume);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set volume', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set volume: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setSpeed(double speed) async {
    try {
      await _audioEngine.setSpeed(speed);
      _currentState = _currentState.copyWith(playbackSpeed: speed);
      _emitState();
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Failed to set speed', tag: 'PlaybackRepository', error: e, stackTrace: stack);
      return Result.err(AudioFailure(message: 'Could not set speed: $e', cause: e));
    }
  }

  void dispose() {
    _eventSub?.cancel();
    _statusSub?.cancel();
    _posSub?.cancel();
    _durSub?.cancel();
    _stateController.close();
  }
}
