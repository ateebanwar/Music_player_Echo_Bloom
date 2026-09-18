import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sound_foundry/core/constants/app_constants.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';
import 'package:sound_foundry/core/theme/app_typography.dart';
import 'package:sound_foundry/core/theme/neumorphic_decorations.dart';
import 'package:sound_foundry/features/profile/profile_controller.dart';
import 'package:sound_foundry/presentation/screens/main_navigation_shell.dart';
import 'package:sound_foundry/presentation/screens/onboarding/welcome_screen.dart';

/// Entry gate that decides between [WelcomeScreen] (first launch) and [MainNavigationShell].
class EntryGate extends ConsumerWidget {
  const EntryGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(profileControllerProvider);

    if (profileState.isLoading) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: isDark ? AppColors.darkBackgroundGradient : AppColors.backgroundGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 104.0,
                    height: 104.0,
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
                  const SizedBox(height: 24.0),
                  Text(
                    AppConstants.appName,
                    style: AppTypography.trackTitle.copyWith(
                      fontSize: 28.0,
                      letterSpacing: -0.5,
                      color: isDark ? AppColors.darkText : AppColors.textNavy,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    AppConstants.appSubtitle,
                    style: AppTypography.artistName.copyWith(
                      fontSize: 14.0,
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (profileState.isSetupCompleted) {
      return const MainNavigationShell();
    }

    return const WelcomeScreen();
  }
}
