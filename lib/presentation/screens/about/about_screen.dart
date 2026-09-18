import 'package:flutter/material.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';

/// Dedicated About screen displaying app version, offline privacy pledge, and developer attribution.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                      'About',
                      style: AppTypography.trackTitle.copyWith(
                        fontSize: 22.0,
                        color: isDark ? AppColors.darkText : AppColors.textNavy,
                      ),
                    ),
                  ],
                ),
              ),

              // About Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  children: [
                    const SizedBox(height: 12.0),

                    // App Logo Icon
                    Center(
                      child: Container(
                        width: 84.0,
                        height: 84.0,
                        decoration: NeumorphicDecorations.elevatedCard(
                          borderRadius: AppSpacing.roundedArtwork,
                          color: isDark ? AppColors.darkSurface : AppColors.surface,
                        ),
                        child: ClipRRect(
                          borderRadius: AppSpacing.roundedArtwork,
                          child: Image.asset(
                            'assets/images/echo_bloom_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20.0),

                    // App Name & Version
                    Center(
                      child: Text(
                        AppConstants.appName,
                        style: AppTypography.trackTitle.copyWith(
                          fontSize: 24.0,
                          color: isDark ? AppColors.darkText : AppColors.textNavy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Center(
                      child: Text(
                        'Version ${AppConstants.appVersion}',
                        style: AppTypography.artistName.copyWith(
                          fontSize: 13.0,
                          color: AppColors.primaryPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Center(
                      child: Text(
                        AppConstants.appSubtitle,
                        textAlign: TextAlign.center,
                        style: AppTypography.artistName.copyWith(
                          fontSize: 14.0,
                          color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32.0),

                    // Privacy & Offline Pledge Card
                    Container(
                      padding: const EdgeInsets.all(18.0),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.shield_outlined, color: AppColors.primaryPurple, size: 22.0),
                              const SizedBox(width: 10.0),
                              Text(
                                'Offline-First & Private',
                                style: AppTypography.headerTitle.copyWith(
                                  fontSize: 16.0,
                                  color: isDark ? AppColors.darkText : AppColors.textNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Text(
                            'Your profile, songs, playlists, favorites, and equalizer settings are stored exclusively on your device in local SQLite databases. No cloud syncing, no background telemetry, zero tracking.',
                            style: AppTypography.artistName.copyWith(
                              fontSize: 13.0,
                              height: 1.4,
                              color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48.0),

                    // Developer Attribution
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: Text(
                          AppConstants.developerAttribution,
                          style: TextStyle(
                            color: isDark ? AppColors.darkText : AppColors.textNavy,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
