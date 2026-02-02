import 'package:flutter/material.dart';

/// Dark Glass aesthetic color palette for Surveyor Cam
class AppColors {
  // Primary dark theme - Matte Black Base
  static const Color background = Color(0xFF121212); // Deep OLED Black

  // Opacity Tokens (Apple Style)
  static const double opTextPrimary = 1.0;
  static const double opTextSecondary = 0.56;
  static const double opTextTertiary = 0.32;

  // Glass Tokens
  static const double opGlassMin = 0.08;
  static const double opGlassMax = 0.14;
  static const double opGlassBorder = 0.18;

  // Accents - Professional Green (Use sparingly: Underlines, Glows)
  static const Color accentGreen = Color(0xFF22C55E);
  // Deprecated: Use for legacy support until refactor complete.
  static const Color activeGreenBG = Color(0x1A22C55E);

  // Overlay - Transparent Black (Legacy, use Glass tokens preferred)
  static const Color overlayBlack = Color(0x26000000);

  static const Color warnYellow = Color(0xFFFFC107);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0x8FFFFFFF); // ~56%
  static const Color textTertiary = Color(0x52FFFFFF); // ~32%

  // UI Elements
  static const Color shutterRing = Color(0xFFFFFFFF); // Ceramic White
  static const Color shutterInner = Color(0xFF1F2023);

  // Tags
  static const Color tagBad = Color(0xFFEF4444);
  static const Color tagGood = Color(0xFF22C55E);
  static const Color tagFix = Color(0xFFF59E0B);

  // Thin lines
  static const Color guideLines = Color(0x4DFFFFFF);
}
