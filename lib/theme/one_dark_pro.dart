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

  /// Texto secundario AA sobre background/sidebar/darker (≥5.3:1).
  /// `fgDim` queda reservado a iconos decorativos y placeholders grandes.
  static const fgMid = Color(0xFF9AA0AB);
  static const white = Color(0xFFD7DAE0);

  static const green = Color(0xFF6C9C54);
  static const blue = Color(0xFF5F7EA6);
  static const red = Color(0xFFA35C62);
  static const yellow = Color(0xFFA38B5C);

  /// Variantes de texto AA (≥6:1 sobre los tres fondos).
  /// Usar estas —no los tonos base— para cualquier texto en color.
  static const greenText = Color(0xFF9AD08A);
  static const blueText = Color(0xFF8AB4F8);
  static const redText = Color(0xFFE0989D);

  /// Fondo de botón primario: mismo matiz que `blue`, aclarado para
  /// que el texto `darker` alcance 6.4:1 (el `blue` base daba 4.0:1).
  static const buttonBlue = Color(0xFF7FA3CC);

  /// Fondo de botón de marca (login YouTube): `red` aclarado +8 por canal
  /// para que el texto negro alcance 4.8:1 (el `red` base daba 4.3:1).
  static const buttonRed = Color(0xFFAB646A);
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
    // Anillo de foco visible para navegación por teclado (desktop).
    focusColor: OneDarkPro.blueText.withValues(alpha: 0.22),
    hoverColor: OneDarkPro.cardHover,
    highlightColor: OneDarkPro.blueText.withValues(alpha: 0.12),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: OneDarkPro.fg),
      bodyMedium: TextStyle(color: OneDarkPro.fg),
      bodySmall: TextStyle(color: OneDarkPro.fgMid),
      titleLarge: TextStyle(
        color: OneDarkPro.white,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: TextStyle(
        color: OneDarkPro.white,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: TextStyle(color: OneDarkPro.fg, fontWeight: FontWeight.w600),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: OneDarkPro.background,
      foregroundColor: OneDarkPro.white,
      elevation: 0,
    ),
    dividerTheme: const DividerThemeData(
      color: OneDarkPro.border,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OneDarkPro.darker,
      hintStyle: const TextStyle(color: OneDarkPro.fgMid),
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
        borderSide: const BorderSide(color: OneDarkPro.blueText, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OneDarkPro.buttonBlue,
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

/// Escala tipográfica (5 niveles, una sola familia base).
/// Los tamaños fuera de escala se expresan con copyWith sobre el nivel base.
abstract class AppText {
  /// Hero 18/w800: título principal de vista.
  static const hero = TextStyle(
    color: OneDarkPro.white,
    fontSize: 18,
    fontWeight: FontWeight.w800,
  );

  /// Título 13.5/w600: canciones, items, títulos de panel.
  static const title = TextStyle(
    color: OneDarkPro.white,
    fontSize: 13.5,
    fontWeight: FontWeight.w600,
  );

  /// Cuerpo 12: texto funcional (botones, inputs, álbumes).
  static const body = TextStyle(color: OneDarkPro.fg, fontSize: 12);

  /// Entrada 14: texto del campo de búsqueda (hero de la vista).
  static const input = TextStyle(color: OneDarkPro.fg, fontSize: 14);

  /// Secundario 12.5: artistas, hints, mensajes (AA en los 3 fondos).
  static const secondary = TextStyle(color: OneDarkPro.fgMid, fontSize: 12.5);

  /// Etiqueta 11/w700 con tracking: headers, badges, secciones (AA).
  static const caps = TextStyle(
    color: OneDarkPro.fgMid,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );
}
