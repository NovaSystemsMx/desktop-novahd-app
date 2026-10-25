# Reglas de UI — contrato para agentes

Versión 2 · 2026-10-24 · Nova Hub Downloader v0.8

Base: convergencia de **Material 3 (40)**, **Carbon md (40)** y **Fluent
large (40)**, sobre retícula de 4/8. Controles de 40, cuerpo 14, caption 12
y filas de dos líneas de 64. Ver ADR 18.

Este documento es la ley visual del proyecto. `AGENTS.md` es el resumen
ejecutable; si hay conflicto, manda este archivo. Toda excepción se anota
en la sección 10 (Decisiones) con su motivo.

---

## 0. Por qué existe

La auditoría de `docs/auditoria-consistencia-vistas.md` encontró 43
desviaciones entre Spotify y Ajustes. Casi ninguna era un bug: eran
decisiones locales repetidas en cada widget (un padding aquí, un
`fontSize` allá, un default de Material que nadie fijó). La regla base es
simple:

> **Una vista no se diseña: se compone con las piezas del contrato.**
> Si una pieza no existe, se crea en el sistema (token o widget), no en la vista.

---

## 1. Jerarquía de la verdad

De arriba abajo; lo de abajo no puede contradecir a lo de arriba:

1. `lib/theme/one_dark_pro.dart` → color (`OneDarkPro`), tema y tipografía (`AppText`).
2. `lib/theme/ui_tokens.dart` → espacio, tamaño, radio, icono, breakpoint (`UiTokens`).
3. Widgets compartidos (cuando existan) → `ViewHeader`, `CardShell`, `PrimaryButton`, `EmptyState`.
4. Vistas (`lib/views/*`) → solo composición.
5. Valores literales → **prohibidos** salvo en el tema o en los tokens.

Un color nuevo no se escribe en la vista: se añade a `OneDarkPro` con su
ratio de contraste documentado. Un tamaño nuevo no se escribe con
`copyWith`: se añade a `AppText`.

### 1.1 Origen de las reglas

| Origen | Qué significa | Ejemplos |
|---|---|---|
| **A. Ya coincide** | ambas vistas ya lo hacen igual; se congela | card radio 12 y header 40; inputs/body 14; controles a 40; paleta; top bar 48 y status bar 32 |
| **B. Se elige una** | las vistas difieren; se adopta la que mejor funciona | header a 16; vacío 48/16; gap de bloque 16; icono de botón 16; radio de control 8; fila de dos líneas 64 |
| **C. Decisión nueva** | no existía en ninguna; se define ahora | cola 320/360; tabla de alphas; label `CANCIÓN`; sin punto en el sidebar; status por vista; wordmark `brand` |
| **D. Restricción externa** | la impone el SDK o la accesibilidad | AA 4.5:1; tooltips de M3; Segoe UI; `height` de Flutter |

Matiz importante: “ya coincide” significa **en píxeles**, no
necesariamente en construcción. El contrato unifica también cómo se
construyen las piezas.

Por eso el contrato **no describe el código actual: lo corrige**.

---

## 2. Tokens

### 2.1 Espaciado (por rol, no por número)

| Token | Valor | Dónde se usa |
|---|---:|---|
| `spacePage` | 24 | margen exterior de la vista |
| `spaceBlock` | 16 | entre cards/bloques hermanos |
| `spaceCard` | 16 | padding interior de card |
| `spaceRowH` | 16 | padding horizontal de fila |
| `spaceRowV` | 12 | padding vertical de fila (40 + 2 × 12 = 64) |
| `spaceInline` | 8 | icono ↔ texto, separaciones internas |
| `spaceCluster` | 4 | iconos de acción contiguos |
| `spaceControlGap` | 8 | input ↔ botón |
| `spaceEmptyGap` | 12 | tile ↔ texto en vacíos |
| `spaceSectionTop` | 16 | aire sobre un label de sección |
| `spaceSectionBottom` | 8 | aire bajo un label de sección |
| `spaceItemH` | 12 | padding interior de ítem de sidebar |
| `spaceItemV` | 8 | padding interior de ítem de sidebar |
| `spaceItemOuterH` | 8 | aire exterior entre ítems |
| `spaceItemOuterV` | 2 | aire exterior entre ítems |
| `spaceBadgeH` | 6 | badge compacto |
| `spaceBadgeV` | 2 | badge compacto |
| `spaceTextGap` | 2 | título ↔ artista/mensaje |
| `spaceControlV` | 10 | padding vertical de control de 40 |
| `spaceHeaderGap` | 12 | tile de cabecera ↔ texto |

