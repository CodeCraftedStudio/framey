import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF137FEC);
  static const Color surfaceDark = Color(0xFF0F1115);
  static const Color backgroundDark = Color(0xFF07080A);
  static const Color cardColorDark = Color(0xFF181A20);
  static const Color errorColor = Color(0xFFFE4A49);

  static ThemeData darkTheme = ThemeData(
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
    cardTheme: const CardThemeData(
      color: cardColorDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
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
          return const IconThemeData(color: primaryColor, size: 26);
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

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
    ),
    textTheme: GoogleFonts.plusJakartaSansTextTheme(
      ThemeData.light().textTheme,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: Colors.black,
      ),
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F9FA),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFFE9ECEF), width: 1),
      ),
    ),
  );
}
