import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // New "Soft Premium" Palette (Inspired by image_1.png)
  // Gradients for backgrounds
  static const Color gradientStart = Color(0xFFFFE0E0); // Soft Coral Pink
  static const Color gradientEnd = Color(0xFFF3E5F5); // Very Light Purple

  // Main Surfaces
  static const Color backgroundLight = Colors.white;
  static const Color surfaceLight = Color(0xFFF8F9FA); // Very light grey
  static const Color surfaceBorder = Color(0x0D000000); // Subtle border

  // Accents & Interactions (Softer than neon green)
  static const Color primarySoft = Color(0xFFFF7043); // Coral
  static const Color primaryGlow = Color(0x1AFF7043); // Subtle coral glow
  static const Color accentSoft = Color(0xFFAB47BC); // Soft Purple

  // Text
  static const Color textPrimary = Color(0xFF212121); // Almost black grey
  static const Color textSecondary = Color(0xFF757575); // Medium grey
  static const Color textMuted = Color(0xFFBDBDBD); // Light grey

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light, // Crucial change!
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primarySoft,
      colorScheme: const ColorScheme.light(
        primary: primarySoft,
        secondary: accentSoft,
        surface: surfaceLight,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Keeps the gradient visible
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Dark icons for light bg
          systemNavigationBarColor: backgroundLight,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 24, // Slightly larger
          fontWeight: FontWeight.w800, // Thicker weight
          letterSpacing: -0.8,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Maximize roundedness
          side: const BorderSide(color: surfaceBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySoft,
          foregroundColor: Colors.white,
          elevation: 4, // Softer shadow
          shadowColor: primaryGlow,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Softer corners
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.1,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimary,
          side: const BorderSide(color: surfaceBorder),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
