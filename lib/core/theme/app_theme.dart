import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color surfaceDark = Color(0xFF0F1115);
  static const Color backgroundDark = Color(0xFF07080A);
  static const Color cardColorDark = Color(0xFF181A20);
  static const Color errorColor = Color(0xFFFE4A49);

  static ThemeData getDarkTheme(Color primaryColor) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      surface: surfaceDark,
      background: backgroundDark,
      error: errorColor,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
    ),
    scaffoldBackgroundColor: backgroundDark,
    listTileTheme: const ListTileThemeData(
      dense: false,
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    ),
    iconTheme: const IconThemeData(color: Colors.white, size: 24),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceDark,
      indicatorColor: primaryColor.withOpacity(0.1),
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return IconThemeData(color: primaryColor, size: 26);
        }
        return IconThemeData(color: Colors.white.withOpacity(0.5), size: 24);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.plusJakartaSans(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          );
        }
        return GoogleFonts.plusJakartaSans(
          color: Colors.white.withOpacity(0.5),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
  );

  static ThemeData getLightTheme(Color primaryColor) => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      surface: Colors.white,
      background: const Color(0xFFF8FAFC),
      onBackground: const Color(0xFF0F172A),
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF8FAFC).withOpacity(0.8),
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF0F172A),
        letterSpacing: -1,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8FAFC),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: primaryColor.withOpacity(0.1),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.plusJakartaSans(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          );
        }
        return GoogleFonts.plusJakartaSans(
          color: const Color(0xFF64748B),
          fontWeight: FontWeight.w500,
          fontSize: 12,
        );
      }),
    ),
  );
}
