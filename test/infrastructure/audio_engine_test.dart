import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine_impl.dart';

void main() {
  group('AudioEngineImpl Tests', () {
    late AudioEngineImpl audioEngine;

    final testTrack = Track(
      id: 'test-1',
      title: 'Test Song',
      artist: 'Test Artist',
      duration: const Duration(seconds: 10),
      mediaUri: 'assets/audio/test.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    setUp(() {
      audioEngine = AudioEngineImpl();
    });

    tearDown(() async {
      await audioEngine.dispose();
    });

    test('load track sets duration and updates status to paused', () async {
      await audioEngine.load(testTrack);

      expect(audioEngine.currentStatus, PlaybackStatus.paused);
      expect(audioEngine.currentDuration, const Duration(seconds: 10));
      expect(audioEngine.currentPosition, Duration.zero);
    });

    test('play updates status to playing and begins progression', () async {
      await audioEngine.load(testTrack);
      await audioEngine.play();

      expect(audioEngine.currentStatus, PlaybackStatus.playing);

      // Wait a short duration for the ticker to tick
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(audioEngine.currentPosition.inMilliseconds, greaterThan(0));

      await audioEngine.pause();
      expect(audioEngine.currentStatus, PlaybackStatus.paused);
    });

    test('seek clamps within duration bounds and updates position', () async {
      await audioEngine.load(testTrack);

      await audioEngine.seek(const Duration(seconds: 5));
      expect(audioEngine.currentPosition, const Duration(seconds: 5));

      await audioEngine.seek(const Duration(seconds: 15)); // Exceeds duration
      expect(audioEngine.currentPosition, const Duration(seconds: 10));

      await audioEngine.seek(const Duration(seconds: -2)); // Negative
      expect(audioEngine.currentPosition, Duration.zero);
    });

    test('stop resets position to zero and updates status to idle', () async {
      await audioEngine.load(testTrack);
      await audioEngine.play();
      await audioEngine.seek(const Duration(seconds: 3));

      await audioEngine.stop();
      expect(audioEngine.currentStatus, PlaybackStatus.idle);
      expect(audioEngine.currentPosition, Duration.zero);
    });

    test('reaching track end triggers trackEnded event', () async {
      final shortTrack = Track(
        id: 'short-1',
        title: 'Short Song',
        artist: 'Short Artist',
        duration: const Duration(milliseconds: 80),
        mediaUri: 'assets/audio/short.mp3',
        dateAdded: DateTime(2026, 1, 1),
      );

      final events = <AudioEngineEvent>[];
      final sub = audioEngine.events.listen(events.add);

      await audioEngine.load(shortTrack);
      await audioEngine.play();

      for (int i = 0; i < 15; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        if (events.any((e) => e.type == AudioEngineEventType.trackEnded)) {
          break;
        }
      }

      expect(
        events.any((e) => e.type == AudioEngineEventType.trackEnded),
        isTrue,
      );

      await sub.cancel();
    });
  });
}
