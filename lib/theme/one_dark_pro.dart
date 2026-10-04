import 'package:flutter/material.dart';

/// Paleta inspirada en One Dark Pro.
abstract class OneDarkPro {
  static const background = Color(0xFF282C34);
  static const sidebar = Color(0xFF21252B);
  static const darker = Color(0xFF1B1E23);
  static const border = Color(0xFF181A1F);
  static const card = Color(0xFF2C313C);
  static const cardHover = Color(0xFF323842);

  static const fg = Color(0xFFABB2BF);
  static const fgDim = Color(0xFF7F848E);
  static const white = Color(0xFFD7DAE0);

  static const green = Color(0xFF98C379);
  static const blue = Color(0xFF61AFEF);
  static const purple = Color(0xFFC678DD);
  static const red = Color(0xFFE06C75);
  static const yellow = Color(0xFFE5C07B);
  static const cyan = Color(0xFF56B6C2);
  static const orange = Color(0xFFD19A66);

  static const spotify = Color(0xFF1DB954);
}

ThemeData buildNovadhTheme() {
  final scheme = const ColorScheme.dark(
    primary: OneDarkPro.green,
    secondary: OneDarkPro.blue,
    surface: OneDarkPro.card,
    error: OneDarkPro.red,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: OneDarkPro.background,
    splashFactory: NoSplash.splashFactory,
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: OneDarkPro.fg),
      bodyMedium: TextStyle(color: OneDarkPro.fg),
      bodySmall: TextStyle(color: OneDarkPro.fgDim),
      titleLarge: TextStyle(color: OneDarkPro.white, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: OneDarkPro.white, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: OneDarkPro.fg, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OneDarkPro.background,
      foregroundColor: OneDarkPro.white,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(color: OneDarkPro.border, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OneDarkPro.darker,
      hintStyle: const TextStyle(color: OneDarkPro.fgDim),
      prefixIconColor: OneDarkPro.fgDim,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: OneDarkPro.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: OneDarkPro.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: OneDarkPro.green, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OneDarkPro.green,
        foregroundColor: const Color(0xFF1B1E23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OneDarkPro.fg,
        side: const BorderSide(color: OneDarkPro.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: OneDarkPro.green,
      linearTrackColor: OneDarkPro.border,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(const Color(0xFF3E4451)),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(8),
      minThumbLength: 40,
    ),
  );
}
