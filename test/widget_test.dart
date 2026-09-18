import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/now_playing_header.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/playback_control_panel.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/track_info_section.dart';
import 'package:sound_foundry/presentation/widgets/circular_seeker.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_bottom_nav.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_container.dart';

void main() {
  group('UI Component Tests', () {
    testWidgets('NowPlayingHeader renders menu, title, and options without chevron', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NowPlayingHeader(),
          ),
        ),
      );

      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.bySemanticsLabel('Menu'), findsOneWidget);
      expect(find.bySemanticsLabel('More options'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });

    testWidgets('TrackInfoSection renders track details and favorite button', (WidgetTester tester) async {
      final track = Track(
        id: 'test-1',
        title: 'Night Changes',
        artist: 'One Direction',
        duration: const Duration(minutes: 3, seconds: 46),
        mediaUri: '/music/night_changes.mp3',
        dateAdded: DateTime(2026, 1, 1),
        isFavorite: true,
      );

      var favoriteToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackInfoSection(
              track: track,
              position: const Duration(minutes: 1, seconds: 32),
              duration: const Duration(minutes: 3, seconds: 46),
              isFavorite: true,
              onFavoriteToggle: () => favoriteToggled = true,
            ),
          ),
        ),
      );

      expect(find.text('Night Changes'), findsOneWidget);
      expect(find.text('One Direction'), findsOneWidget);
      expect(find.text('01:32 / 03:46'), findsOneWidget);

      await tester.tap(find.byType(NeumorphicContainer), warnIfMissed: false);
      expect(favoriteToggled, isTrue);
    });

    testWidgets('PlaybackControlPanel renders CircularSeeker and playback controls', (WidgetTester tester) async {
      const state = PlaybackState(
        status: PlaybackStatus.playing,
        position: Duration(minutes: 1, seconds: 32),
        duration: Duration(minutes: 3, seconds: 46),
      );

      var playPauseTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlaybackControlPanel(
                playbackState: state,
                onPlayPauseTap: () => playPauseTapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularSeeker), findsOneWidget);
      expect(find.byType(PlaybackControlPanel), findsOneWidget);

      await tester.tap(find.byType(CircularSeeker));
      expect(playPauseTapped, isTrue);
    });

    testWidgets('NeumorphicBottomNav renders all 4 navigation destinations', (WidgetTester tester) async {
      var selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeumorphicBottomNav(
              currentIndex: selectedIndex,
              onIndexChanged: (idx) => selectedIndex = idx,
            ),
          ),
        ),
      );

      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.byType(NeumorphicBottomNav), findsOneWidget);

      // Tap second tab (All Songs)
      final gestures = find.descendant(
        of: find.byType(NeumorphicBottomNav),
        matching: find.byType(GestureDetector),
      );
      expect(gestures, findsNWidgets(4));

      await tester.tap(gestures.at(1));
      expect(selectedIndex, equals(1));
    });
  });
}
