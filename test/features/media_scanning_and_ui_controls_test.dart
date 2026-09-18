import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/track.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/playback_control_panel.dart';
import 'package:sound_foundry/presentation/screens/now_playing/widgets/track_info_section.dart';
import 'package:sound_foundry/presentation/widgets/custom_icons.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_container.dart';
import 'package:sound_foundry/presentation/widgets/track_artwork_widget.dart';
import 'package:sound_foundry/presentation/widgets/user_profile_avatar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Media Scanning, Album Art, Repeat Indicator & Favorite Controls Tests', () {
    testWidgets('CustomIcons.repeat renders numeric 1 indicator when isRepeatOne is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomIcons.repeat(size: 24.0, isRepeatOne: true),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('CustomIcons.repeat does NOT render 1 indicator when isRepeatOne is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CustomIcons.repeat(size: 24.0, isRepeatOne: false),
            ),
          ),
        ),
      );

      expect(find.text('1'), findsNothing);
    });

    testWidgets('PlaybackControlPanel passes isRepeatOne correctly to repeat icon', (tester) async {
      const repeatOneState = PlaybackState(
        status: PlaybackStatus.playing,
        repeatMode: RepeatMode.one,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PlaybackControlPanel(
              playbackState: repeatOneState,
            ),
          ),
        ),
      );

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('TrackInfoSection favorite button is a raised NeumorphicContainer', (tester) async {
      final track = Track(
        id: 'track-fav-1',
        title: 'Song A',
        artist: 'Artist A',
        duration: const Duration(minutes: 3),
        mediaUri: '/storage/song.mp3',
        dateAdded: DateTime.now(),
        isFavorite: false,
      );

      var toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TrackInfoSection(
              track: track,
              position: Duration.zero,
              duration: const Duration(minutes: 3),
              isFavorite: false,
              onFavoriteToggle: () => toggled = true,
            ),
          ),
        ),
      );

      expect(find.byType(NeumorphicContainer), findsOneWidget);

      await tester.tap(find.byType(NeumorphicContainer));
      expect(toggled, isTrue);
    });

    testWidgets('UserProfileAvatar renders user initials fallback when no image path is provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserProfileAvatar(
              name: 'Ateeb Anwar',
              size: 80.0,
            ),
          ),
        ),
      );

      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('TrackArtworkWidget renders fallback cleanly without error when artwork is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TrackArtworkWidget(
              artworkUri: null,
              size: 46.0,
            ),
          ),
        ),
      );

      expect(find.byType(TrackArtworkWidget), findsOneWidget);
    });
  });
}
