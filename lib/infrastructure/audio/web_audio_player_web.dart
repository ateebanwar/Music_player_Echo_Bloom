import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// High-performance Web Audio element driver for Flutter Web / Microsoft Edge.
class WebAudioPlayer {
  web.HTMLAudioElement? _audio;
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<void> _endedController = StreamController<void>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<void> get onEnded => _endedController.stream;
  Stream<String> get onError => _errorController.stream;

  bool get isSupported => true;

  WebAudioPlayer() {
    _initAudio();
  }

  void _initAudio() {
    final audio = web.HTMLAudioElement();
    audio.preload = 'auto';

    audio.addEventListener(
      'timeupdate',
      ((web.Event e) {
        final sec = audio.currentTime;
        if (!_positionController.isClosed) {
          _positionController.add(Duration(milliseconds: (sec * 1000).round()));
        }
      }).toJS,
    );

    audio.addEventListener(
      'loadedmetadata',
      ((web.Event e) {
        final dur = audio.duration;
        if (!dur.isNaN && dur > 0 && !_durationController.isClosed) {
          _durationController.add(Duration(milliseconds: (dur * 1000).round()));
        }
      }).toJS,
    );

    audio.addEventListener(
      'durationchange',
      ((web.Event e) {
        final dur = audio.duration;
        if (!dur.isNaN && dur > 0 && !_durationController.isClosed) {
          _durationController.add(Duration(milliseconds: (dur * 1000).round()));
        }
      }).toJS,
    );

    audio.addEventListener(
      'ended',
      ((web.Event e) {
        if (!_endedController.isClosed) {
          _endedController.add(null);
        }
      }).toJS,
    );

    audio.addEventListener(
      'error',
      ((web.Event e) {
        if (!_errorController.isClosed) {
          _errorController.add('Web audio playback error');
        }
      }).toJS,
    );

    _audio = audio;
  }

  Future<void> load(String uri) async {
    final audio = _audio;
    if (audio == null) return;
    audio.src = uri;
    audio.load();
  }

  Future<void> play() async {
    final audio = _audio;
    if (audio == null) return;
    try {
      await audio.play().toDart;
    } catch (e) {
      // Browser autoplay restriction or loading error
      _errorController.add('Playback interrupted: $e');
    }
  }

  Future<void> pause() async {
    _audio?.pause();
  }

  Future<void> stop() async {
    final audio = _audio;
    if (audio != null) {
      audio.pause();
      audio.currentTime = 0;
    }
  }

  Future<void> seek(Duration position) async {
    final audio = _audio;
    if (audio != null) {
      audio.currentTime = position.inMilliseconds / 1000.0;
    }
  }

  Future<void> setVolume(double volume) async {
    final audio = _audio;
    if (audio != null) {
      audio.volume = volume.clamp(0.0, 1.0);
    }
  }

  Future<void> setSpeed(double speed) async {
    final audio = _audio;
    if (audio != null) {
      audio.playbackRate = speed.clamp(0.25, 3.0);
    }
  }

  Future<void> dispose() async {
    _audio?.pause();
    _audio?.src = '';
    _audio = null;
    await _positionController.close();
    await _durationController.close();
    await _endedController.close();
    await _errorController.close();
  }
}
