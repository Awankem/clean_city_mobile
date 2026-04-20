import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Verdant Civic)
  static const Color primary = Color(0xFF00482F); // Primary - Deep Forest Green
  static const Color primaryContainer = Color(0xFF006241); // Atmospheric Depth Target
  static const Color secondary = Color(0xFF785A00); // Earthy Gold
  static const Color secondaryContainer = Color(0xFFFEC733); // High Visibility Gold
  static const Color tertiary = Color(0xFF820011); // High Visibility Red
  static const Color tertiaryContainer = Color(0xFFAE001B);
  
  // Tonal Palette (Authority Palette)
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF171C22);
  static const Color onBackground = Color(0xFF171C22);
  
  // Elevation / Tonal Layering
  static const Color surfaceContainerLow = Color(0xFFF0F4FD);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFE4E8F1);
  static const Color surfaceContainerHighest = Color(0xFFDEE3EB);
  
  // UI States & Lines
  static const Color error = Color(0xFFBA1A1A);
  static const Color outline = Color(0xFF6F7A72);
  static const Color outlineVariant = Color(0x26BEC9C0); // 15% opacity - Ghost Border rule
  static const Color outlineVariantSolid = Color(0xFFBEC9C0); // full opacity for dividers

  // Status Colors (Matching Laravel)
  static const Color statusPending = Color(0xFF455A64); // Muted blue-gray
  static const Color statusInProgress = Color(0xFFE69138); // Amber/Orange
  static const Color statusResolved = Color(0xFF006241); // Deep Civic Green
  
  // Signature treatments
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
