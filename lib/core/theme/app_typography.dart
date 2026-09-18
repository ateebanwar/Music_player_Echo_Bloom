import 'package:flutter/material.dart';
import 'package:sound_foundry/core/theme/app_colors.dart';

/// Typography definitions strictly matching the reference font weights and colors.
abstract final class AppTypography {
  /// Header "Now Playing" title
  static const TextStyle headerTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textNavy,
    letterSpacing: -0.2,
  );

  /// Main song title "Night Changes"
  static const TextStyle trackTitle = TextStyle(
    fontSize: 23.0,
    fontWeight: FontWeight.w700,
    color: AppColors.textNavy,
    letterSpacing: -0.4,
    height: 1.2,
  );

  /// Artist name "One Direction"
  static const TextStyle artistName = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textPurple,
    letterSpacing: -0.1,
  );

  /// Position and Duration text "1:32 / 3:46"
  static const TextStyle timeProgress = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: AppColors.textNavy,
    letterSpacing: -0.2,
  );

  /// Navigation Bar Active Label
  static const TextStyle navLabelActive = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryPurple,
    letterSpacing: -0.2,
  );

  /// Navigation Bar Inactive Label
  static const TextStyle navLabelInactive = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w500,
    color: AppColors.iconMuted,
    letterSpacing: -0.2,
  );
}
