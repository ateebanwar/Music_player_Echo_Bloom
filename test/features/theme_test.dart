import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/repositories/settings_repository.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/now_playing/now_playing_screen.dart';

class MockSettingsRepo implements SettingsRepository {
  ThemeMode currentTheme = ThemeMode.light;
  AppMode currentMode = AppMode.offline;

  @override
  Future<Result<ThemeMode, Failure>> getThemeMode() async => Result.ok(currentTheme);

  @override
  Future<Result<void, Failure>> saveThemeMode(ThemeMode t) async {
    currentTheme = t;
    return const Result.ok(null);
  }

  @override
  Future<Result<AppMode, Failure>> getAppMode() async => Result.ok(currentMode);

  @override
  Future<Result<void, Failure>> saveAppMode(AppMode m) async {
    currentMode = m;
    return const Result.ok(null);
  }

  @override
  Future<Result<RepeatMode, Failure>> getSavedRepeatMode() async => const Result.ok(RepeatMode.off);
  @override
  Future<Result<void, Failure>> saveRepeatMode(RepeatMode mode) async => const Result.ok(null);
  @override
  Future<Result<bool, Failure>> getSavedShuffleMode() async => const Result.ok(false);
  @override
  Future<Result<void, Failure>> saveShuffleMode(bool enabled) async => const Result.ok(null);
  @override
  Future<Result<bool, Failure>> getBool(String key, {bool defaultValue = false}) async => Result.ok(defaultValue);
  @override
  Future<Result<double, Failure>> getDouble(String key, {double defaultValue = 0.0}) async => Result.ok(defaultValue);
  @override
  Future<Result<int, Failure>> getInt(String key, {int defaultValue = 0}) async => Result.ok(defaultValue);
  @override
  Future<Result<String?, Failure>> getString(String key, {String? defaultValue}) async => Result.ok(defaultValue);
  @override
  Future<Result<void, Failure>> setBool(String key, bool value) async => const Result.ok(null);
  @override
  Future<Result<void, Failure>> setDouble(String key, double value) async => const Result.ok(null);
  @override
  Future<Result<void, Failure>> setInt(String key, int value) async => const Result.ok(null);
  @override
  Future<Result<void, Failure>> setString(String key, String value) async => const Result.ok(null);
}

void main() {
  group('Theme System, True Dark Neumorphism & Contrast Tests', () {
    test('SettingsState defaults to Light Mode for fresh installation', () {
      const state = SettingsState();
      expect(state.themeMode, equals(ThemeMode.light));
    });

    test('NeumorphicDecorations produces dark-adapted shadows and surfaces in dark mode', () {
      final lightCard = NeumorphicDecorations.elevatedCard(isDark: false);
      final darkCard = NeumorphicDecorations.elevatedCard(isDark: true);

      expect(lightCard.color, equals(AppColors.surface));
      expect(darkCard.color, equals(AppColors.darkSurface));

      expect(lightCard.boxShadow![0].color, equals(AppColors.shadowLight));
      expect(darkCard.boxShadow![0].color, equals(AppColors.darkShadowLight));

      expect(lightCard.boxShadow![1].color, equals(AppColors.shadowDark));
      expect(darkCard.boxShadow![1].color, equals(AppColors.darkShadowDark));
    });

    test('SettingsController changes theme in-memory immediately without waiting for disk', () async {
      final mockRepo = MockSettingsRepo();
      final controller = SettingsController(mockRepo);

      expect(controller.state.themeMode, equals(ThemeMode.light));

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.state.themeMode, equals(ThemeMode.dark));
      expect(mockRepo.currentTheme, equals(ThemeMode.dark));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.state.themeMode, equals(ThemeMode.light));
      expect(mockRepo.currentTheme, equals(ThemeMode.light));
    });

    test('isDarkModeProvider reacts immediately to SettingsController theme change', () async {
      final mockRepo = MockSettingsRepo();
      final container = ProviderContainer(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      expect(container.read(isDarkModeProvider), isFalse);

      await container.read(settingsControllerProvider.notifier).setThemeMode(ThemeMode.dark);
      expect(container.read(isDarkModeProvider), isTrue);

      await container.read(settingsControllerProvider.notifier).setThemeMode(ThemeMode.light);
      expect(container.read(isDarkModeProvider), isFalse);
    });

    test('Rapid theme toggling preserves deterministic final state without race conditions', () async {
      final mockRepo = MockSettingsRepo();
      final controller = SettingsController(mockRepo);

      // Rapidly toggle multiple times in sequence
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setThemeMode(ThemeMode.light);
      await controller.setThemeMode(ThemeMode.dark);
      await controller.setThemeMode(ThemeMode.light);
      await controller.setThemeMode(ThemeMode.dark);

      expect(controller.state.themeMode, equals(ThemeMode.dark));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.state.themeMode, equals(ThemeMode.dark));
    });

    testWidgets('NowPlayingScreen reflects theme change immediately without crashing', (tester) async {
      final mockSettings = MockSettingsRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(mockSettings),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsControllerProvider);
              return MaterialApp(
                themeMode: settings.themeMode,
                themeAnimationDuration: const Duration(milliseconds: 150),
                theme: ThemeData(
                  brightness: Brightness.light,
                  scaffoldBackgroundColor: AppColors.background,
                ),
                darkTheme: ThemeData(
                  brightness: Brightness.dark,
                  scaffoldBackgroundColor: AppColors.darkBackground,
                ),
                home: const Scaffold(body: NowPlayingScreen()),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial Light Mode is mounted
      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(find.text('Now Playing'), findsOneWidget);

      // Switch to Dark Mode
      final element = tester.element(find.byType(NowPlayingScreen));
      final container = ProviderScope.containerOf(element);
      await container.read(settingsControllerProvider.notifier).setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsOneWidget);
      expect(find.text('Now Playing'), findsOneWidget);

      // Switch back to Light Mode
      await container.read(settingsControllerProvider.notifier).setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();

      expect(find.byType(NowPlayingScreen), findsOneWidget);
    });
  });
}
