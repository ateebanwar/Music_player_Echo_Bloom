import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/track.dart';

void main() {
  group('Track entity', () {
    final baseTrack = Track(
      id: 'track-1',
      title: 'Bohemian Rhapsody',
      artist: 'Queen',
      album: 'A Night at the Opera',
      duration: const Duration(minutes: 5, seconds: 55),
      mediaUri: '/storage/music/bohemian.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    test('value equality works as expected', () {
      final duplicateTrack = Track(
        id: 'track-1',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: const Duration(minutes: 5, seconds: 55),
        mediaUri: '/storage/music/bohemian.mp3',
        dateAdded: DateTime(2026, 1, 1),
      );

      expect(baseTrack, equals(duplicateTrack));
    });

    test('copyWith updates specified fields immutably', () {
      final updated = baseTrack.copyWith(
        isFavorite: true,
        title: 'Bohemian Rhapsody (Remastered)',
      );

      expect(updated.id, equals('track-1'));
      expect(updated.title, equals('Bohemian Rhapsody (Remastered)'));
      expect(updated.isFavorite, isTrue);
      expect(baseTrack.isFavorite, isFalse);
    });
  });
}
