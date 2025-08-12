// FILE: lib/design_system/tokens.dart
import 'package:flutter/material.dart';

/// Design tokens for the Ceylon app
/// These tokens provide consistent values for spacing, radius, shadows, and animations
/// throughout the application.
class CeylonTokens {
  // App color seed
  static const Color seedColor = Color(0xFF00A389);

  // Light theme surface colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);

  // Dark theme surface colors
  static const Color darkBackground = Color(0xFF0B1416);
  static const Color darkSurface = Color(0xFF0F1B1D);

  // Border radius values
  static const double radiusSmall = 6.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
  
  // Default radius for cards and buttons
  static const double defaultRadius = radiusMedium;
  
  // Spacing scale (4-point system)
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  
  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 250);
  static const Duration animationSlow = Duration(milliseconds: 300);
  
  // Accessibility 
  static const double minTapArea = 48.0; // Minimum tap area in pixels
  
  // Common border radius shapes
  static final BorderRadius borderRadiusSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius borderRadiusMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius borderRadiusLarge = BorderRadius.circular(radiusLarge);
  
  // Commonly used shadows
  static final List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
  
  static final List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static final List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
