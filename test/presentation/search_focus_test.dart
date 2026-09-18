import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/features/library/library_controller.dart';
import 'package:sound_foundry/features/library/library_providers.dart';
import 'package:sound_foundry/features/library/library_state.dart';
import 'package:sound_foundry/features/search/search_controller.dart';
import 'package:sound_foundry/presentation/screens/all_songs/all_songs_screen.dart';
import 'package:sound_foundry/presentation/widgets/app_drawer.dart';
import '../../test/widgets/onboarding_test.dart';

class FakeLibraryController extends StateNotifier<LibraryState> implements LibraryController {
  FakeLibraryController() : super(const LibraryState());

  @override
  Future<void> loadLibrary({bool refresh = false}) async {}

  @override
  Future<void> rescanLibrary() async {}

  @override
  Future<void> loadMoreTracks() async {}
}

void main() {
  group('Search Focus & Mode Toggle Orchestration Tests', () {
    testWidgets('Toggling Online Mode from AppDrawer sets searchFocusTrigger and switches to All Songs', (tester) async {
      final fakeProfileRepo = FakeUserProfileRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            libraryControllerProvider.overrideWith((ref) => FakeLibraryController()),
          ],
          child: MaterialApp(
            home: Scaffold(
              drawer: const AppDrawer(),
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open drawer
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Drawer is open, tap 'Online Mode'
      expect(find.text('Online Mode'), findsOneWidget);
      await tester.tap(find.text('Online Mode'));
      await tester.pumpAndSettle();

      // Verify drawer closed
      expect(find.text('MUSIC PLAYER'), findsNothing);
    });

    testWidgets('Normal AllSongsScreen display does NOT auto-focus without trigger', (tester) async {
      final fakeProfileRepo = FakeUserProfileRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            libraryControllerProvider.overrideWith((ref) => FakeLibraryController()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AllSongsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search field is present but not focused
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isFalse);
    });

    testWidgets('AllSongsScreen auto-focuses search bar when searchFocusTrigger is true', (tester) async {
      final fakeProfileRepo = FakeUserProfileRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
            libraryControllerProvider.overrideWith((ref) => FakeLibraryController()),
            searchFocusTriggerProvider.overrideWith((ref) => true),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: AllSongsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Search field should have focus
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.focusNode?.hasFocus, isTrue);
    });
  });
}
