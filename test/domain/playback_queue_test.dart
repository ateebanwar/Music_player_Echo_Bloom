import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/features/playback/playback_queue.dart';

void main() {
  group('PlaybackQueue', () {
    final track1 = Track(
      id: 't1',
      title: 'Track 1',
      artist: 'Artist 1',
      duration: const Duration(minutes: 3),
      mediaUri: '/t1.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );
    final track2 = Track(
      id: 't2',
      title: 'Track 2',
      artist: 'Artist 2',
      duration: const Duration(minutes: 4),
      mediaUri: '/t2.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );
    final track3 = Track(
      id: 't3',
      title: 'Track 3',
      artist: 'Artist 3',
      duration: const Duration(minutes: 5),
      mediaUri: '/t3.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    test('initializes with tracks and active index', () {
      final queue = const PlaybackQueue().setTracks([track1, track2, track3], initialIndex: 1);

      expect(queue.currentTrack, equals(track2));
      expect(queue.currentIndex, equals(1));
      expect(queue.currentList.length, equals(3));
    });

    test('advances next and previous properly in default repeat mode', () {
      var queue = const PlaybackQueue().setTracks([track1, track2, track3]);
      expect(queue.currentTrack, equals(track1));

      queue = queue.next();
      expect(queue.currentTrack, equals(track2));

      queue = queue.next();
      expect(queue.currentTrack, equals(track3));

      // At end of queue with repeat off, stays at end
      queue = queue.next();
      expect(queue.currentTrack, equals(track3));

      queue = queue.previous();
      expect(queue.currentTrack, equals(track2));
    });

    test('loops around in RepeatMode.all', () {
      var queue = const PlaybackQueue()
          .setTracks([track1, track2, track3], initialIndex: 2)
          .setRepeatMode(RepeatMode.all);

      queue = queue.next();
      expect(queue.currentTrack, equals(track1));

      queue = queue.previous();
      expect(queue.currentTrack, equals(track3));
    });

    test('advances normally in RepeatMode.one when not final song', () {
      var queue = const PlaybackQueue()
          .setTracks([track1, track2, track3], initialIndex: 1)
          .setRepeatMode(RepeatMode.one);

      queue = queue.next();
      expect(queue.currentTrack, equals(track3));
    });

    test('toggleShuffle shuffles and restores deterministic order', () {
      final queue = const PlaybackQueue().setTracks([track1, track2, track3], initialIndex: 0);

      final shuffledQueue = queue.toggleShuffle(Random(42));
      expect(shuffledQueue.isShuffled, isTrue);
      expect(shuffledQueue.currentTrack, equals(track1)); // current track preserved at top

      final restoredQueue = shuffledQueue.toggleShuffle();
      expect(restoredQueue.isShuffled, isFalse);
      expect(restoredQueue.currentList, equals([track1, track2, track3]));
    });

    test('addTrack appends track to queue', () {
      final queue = const PlaybackQueue().setTracks([track1, track2], initialIndex: 0);
      final updated = queue.addTrack(track3);

      expect(updated.currentList.length, 3);
      expect(updated.currentList.last, equals(track3));
      expect(updated.currentIndex, 0);
    });

    test('insertNext inserts track immediately after current index', () {
      final queue = const PlaybackQueue().setTracks([track1, track3], initialIndex: 0);
      final updated = queue.insertNext(track2);

      expect(updated.currentList.length, 3);
      expect(updated.currentList[1], equals(track2));
      expect(updated.next().currentTrack, equals(track2));
    });
  });
}
