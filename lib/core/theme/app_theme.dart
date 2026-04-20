import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        onSurface: AppColors.onSurface,
        background: AppColors.background,
        onBackground: AppColors.onBackground,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.surfaceContainerLow, // Specified page background
      
      // Typography: "Authority Through Scale"
      textTheme: TextTheme(
        displayLarge: GoogleFonts.publicSans(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          letterSpacing: -1.12, // -0.02em strictly for authority feel
          color: AppColors.onSurface,
        ),
        headlineMedium: GoogleFonts.publicSans(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.56, // -0.02em 
          color: AppColors.primary, // Using brand primary for headlines
        ),
        titleMedium: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.onSurface,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: AppColors.onSurface,
        ),
        labelMedium: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.outline,
        ),
      ),
      
      // Button Theme: "The Action Pillars"
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // xl rounding
          ),
          elevation: 0,
        ),
      ),
      
      // Card Theme: Tonal Layering (No-Line Rule)
      cardTheme: CardThemeData(
        color: AppColors.surfaceContainerLowest, // Pure White on Light Blue BG
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          // BORDERS PROHIBITED for sectioning as per spec
          side: BorderSide.none, 
        ),
      ),
      
      // Input Decoration: "Active State Bottom-bar"
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: const UnderlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outline.withOpacity(0.1), width: 1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2), // 2px primary bottom-bar only
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        labelStyle: const TextStyle(color: AppColors.outline),
      ),
    );
  }
}