Derivados: `paddingPage`, `paddingCard`, `paddingCardHeader`,
`paddingRow`, `paddingButton`, `paddingSectionLabel`,
`paddingSidebarLabel`.

La retícula es **4/8**. Valores con rol: 24, 16, 12, 10 (solo control),
8, 6 (solo badge), 4, 2. Prohibido escribir un número suelto: si no encaja
en un rol, se discute y se añade el token; no se escribe el número.

### 2.2 Tamaños

| Token | Valor | Elemento |
|---|---:|---|
| `sizeControl` | 40 | input de una línea |
| `sizeButton` | 40 | botón (primario, outlined, text) |
| `sizeCardHeader` | 40 | header de card (4 + 32 + 4) |
| `sizeHeaderContent` | 32 | contenido del header |
| `sizeTopBar` | 48 | barra superior |
| `sizeStatusBar` | 32 | barra de estado |
| `sizeRow` | 64 | fila de tabla y tile de cola (dos líneas) |
| `sizeHeaderAction` | 32 | hit target de icono de header |
| `sizeSidebar` | 256 | ancho del sidebar |
| `sizeTileSidebar` | 32 | logo del sidebar |
| `sizeTileView` | 40 | tile de cabecera de vista |
| `sizeTileEmpty` | 48 | tile de estado vacío |
| `sizeProgress` | 3 | barra de progreso de la cola |
| `sizeConsole` | 220 | alto de la consola de Ajustes |
| `sizeDialogW` | 520 | ancho del diálogo de cookies |
| `sizeDialogH` | 300 | alto del diálogo de cookies |
| `sizeStatusDot` | 8 | punto de estado (exterior) |
| `sizeStatusDotInner` | 4 | punto de estado (interior) |

> Los tamaños son de **caja**, no de texto. Un alto fijo (40/64) asume
> contenido de una o dos líneas: el copy de UI debe caber; los datos de
> usuario se truncan con ellipsis + tooltip (ver §4.1). Si el contenido
> necesita otra altura, no se estira el token: se usa un contenedor
> flexible y se documenta.

### 2.3 Radios

| Token | Valor | Elemento |
|---|---:|---|
| `radiusCard` | 12 | card, tile, diálogo |
| `radiusControl` | 8 | input, botón, ítem de sidebar, portada |
| `radiusSmall` | 4 | badge |
| `radiusScrollbar` | 8 | thumb |

El tooltip usa radio 6 y el diálogo 12; ambos se fijan en el tema, no en
la vista.

### 2.4 Iconos

| Token | Valor | Elemento |
|---|---:|---|
| `iconButton` | 16 | icono dentro de botón |
| `iconHeaderAction` | 16 | acciones del header de card |
| `iconInline` | 16 | icono de banner/aviso |
| `iconTileSidebar` | 18 | logo y plataformas del sidebar |
| `iconTileView` | 20 | tile de cabecera de vista |
| `iconTileEmpty` | 24 | tile de vacío |

### 2.5 Tipografía (`AppText`)

| Nivel | Tamaño | Peso | Uso |
|---|---:|---:|---|
| `hero` | 20 | 700 | título de vista (uno por vista) |
| `brand` | 14 | 800 · ls 1.0 | wordmark `NOVA HUB` (logotipo, no texto de UI) |
| `title` | 14 | 600 | canción, ítem, título de panel |
| `body` | 14 | 400 | texto funcional, instrucciones, álbum, label de botón |
| `input` | 14 | 400 | texto del campo |
| `secondary` | 12 | 400 | artista, subtítulo, mensaje, hint |
| `caps` | 12 | 600 · ls 0.5 | headers de card, labels de sección, badges |
| `caption` | 12 | 400 | subtítulo denso del sidebar, status bar |
| `mono` | 12 | 400 · Consolas | consola y cookies |

Reglas:

- No existe el 16 en la escala. El label flotante de un input no puede
  introducirlo: o se usa `body`/`secondary`, o se saca el label fuera del
  campo (como en cookies).
- No se crean tamaños con `copyWith(fontSize:)`. Si falta un nivel, se
  añade a `AppText` y se documenta aquí.
- `title` para títulos, no `body.copyWith(fontSize: 14)`.
- Label de botón = `body` 14/w500; se fija en el tema, no por instancia.
- El título de diálogo lo pone `dialogTheme` (20/w600); no usar `hero`.
- El status bar y los subtítulos densos usan `caption` (12), no 11.
- `height` siempre explícito en el nivel (nunca heredado de M3).

