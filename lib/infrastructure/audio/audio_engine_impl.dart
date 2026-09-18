import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine.dart';

/// Production-ready audio engine bridge.
/// Manages real playback lifecycle, ticking position stream, event dispatching, and streams.
/// Connects to native Android MediaPlayer for real offline MP3 audio playback.
/// Supports media notification actions (play/pause/skip) via the native MediaPlaybackService.
class AudioEngineImpl implements AudioEngine {
  final AppLogger? _logger;

  static const MethodChannel _nativePlayerChannel =
      MethodChannel('com.antigravity.sound_foundry/audio_player');

  final StreamController<AudioEngineEvent> _eventController =
      StreamController<AudioEngineEvent>.broadcast();
  final StreamController<Duration> _positionController =
      StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController =
      StreamController<Duration>.broadcast();
  final StreamController<PlaybackStatus> _statusController =
      StreamController<PlaybackStatus>.broadcast();

  PlaybackStatus _status = PlaybackStatus.idle;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  double _speed = 1.0;
  Track? _activeTrack;

  Timer? _ticker;
  DateTime? _lastTickTime;
  final bool _isAndroid = !kIsWeb && Platform.isAndroid;

  /// Callback for media notification actions (skip next/previous).
  /// Set by PlaybackRepositoryImpl to handle notification button presses.
  void Function(String action)? onMediaAction;

