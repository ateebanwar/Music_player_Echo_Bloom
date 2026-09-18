import 'package:flutter/material.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';

/// Contract for persistent user settings and player preferences.
abstract class SettingsRepository {
  /// Gets a string setting or returns defaultValue.
  Future<Result<String?, Failure>> getString(String key, {String? defaultValue});

  /// Sets a string setting.
  Future<Result<void, Failure>> setString(String key, String value);

  /// Gets a bool setting or returns defaultValue.
  Future<Result<bool, Failure>> getBool(String key, {bool defaultValue = false});

  /// Sets a bool setting.
  Future<Result<void, Failure>> setBool(String key, bool value);

  /// Gets a double setting or returns defaultValue.
  Future<Result<double, Failure>> getDouble(String key, {double defaultValue = 0.0});

  /// Sets a double setting.
  Future<Result<void, Failure>> setDouble(String key, double value);

  /// Gets an int setting or returns defaultValue.
  Future<Result<int, Failure>> getInt(String key, {int defaultValue = 0});

  /// Sets an int setting.
  Future<Result<void, Failure>> setInt(String key, int value);

  /// Gets persisted repeat mode.
  Future<Result<RepeatMode, Failure>> getSavedRepeatMode();

  /// Persists repeat mode.
  Future<Result<void, Failure>> saveRepeatMode(RepeatMode mode);

  /// Gets persisted shuffle mode.
  Future<Result<bool, Failure>> getSavedShuffleMode();

  /// Persists shuffle mode.
  Future<Result<void, Failure>> saveShuffleMode(bool enabled);

  /// Gets persisted app mode (offline or online).
  Future<Result<AppMode, Failure>> getAppMode();

  /// Persists app mode (offline or online).
  Future<Result<void, Failure>> saveAppMode(AppMode mode);

  /// Gets persisted theme mode (system, light, dark).
  Future<Result<ThemeMode, Failure>> getThemeMode();

  /// Persists theme mode.
  Future<Result<void, Failure>> saveThemeMode(ThemeMode mode);
}