### 2.6 Color

| Rol | Token |
|---|---|
| Texto principal | `fg` |
| Títulos y énfasis | `white` |
| Texto secundario / hints | `fgMid` |
| Texto deshabilitado / placeholders grandes | `fgDim` (excepción controlada) |
| Acento azul (texto e icono) | `blueText` |
| Acento rojo (texto) | `redText` |
| Acento verde (texto) | `greenText` |
| Fondo primario azul | `buttonBlue` + texto `darker` |
| Fondo primario de marca | `buttonRed` + texto `darker` |
| Hover de card/ítem | `cardHover` |
| Tonos base (`blue`, `red`, `green`, `yellow`) | solo fondos, bordes e iconos decorativos |

Prohibido: `Colors.white`, `Colors.black`, `Color(0xFF…)` en vistas.
`Colors.transparent` sí se permite. Todo texto con acento usa variantes
`*Text` (AA); los tonos base no se usan como color de texto.

**Excepción documentada (E7).** El warning de la consola usa `yellow`
base como texto porque la paleta cerrada no tiene `yellowText`; el
contraste es ~5.1:1 y pasa AA. Si se aprueba `yellowText`, se migra ese
único punto y se elimina la excepción.

#### Alta de color (requiere aprobación)

La paleta es cerrada. Un agente **no** añade colores a `OneDarkPro` por su
cuenta —ni en el tema ni en la vista— ni aproxima un tono nuevo con
`Opacity` o `withValues`.

Si hace falta un color o un alpha que no existe:

1. **Detente y pregunta antes de escribir código.**
2. Presenta: rol (texto/fondo/borde/icono), hex propuesto, dónde se usa y
   contraste calculado sobre `background`, `sidebar`, `card` y `darker`.
3. Propón primero la alternativa con la paleta actual.
4. Solo con aprobación explícita se añade a `OneDarkPro`, con nombre de rol
   y el ratio en el comentario.
5. Actualiza esta tabla y el ADR (sección 10).

Variantes alfa aprobadas (siempre sobre un token de la paleta):

| Alpha | Uso |
|---:|---|
| 0.10 | fondo del banner de error (`red`) |
| 0.12 | fondo de “en cola” / highlight (`blue`, `blueText`) |
| 0.15 | fondo de tile decorativo (`blue`) |
| 0.22 | anillo de foco (`blueText`) |
| 0.40 | borde de marca / error (`blue`, `red`) |
| 0.45 | borde de ítem activo / punto de estado (`blue`) |
| 0.55 | icono deshabilitado (`fgDim`) |

Cualquier otro alpha se pregunta igual que un color nuevo.

### 2.7 Responsive

Se mide el **ancho de contenido** (después del sidebar y del padding), no
el de la ventana. Usar `LayoutBuilder`, no `MediaQuery.size`.

| Token | Valor | Efecto |
|---|---:|---|
| `stackBelow` | 820 | por debajo, la cola se apila bajo la tabla |
| `queueWideFrom` | 1000 | desde aquí la cola mide 360 |
| `queueNarrow` | 320 | cola entre 820 y 1000 |
| `queueWide` | 360 | cola desde 1000 |

Al apilar, la tabla y la cola se reparten con `Expanded(flex: 1)` y
`Expanded(flex: 1)`; nunca una cola de alto fijo que ahogue la tabla. El
reparto 3:2 se probó a 1100×630 y desbordaba el vacío de la cola; 1:1
deja 168 lógicos para cada panel, suficiente para el vacío compacto.
Por encima de 820 el peor caso es tabla ≈ 484 y cola 320: con `CANCIÓN` y
acción 128 la tabla sigue siendo legible.

Columnas de tabla: portada 40 + gap 12, duración 72, acción 128; título y
álbum a flex igual. Nunca anchos fijos que sumen más que el contenedor.

Orden de defensa antes de añadir un breakpoint:

1. Acortar el label (`TÍTULO / ARTISTA` → `CANCIÓN`).
2. Recortar columna de acción a 128.
3. Ajustar el ancho de la cola (320/360).
4. Apilar (820) con reparto 1:1.
5. Solo entonces, breakpoint nuevo (y se añade a `UiTokens`).

---

## 3. Recetario

Copiar estas estructuras. Si una vista necesita algo distinto, se cambia
el recetario y se aplica a todas; no se hace solo en una vista.

### 3.1 Página

```dart
Padding(
  padding: UiTokens.paddingPage,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [/* header, controles, contenido */],
  ),
)
```

