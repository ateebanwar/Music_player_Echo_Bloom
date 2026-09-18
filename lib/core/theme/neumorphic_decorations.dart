import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';
import 'package:sound_foundry/core/theme/app_spacing.dart';

/// Predefined neumorphic box decorations with full Light and Dark Neumorphism support.
abstract final class NeumorphicDecorations {
  /// Elevated rounded card (e.g. Playback control panel, bottom nav)
  static BoxDecoration elevatedCard({
    BorderRadius? borderRadius,
    Color? color,
    bool isDark = false,
  }) {
    final surfaceColor = color ?? (isDark ? AppColors.darkSurface : AppColors.surface);
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: borderRadius ?? AppSpacing.roundedControlPanel,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: const Offset(-6, -6),
          blurRadius: 16,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
          offset: const Offset(7, 11),
          blurRadius: 22,
          spreadRadius: -2,
        ),
      ],
    );
  }

  /// Elevated circular button (Shuffle, Repeat, Center Play/Pause)
  static BoxDecoration circularButton({
    Color? color,
    double elevation = 1.0,
    bool isDark = false,
  }) {
    final surfaceColor = color ?? (isDark ? AppColors.darkSurfaceElevated : AppColors.surface);
    return BoxDecoration(
      color: surfaceColor,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: Offset(-3.5 * elevation, -3.5 * elevation),
          blurRadius: 8 * elevation,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
          offset: Offset(4.5 * elevation, 6.5 * elevation),
          blurRadius: 12 * elevation,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Elevated Favorite Button Squircle
  static BoxDecoration favoriteButton({
    Color? color,
    bool isDark = false,
  }) {
    final surfaceColor = color ?? (isDark ? AppColors.darkSurface : AppColors.surface);
    return BoxDecoration(
      color: surfaceColor,
      borderRadius: AppSpacing.roundedFavoriteBtn,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: const Offset(-5, -5),
          blurRadius: 12,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowDark : AppColors.shadowDark,
          offset: const Offset(6, 9),
          blurRadius: 16,
          spreadRadius: -1,
        ),
      ],
    );
  }

  /// Album Artwork Container with soft diffused shadow
  static BoxDecoration artworkContainer({bool isDark = false}) {
    return BoxDecoration(
      borderRadius: AppSpacing.roundedArtwork,
      color: isDark ? AppColors.darkSurfaceElevated : Colors.transparent,
      border: isDark
          ? Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1.0)
          : null,
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: const Offset(-7, -7),
          blurRadius: 18,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowArtwork : AppColors.shadowArtwork,
          offset: const Offset(8, 16),
          blurRadius: 28,
          spreadRadius: 2,
        ),
      ],
    );
  }

  /// Active Navigation Tab Pill Capsule
  static BoxDecoration activeNavCapsule({bool isDark = false}) {
    return BoxDecoration(
      color: isDark ? AppColors.darkCapsule : AppColors.capsuleActiveSurface,
      borderRadius: BorderRadius.circular(24.0),
      boxShadow: [
        BoxShadow(
          color: isDark ? AppColors.darkShadowLight : AppColors.shadowLight,
          offset: const Offset(-2, -2),
          blurRadius: 6,
        ),
        BoxShadow(
          color: isDark ? AppColors.darkShadowSubtle : AppColors.shadowSubtle,
          offset: const Offset(2, 4),
          blurRadius: 8,
        ),
      ],
    );
  }
}
