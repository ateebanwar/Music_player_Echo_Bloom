import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/playback/playback_repository_impl.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine_impl.dart';

void main() {
  group('PlaybackRepository Integration Tests', () {
    late AudioEngineImpl audioEngine;
    late PlaybackRepositoryImpl playbackRepo;

    final track1 = Track(
      id: 't-1',
      title: 'Song One',
      artist: 'Artist A',
      duration: const Duration(seconds: 100),
      mediaUri: 'assets/audio/1.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    final track2 = Track(
      id: 't-2',
      title: 'Song Two',
      artist: 'Artist B',
      duration: const Duration(seconds: 120),
      mediaUri: 'assets/audio/2.mp3',
      dateAdded: DateTime(2026, 1, 2),
    );

    setUp(() {
      audioEngine = AudioEngineImpl();
      playbackRepo = PlaybackRepositoryImpl(audioEngine: audioEngine);
    });

    tearDown(() {
      playbackRepo.dispose();
      audioEngine.dispose();
    });

    test('setQueue sets queue and plays initial track', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);

      expect(playbackRepo.currentState.currentTrack?.id, 't-1');
      expect(playbackRepo.currentState.isPlaying, isTrue);
    });

    test('skipToNext advances to next track in queue', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);
      await playbackRepo.skipToNext();

      expect(playbackRepo.currentState.currentTrack?.id, 't-2');
    });

    test('skipToPrevious restarts track if position > 3 seconds', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 1);
      await playbackRepo.seek(const Duration(seconds: 10));

      await playbackRepo.skipToPrevious();

      // Should restart current track (t-2) to position 0 instead of jumping to t-1
      expect(playbackRepo.currentState.currentTrack?.id, 't-2');
      expect(playbackRepo.currentState.position, Duration.zero);
    });

    test('skipToPrevious jumps to previous track if position <= 3 seconds', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 1);
      await playbackRepo.seek(const Duration(seconds: 1));

      await playbackRepo.skipToPrevious();

      expect(playbackRepo.currentState.currentTrack?.id, 't-1');
    });

    test('toggleShuffle and setRepeatMode update state predictably', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);

      await playbackRepo.toggleShuffle();
      expect(playbackRepo.currentState.isShuffleEnabled, isTrue);

      await playbackRepo.setRepeatMode(RepeatMode.all);
      expect(playbackRepo.currentState.repeatMode, RepeatMode.all);

      await playbackRepo.setRepeatMode(RepeatMode.one);
      expect(playbackRepo.currentState.repeatMode, RepeatMode.one);
    });

    test('skipToNext at end of queue with RepeatMode.off does not crash or loop', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 1);
      expect(playbackRepo.currentState.currentTrack?.id, 't-2');

      await playbackRepo.skipToNext();

      // Should remain safely at t-2 without restarting or crashing
      expect(playbackRepo.currentState.currentTrack?.id, 't-2');
    });

    test('skipToNext at end of queue with RepeatMode.all wraps to first track', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 1);
      await playbackRepo.setRepeatMode(RepeatMode.all);

      await playbackRepo.skipToNext();

      expect(playbackRepo.currentState.currentTrack?.id, 't-1');
    });

    test('skipToNext with RepeatMode.one advances to next track when manually triggered', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);
      await playbackRepo.setRepeatMode(RepeatMode.one);

      await playbackRepo.skipToNext();

      expect(playbackRepo.currentState.currentTrack?.id, 't-2');
    });

    test('skipToPrevious at start of queue with RepeatMode.off seeks to zero', () async {
      await playbackRepo.setQueue([track1, track2], initialIndex: 0);
      await playbackRepo.seek(const Duration(seconds: 1));

      await playbackRepo.skipToPrevious();

      expect(playbackRepo.currentState.currentTrack?.id, 't-1');
      expect(playbackRepo.currentState.position, Duration.zero);
    });
  });
}