- Si el contenido no cabe: `SingleChildScrollView` + `padding: UiTokens.paddingPage`
  (el último bloque no queda pegado).
- El scroll es una propiedad del contenido, no de la vista: Spotify no
  scrollea porque cabe; Ajustes sí porque es largo.

### 3.2 Cabecera de vista

```dart
Row(
  children: [
    Container(
      width: UiTokens.sizeTileView,
      height: UiTokens.sizeTileView,
      decoration: BoxDecoration(
        color: OneDarkPro.blue.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
      ),
      child: Icon(Icons.x, color: OneDarkPro.blueText, size: UiTokens.iconTileView),
    ),
    const SizedBox(width: UiTokens.spaceHeaderGap),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Título', style: AppText.hero),
          Text('Subtítulo', style: AppText.secondary),
        ],
      ),
    ),
  ],
)
```

- Icono del tile: `blueText` (no `blue`), sin borde.
- Subtítulo: `secondary` (12). Gap tile ↔ texto: 12.
- El título de vista es 20/w700; no se trunca (el copy debe caber).

### 3.3 Card con header

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(UiTokens.radiusCard),
  child: Container(
    decoration: BoxDecoration(
      color: OneDarkPro.sidebar,
      borderRadius: BorderRadius.circular(UiTokens.radiusCard),
      border: Border.all(color: OneDarkPro.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: UiTokens.sizeCardHeader,
          padding: UiTokens.paddingCardHeader,
          decoration: const BoxDecoration(
            color: OneDarkPro.darker,
            border: Border(bottom: BorderSide(color: OneDarkPro.border)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'TÍTULO',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caps,
                ),
              ),
              // acciones: icono 16, hit 32, gap 4
            ],
          ),
        ),
        Padding(padding: UiTokens.paddingCard, child: /* cuerpo */),
      ],
    ),
  ),
)
```

- Header siempre 40: padding 16/4 y contenido de 32 (título caps 12 +
  acciones de 32). **Derecha 16**, izquierda 16.
- Título con `maxLines: 1` + ellipsis (red de seguridad; el copy debe caber).
- Acciones con tooltip y color `blueText`; deshabilitadas con `fgDim`.
- El cuerpo de la card usa padding 16.

### 3.4 Label de sección

```dart
Padding(
  padding: UiTokens.paddingSectionLabel, // left 16, top 16, bottom 8
  child: Text('CONFIGURACIÓN', style: AppText.caps),
)
```

- Alineado con el **contenido** de la card (x = 16 dentro de la card).
- El label de sección del sidebar usa `paddingSidebarLabel` (x = 8 + 12,
  alineado con el contenido del ítem), no el de card.
- Mismo tracking que `caps` (0.5); no se sobreescribe.

### 3.5 Fila de control (input + botón)

```dart
Row(
  children: [
    Expanded(
      child: SizedBox(
        height: UiTokens.sizeControl,
        child: TextField(
          style: AppText.input,
          decoration: InputDecoration(
            hintText: 'Busca una canción, artista o álbum…',
            prefixIcon: Icon(Icons.search_rounded, size: UiTokens.iconInline),
            prefixIconConstraints: BoxConstraints(
              minWidth: UiTokens.sizeControl,
              minHeight: UiTokens.sizeControl,
            ),
          ),
        ),
      ),
    ),
    const SizedBox(width: UiTokens.spaceControlGap),
    SizedBox(
      height: UiTokens.sizeButton,
      child: ElevatedButton.icon(
        icon: Icon(Icons.search_rounded, size: UiTokens.iconButton),
        label: const Text('Buscar'),
      ),
    ),
  ],
)
```

- Ambas alturas son 40 exactos. Diferencia aceptable: **0 px**.
- El botón hereda del tema: 40, padding 16/10, icono 16, radio 8,
  label `body` 14/w500. No se pasa padding por instancia.
- El `prefixIconConstraints` es obligatorio: sin él, M3 impone 48 al
  icono y el campo deja de medir 40.
- Label completo en una línea, sin truncar; si no cabe, se acorta el copy.

### 3.6 Botones

| Tipo | Fondo | Texto | Borde | Icono | Alto | Padding |
|---|---|---|---|---:|---:|---|
| Primario azul | `buttonBlue` | `darker` | — | 16 | 40 | 16/10 |
| Primario marca | `buttonRed` | `darker` | — | 16 | 40 | 16/10 |
| Outlined | transparente | `fg` | `border` 1 | 16 | 40 | 16/10 |
| Text | transparente | `blueText` | — | 16 | 40 | 12/10 |
| Icono de header | transparente | `blueText` / `fgDim` | — | 16 | hit 32 | 0 |

- Todos: label `body` 14/w500, radio 8, una sola línea (sin truncar).
- Deshabilitado: `disabledBackgroundColor: card`,
  `disabledForegroundColor: fgDim` (tema), nunca `Opacity` sobre texto.
- Los `IconButton` usan `tapTargetSize: shrinkWrap` y `minimumSize: 32`
  desde `iconButtonTheme`; si se omite, M3 los infla a 48 y rompe el header.
- Nada de `fontWeight: w600` puntual.
- Un solo color de texto para primarios: `darker` (no `#000`).

