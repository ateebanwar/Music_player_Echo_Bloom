import 'dart:async';

/// Stub implementation for non-web platforms.
class WebAudioPlayer {
  final StreamController<Duration> _positionController = StreamController<Duration>.broadcast();
  final StreamController<Duration> _durationController = StreamController<Duration>.broadcast();
  final StreamController<void> _endedController = StreamController<void>.broadcast();
  final StreamController<String> _errorController = StreamController<String>.broadcast();

  Stream<Duration> get onPositionChanged => _positionController.stream;
  Stream<Duration> get onDurationChanged => _durationController.stream;
  Stream<void> get onEnded => _endedController.stream;
  Stream<String> get onError => _errorController.stream;

  bool get isSupported => false;

  Future<void> load(String uri) async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration position) async {}
  Future<void> setVolume(double volume) async {}
  Future<void> setSpeed(double speed) async {}
  Future<void> dispose() async {
    await _positionController.close();
    await _durationController.close();
    await _endedController.close();
    await _errorController.close();
  }
}
