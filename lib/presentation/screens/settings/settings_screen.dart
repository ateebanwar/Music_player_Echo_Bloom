import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/domain/entities/app_mode.dart';
import 'package:sound_foundry/features/settings/settings_controller.dart';
import 'package:sound_foundry/presentation/screens/equalizer/equalizer_screen.dart';

/// Clean and focused Settings screen.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const SettingsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final notifier = ref.read(settingsControllerProvider.notifier);
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
                    Text(
                      'Settings',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                  ],
                ),
              ),

              // Settings List
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                  children: [
                    // Section: Appearance
                    _buildSectionHeader('APPEARANCE', isDark),
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildSelectableTile(
                            isDark: isDark,
                            title: 'Light Theme',
                            icon: Icons.light_mode_rounded,
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () => notifier.setThemeMode(ThemeMode.light),
                          ),
                          Divider(
                            color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                            height: 1.0,
                          ),
                          _buildSelectableTile(
                            isDark: isDark,
                            title: 'Dark Theme',
                            icon: Icons.dark_mode_rounded,
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () => notifier.setThemeMode(ThemeMode.dark),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20.0),

                    // Section: Connectivity & Modes
                    _buildSectionHeader('OPERATING MODE', isDark),
                    _buildCard(
                      isDark: isDark,
                      child: Column(
                        children: [
                          _buildSelectableTile(
                            isDark: isDark,
                            title: 'Offline Mode',
                            subtitle: '100% Local database playback & search',
                            icon: Icons.cloud_off_rounded,
                            isSelected: settings.appMode == AppMode.offline,
                            onTap: () => notifier.setAppMode(AppMode.offline),
                          ),
                          Divider(
                            color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                            height: 1.0,
                          ),
                          _buildSelectableTile(
                            isDark: isDark,
                            title: 'Online Mode',
                            subtitle: 'Permits future online metadata & search',
                            icon: Icons.cloud_queue_rounded,
                            isSelected: settings.appMode == AppMode.online,
                            onTap: () => notifier.setAppMode(AppMode.online),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20.0),

                    // Section: Audio
                    _buildSectionHeader('AUDIO ENGINE', isDark),
                    _buildCard(
                      isDark: isDark,
                      child: ListTile(
                        leading: const Icon(Icons.equalizer_rounded, color: AppColors.primaryPurple),
                        title: Text(
                          'Audio Equalizer',
                          style: AppTypography.headerTitle.copyWith(
                            fontSize: 14.0,
                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                          ),
                        ),
                        subtitle: const Text(
                          'Customize 5-band frequency gains & presets',
                          style: TextStyle(fontSize: 12.0),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.iconMuted),
                        onTap: () => EqualizerScreen.show(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableTile({
    required bool isDark,
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primaryPurple : (isDark ? AppColors.darkTextMuted : AppColors.iconNavy)),
      title: Text(
        title,
        style: AppTypography.headerTitle.copyWith(
          fontSize: 14.0,
          color: isSelected ? AppColors.primaryPurple : (isDark ? AppColors.darkText : AppColors.textNavy),
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 12.0,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            )
          : null,
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.primaryPurple, size: 20.0)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: AppColors.primaryPurple,
        ),
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }
}