### 3.7 Estado vacío

```dart
Center(
  child: Padding(
    padding: EdgeInsets.all(UiTokens.spaceBlock),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EmptyIconTile(icon: Icons.x),
        const SizedBox(height: UiTokens.spaceEmptyGap),
        Text('Copy', textAlign: TextAlign.center, style: AppText.secondary),
      ],
    ),
  ),
)
```

- Tile 48/radio 12, icono 24 `blueText`, fondo `blue` 15%, gap 12.
- Padding interior 16 (el de la card), no 24: el vacío vive dentro de una
  card; a 1100×630 el de 24 desbordaba la cola.
- **Mismo layout vertical en tabla y cola**: icono arriba, texto abajo.
- Sin `\n` manuales: el wrap lo hace el ancho.
- El copy no usa “una” de forma inconsistente con el hint.

### 3.8 Tabla

- Card 12, borde `border`, header 40 (`paddingCardHeader`).
- Header: celda vacía de portada 40 + gap 12, luego `CANCIÓN`, `ÁLBUM`,
  `DURACIÓN` (72, izquierda) y `ACCIÓN` (128, derecha). El primer label
  arranca a 68 (16 + 40 + 12), alineado con el título de la fila; el hueco
  de la portada es intencional (A1).
- Fila: 64 de alto, `paddingRow` (16/12), divisor 1 `border` con indent 16.
- Portada 40 radio 8; gap 12; título `title` + artista `secondary` con gap
  2; álbum `body`; duración `body`; acción 128.
- Botón de acción natural (≈118) alineado a la derecha; el label
  `Descargar` no se trunca. Chip `En cola` de 40.
- Datos (título, artista, álbum) con `maxLines: 1` + ellipsis + `Tooltip`.
- Vacío: receta 3.7.
- Sin cebreado, sin sombras, sin bordes internos.

### 3.9 Tile de cola

- Header 40: título `caps` truncable, contador en badge propio **no
  truncable**, acciones 16/hit 32, padding 16/4/16/4.
- Tile 64, padding 12/12; título `title`, mensaje `secondary`, gap 2.
- Progreso 3 px **en el borde inferior** del tile (Stack), no en el flujo:
  así el tile conserva 64 con título + mensaje.
- Acción 16/hit 32; reintentar solo en error; quitar siempre.
- Vacío: receta 3.7. Footer (ruta `caption` con ellipsis + tooltip) **solo
  si hay tareas**; en vacío se oculta para no desbordar a 1100×630.
- El contador no se trunca: va en un `Text`/badge separado del título.

### 3.10 Sidebar

- Ancho 256, fondo `sidebar`, borde derecho `border`.
- Marca: tile 32/radio 8 con borde `blue` 40%, icono 18; wordmark `brand`
  (14/w800/ls 1.0), subtítulo `caption`.
- Label de sección: `paddingSidebarLabel` (20/16/20/8), `caps` sin override.
- Ítem: padding exterior 8/2, interior 12/8, radio 8, icono 18, gap 8;
  label de una línea con ellipsis + tooltip si no cabe.
- **Estado activo único**: fondo `card` + borde `blue` 45% +
  `Semantics(selected: true)`. Sin punto indicador aparte.
- Ajustes usa el mismo estado activo cuando está seleccionado (fondo card,
  borde azul 45%, label blanco, icono `blue`) y el mismo ancho exterior de 8
  que los ítems; no se mete en un padding de 12.
- Deshabilitado: color `fgDim` explícito (no `Opacity` sobre texto); badge
  `Pronto` en `caps` sobre `darker` con borde.
- El icono del servicio activo puede ir en `blue` (decorativo); el texto
  del ítem va en `white`/`fgMid`/`fgDim`.

### 3.11 Overlays (pinneados en el tema)

