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

  static const green  = Color(0xFF6C9C54);
  static const blue   = Color(0xFF5F7EA6);
  static const red    = Color(0xFFA35C62);
  static const yellow = Color(0xFFA38B5C);
}

ThemeData buildNovadhTheme() {
  final scheme = const ColorScheme.dark(
    primary: OneDarkPro.blue,
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
        borderSide: const BorderSide(color: OneDarkPro.blue, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OneDarkPro.blue,
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
      color: OneDarkPro.blue,
      linearTrackColor: OneDarkPro.border,
    ),
    scrollbarTheme: ScrollbarThemeData(
      thumbVisibility: WidgetStateProperty.all(true),
      thumbColor: WidgetStateProperty.all(OneDarkPro.cardHover),
      trackColor: WidgetStateProperty.all(Colors.transparent),
      radius: const Radius.circular(8),
      thickness: WidgetStateProperty.all(8),
      mainAxisMargin: 4,
      crossAxisMargin: 0,
      minThumbLength: 40,
    ),
  );
}
