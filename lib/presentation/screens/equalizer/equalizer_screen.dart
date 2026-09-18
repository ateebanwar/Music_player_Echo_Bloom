import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/equalizer_configuration.dart';
import 'package:sound_foundry/domain/entities/equalizer_preset.dart';
import 'package:sound_foundry/features/equalizer/equalizer_controller.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';

/// Interactive Equalizer screen with multi-band sliders and preset controls.
class EqualizerScreen extends ConsumerWidget {
  const EqualizerScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const EqualizerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eqState = ref.watch(equalizerControllerProvider);
    final eqController = ref.read(equalizerControllerProvider.notifier);
    final config = eqState.configuration;

    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 24.0, 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: isDark ? AppColors.darkText : AppColors.iconNavy,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Equalizer',
                        style: AppTypography.trackTitle.copyWith(
                          fontSize: 22.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: config.isEnabled,
                      activeThumbColor: AppColors.primaryPurple,
                      onChanged: (val) => eqController.toggleEnabled(val),
                    ),
                  ],
                ),
              ),

              // Presets Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EqualizerPreset.defaultPresets.map((preset) {
                      final isSelected = config.activePresetId == preset.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(preset.name),
                          selected: isSelected,
                          selectedColor: AppColors.primaryPurple,
                          backgroundColor: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.darkText : AppColors.textNavy),
                            fontWeight: FontWeight.w600,
                            fontSize: 13.0,
                          ),
                          onSelected: (_) => eqController.applyPreset(preset),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 8.0),

              // Multi-Band Sliders List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                  itemCount: EqualizerConfiguration.bandLabels.length,
                  itemBuilder: (context, index) {
                    final label = EqualizerConfiguration.bandLabels[index];
                    final gain = config.bandGains[index];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14.0),
                      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 12.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.surface,
                        borderRadius: BorderRadius.circular(16.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                            blurRadius: 8.0,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                label,
                                style: AppTypography.headerTitle.copyWith(
                                  fontSize: 14.0,
                                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                                ),
                              ),
                              Text(
                                '${gain >= 0 ? '+' : ''}${gain.toStringAsFixed(1)} dB',
                                style: TextStyle(
                                  color: gain == 0.0
                                      ? (isDark ? AppColors.darkTextMuted : AppColors.textMuted)
                                      : AppColors.primaryPurple,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.0,
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primaryPurple,
                              inactiveTrackColor: isDark ? AppColors.darkCapsule : AppColors.seekerTrackWhite,
                              thumbColor: AppColors.primaryPurple,
                              overlayColor: AppColors.primaryPurple.withValues(alpha: 0.2),
                              trackHeight: 4.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                            ),
                            child: Slider(
                              value: gain,
                              min: EqualizerConfiguration.minGain,
                              max: EqualizerConfiguration.maxGain,
                              divisions: 24, // 1 dB increments
                              onChanged: config.isEnabled
                                  ? (newVal) => eqController.setBandGain(index, newVal)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions: Reset to Flat
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18.0),
                    label: const Text(
                      'Reset to Flat (0 dB)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.0),
                    ),
                    onPressed: () => eqController.resetToFlat(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
