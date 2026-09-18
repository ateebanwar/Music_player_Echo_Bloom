import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/presentation/widgets/create_playlist_dialog.dart';

void main() {
  group('CreatePlaylistDialog Tests', () {
    final testTrack = Track(
      id: 'song-1',
      title: 'Night Changes',
      artist: 'One Direction',
      duration: const Duration(minutes: 3, seconds: 46),
      mediaUri: 'assets/audio/night_changes.mp3',
      dateAdded: DateTime(2026, 1, 1),
    );

    testWidgets('Renders input field, Cancel, and Create buttons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CreatePlaylistDialog.show(context: context, ref: ref),
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('New Playlist'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });

    testWidgets('Rejects empty or whitespace-only names with validation error', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CreatePlaylistDialog.show(context: context, ref: ref),
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Tap create with empty input
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.text('Please enter a playlist name'), findsOneWidget);

      // Enter only whitespace
      await tester.enterText(find.byType(TextField), '     ');
      await tester.tap(find.text('Create'));
      await tester.pump();

      expect(find.text('Please enter a playlist name'), findsOneWidget);
    });

    testWidgets('Cancel button dismisses dialog without creating', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CreatePlaylistDialog.show(context: context, ref: ref),
                    child: const Text('Open Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Chill Vibes');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(CreatePlaylistDialog), findsNothing);
    });

    testWidgets('Song context creation displays song name in subtitle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  return ElevatedButton(
                    onPressed: () => CreatePlaylistDialog.show(
                      context: context,
                      ref: ref,
                      initialTrack: testTrack,
                    ),
                    child: const Text('Open Song Dialog'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Song Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Create a playlist and add "Night Changes"'), findsOneWidget);
    });
  });
}
