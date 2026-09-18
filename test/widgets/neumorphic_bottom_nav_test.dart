import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/presentation/widgets/neumorphic_bottom_nav.dart';

void main() {
  group('NeumorphicBottomNav Static Strip / Zero Layout Shift Tests', () {
    testWidgets('Every button preserves exact geometry and position across selection changes', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Align(
                  alignment: Alignment.bottomCenter,
                  child: NeumorphicBottomNav(
                    currentIndex: selectedIndex,
                    onIndexChanged: (idx) {
                      setState(() {
                        selectedIndex = idx;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all 4 labels are present simultaneously
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text('All Songs'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);

      // Record initial rects when Tab 0 (Now Playing) is active
      final rectNowPlaying0 = tester.getRect(find.text('Now Playing'));
      final rectAllSongs0 = tester.getRect(find.text('All Songs'));
      final rectLikes0 = tester.getRect(find.text('Likes'));
      final rectLibrary0 = tester.getRect(find.text('Library'));

      // Select Tab 1 (All Songs)
      await tester.tap(find.text('All Songs'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(1));

      // Check rects when Tab 1 (All Songs) is active
      final rectNowPlaying1 = tester.getRect(find.text('Now Playing'));
      final rectAllSongs1 = tester.getRect(find.text('All Songs'));
      final rectLikes1 = tester.getRect(find.text('Likes'));
      final rectLibrary1 = tester.getRect(find.text('Library'));

      // ZERO LAYOUT SHIFT CHECKS:
      expect(rectNowPlaying1, equals(rectNowPlaying0), reason: 'Now Playing must not move when All Songs is selected');
      expect(rectAllSongs1, equals(rectAllSongs0), reason: 'All Songs must not change position when selected');
      expect(rectLikes1, equals(rectLikes0), reason: 'Likes must not move when All Songs is selected');
      expect(rectLibrary1, equals(rectLibrary0), reason: 'Library must not move when All Songs is selected');

      // Select Tab 2 (Likes)
      await tester.tap(find.text('Likes'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(2));

      expect(tester.getRect(find.text('Now Playing')), equals(rectNowPlaying0));
      expect(tester.getRect(find.text('All Songs')), equals(rectAllSongs0));
      expect(tester.getRect(find.text('Likes')), equals(rectLikes0));
      expect(tester.getRect(find.text('Library')), equals(rectLibrary0));

      // Select Tab 3 (Library)
      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(3));

      expect(tester.getRect(find.text('Now Playing')), equals(rectNowPlaying0));
      expect(tester.getRect(find.text('All Songs')), equals(rectAllSongs0));
      expect(tester.getRect(find.text('Likes')), equals(rectLikes0));
      expect(tester.getRect(find.text('Library')), equals(rectLibrary0));

      // Repeated rapid toggling: Now Playing -> All Songs -> Now Playing
      await tester.tap(find.text('Now Playing'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(0));
      expect(tester.getRect(find.text('Now Playing')), equals(rectNowPlaying0));
      expect(tester.getRect(find.text('All Songs')), equals(rectAllSongs0));

      await tester.tap(find.text('All Songs'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(1));
      expect(tester.getRect(find.text('Now Playing')), equals(rectNowPlaying0));
      expect(tester.getRect(find.text('All Songs')), equals(rectAllSongs0));

      await tester.tap(find.text('Now Playing'));
      await tester.pumpAndSettle();
      expect(selectedIndex, equals(0));
      expect(tester.getRect(find.text('Now Playing')), equals(rectNowPlaying0));
      expect(tester.getRect(find.text('All Songs')), equals(rectAllSongs0));
    });

    testWidgets('Strip retains static geometry in both Dark and Light themes', (tester) async {
      int selectedIndex = 0;

      for (final isDark in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return NeumorphicBottomNav(
                    currentIndex: selectedIndex,
                    isDark: isDark,
                    onIndexChanged: (idx) {
                      setState(() {
                        selectedIndex = idx;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final rect0 = tester.getRect(find.text('Now Playing'));
        final rect1 = tester.getRect(find.text('All Songs'));

        // Tap All Songs
        await tester.tap(find.text('All Songs'));
        await tester.pumpAndSettle();

        expect(tester.getRect(find.text('Now Playing')), equals(rect0));
        expect(tester.getRect(find.text('All Songs')), equals(rect1));
      }
    });

    testWidgets('Strip renders without overflow on compact screen width (320px)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 600 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return NeumorphicBottomNav(
                  currentIndex: selectedIndex,
                  onIndexChanged: (idx) => setState(() => selectedIndex = idx),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // No Flutter overflow error should occur
      expect(tester.takeException(), isNull);

      final rect0 = tester.getRect(find.text('Now Playing'));
      await tester.tap(find.text('All Songs'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(tester.getRect(find.text('Now Playing')), equals(rect0));
    });
  });
}