- `tooltipTheme`: fondo `darker`, borde `border`, radio 6, texto `fg` 12.
- `textButtonTheme`: `blueText` (nunca `colorScheme.primary`), 40, 12/10.
- `iconButtonTheme`: hit 32, padding 0, `shrinkWrap`.
- `dialogTheme`: card, radio 12, borde, título 20/w600, contenido 14.
- `snackBarTheme`: card, radio 8, borde, texto 14.
- `scrollbarTheme`: 8 px, thumb `cardHover`, auto-hide.
- `inputDecorationTheme`: fondo `darker`, radio 8, borde 1 `border`, foco
  2 `blueText`, padding 12/10, hint 14, label 12.
- `dividerTheme`: 1 `border`.

Si un widget nuevo trae un default de M3, **primero** se fija en el tema.

---

## 4. Copy

- Sentence case: `Iniciar sesión`, `Guardar cookies`, `Abrir descargas`,
  `Abrir YouTube para iniciar sesión`.
- Tildes siempre: `búsqueda`, `álbum`, `canción`, `duración`, `acción`.
- Puntos suspensivos: `…` (no `...`).
- Un verbo por acción; el botón dice exactamente lo que hace (si solo
  abre el navegador, no se llama “Iniciar sesión”).
- Sin `\n` manuales en textos que pueden envolver.
- El status bar habla de la vista activa: `Listo para buscar` en Spotify;
  `Sesión y ajustes` en Ajustes (los estados de descarga/búsqueda siguen
  siendo globales).
- Un mismo concepto, una misma palabra (`canción`, no `tema`/`pista`).

### 4.1 Texto largo y truncado

Regla de reparto: **el copy de UI se acorta; el dato del usuario se trunca.**

1. **Copy de UI** (botones, headers, labels de campo, errores, vacíos):
   debe caber. No se trunca ni se encoge; si no cabe, se acorta el texto
   o se cambia el layout. El ellipsis en copy de UI es una red de
   seguridad, no una estrategia. Los botones son de una línea (Material
   no permite truncar ni envolver su label).
2. **Datos de usuario/plataforma** en caja fija (canción, artista, álbum,
   archivo, ruta, nombre de plataforma): `maxLines: 1` +
   `overflow: ellipsis` **y** `Tooltip` con el valor completo. Sin tooltip
   no se considera terminado.
3. **Contenedores flexibles** (card, cola, vacío, diálogo): dejar envolver,
   sin `maxLines`. Para overflow grande, “Ver más”.
4. **Nunca** `FittedBox`, `AutoSizeText` ni bajar el `fontSize`. Tampoco
   truncar títulos de página, errores ni validaciones (Carbon).
5. **Alturas fijas**: 40 (control), 64 (fila de dos líneas) y 48 (tile
   vacío) asumen escala 1.0. Si algún día se habilita escalado solo de
   texto, hay que migrar a `minHeight` y probar 200% (WCAG 1.4.4 y F69).

Prueba obligatoria: título/artista de 120 caracteres y plataforma larga →
ellipsis + tooltip, sin overflow. Label de botón largo → o cabe, o se
cambia el copy: **nunca ellipsis**.

---

## 5. Estados y accesibilidad

- `Semantics(selected: true)` en el ítem activo del sidebar (y en Ajustes).
- `liveRegion: true` en errores y en “Buscando”.
- Tooltip obligatorio en todo botón que solo tenga icono.
- Foco visible: borde 2 px `blueText`; no eliminarlo con `focusColor`
  transparente.
- Contraste mínimo 4.5:1 en texto normal y 3:1 en texto grande/iconos.
- Deshabilitado: color explícito; si se usa `Opacity`, mínimo 0.65 y
  nunca sobre texto que deba leerse.
- El estado vacío y el de error no comparten color: vacío azul, error rojo.
- Hit targets: 40 en controles, 32 en iconos de header. 32 cumple el
  mínimo AA de 24 (WCAG 2.5.8); no cumple el AAA de 44, que no se exige.

---

## 6. Prohibiciones (grep antes de terminar)

```bash
rg "fontSize:" lib/views lib/widgets
rg "Color\(0x" lib/views lib/widgets
rg "Colors\.(white|black)" lib
rg "EdgeInsets\.[a-z]+\([0-9]" lib/views lib/widgets
rg "SizedBox\(\s*(width|height):\s*[0-9]" lib/views lib/widgets
rg "letterSpacing:" lib/views lib/widgets
rg "Opacity\(" lib/views lib/widgets
rg "withValues\(alpha:" lib/views lib/widgets   # solo los alpha de §2.6
```

