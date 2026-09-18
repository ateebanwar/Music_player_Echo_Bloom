import 'package:equatable/equatable.dart';

/// User's persistent Equalizer configuration.
class EqualizerConfiguration extends Equatable {
  final bool isEnabled;
  final List<double> bandGains; // 5 frequency bands: [60Hz, 230Hz, 910Hz, 3.6kHz, 14kHz] in dB (-12 to +12)
  final String activePresetId;

  const EqualizerConfiguration({
    this.isEnabled = true,
    this.bandGains = const [0.0, 0.0, 0.0, 0.0, 0.0],
    this.activePresetId = 'flat',
  });

  static const List<String> bandLabels = [
    '60 Hz',
    '230 Hz',
    '910 Hz',
    '3.6 kHz',
    '14 kHz',
  ];

  static const double minGain = -12.0;
  static const double maxGain = 12.0;

  EqualizerConfiguration copyWith({
    bool? isEnabled,
    List<double>? bandGains,
    String? activePresetId,
  }) {
    return EqualizerConfiguration(
      isEnabled: isEnabled ?? this.isEnabled,
      bandGains: bandGains ?? this.bandGains,
      activePresetId: activePresetId ?? this.activePresetId,
    );
  }

  @override
  List<Object?> get props => [isEnabled, bandGains, activePresetId];
}