  AudioEngineImpl({AppLogger? logger}) : _logger = logger {
    if (_isAndroid) {
      _nativePlayerChannel.setMethodCallHandler(_handleNativeCall);
    }
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onPositionUpdate':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final posMs = (args['position'] as num?)?.toInt() ?? 0;
        final durMs = (args['duration'] as num?)?.toInt() ?? 0;

        _position = Duration(milliseconds: posMs);
        if (durMs > 0 && durMs != _duration.inMilliseconds) {
          _duration = Duration(milliseconds: durMs);
          if (!_durationController.isClosed) {
            _durationController.add(_duration);
          }
        }
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
        break;

      case 'onStatusChanged':
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final statusStr = args['status'] as String?;
        switch (statusStr) {
          case 'playing':
            _updateStatus(PlaybackStatus.playing);
            break;
          case 'paused':
            _updateStatus(PlaybackStatus.paused);
            break;
          case 'completed':
            _updateStatus(PlaybackStatus.idle);
            if (!_eventController.isClosed) {
              _eventController.add(const AudioEngineEvent(
                type: AudioEngineEventType.trackEnded,
              ));
            }
            break;
          case 'error':
            _updateStatus(PlaybackStatus.error);
            if (!_eventController.isClosed) {
              _eventController.add(const AudioEngineEvent(
                type: AudioEngineEventType.error,
                errorMessage: 'Native playback error',
              ));
            }
            break;
        }
        break;

      case 'onMediaAction':
        // Handle media notification button actions (skip next/previous)
        final args = Map<String, dynamic>.from(call.arguments as Map);
        final action = args['action'] as String?;
        if (action != null) {
          _logger?.info('Media action received: $action', tag: 'AudioEngine');
          onMediaAction?.call(action);
        }
        break;
    }
  }

  @override
  Stream<AudioEngineEvent> get events => _eventController.stream;

  @override
  Stream<Duration> get positionStream => _positionController.stream;

  @override
  Stream<Duration> get durationStream => _durationController.stream;

  @override
  Stream<PlaybackStatus> get statusStream => _statusController.stream;

  @override
  PlaybackStatus get currentStatus => _status;

  @override
  Duration get currentPosition => _position;

  @override
  Duration get currentDuration => _duration;

  @override
  Future<void> load(Track track) async {
    _logger?.info('Loading track: ${track.title} (${track.mediaUri})', tag: 'AudioEngine');
    _stopTicker();
    _activeTrack = track;
    _updateStatus(PlaybackStatus.loading);

    _duration = track.duration;
    _position = Duration.zero;

    if (!_durationController.isClosed) {
      _durationController.add(_duration);
    }
    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }

    if (_isAndroid) {
      try {
        final res = await _nativePlayerChannel.invokeMethod<Map<dynamic, dynamic>>('load', {
          'uri': track.mediaUri,
          'title': track.title,
          'artist': track.artist,
          'album': track.album,
          'artworkPath': track.artworkUri,
        });
        if (res != null && res['duration'] != null) {
          final durMs = (res['duration'] as num).toInt();
          if (durMs > 0) {
            _duration = Duration(milliseconds: durMs);
            if (!_durationController.isClosed) {
              _durationController.add(_duration);
            }
          }
        }
      } catch (e) {
        _logger?.warning('Native player load failed: $e', tag: 'AudioEngine');
        _updateStatus(PlaybackStatus.error);
        rethrow;
      }
    }

    _updateStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> play() async {
    if (_activeTrack == null) {
      _logger?.warning('Cannot play: no active track loaded', tag: 'AudioEngine');
      return;
    }
    _logger?.info('Play requested for ${_activeTrack!.title}', tag: 'AudioEngine');

    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('play');
        _updateStatus(PlaybackStatus.playing);
        return;
      } catch (e) {
        _logger?.warning('Native play failed: $e', tag: 'AudioEngine');
        _updateStatus(PlaybackStatus.error);
        rethrow;
      }
    }

    _updateStatus(PlaybackStatus.playing);
    _startTicker();
  }

  @override
  Future<void> pause() async {
    _logger?.info('Pause requested', tag: 'AudioEngine');
    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('pause');
      } catch (_) {}
    }
    _stopTicker();
    _updateStatus(PlaybackStatus.paused);
  }

  @override
  Future<void> stop() async {
    _logger?.info('Stop requested', tag: 'AudioEngine');
    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('stop');
      } catch (_) {}
    }
    _stopTicker();
    _updateStatus(PlaybackStatus.idle);
    _position = Duration.zero;
    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    final clampedMs = _duration.inMilliseconds > 0
        ? position.inMilliseconds.clamp(0, _duration.inMilliseconds)
        : position.inMilliseconds.clamp(0, 86400000);
    _position = Duration(milliseconds: clampedMs);

    _logger?.info('Seeked to ${_position.inSeconds}s', tag: 'AudioEngine');

    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('seek', {'position': clampedMs});
      } catch (_) {}
    }

    if (!_positionController.isClosed) {
      _positionController.add(_position);
    }
    if (!_eventController.isClosed) {
      _eventController.add(AudioEngineEvent(
        type: AudioEngineEventType.positionDiscontinuity,
        position: _position,
      ));
    }
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    _logger?.debug('Volume set to $_volume', tag: 'AudioEngine');
    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('setVolume', {'volume': _volume});
      } catch (_) {}
    }
  }

  @override
  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.25, 3.0);
    _logger?.debug('Playback speed set to $_speed', tag: 'AudioEngine');
    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('setSpeed', {'speed': _speed});
      } catch (_) {}
    }
  }

  List<double> _equalizerGains = [0.0, 0.0, 0.0, 0.0, 0.0];
  bool _isEqualizerEnabled = true;

  @override
  List<double> get currentEqualizerGains => List.unmodifiable(_equalizerGains);

  @override
  bool get isEqualizerEnabled => _isEqualizerEnabled;

  @override
  Future<void> setEqualizerGains(List<double> bandGains) async {
    _equalizerGains = bandGains.map((g) => g.clamp(-12.0, 12.0)).toList();
    _logger?.debug('Equalizer gains updated: $_equalizerGains', tag: 'AudioEngine');
  }

  @override
  Future<void> setEqualizerEnabled(bool enabled) async {
    _isEqualizerEnabled = enabled;
    _logger?.debug('Equalizer enabled: $_isEqualizerEnabled', tag: 'AudioEngine');
  }

  void _startTicker() {
    _stopTicker();
    _lastTickTime = DateTime.now();
    // 50ms tick for ultra-smooth 20fps circular progress updates with low CPU footprint
    _ticker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_status != PlaybackStatus.playing) {
        _stopTicker();
        return;
      }

      final now = DateTime.now();
      final elapsedMs = (_lastTickTime != null)
          ? ((now.difference(_lastTickTime!).inMilliseconds) * _speed).round()
          : 50;
      _lastTickTime = now;

      final nextPosMs = _position.inMilliseconds + elapsedMs;

      if (_duration > Duration.zero && nextPosMs >= _duration.inMilliseconds) {
        _position = _duration;
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
        _stopTicker();
        _updateStatus(PlaybackStatus.idle);
        if (!_eventController.isClosed) {
          _eventController.add(const AudioEngineEvent(
            type: AudioEngineEventType.trackEnded,
          ));
        }
      } else {
        _position = Duration(milliseconds: nextPosMs);
        if (!_positionController.isClosed) {
          _positionController.add(_position);
        }
      }
    });
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
    _lastTickTime = null;
  }

  void _updateStatus(PlaybackStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
    if (!_eventController.isClosed) {
      _eventController.add(AudioEngineEvent(
        type: AudioEngineEventType.statusChanged,
        status: _status,
      ));
    }
  }

  @override
  Future<void> dispose() async {
    _stopTicker();
    if (_isAndroid) {
      try {
        await _nativePlayerChannel.invokeMethod('stop');
      } catch (_) {}
    }
    await _eventController.close();
    await _positionController.close();
    await _durationController.close();
    await _statusController.close();
  }
}
