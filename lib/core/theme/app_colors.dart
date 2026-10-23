import 'package:flutter/material.dart';

/// Exact color palette and semantic tokens for both Light Mode and True Dark Neumorphism.
/// Echo Bloom botanical green/teal identity.
abstract final class AppColors {
  // Light Theme - Background & Surfaces
  /// Primary background: #F8FCF7 (very soft white with subtle green undertone)
  static const Color background = Color(0xFFF8FCF7);
  /// Primary surface: #FFFFFF
  static const Color surface = Color(0xFFFFFFFF);
  /// Secondary surface: #F0F8EE
  static const Color surfaceElevated = Color(0xFFF0F8EE);

  // Dark Theme - Background & Surfaces
  /// Main background: #08120F
  static const Color darkBackground = Color(0xFF08120F);
  /// Primary surface: #0D1B17
  static const Color darkSurface = Color(0xFF0D1B17);
  /// Secondary surface: #122620
  static const Color darkSurfaceElevated = Color(0xFF122620);

  // Light Theme - Typography & Icons
  /// Dark text: #17231F
  static const Color textNavy = Color(0xFF17231F);
  /// Deep botanical teal: #176B5A
  static const Color textPurple = Color(0xFF176B5A);
  /// Secondary text: #60716A
  static const Color textMuted = Color(0xFF60716A);
  static const Color iconNavy = Color(0xFF17231F);
  static const Color iconMuted = Color(0xFF60716A);

  // Dark Theme - Typography & Icons
  /// Primary text: #F3FAF5
  static const Color darkText = Color(0xFFF3FAF5);
  /// Secondary text: #A8BBB2
  static const Color darkTextMuted = Color(0xFFA8BBB2);
  static const Color darkIcon = Color(0xFFF3FAF5);
  static const Color darkIconMuted = Color(0xFFA8BBB2);

  // Primary Accents & Brand Colors (Echo Bloom)
  /// Primary Echo Green: #65B995
  static const Color primaryPurple = Color(0xFF65B995);
  /// Secondary mint: #A6DEC0
  static const Color purpleLight = Color(0xFFA6DEC0);
  /// Primary accent: #75C9A3
  static const Color gradientPink = Color(0xFF75C9A3);
  /// Soft pistachio: #DDEFD8
  static const Color capsuleActiveSurface = Color(0xFFDDEFD8);
  /// Elevated surface: #17342C
  static const Color darkCapsule = Color(0xFF17342C);

  // Track & Seeker & Divider Colors
  /// Divider: #DCE7E1
  static const Color divider = Color(0xFFDCE7E1);
  /// Dark Divider: #263C35
  static const Color darkDivider = Color(0xFF263C35);
  /// Track: #DCE7E1
  static const Color seekerTrackWhite = Color(0xFFDCE7E1);
  /// Dark botanical green: #1E5143
  static const Color darkSeekerTrack = Color(0xFF1E5143);

  // Semantic Colors
  static const Color favoriteRed = Color(0xFFE53935);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF65B995);
  static const Color accentGreen = successGreen;
  static const Color accentRed = favoriteRed;


  // Light Neumorphic Shadows (Soft white highlight + subtle botanical shadow)
  static const Color shadowLight = Color(0xFFFFFFFF);
  static const Color shadowDark = Color(0x1E17231F);
  static const Color shadowMedium = Color(0x1417231F);
  static const Color shadowSubtle = Color(0x0A17231F);
  static const Color shadowArtwork = Color(0x28176B5A);

  // True Dark Neumorphic Shadows (Subtle soft highlight + deep dark shadow)
  static const Color darkShadowLight = Color(0x0EFFFFFF);
  static const Color darkShadowDark = Color(0x80000000);
  static const Color darkShadowMedium = Color(0x60000000);
  static const Color darkShadowSubtle = Color(0x40000000);
  static const Color darkShadowArtwork = Color(0xA0000000);

  // Background Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FCF7),
      Color(0xFFF0F8EE),
    ],
    stops: [0.0, 0.45, 1.0],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0D1B17),
      Color(0xFF08120F),
      Color(0xFF050B09),
    ],
    stops: [0.0, 0.45, 1.0],
  );
}
