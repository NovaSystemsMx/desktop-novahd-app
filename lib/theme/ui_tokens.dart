import 'package:flutter/widgets.dart';

/// Contrato de métricas de la UI. Ver `docs/reglas-ui.md`.
///
/// Regla: un número que no esté aquí no debe aparecer en `lib/views` ni en
/// `lib/widgets`. Si hace falta un valor nuevo, se añade con nombre de rol
/// (no un número suelto) y se documenta en el contrato.
///
/// Escala alineada con la convergencia de Material 3 (40), Carbon md (40)
/// y Fluent large (40), sobre una retícula de 4/8. Ver ADR 18.
abstract final class UiTokens {
  // ── Espaciado por rol ────────────────────────────────────────────────

  /// Margen exterior de una vista (retícula 8).
  static const double spacePage = 24;

  /// Separación entre bloques/cards hermanos.
  static const double spaceBlock = 16;

  /// Padding interior de card.
  static const double spaceCard = 16;

  /// Padding horizontal de fila.
  static const double spaceRowH = 16;

  /// Padding vertical de fila (64 = botón 40 + 2 × 12).
  static const double spaceRowV = 12;

  /// Icono ↔ texto y separaciones internas.
  static const double spaceInline = 8;

  /// Cluster de iconos de acción (header).
  static const double spaceCluster = 4;

  /// Input ↔ botón en una fila de control.
  static const double spaceControlGap = 8;

  /// Gap del estado vacío (tile ↔ texto).
  static const double spaceEmptyGap = 12;

  /// Gap entre el tile del encabezado de vista y su bloque de título.
  static const double spaceHeaderGap = 12;

  /// Label de sección: aire superior.
  static const double spaceSectionTop = 16;

  /// Label de sección: aire inferior.
  static const double spaceSectionBottom = 8;

  /// Padding interior de un item de navegación (sidebar).
  static const double spaceItemH = 12;
  static const double spaceItemV = 8;

  /// Aire exterior entre items de navegación.
  static const double spaceItemOuterH = 8;
  static const double spaceItemOuterV = 2;

  /// Badge compacto (“Pronto”).
  static const double spaceBadgeH = 6;
  static const double spaceBadgeV = 2;

  /// Separación entre dos líneas de texto de una misma celda.
  static const double spaceTextGap = 2;

  /// Aire vertical interno de un control de 40 (input/botón).
  static const double spaceControlV = 10;

  static const EdgeInsets paddingPage = EdgeInsets.all(spacePage);
  static const EdgeInsets paddingCard = EdgeInsets.all(spaceCard);

  /// Header de 40: contenido de 32 y 4 de aire vertical. Así el título
  /// (caps 12) y las acciones (hit 32) caben en la misma tira.
  static const EdgeInsets paddingCardHeader = EdgeInsets.fromLTRB(
    spaceCard,
    4,
    spaceCard,
    4,
  );
  static const EdgeInsets paddingRow = EdgeInsets.symmetric(
    horizontal: spaceRowH,
    vertical: spaceRowV,
  );
  static const EdgeInsets paddingButton = EdgeInsets.symmetric(
    horizontal: spaceCard,
    vertical: spaceControlV,
  );
  static const EdgeInsets paddingSectionLabel = EdgeInsets.only(
    left: spaceCard,
    top: spaceSectionTop,
    bottom: spaceSectionBottom,
  );

  /// Label de sección del sidebar: alineado con el contenido del ítem
  /// (aire exterior + padding interior), no con el borde.
  static const EdgeInsets paddingSidebarLabel = EdgeInsets.fromLTRB(
    spaceItemOuterH + spaceItemH,
    spaceSectionTop,
    spaceItemOuterH + spaceItemH,
    spaceSectionBottom,
  );

  // ── Tamaños ──────────────────────────────────────────────────────────

  /// Alto de input y botón de una línea. Deben coincidir en la misma fila.
  /// El input hace scroll; el label del botón no se trunca (se acorta).
  static const double sizeControl = 40;
  static const double sizeButton = 40;
  static const double sizeCardHeader = 40;
  static const double sizeHeaderContent = 32;
  static const double sizeTopBar = 48;
  static const double sizeStatusBar = 32;

  /// Alto de fila de dos líneas (título 14 + artista 12).
  static const double sizeRow = 64;
  static const double sizeHeaderAction = 32;
  static const double sizeSidebar = 256;
  static const double sizeTileSidebar = 32;
  static const double sizeTileView = 40;
  static const double sizeTileEmpty = 48;

  /// Grosor de la barra de progreso de la cola.
  static const double sizeProgress = 3;

  /// Alto del bloque de consola de Ajustes.
  static const double sizeConsole = 220;

  /// Caja del diálogo de cookies guardadas.
  static const double sizeDialogW = 520;
  static const double sizeDialogH = 300;

  // ── Iconos ───────────────────────────────────────────────────────────

  static const double iconButton = 16;
  static const double iconHeaderAction = 16;
  static const double iconInline = 16;
  static const double iconTileSidebar = 18;
  static const double iconTileView = 20;
  static const double iconTileEmpty = 24;

  // ── Radios ───────────────────────────────────────────────────────────

  static const double radiusCard = 12;
  static const double radiusControl = 8;
  static const double radiusSmall = 4;
  static const double radiusScrollbar = 8;

  // ── Bordes ───────────────────────────────────────────────────────────

  static const double borderWidth = 1;
  static const double borderFocus = 2;

  // ── Responsive (ancho de CONTENIDO, no de ventana) ───────────────────

  /// Por debajo de este ancho la cola de descargas se apila.
  static const double stackBelow = 820;

  /// A partir de este ancho la cola usa su ancho completo.
  static const double queueWideFrom = 1000;

  /// Ancho de la cola cuando el contenido está entre [stackBelow, queueWideFrom).
  static const double queueNarrow = 320;

  /// Ancho de la cola por encima de [queueWideFrom].
  static const double queueWide = 360;

  // ── Columnas de la tabla ─────────────────────────────────────────────

  static const double colCover = 40;
  static const double colCoverGap = 12;
  static const double colDuration = 72;

  /// Incluye el botón de acción y 8 de aire.
  static const double colAction = 128;

  // ── Indicadores ──────────────────────────────────────────────────────

  static const double sizeStatusDot = 8;
  static const double sizeStatusDotInner = 4;
}
