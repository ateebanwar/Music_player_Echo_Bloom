import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/app/bootstrap/dependency_bootstrap.dart';
import 'package:sound_foundry/domain/entities/equalizer_configuration.dart';
import 'package:sound_foundry/domain/entities/equalizer_preset.dart';
import 'package:sound_foundry/domain/repositories/equalizer_repository.dart';
import 'package:sound_foundry/infrastructure/audio/audio_engine.dart';

class EqualizerState extends Equatable {
  final bool isLoading;
  final EqualizerConfiguration configuration;

  const EqualizerState({
    this.isLoading = false,
    this.configuration = const EqualizerConfiguration(),
  });

  EqualizerState copyWith({
    bool? isLoading,
    EqualizerConfiguration? configuration,
  }) {
    return EqualizerState(
      isLoading: isLoading ?? this.isLoading,
      configuration: configuration ?? this.configuration,
    );
  }

  @override
  List<Object?> get props => [isLoading, configuration];
}

class EqualizerController extends StateNotifier<EqualizerState> {
  final EqualizerRepository _repository;
  final AudioEngine _audioEngine;

  EqualizerController({
    required EqualizerRepository repository,
    required AudioEngine audioEngine,
  })  : _repository = repository,
        _audioEngine = audioEngine,
        super(const EqualizerState()) {
    loadConfiguration();
  }

  Future<void> loadConfiguration() async {
    state = state.copyWith(isLoading: true);
    final res = await _repository.getConfiguration();
    final config = res.valueOrNull ?? const EqualizerConfiguration();

    // Apply to audio engine pipeline
    await _audioEngine.setEqualizerEnabled(config.isEnabled);
    await _audioEngine.setEqualizerGains(config.bandGains);

    state = state.copyWith(isLoading: false, configuration: config);
  }

  Future<void> setBandGain(int bandIndex, double gain) async {
    if (bandIndex < 0 || bandIndex >= state.configuration.bandGains.length) return;

    final updatedGains = List<double>.from(state.configuration.bandGains);
    updatedGains[bandIndex] = gain.clamp(EqualizerConfiguration.minGain, EqualizerConfiguration.maxGain);

    final updatedConfig = state.configuration.copyWith(
      bandGains: updatedGains,
      activePresetId: 'custom',
    );

    state = state.copyWith(configuration: updatedConfig);

    // Real audio engine effect application
    if (updatedConfig.isEnabled) {
      await _audioEngine.setEqualizerGains(updatedGains);
    }
    await _repository.saveConfiguration(updatedConfig);
  }

  Future<void> applyPreset(EqualizerPreset preset) async {
    final updatedConfig = state.configuration.copyWith(
      bandGains: List<double>.from(preset.bandGains),
      activePresetId: preset.id,
    );

    state = state.copyWith(configuration: updatedConfig);

    if (updatedConfig.isEnabled) {
      await _audioEngine.setEqualizerGains(preset.bandGains);
    }
    await _repository.saveConfiguration(updatedConfig);
  }

  Future<void> toggleEnabled(bool enabled) async {
    final updatedConfig = state.configuration.copyWith(isEnabled: enabled);
    state = state.copyWith(configuration: updatedConfig);

    await _audioEngine.setEqualizerEnabled(enabled);
    if (enabled) {
      await _audioEngine.setEqualizerGains(updatedConfig.bandGains);
    }
    await _repository.saveConfiguration(updatedConfig);
  }

  Future<void> resetToFlat() async {
    final flatGains = [0.0, 0.0, 0.0, 0.0, 0.0];
    final updatedConfig = state.configuration.copyWith(
      bandGains: flatGains,
      activePresetId: 'flat',
    );

    state = state.copyWith(configuration: updatedConfig);

    if (updatedConfig.isEnabled) {
      await _audioEngine.setEqualizerGains(flatGains);
    }
    await _repository.saveConfiguration(updatedConfig);
  }
}

final equalizerControllerProvider =
    StateNotifierProvider<EqualizerController, EqualizerState>((ref) {
  final repo = ref.watch(equalizerRepositoryProvider);
  final engine = ref.watch(audioEngineProvider);
  return EqualizerController(repository: repo, audioEngine: engine);
});
