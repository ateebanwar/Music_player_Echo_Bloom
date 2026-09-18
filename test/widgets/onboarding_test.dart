import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';
import 'package:sound_foundry/domain/repositories/settings_repository.dart';
import 'package:sound_foundry/domain/repositories/user_profile_repository.dart';
import 'package:sound_foundry/presentation/screens/onboarding/profile_setup_screen.dart';
import 'package:sound_foundry/presentation/screens/onboarding/welcome_screen.dart';
import 'package:sound_foundry/presentation/widgets/app_drawer.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? _profile;
  bool _setupCompleted = false;

  @override
  Future<Result<UserProfile?, Failure>> getProfile() async => Result.ok(_profile);

  @override
  Future<Result<void, Failure>> saveProfile(UserProfile profile) async {
    _profile = profile;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool, Failure>> isSetupCompleted() async => Result.ok(_setupCompleted);

  @override
  Future<Result<void, Failure>> setSetupCompleted(bool completed) async {
    _setupCompleted = completed;
    return const Result.ok(null);
  }
}

class FakeSettingsRepository implements SettingsRepository {
  AppMode _appMode = AppMode.offline;
  ThemeMode _themeMode = ThemeMode.system;
  RepeatMode _repeatMode = RepeatMode.off;
  bool _shuffle = false;

  @override
  Future<Result<AppMode, Failure>> getAppMode() async => Result.ok(_appMode);

  @override
  Future<Result<void, Failure>> saveAppMode(AppMode mode) async {
    _appMode = mode;
    return const Result.ok(null);
  }

  @override
  Future<Result<ThemeMode, Failure>> getThemeMode() async => Result.ok(_themeMode);

  @override
  Future<Result<void, Failure>> saveThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    return const Result.ok(null);
  }

  @override
  Future<Result<RepeatMode, Failure>> getSavedRepeatMode() async => Result.ok(_repeatMode);

  @override
  Future<Result<void, Failure>> saveRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool, Failure>> getSavedShuffleMode() async => Result.ok(_shuffle);

  @override
  Future<Result<void, Failure>> saveShuffleMode(bool enabled) async {
    _shuffle = enabled;
    return const Result.ok(null);
  }

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
  group('Onboarding & Sidebar Widget Tests', () {
    testWidgets('WelcomeScreen renders branding, badges, and Setup to Continue button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Setup to Continue'), findsOneWidget);
      expect(find.text('100% Offline'), findsOneWidget);
      expect(find.text('Zero Cloud Tracking'), findsOneWidget);
    });

    testWidgets('ProfileSetupScreen renders inputs and validates empty name', (tester) async {
      final fakeProfileRepo = FakeUserProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
          ],
          child: const MaterialApp(
            home: ProfileSetupScreen(),
          ),
        ),
      );

      expect(find.text('Create Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);

      final continueButton = find.text('Continue');
      await tester.ensureVisible(continueButton);
      await tester.pumpAndSettle();

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your name'), findsOneWidget);
    });

    testWidgets('AppDrawer renders profile header, operating mode, and bottom-anchored Settings', (tester) async {
      final fakeProfileRepo = FakeUserProfileRepository();
      final fakeSettingsRepo = FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfileRepo),
            settingsRepositoryProvider.overrideWithValue(fakeSettingsRepo),
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

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('MUSIC PLAYER'), findsOneWidget);
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text('All Songs'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);
      expect(find.text('Downloaded'), findsOneWidget);
      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.text('OPERATING MODE'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Online Mode'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });
  });
}
