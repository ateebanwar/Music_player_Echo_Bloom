import 'package:flutter/material.dart';
import 'package:sound_foundry/core/constants/storage_keys.dart';
import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/logging/app_logger.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/domain/entities/playback_state.dart';
import 'package:sound_foundry/domain/repositories/settings_repository.dart';
import 'package:sound_foundry/infrastructure/storage/key_value_store.dart';

/// Concrete implementation of [SettingsRepository] backed by [KeyValueStore].
class SettingsRepositoryImpl implements SettingsRepository {
  final KeyValueStore _store;
  final AppLogger? _logger;

  SettingsRepositoryImpl({
    required KeyValueStore store,
    AppLogger? logger,
  })  : _store = store,
        _logger = logger;

  @override
  Future<Result<String?, Failure>> getString(String key, {String? defaultValue}) async {
    try {
      final value = await _store.getString(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading string setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setString(String key, String value) async {
    try {
      await _store.setString(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing string setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<bool, Failure>> getBool(String key, {bool defaultValue = false}) async {
    try {
      final value = await _store.getBool(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading bool setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setBool(String key, bool value) async {
    try {
      await _store.setBool(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing bool setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<double, Failure>> getDouble(String key, {double defaultValue = 0.0}) async {
    try {
      final value = await _store.getDouble(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading double setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setDouble(String key, double value) async {
    try {
      await _store.setDouble(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing double setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<int, Failure>> getInt(String key, {int defaultValue = 0}) async {
    try {
      final value = await _store.getInt(key);
      return Result.ok(value ?? defaultValue);
    } catch (e, stack) {
      _logger?.error('Error reading int setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to read setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> setInt(String key, int value) async {
    try {
      await _store.setInt(key, value);
      return const Result.ok(null);
    } catch (e, stack) {
      _logger?.error('Error writing int setting $key', tag: 'SettingsRepository', error: e, stackTrace: stack);
      return Result.err(StorageFailure(message: 'Failed to write setting $key: $e', cause: e));
    }
  }

  @override
  Future<Result<RepeatMode, Failure>> getSavedRepeatMode() async {
    final res = await getInt(StorageKeys.keyRepeatMode, defaultValue: 0);
    return res.map((index) => (index >= 0 && index < RepeatMode.values.length)
        ? RepeatMode.values[index]
        : RepeatMode.off);
  }

  @override
  Future<Result<void, Failure>> saveRepeatMode(RepeatMode mode) {
    return setInt(StorageKeys.keyRepeatMode, mode.index);
  }

  @override
  Future<Result<bool, Failure>> getSavedShuffleMode() {
    return getBool(StorageKeys.keyShuffleMode, defaultValue: false);
  }

  @override
  Future<Result<void, Failure>> saveShuffleMode(bool enabled) {
    return setBool(StorageKeys.keyShuffleMode, enabled);
  }

  @override
  Future<Result<AppMode, Failure>> getAppMode() async {
    final res = await getString('app_mode', defaultValue: 'offline');
    return res.map((str) => str == 'online' ? AppMode.online : AppMode.offline);
  }

  @override
  Future<Result<void, Failure>> saveAppMode(AppMode mode) {
    return setString('app_mode', mode == AppMode.online ? 'online' : 'offline');
  }

  @override
  Future<Result<ThemeMode, Failure>> getThemeMode() async {
    final res = await getString('theme_mode', defaultValue: 'light');
    return res.map((str) {
      if (str == 'dark') return ThemeMode.dark;
      return ThemeMode.light;
    });
  }

  @override
  Future<Result<void, Failure>> saveThemeMode(ThemeMode mode) {
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    return setString('theme_mode', val);
  }
}
