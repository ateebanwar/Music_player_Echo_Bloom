import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/equalizer_configuration.dart';
import 'package:sound_foundry/domain/repositories/equalizer_repository.dart';
import 'package:sound_foundry/infrastructure/storage/key_value_store.dart';

/// SQLite Key-Value backed implementation of [EqualizerRepository].
class EqualizerRepositoryImpl implements EqualizerRepository {
  final KeyValueStore _store;

  static const String _keyEqEnabled = 'eq_enabled';
  static const String _keyEqBands = 'eq_bands';
  static const String _keyEqPreset = 'eq_preset';

  const EqualizerRepositoryImpl(this._store);

  @override
  Future<Result<EqualizerConfiguration, Failure>> getConfiguration() async {
    try {
      final enabled = await _store.getBool(_keyEqEnabled) ?? true;
      final preset = await _store.getString(_keyEqPreset) ?? 'flat';
      final bandsStr = await _store.getString(_keyEqBands);

      List<double> gains = [0.0, 0.0, 0.0, 0.0, 0.0];
      if (bandsStr != null && bandsStr.isNotEmpty) {
        final parsed = bandsStr
            .split(',')
            .map((s) => double.tryParse(s.trim()) ?? 0.0)
            .toList();
        if (parsed.length == 5) {
          gains = parsed;
        }
      }

      return Result.ok(EqualizerConfiguration(
        isEnabled: enabled,
        bandGains: gains,
        activePresetId: preset,
      ));
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to read equalizer configuration: $e',
        cause: e,
      ));
    }
  }

  @override
  Future<Result<void, Failure>> saveConfiguration(EqualizerConfiguration configuration) async {
    try {
      await _store.setBool(_keyEqEnabled, configuration.isEnabled);
      await _store.setString(_keyEqPreset, configuration.activePresetId);
      final bandsStr = configuration.bandGains.map((g) => g.toStringAsFixed(1)).join(',');
      await _store.setString(_keyEqBands, bandsStr);
      return const Result.ok(null);
    } catch (e) {
      return Result.err(StorageFailure(
        message: 'Failed to save equalizer configuration: $e',
        cause: e,
      ));
    }
  }
}
