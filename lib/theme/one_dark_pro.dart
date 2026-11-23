import 'package:flutter/material.dart';

import 'ui_tokens.dart';

/// Paleta inspirada en One Dark Pro.
///
/// Paleta cerrada: no se añaden colores sin aprobación explícita.
/// Ver `docs/reglas-ui.md` §2.6.
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
}

/// Overlay explícito para botones.
///
/// `styleFrom` deriva el overlay del `foregroundColor` al 8 %, que sobre un
/// relleno sólido es casi invisible. Aquí se fijan hover, pressed y foco.
/// El foco añade un cambio de relleno además del anillo ([focusRing]):
/// sobre los botones claros el anillo oscuro se lee como sombra si el
/// relleno no cambia.
///
/// Público para que los botones con estilo propio (Ajustes activo) no
/// pierdan los estados del tema al pasar `styleFrom`.
WidgetStateProperty<Color?> buttonOverlay({
  required Color hover,
  required Color pressed,
  required Color focus,
}) {
  return WidgetStateProperty.resolveWith<Color?>((states) {
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.focused)) return focus;
    if (states.contains(WidgetState.hovered)) return hover;
    return null;
  });
}

/// Hover/pressed/foco del primario azul. El hover aclara con `white` 15 %
/// (el label `darker` sube de 6.38:1 a ~7.0:1); pressed y foco oscurecen
/// con `darker` 10 %: el foco se distingue del reposo por el relleno y por
/// el anillo de [focusRing].
WidgetStateProperty<Color?> get primaryButtonOverlay => buttonOverlay(
  hover: OneDarkPro.white.withValues(alpha: 0.15),
  pressed: OneDarkPro.darker.withValues(alpha: 0.10),
  focus: OneDarkPro.darker.withValues(alpha: 0.10),
);

/// Hover/pressed/foco de botón sin relleno (outlined, text, icono): hover
/// `cardHover`; pressed y foco `blueText` 12 %, el mismo tinte del
/// highlight. En estos botones el anillo `blueText` es el indicador fuerte.
WidgetStateProperty<Color?> get plainButtonOverlay => buttonOverlay(
  hover: OneDarkPro.cardHover,
  pressed: OneDarkPro.blueText.withValues(alpha: 0.12),
  focus: OneDarkPro.blueText.withValues(alpha: 0.12),
);

/// Borde de foco por teclado: 2 px dentro de la forma, sin cambiar tamaño.
///
/// `blueText` sobre fondos oscuros va de 5.6:1 a 7.3:1. Sobre el relleno
/// claro del primario (`buttonBlue`) cae a 1.24:1, así que ese botón pasa
/// `color: darker` (6.38:1). Ver contrato §5.
WidgetStateProperty<BorderSide?> focusRing({
  Color color = OneDarkPro.blueText,
  BorderSide? rest,
}) {
  return WidgetStateProperty.resolveWith<BorderSide?>((states) {
    if (states.contains(WidgetState.focused)) {
      return BorderSide(color: color, width: UiTokens.borderFocus);
    }
    return rest;
  });
}

