import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  AppThemes._();

  static const Color _black = Color(0xFF0C0F0A);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _grey = Color(0xFFD9D9D9);

  static TextStyle storyScript(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextStyle? baseStyle,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle fallback = theme.textTheme.headlineMedium ?? const TextStyle();
    return GoogleFonts.styleScript(
      textStyle: baseStyle ?? fallback,
    ).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
    );
  }

  static TextStyle poppins(
    BuildContext context, {
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    TextStyle? baseStyle,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
  }) {
    final ThemeData theme = Theme.of(context);
    final TextStyle fallback = theme.textTheme.bodyMedium ?? const TextStyle();
    return GoogleFonts.poppins(
      textStyle: baseStyle ?? fallback,
    ).copyWith(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color ?? theme.colorScheme.onSurface,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme _mixedTextTheme(TextTheme base) {
    final TextTheme poppins = GoogleFonts.poppinsTextTheme(base);
    return poppins.copyWith(
      displayLarge: GoogleFonts.carterOne(textStyle: poppins.displayLarge),
      displayMedium: GoogleFonts.carterOne(textStyle: poppins.displayMedium),
      displaySmall: GoogleFonts.carterOne(textStyle: poppins.displaySmall),
      headlineLarge: GoogleFonts.carterOne(textStyle: poppins.headlineLarge),
      headlineMedium: GoogleFonts.carterOne(textStyle: poppins.headlineMedium),
      headlineSmall: GoogleFonts.carterOne(textStyle: poppins.headlineSmall),
    );
  }

  static ThemeData _applyFonts(ThemeData theme) {
    return theme.copyWith(
      textTheme: _mixedTextTheme(theme.textTheme),
      primaryTextTheme: _mixedTextTheme(theme.primaryTextTheme),
    );
  }

  static ThemeData lightTheme() {
    const ColorScheme scheme = ColorScheme.light(
      primary: _black,
      onPrimary: _white,
      secondary: _grey,
      onSecondary: _black,
      surface: _white,
      onSurface: _black,
      error: _black,
      onError: _white,
    );

    return _applyFonts(ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _white,
        foregroundColor: _black,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: _white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _grey),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.primary.withOpacity(0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _black, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _black,
          foregroundColor: _white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _black,
          side: BorderSide(color: _grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _black,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _black,
        contentTextStyle: const TextStyle(color: _white),
      ),
      dividerTheme: const DividerThemeData(color: _grey),
    ));
  }

  static ThemeData darkTheme() {
    const ColorScheme scheme = ColorScheme.dark(
      primary: _white,
      onPrimary: _black,
      secondary: _grey,
      onSecondary: _black,
      surface: _black,
      onSurface: _white,
      error: _white,
      onError: _black,
    );

    return _applyFonts(ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _black,
        foregroundColor: _white,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      cardTheme: CardThemeData(
        color: _black,
        elevation: 0.5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _grey),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _grey,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _white, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _white,
          foregroundColor: _black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _white,
          side: BorderSide(color: _grey),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _white,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _white,
        contentTextStyle: const TextStyle(color: _black),
      ),
      dividerTheme: const DividerThemeData(color: _grey),
    ));
  }
}
