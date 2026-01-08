import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryBlue = Color(0xFF0046FF);
  static const Color appBarBlue = Color(0xFF0046FF);
  static const Color lightBlue = Color(0xFF73C8D2);
  static const Color secondaryOrange = Color(0xFFFF9013);
  static const Color backgroundBeige = Colors.white;
  static const Color textGrey = Color(0xFF666666);
  static const Color iconGrey = Color(0xFF9E9E9E);
  static const Color iconBgOrange = Color(0xFFA57C36);
  static const Color labelBlue = Color(0xFF34B3E4);
  static const Color reminderRed = Color(0xFFC60808);
  static const Color proposalGreen = Color(0xFF89C103);
  static const Color noteOrange = Color(0xFFFFB13C);

  static TextStyle get textStyle =>
      GoogleFonts.roboto(); // Roboto seems closer to the screenshot

  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        secondary: secondaryOrange,
        surface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: appBarBlue,
        foregroundColor: Colors.white,
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
        fillColor: Colors.transparent,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
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
        contentPadding: EdgeInsets.symmetric(vertical: 8),
      ),
      textTheme: GoogleFonts.robotoTextTheme().copyWith(
        titleLarge: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        bodyLarge: const TextStyle(fontSize: 15, color: Colors.black87),
        bodyMedium: const TextStyle(fontSize: 14, color: Colors.black54),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
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