/// Tema alineado con la convergencia de Material 3 (40), Carbon md (40)
/// y Fluent large (40): controles de 40, cuerpo 14, caption 12 y filas de
/// 64 para dos líneas. Ver `docs/reglas-ui.md` §2 y ADR 18.
ThemeData buildNovadhTheme() {
  final scheme = const ColorScheme.dark(
    primary: OneDarkPro.blue,
    secondary: OneDarkPro.blue,
    surface: OneDarkPro.card,
    error: OneDarkPro.red,
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Segoe UI',
    colorScheme: scheme,
    scaffoldBackgroundColor: OneDarkPro.background,
    splashFactory: NoSplash.splashFactory,
    // Anillo de foco visible para navegación por teclado (desktop).
    focusColor: OneDarkPro.blueText.withValues(alpha: 0.22),
    hoverColor: OneDarkPro.cardHover,
    highlightColor: OneDarkPro.blueText.withValues(alpha: 0.12),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 14,
        height: 1.5,
        fontFamily: 'Segoe UI',
      ),
      bodyMedium: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 14,
        height: 1.5,
        fontFamily: 'Segoe UI',
      ),
      bodySmall: TextStyle(
        color: OneDarkPro.fgMid,
        fontSize: 12,
        height: 1.5,
        fontFamily: 'Segoe UI',
      ),
      titleLarge: TextStyle(
        color: OneDarkPro.white,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w700,
        fontFamily: 'Segoe UI',
      ),
      titleMedium: TextStyle(
        color: OneDarkPro.white,
        fontSize: 16,
        height: 1.3,
        fontWeight: FontWeight.w600,
        fontFamily: 'Segoe UI',
      ),
      titleSmall: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 14,
        height: 1.35,
        fontWeight: FontWeight.w600,
        fontFamily: 'Segoe UI',
      ),
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
    // Diálogos al ritmo de las cards: borde, radio 12 y título 20.
    dialogTheme: const DialogThemeData(
      backgroundColor: OneDarkPro.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: OneDarkPro.border),
      ),
      titleTextStyle: TextStyle(
        color: OneDarkPro.white,
        fontSize: 20,
        height: 1.2,
        fontWeight: FontWeight.w600,
        fontFamily: 'Segoe UI',
      ),
      contentTextStyle: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 14,
        height: 1.5,
        fontFamily: 'Segoe UI',
      ),
    ),
    // SnackBars oscuros (M3 usaría superficie inversa clara).
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: OneDarkPro.card,
      contentTextStyle: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 14,
        height: 1.5,
        fontFamily: 'Segoe UI',
      ),
      actionTextColor: OneDarkPro.blueText,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        side: BorderSide(color: OneDarkPro.border),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: OneDarkPro.darker,
      hintStyle: const TextStyle(
        color: OneDarkPro.fgMid,
        fontSize: 14,
        height: 1.4,
        fontFamily: 'Segoe UI',
      ),
      labelStyle: const TextStyle(
        color: OneDarkPro.fgMid,
        fontSize: 12,
        height: 1.33,
        fontFamily: 'Segoe UI',
      ),
      floatingLabelStyle: const TextStyle(
        color: OneDarkPro.blueText,
        fontSize: 12,
        height: 1.33,
        fontFamily: 'Segoe UI',
      ),
      prefixIconColor: OneDarkPro.fgDim,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: OneDarkPro.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: OneDarkPro.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: OneDarkPro.blueText, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: OneDarkPro.buttonBlue,
        foregroundColor: OneDarkPro.darker,
        disabledBackgroundColor: OneDarkPro.card,
        disabledForegroundColor: OneDarkPro.fgDim,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        // El primario aclara con `white` 15 % y el label `darker`
        // sube de 6.38:1 a ~7.0:1.
        overlayColor: primaryButtonOverlay,
        // El relleno primario es claro: un anillo `blueText` daría 1.24:1;
        // `darker` da 6.38:1.
        side: focusRing(color: OneDarkPro.darker),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: OneDarkPro.fg,
        disabledForegroundColor: OneDarkPro.fgDim,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        side: const BorderSide(color: OneDarkPro.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        overlayColor: plainButtonOverlay,
        side: focusRing(rest: const BorderSide(color: OneDarkPro.border)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: OneDarkPro.blueText,
        disabledForegroundColor: OneDarkPro.fgDim,
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        textStyle: AppText.body.copyWith(fontWeight: FontWeight.w500),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).copyWith(
        overlayColor: plainButtonOverlay,
        side: focusRing(),
      ),
    ),
    // IconButton de header/acción: 32 reales, sin el padding de 48 de M3.
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStateProperty.all(const Size(32, 32)),
        padding: WidgetStateProperty.all(EdgeInsets.zero),
        overlayColor: plainButtonOverlay,
        side: focusRing(),
      ),
    ),
    // M3 pinta los tooltips blancos en oscuro; aquí van al tema.
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: OneDarkPro.darker,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        border: Border.fromBorderSide(BorderSide(color: OneDarkPro.border)),
      ),
      textStyle: TextStyle(
        color: OneDarkPro.fg,
        fontSize: 12,
        height: 1.33,
        fontFamily: 'Segoe UI',
      ),
      waitDuration: Duration(milliseconds: 500),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: OneDarkPro.blueText,
      linearTrackColor: OneDarkPro.border,
    ),
    scrollbarTheme: ScrollbarThemeData(
      // Auto-hide: aparece al hacer scroll o hover, no en reposo.
      thumbVisibility: WidgetStateProperty.all(false),
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

/// Escala tipográfica (9 estilos, una sola familia base).
/// Alineada a la convergencia M3 / Carbon / Fluent: 20 / 14 / 12.
/// Los tamaños fuera de escala no se inventan con copyWith: se añade un
/// nivel aquí y se documenta en `docs/reglas-ui.md`.
/// El `height` va explícito en cada nivel: sin él, el texto hereda el 1.5
/// implícito de M3 y el interlineado cambia entre widgets.
abstract class AppText {
  /// Hero 20/w700: título principal de vista.
  static const hero = TextStyle(
    color: OneDarkPro.white,
    fontSize: 20,
    height: 1.2,
    fontWeight: FontWeight.w700,
    fontFamily: 'Segoe UI',
  );

  /// Wordmark de la marca: 14/w800 con tracking (logotipo, no texto de UI).
  static const brand = TextStyle(
    color: OneDarkPro.white,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w800,
    letterSpacing: 1,
    fontFamily: 'Segoe UI',
  );

  /// Título 14/w600: canciones, items, títulos de panel.
  static const title = TextStyle(
    color: OneDarkPro.white,
    fontSize: 14,
    height: 1.35,
    fontWeight: FontWeight.w600,
    fontFamily: 'Segoe UI',
  );

  /// Cuerpo 14: texto funcional (botones, inputs, álbumes).
  static const body = TextStyle(
    color: OneDarkPro.fg,
    fontSize: 14,
    height: 1.4,
    fontFamily: 'Segoe UI',
  );

  /// Entrada 14: texto del campo de búsqueda.
  static const input = TextStyle(
    color: OneDarkPro.fg,
    fontSize: 14,
    height: 1.4,
    fontFamily: 'Segoe UI',
  );

  /// Secundario 12: artistas, hints, mensajes (AA en los 3 fondos).
  static const secondary = TextStyle(
    color: OneDarkPro.fgMid,
    fontSize: 12,
    height: 1.5,
    fontFamily: 'Segoe UI',
  );

  /// Etiqueta 12/w600 con tracking: headers, badges, secciones (AA).
  static const caps = TextStyle(
    color: OneDarkPro.fgMid,
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFamily: 'Segoe UI',
  );

  /// Caption 12: subtítulos densos (sidebar, metadatos).
  static const caption = TextStyle(
    color: OneDarkPro.fgMid,
    fontSize: 12,
    height: 1.33,
    fontFamily: 'Segoe UI',
  );

  /// Mono 12: consola y bloques de cookies (mismo tamaño en ambos).
  static const mono = TextStyle(
    color: OneDarkPro.fg,
    fontSize: 12,
    height: 1.5,
    fontFamily: 'Consolas',
  );
}
