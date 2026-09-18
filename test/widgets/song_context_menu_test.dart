import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/presentation/widgets/song_context_menu.dart';

void main() {
  group('SongContextMenu Tests', () {
    final testTrack = Track(
      id: 't-1',
      title: 'Night Changes',
      artist: 'One Direction',
      duration: const Duration(minutes: 3, seconds: 46),
      mediaUri: 'assets/audio/night_changes.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    testWidgets('Now Playing context menu shows state-dependent favorite and NO Add to Queue or Share', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      SongContextMenu.show(
                        context: context,
                        ref: ref,
                        track: testTrack,
                        isNowPlayingContext: true,
                        isFavorite: false,
                      );
                    },
                    child: const Text('Open Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Should show track title and artist
      expect(find.text('Night Changes'), findsOneWidget);
      expect(find.text('One Direction'), findsOneWidget);

      // Should show Add to Favorites when unliked
      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.text('Remove from Favorites'), findsNothing);

      // Should show Add to Playlist, Equalizer, Crop Audio, Set as Ringtone
      expect(find.text('Add to Playlist'), findsOneWidget);
      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.text('Crop Audio'), findsOneWidget);
      expect(find.text('Set as Ringtone'), findsOneWidget);

      // Must NOT show Add to Queue or Share in Now Playing
      expect(find.text('Add to Queue'), findsNothing);
      expect(find.text('Share'), findsNothing);
    });

    testWidgets('Now Playing context menu shows Remove from Favorites when liked', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      SongContextMenu.show(
                        context: context,
                        ref: ref,
                        track: testTrack,
                        isNowPlayingContext: true,
                        isFavorite: true,
                      );
                    },
                    child: const Text('Open Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      // Should show Remove from Favorites when liked
      expect(find.text('Remove from Favorites'), findsOneWidget);
      expect(find.text('Add to Favorites'), findsNothing);
    });

    testWidgets('All Songs context menu includes Play, Play Next, and Add to Queue', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () {
                      SongContextMenu.show(
                        context: context,
                        ref: ref,
                        track: testTrack,
                        isNowPlayingContext: false,
                        isFavorite: false,
                      );
                    },
                    child: const Text('Open Menu'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Play'), findsOneWidget);
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);
      expect(find.text('Share'), findsNothing);
    });
  });
}
