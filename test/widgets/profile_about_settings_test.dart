import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/equalizer_configuration.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/entities/user_profile.dart';
import 'package:sound_foundry/domain/repositories/equalizer_repository.dart';
import 'package:sound_foundry/domain/repositories/settings_repository.dart';
import 'package:sound_foundry/domain/repositories/user_profile_repository.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine_impl.dart';
import 'package:sound_foundry/presentation/screens/about/about_screen.dart';
import 'package:sound_foundry/presentation/screens/equalizer/equalizer_screen.dart';
import 'package:sound_foundry/presentation/screens/profile/profile_screen.dart';
import 'package:sound_foundry/presentation/screens/settings/settings_screen.dart';

class FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? profile = UserProfile(
    name: 'Ateeb',
    dateOfBirth: DateTime(2000, 5, 15),
    gender: 'Male',
    isCompleted: true,
  );

  @override
  Future<Result<UserProfile?, Failure>> getProfile() async => Result.ok(profile);

  @override
  Future<Result<void, Failure>> saveProfile(UserProfile p) async {
    profile = p;
    return const Result.ok(null);
  }

  @override
  Future<Result<bool, Failure>> isSetupCompleted() async => const Result.ok(true);

  @override
  Future<Result<void, Failure>> setSetupCompleted(bool completed) async => const Result.ok(null);
}

class FakeSettingsRepository implements SettingsRepository {
  AppMode mode = AppMode.offline;
  ThemeMode theme = ThemeMode.system;

  @override
  Future<Result<AppMode, Failure>> getAppMode() async => Result.ok(mode);

  @override
  Future<Result<void, Failure>> saveAppMode(AppMode m) async {
    mode = m;
    return const Result.ok(null);
  }

  @override
  Future<Result<ThemeMode, Failure>> getThemeMode() async => Result.ok(theme);

  @override
  Future<Result<void, Failure>> saveThemeMode(ThemeMode t) async {
    theme = t;
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

class FakeEqualizerRepository implements EqualizerRepository {
  @override
  Future<Result<EqualizerConfiguration, Failure>> getConfiguration() async =>
      const Result.ok(EqualizerConfiguration());

  @override
  Future<Result<void, Failure>> saveConfiguration(EqualizerConfiguration configuration) async =>
      const Result.ok(null);
}

void main() {
  group('Profile, About, Settings & Equalizer Widget Tests', () {
    testWidgets('ProfileScreen renders local info, Edit, and Sign Out actions', (tester) async {
      final fakeProfile = FakeUserProfileRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileRepositoryProvider.overrideWithValue(fakeProfile),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Ateeb'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      final signOutButton = find.text('Sign Out (Reset Setup)');
      expect(signOutButton, findsOneWidget);

      // Tap Sign Out to show confirmation dialog
      await tester.ensureVisible(signOutButton);
      await tester.pumpAndSettle();
      await tester.tap(signOutButton);
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to sign out? Your local profile setup will be reset, and you will return to the Welcome screen. Your downloaded music and playlists will remain untouched.'), findsOneWidget);
    });

    testWidgets('AboutScreen renders AppConstants and Ateeb Anwar attribution', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutScreen(),
        ),
      );

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text('Version ${AppConstants.appVersion}'), findsOneWidget);
      expect(find.text(AppConstants.developerAttribution), findsOneWidget);
      expect(find.text('Offline-First & Private'), findsOneWidget);
    });

    testWidgets('SettingsScreen renders Theme, Operating Mode and Equalizer shortcuts', (tester) async {
      final fakeSettings = FakeSettingsRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWithValue(fakeSettings),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Light Theme'), findsOneWidget);
      expect(find.text('Dark Theme'), findsOneWidget);
      expect(find.text('Offline Mode'), findsOneWidget);
      expect(find.text('Online Mode'), findsOneWidget);
      expect(find.text('Audio Equalizer'), findsOneWidget);
    });

    testWidgets('EqualizerScreen renders 5 frequency band sliders and presets', (tester) async {
      final fakeEq = FakeEqualizerRepository();
      final engine = AudioEngineImpl();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            equalizerRepositoryProvider.overrideWithValue(fakeEq),
            audioEngineProvider.overrideWithValue(engine),
          ],
          child: const MaterialApp(
            home: EqualizerScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Equalizer'), findsOneWidget);
      expect(find.text('Flat'), findsOneWidget);
      expect(find.text('Bass Boost'), findsOneWidget);
      expect(find.text('60 Hz'), findsOneWidget);
    });
  });
}
