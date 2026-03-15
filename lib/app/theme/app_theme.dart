import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // --- PRIMARY COLORS ---
  static const Color primaryColor = Color(0xFF1565C0); // Deep Blue jo aapke dashboard se match karega

  // --- THEME COLORS (#F8F4EC Background) ---
  static const Color appBackground = Color(0xFFF8F4EC); // Aapka bataya hua color
  static const Color surfaceColor = Colors.white;      // Cards ke liye pure white best rehta hai
  static const Color textPrimary = Color(0xFF1F2937);  // Dark Grey for readability
  static const Color textSecondary = Color(0xFF6B7280); // Muted Grey for subtitles

  // --- THEME DEFINITION ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: appBackground,
      
      // Card Theme ko optimize kiya gaya hai taake background par utha hua nazar aaye
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: surfaceColor,
      ).copyWith(
        background: appBackground,
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // Background se blend karne ke liye
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // Status bar icons dark rahengi
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
        titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: textSecondary),
        bodySmall: TextStyle(color: textSecondary),
      ),

      // Bottom Navigation Bar
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: textSecondary,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
      ),

      // Input Decoration (TextFields ke liye)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }

  // Dark Theme ko yahan se remove kar diya gaya hai.
}