Los aciertos deben ser: token (`UiTokens.*` / `AppText.*`), tema, o una
excepción documentada. Si el grep encuentra un literal nuevo, la tarea no
está terminada.

Prohibido además:

- `SizedBox(height: 40)` **y** `padding` vertical en el mismo botón (el
  alto lo da el tema; el `SizedBox` solo envuelve la fila de control).
- `TextButton` / `Tooltip` / `OutlinedButton.icon` sin tema fijado.
- `MediaQuery.of(context).size` para layout del contenido.
- `maxLines` sin `overflow` en títulos de card.
- `Row` con hijos que pueden desbordar: usar `Expanded`/`Flexible`.
- Datos de usuario en caja fija sin `maxLines` + `overflow` + tooltip.
- Copy de UI que no cabe y se resuelve con ellipsis en vez de acortarlo.
- `FittedBox` / `AutoSizeText` para hacer caber un texto.
- Label de botón que envuelve a dos líneas.
- Sombras, gradientes o colores nuevos sin pasar por `OneDarkPro`.
- Un `IconButton` sin `shrinkWrap` en un header de 40 (M3 lo infla a 48).

---

## 7. Definición de terminado (UI)

1. `flutter analyze --no-pub` limpio.
2. Si cambió layout: sonda temporal de rects/estilos (test) y **borrarla**.
3. Captura real a **1200×660 lógicos** si la pantalla lo permite; si no,
   la ventana se ajusta al área visible y se reporta el tamaño real
   (p. ej. 1148×630 en una pantalla 1536×864 al 125%).
4. Revisar la matriz de paridad: header, fila de control, card, header,
   botones, vacío, sidebar, status bar.
5. Cero literales nuevos (sección 6).
6. Prueba de cadena larga (§4.1): título/artista de 120 caracteres con
   ellipsis + tooltip; label de botón largo que quepa o se acorte (nunca
   ellipsis).
7. `CHANGELOG.md` si el cambio es visible al usuario.
8. Informe de desviaciones: qué no se pudo igualar y por qué.
9. **No** `git add` / `git commit` sin petición explícita.

### Matriz de paridad

| Pieza | Spotify | Ajustes |
|---|---|---|
| Margen de página | 24 | 24 |
| Cabecera | tile 40, icono 20, hero 20, subtítulo 12 | igual |
| Fila de control | input 40 + botón 40, gap 8 | input 40, botón 40 |
| Card | radio 12, header 40, cuerpo 16 | igual |
| Labels de sección | — | contenido de card (x=40) |
| Botones | 40, 14, icono 16, radio 8 | igual |
| Vacío | 48/16/gap 12, vertical | 48/16/gap 12, vertical |
| Sidebar | 256, ítem 12/8, activo card + blue 45% | igual |
| Top bar / status | 48 / 32 | 48 / 32 |
| Tipografía | 20/14/12 | 20/14/12 |

---

## 8. Cómo añadir una vista

1. Leer este documento y `docs/auditoria-consistencia-vistas.md`.
2. Copiar el esqueleto de 3.1 y la cabecera de 3.2.
3. Componer con 3.3–3.10; no crear variantes locales.
4. Si falta una pieza, crearla como token/widget compartido y aplicar el
   cambio a la vista existente en el mismo PR.
5. Pasar la sección 7.
6. Añadir la vista a la matriz de paridad del punto 4.

---

## 9. Deuda y fases

| Fase | Qué | Estado |
|---|---|---|
| 1 | Contrato escrito + `AGENTS.md` | hecho (v1) |
| 2 | `UiTokens` + `AppText` | hecho |
| 3 | Refactor de vistas a tokens y estándar 40/14/64 | hecho (v2) |
| 4 | Widgets compartidos: `ViewHeader`, `CardShell`, `PrimaryButton`, `EmptyState` | pendiente |
| 5 | Test de contrato: falla si aparecen literales o si cambian las métricas | pendiente |

La fase 3 aplicó los hallazgos A–I que tocan tokens y métricas. Quedan
abiertos los que requiere la fase 4 (piezas compartidas) y la excepción
E7 de color. Cualquier código nuevo ya debe usar tokens.

---

## 10. Decisiones (ADR)

