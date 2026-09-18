import 'package:flutter/material.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/presentation/screens/onboarding/profile_setup_screen.dart';

/// Modern first-launch Welcome screen with neumorphic aesthetic and theme adaptability.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Neumorphic Logo / Icon Card
                Container(
                  width: 110.0,
                  height: 110.0,
                  decoration: NeumorphicDecorations.elevatedCard(
                    borderRadius: AppSpacing.roundedArtwork,
                    isDark: isDark,
                  ),
                  child: ClipRRect(
                    borderRadius: AppSpacing.roundedArtwork,
                    child: Image.asset(
                      'assets/images/echo_bloom_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 36.0),

                // Application Title
                Text(
                  AppConstants.appName,
                  style: AppTypography.trackTitle.copyWith(
                    fontSize: 32.0,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkText : AppColors.textNavy,
                  ),
                ),
                const SizedBox(height: 12.0),

                // Subtitle
                Text(
                  AppConstants.appSubtitle,
                  textAlign: TextAlign.center,
                  style: AppTypography.artistName.copyWith(
                    fontSize: 15.0,
                    color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32.0),

                // Privacy & Offline Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge('100% Offline', isDark),
                    const SizedBox(width: 12.0),
                    _buildBadge('Zero Cloud Tracking', isDark),
                  ],
                ),

                const Spacer(flex: 3),

                // Primary Action Button: "Setup to Continue"
                SizedBox(
                  width: double.infinity,
                  height: 56.0,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 4.0,
                      shadowColor: AppColors.primaryPurple.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ProfileSetupScreen(),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Setup to Continue',
                          style: AppTypography.headerTitle.copyWith(
                            fontSize: 16.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        const Icon(Icons.arrow_forward_rounded, size: 18.0, color: Colors.white),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isDark ? AppColors.darkText : AppColors.textNavy,
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
