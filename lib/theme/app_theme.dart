import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // New Color Palette
  static const Color palette1 = Color(0xFFF3EEEA); // Lightest - Accent/Surface
  static const Color palette2 = Color(
    0xFFEBE3D5,
  ); // Light Beige - Secondary Surface
  static const Color palette3 = Color(
    0xFFB0A695,
  ); // Medium Brown - Secondary/Icons
  static const Color palette4 = Color(0xFF776B5D); // Dark Brown - Primary/Text

  // Mapping
  static const Color primaryBlue = palette4;
  static const Color appBarBlue = palette4; // App Bar Background
  static const Color lightBlue = palette3;
  static const Color secondaryOrange = palette3; // Accent
  static const Color backgroundBeige =
      Colors.white; // User requested pure white
  static const Color textGrey = palette4;
  static const Color iconGrey = palette3;
  static const Color iconBgOrange = palette2;
  static const Color labelBlue = palette3;
  static const Color reminderRed = Color(0xFFC60808);
  static const Color proposalGreen = Color(0xFF89C103);
  static const Color noteOrange = Color(0xFFFFB13C);

  static TextStyle get textStyle => GoogleFonts.roboto();

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white, // Pure white background
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        secondary: secondaryOrange,
        surface: Colors.white, // Pure white surface
        background: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBlue,
        foregroundColor: Colors.white, // White text on Dark Brown
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 20,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryOrange,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        fillColor: palette1, // Using lightest palette for input background
        border: UnderlineInputBorder(borderSide: BorderSide(color: palette3)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: palette3),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: TextStyle(
          color: textGrey,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        hintStyle: TextStyle(
          color: iconGrey,
          fontSize: 16,
          fontFamily: 'Roboto',
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: palette4, // Dark brown title
        ),
        bodyLarge: const TextStyle(fontSize: 15, color: palette4),
        bodyMedium: const TextStyle(fontSize: 14, color: palette4),
      ),
      cardTheme: CardThemeData(
        color: Colors.white, // White cards
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: palette3.withOpacity(0.2)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