| ID | Decisión | Motivo |
|---|---|---|
| 01 | Padding de página 24 | Retícula 4/8 de M3/Carbon/Fluent; reemplaza el 22 histórico. |
| 02 | Header de card a 16 y título de tabla alineado al título | Alinea Ajustes y tabla; la celda de portada vacía hace intencional el hueco (A1). |
| 03 | Controles a 40, label 14, padding 16/10, icono 16, radio 8 | Convergencia M3 40 / Carbon md 40 / Fluent large 40; reemplaza 48. |
| 04 | Vacío 48/16/gap 12, vertical en tabla y cola | Unifica results y cola (C1, C2); reemplaza 52/26. |
| 05 | Escala 20/14/12, sin 16 | Elimina el label de 16 (D1, D5); tres tamaños, nueve roles. |
| 06 | Acento de texto = `*Text`; base solo fondos/iconos | Contraste AA y coherencia (E1–E4). |
| 07 | Un solo estado activo, sin punto; Ajustes también | (F1). |
| 08 | Gap de bloque 16, nunca 18 | Ritmo único (A8). |
| 09 | Cola 320/360, apilar bajo 820 y reparto 1:1 | Evita el acantilado del breakpoint 860 (G1) y el tile fijo que ahogaba la tabla. 1:1 se verificó a 1100×630: 3:2 desbordaba el vacío de la cola. |
| 10 | Tooltip, TextButton, IconButton y botones pinneados | M3 pinta tooltips blancos, TextButton azul base e IconButton de 48 (I1, I2). |
| 11 | Texto de primarios = `darker` | Unifica azul y rojo (B4). |
| 12 | Mono 12 en consola y cookies | Elimina 12/11 (D4). |
| 13 | Copy sentence case + `…` | Coherencia (H1–H4). |
| 14 | Status bar por vista | “Listo para buscar” no aplica en Ajustes (H5). |
| 15 | Subtítulo de vista = `secondary` 12 | Elimina el `copyWith(12)` repetido. |
| 16 | Paleta cerrada: color nuevo requiere aprobación | Evita deriva cromática; el agente pregunta antes de añadir. |
| 17 | Alturas fijas (40/64/48) + copy corto + dato truncado con tooltip | Norma desktop; el copy de UI cabe, el dato de usuario trunca. Si se habilita escalado de texto, migrar a `minHeight` (WCAG 1.4.4/F69). |
| 18 | Estándar 40/14/64: controles 40, cuerpo 14, caption 12, filas de dos líneas 64, header 40, top 48, status 32, sidebar 256 | Adopta la convergencia de las grandes empresas (M3 40, Carbon md 40, Fluent large 40) en lugar de los 48/68/22 locales. Da densidad desktop, targets AA y una escala tipográfica reconocible. Reemplaza ADR 01/03/04/05/17 en sus valores. |
| 19 | Excepción de color: `yellow` base como texto solo en el warning de consola | No hay `yellowText` en la paleta; contraste ~5.1:1. Es el único punto; si se aprueba `yellowText`, se migra y se elimina la excepción (E7). |

---

## 11. Referencias

- **Material 3 — Buttons (guidelines):** el label no se trunca ni se
  envuelve; debe verse completo en una línea.
  <https://m3.material.io/components/buttons/guidelines>
- **Material 3 — Buttons (accessibility):** a 200% el label debe seguir
  siendo conciso y legible.
  <https://m3.material.io/components/buttons/accessibility>
- **Material 3 — Text fields:** alturas y densidad de campos.
  <https://m3.material.io/components/text-fields/guidelines>
- **Carbon — Data table:** alturas de fila fijas (24/32/40/48/64) y
  truncado con tooltip.
  <https://carbondesignsystem.com/components/data-table/usage>
- **Carbon — Overflow content:** truncar solo datos largos; nunca headers,
  títulos, labels, errores ni validaciones.
  <https://carbondesignsystem.com/patterns/overflow-content>
- **Fluent 2 — Button:** controles de altura fija (32 por defecto) y
  labels breves.
  <https://fluent2.microsoft.design/components/web/react/core/button/usage>
- **Fluent 2 — Type ramp:** cuerpo 14 y caption 12 en desktop.
  <https://fluent2.microsoft.design/typography>
- **WCAG 2.2 — 1.4.4 Resize text:** el texto debe escalar al 200% sin
  pérdida de contenido.
  <https://www.w3.org/WAI/WCAG22/Understanding/resize-text>
- **WCAG — F69:** un contenedor de alto fijo que recorta el texto al 200%
  es un fallo.
  <https://www.w3.org/WAI/WCAG21/Techniques/failures/F69>
- **WCAG 2.2 — 2.5.8 Target size (minimum):** 24×24 CSS px como mínimo.
  <https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum>
- **Apple HIG — Typography:** evitar el truncado; permitir más líneas
  antes que recortar.
  <https://developer.apple.com/design/human-interface-guidelines/typography>
