import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/presentation/widgets/circular_seeker.dart';

void main() {
  group('CircularSeeker Interaction & Rotational Seeking Tests', () {
    testWidgets('Renders progress arc and center child accurately', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSeeker(
                position: Duration(seconds: 30),
                duration: Duration(seconds: 120),
                centerChild: Text('Play'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Play'), findsOneWidget);
      expect(find.byType(CircularSeeker), findsOneWidget);
    });

    testWidgets('Short tap on center triggers onPlayPauseTap without seeking', (tester) async {
      var playPauseTapped = false;
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSeeker(
                position: const Duration(seconds: 20),
                duration: const Duration(seconds: 100),
                size: 106.0,
                onPlayPauseTap: () => playPauseTapped = true,
                onSeek: (pos) => seekedDuration = pos,
                centerChild: const Text('Play'),
              ),
            ),
          ),
        ),
      );

      final seekerFinder = find.byType(CircularSeeker);
      final center = tester.getCenter(seekerFinder);

      // Short tap on center point
      final gesture = await tester.startGesture(center);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(playPauseTapped, isTrue);
      expect(seekedDuration, isNull);
    });

    testWidgets('Press, hold and rotate clockwise seeks forward', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSeeker(
                position: const Duration(seconds: 20),
                duration: const Duration(seconds: 100),
                size: 106.0,
                onSeek: (pos) => seekedDuration = pos,
                centerChild: const Text('Play'),
              ),
            ),
          ),
        ),
      );

      final seekerFinder = find.byType(CircularSeeker);
      final center = tester.getCenter(seekerFinder);

      // Start gesture near center-top (12 o'clock: dx=0, dy=-20)
      final topPoint = center + const Offset(0, -20);
      final rightPoint = center + const Offset(20, 0);
      final bottomPoint = center + const Offset(0, 20);

      final gesture = await tester.startGesture(topPoint);
      await tester.pump();
      // Rotate clockwise: 12 o'clock -> 3 o'clock -> 6 o'clock (+180° = +0.5 of revolution)
      await gesture.moveTo(rightPoint);
      await tester.pump();
      await gesture.moveTo(bottomPoint);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekedDuration, isNotNull);
      // Started at 20s + 50s = 70s
      expect(seekedDuration!.inSeconds, inInclusiveRange(60, 80));
    });

    testWidgets('Press, hold and rotate anti-clockwise seeks backward', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSeeker(
                position: const Duration(seconds: 80),
                duration: const Duration(seconds: 100),
                size: 106.0,
                onSeek: (pos) => seekedDuration = pos,
                centerChild: const Text('Play'),
              ),
            ),
          ),
        ),
      );

      final seekerFinder = find.byType(CircularSeeker);
      final center = tester.getCenter(seekerFinder);

      // Start at 6 o'clock -> rotate anti-clockwise to 3 o'clock -> 12 o'clock (-180° = -0.5 of revolution)
      final bottomPoint = center + const Offset(0, 20);
      final rightPoint = center + const Offset(20, 0);
      final topPoint = center + const Offset(0, -20);

      final gesture = await tester.startGesture(bottomPoint);
      await tester.pump();
      await gesture.moveTo(rightPoint);
      await tester.pump();
      await gesture.moveTo(topPoint);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekedDuration, isNotNull);
      // Started at 80s - 50s = 30s
      expect(seekedDuration!.inSeconds, inInclusiveRange(20, 40));
    });

    testWidgets('Anti-clockwise rotation clamps at 0:00 without jumping', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CircularSeeker(
                position: const Duration(seconds: 10),
                duration: const Duration(seconds: 100),
                size: 106.0,
                onSeek: (pos) => seekedDuration = pos,
                centerChild: const Text('Play'),
              ),
            ),
          ),
        ),
      );

      final seekerFinder = find.byType(CircularSeeker);
      final center = tester.getCenter(seekerFinder);

      final bottomPoint = center + const Offset(0, 20);
      final rightPoint = center + const Offset(20, 0);
      final topPoint = center + const Offset(0, -20);

      final gesture = await tester.startGesture(bottomPoint);
      await tester.pump();
      // Rotate backwards 180° (exceeds 10s position)
      await gesture.moveTo(rightPoint);
      await tester.pump();
      await gesture.moveTo(topPoint);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(seekedDuration, isNotNull);
      expect(seekedDuration!.inSeconds, 0);
    });
  });
}
