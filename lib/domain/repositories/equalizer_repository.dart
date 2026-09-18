import 'package:sound_foundry/core/errors/failures.dart';
import 'package:sound_foundry/core/result/result.dart';
import 'package:sound_foundry/domain/entities/equalizer_configuration.dart';

/// Contract for persistent Equalizer configuration storage.
abstract class EqualizerRepository {
  Future<Result<EqualizerConfiguration, Failure>> getConfiguration();
  Future<Result<void, Failure>> saveConfiguration(EqualizerConfiguration configuration);
}
