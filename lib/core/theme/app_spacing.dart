import 'package:flutter/widgets.dart';

/// Centralized spacing, padding, and corner radius constants.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;

  // Screen horizontal margins
  static const double screenMarginHorizontal = 24.0;

  // Corner Radii
  static const double radiusSm = 12.0;
  static const double radiusMd = 18.0;
  static const double radiusLg = 24.0;
  static const double radiusArtwork = 30.0;
  static const double radiusControlPanel = 32.0;
  static const double radiusNavCapsule = 24.0;
  static const double radiusNavContainer = 32.0;

  // BorderRadius helpers
  static final BorderRadius roundedArtwork = BorderRadius.circular(radiusArtwork);
  static final BorderRadius roundedControlPanel = BorderRadius.circular(radiusControlPanel);
  static final BorderRadius roundedNavCapsule = BorderRadius.circular(radiusNavCapsule);
  static final BorderRadius roundedNavContainer = BorderRadius.circular(radiusNavContainer);
  static final BorderRadius roundedFavorite = BorderRadius.circular(18.0);
  static final BorderRadius roundedFavoriteBtn = BorderRadius.circular(18.0);
}
