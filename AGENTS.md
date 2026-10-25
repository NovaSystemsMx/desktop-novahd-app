# AGENTS.md — Nova Hub Downloader

App Flutter de escritorio (Windows). Un producto, dos vistas: **Spotify** y **Ajustes**.
El contrato visual completo está en `docs/reglas-ui.md`; esto es el resumen ejecutable.
Estándar vigente: **40/14/64** (M3 40 · Carbon md 40 · Fluent large 40). Ver ADR 18.

## Lectura obligatoria antes de tocar UI

1. `docs/reglas-ui.md` — tokens, recetas, prohibiciones y definición de terminado.
2. `docs/auditoria-consistencia-vistas.md` — deuda abierta con IDs (A1, B2, G1…).
3. La vista hermana: si cambias Spotify, abre Ajustes; y viceversa.

## Reglas duras

1. **Cero valores mágicos.** Color → `OneDarkPro`; tipografía → `AppText`;
   espacio/tamaño/radio/breakpoint → `UiTokens` (`lib/theme/ui_tokens.dart`).
   Nada de `Color(0x…)`, `fontSize:`, `EdgeInsets` con números, ni
   `SizedBox(height/width: <literal>)` en `lib/views` o `lib/widgets`.
2. **Paleta cerrada.** No se añaden colores a `OneDarkPro` ni se usa ningún
   tono fuera de la paleta. Si un diseño necesita un color nuevo —o un alpha
   nuevo— **detente y pregunta antes de escribir código**: rol, hex, dónde se
   usa y contraste sobre `background`/`sidebar`/`card`/`darker`. Solo se
   añade con aprobación explícita, nombre de rol y ratio documentado.
   Prohibido aproximar un tono con `Opacity`, `withValues` o `Colors.*`.
3. **Todo texto visible usa un nivel de `AppText`.** No se inventan tamaños
   con `copyWith(fontSize:)`; si falta un nivel, se añade al tema y se
   documenta en el contrato. Escala: 20/14/12. No existe 16, 13.5 ni 12.5.
4. **Controles a 40.** Input y botón comparten altura exacta y fila.
   Botón: 40, padding 16/10, icono 16, radio 8, label `body` (14/w500),
   `minimumSize: Size(0, 40)`, todo desde el tema. El input necesita
   `prefixIconConstraints` de 40 para no heredar los 48 de M3.
5. **Cards idénticas.** Radio 12, borde `border`, header 40 (padding 16/4,
   contenido 32, `caps`), título `maxLines: 1` + ellipsis (red de seguridad:
   el copy debe caber), acciones de 16 con hit 32. El header arranca a 16
   del borde, también en la tabla.
6. **Vacío idéntico.** Tile 48/radio 12, icono 24 `blueText`, gap 12,
   texto `secondary` centrado, mismo layout vertical en tabla y cola, sin
   `\n` manuales.
7. **Copy corto, dato truncado.** El copy de UI (botones, headers, labels,
   errores) no se trunca: si no cabe, se acorta el texto. Los datos de
   usuario/plataforma (canción, artista, álbum, archivo) en caja fija se
   truncan con `maxLines: 1` + ellipsis + `Tooltip`. Nunca `FittedBox`,
   `AutoSizeText` ni bajar el `fontSize` para encajar.
8. **Un solo estado activo en el sidebar** (fondo `card` + borde `blue` 45%
   + `Semantics(selected: true)`). Ajustes también lo tiene. Sin puntos
   indicadores duplicados.
9. **Acento de texto = `blueText` / `redText` / `greenText`.** Los tonos
   base (`blue`, `red`, `green`, `yellow`) solo para fondos, bordes e
   iconos decorativos. Excepción E7: el warning de consola usa `yellow`
   como texto (no hay `yellowText`; contraste ~5.1:1) y está documentada.
10. **Nada de defaults de M3 en oscuro.** Tooltip, TextButton, IconButton,
    Dialog, SnackBar, Scrollbar, inputs y botones se fijan en el tema. Si un
    widget nuevo trae un default, se pinnea antes de usarlo.
11. **Deshabilitado con color explícito**, no `Opacity` sobre texto.
    Botones: `disabledBackgroundColor: card`, `disabledForegroundColor: fgDim`.
12. **Copy:** sentence case, tildes, `…` (no `...`), sin promesas falsas en
    botones, un término por concepto.
13. **Responsive:** solo `UiTokens.stackBelow` / `queueWideFrom`, y se mide
    el ancho de **contenido** con `LayoutBuilder`. Nada de breakpoints
    ad-hoc ni `MediaQuery.size` para layout. Al apilar: tabla/cola 1:1, no
    una cola de alto fijo.
14. **No `git add` / `git commit`** sin petición explícita del usuario
    (`@commitizen-commits`). Tampoco revertir cambios ajenos.

## Terminado (UI)

- `flutter analyze --no-pub` limpio.
- Si cambió layout: sonda temporal de rects/estilos + captura real a
  1200×660 lógicos si la pantalla lo permite; si no, al tamaño ajustado al
  área visible, reportando el real. La sonda se borra al terminar.
- Paridad revisada contra la otra vista: header, fila de control, cards,
  botones, vacío, sidebar, status bar.
- Cero literales nuevos (grep de la sección 6 del contrato).
- `CHANGELOG.md` si el cambio es visible al usuario.
- Informe de desviaciones: qué no se pudo igualar y por qué.

## Mapa

| Archivo | Qué manda |
|---|---|
| `lib/theme/one_dark_pro.dart` | paleta `OneDarkPro`, tema M3, escala `AppText` |
| `lib/theme/ui_tokens.dart` | espacio, tamaño, radio, icono, breakpoint |
| `lib/app.dart` | shell, top bar, navegación |
| `lib/views/spotify_view.dart` | vista Spotify |
| `lib/views/settings_view.dart` | vista Ajustes |
| `lib/widgets/results_table.dart` | tabla de resultados |
| `lib/widgets/download_queue_panel.dart` | cola de descargas |
| `lib/widgets/sidebar.dart` | navegación lateral |
| `lib/widgets/status_bar.dart` | barra de estado |

## Estado actual

- Fase 3 hecha: las dos vistas usan `UiTokens`/`AppText` y el estándar
  40/14/64. Fase 4 (widgets compartidos `ViewHeader`, `CardShell`,
  `PrimaryButton`, `EmptyState`) y fase 5 (test de contrato) pendientes.
- La consola conserva `yellow` como texto por la excepción E7; no añadir
  más usos.
- No hacer `git add` / `git commit` sin pedido explícito.
