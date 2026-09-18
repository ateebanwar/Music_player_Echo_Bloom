import 'package:equatable/equatable.dart';

/// Preset equalizer configurations.
class EqualizerPreset extends Equatable {
  final String id;
  final String name;
  final List<double> bandGains; // 5 bands in dB (-12 to +12)

  const EqualizerPreset({
    required this.id,
    required this.name,
    required this.bandGains,
  });

  static const List<EqualizerPreset> defaultPresets = [
    EqualizerPreset(
      id: 'flat',
      name: 'Flat',
      bandGains: [0.0, 0.0, 0.0, 0.0, 0.0],
    ),
    EqualizerPreset(
      id: 'bass_boost',
      name: 'Bass Boost',
      bandGains: [6.0, 4.0, 0.0, 0.0, -1.0],
    ),
    EqualizerPreset(
      id: 'vocal',
      name: 'Vocal',
      bandGains: [-2.0, 0.0, 5.0, 3.0, 0.0],
    ),
    EqualizerPreset(
      id: 'rock',
      name: 'Rock',
      bandGains: [5.0, 3.0, -1.0, 3.0, 5.0],
    ),
    EqualizerPreset(
      id: 'electronic',
      name: 'Electronic',
      bandGains: [6.0, 3.0, 0.0, 2.0, 5.0],
    ),
    EqualizerPreset(
      id: 'acoustic',
      name: 'Acoustic',
      bandGains: [4.0, 2.0, 1.0, 3.0, 4.0],
    ),
  ];

  @override
  List<Object?> get props => [id, name, bandGains];
}
