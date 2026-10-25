# Auditoría de consistencia visual — pendientes y excepciones

Fecha: 2026-10-25 · App: Nova Hub Downloader v0.9 (Windows/Flutter)
Contrato vigente: 40/14/64 (`docs/reglas-ui.md`)

> Documento reducido: los hallazgos A–I ya aplicados se eliminaron.
> Aquí solo queda lo que falta verificar y las excepciones aceptadas.

---

## Pendiente

### P1 — Estados hover/focus sin verificar

- Botones primarios, outlined, text e icon buttons.
- Ítems del sidebar, incluido Ajustes.
- Comprobar foco visible por teclado, hover y pressed.
- No introducir tonos ni alphas fuera de la paleta aprobada.
- Archivos: `lib/theme/one_dark_pro.dart`, `lib/widgets/sidebar.dart`.

### P2 — Contraste sobre `cardHover` sin medir

- Algunos combos de color no se usan todavía en Spotify ni en Ajustes.
- Medir antes de usarlos: AA 4.5:1 para texto y 3:1 para límites e iconos.
- Archivo de referencia: `lib/theme/one_dark_pro.dart`.

No queda ningún hallazgo A–I pendiente de aplicación.

---

## Excepciones aceptadas

### E7 — `yellow` base como texto en la consola

- El warning de consola usa `OneDarkPro.yellow` como color de texto.
- No existe `yellowText` en la paleta; contraste ~5.1:1, cumple AA.
- Es el único uso permitido de un tono base como texto.
- Documentada en `docs/reglas-ui.md` (ADR 19).

### G3 — Top bar 48 / status bar 32

- Se mantiene la asimetría de chrome: top bar 48, status bar 32.
- El status bar es exclusivo de Spotify; Ajustes solo lleva top bar.
- Es una decisión de producto, no un pendiente.
- Archivos: `lib/app.dart`, `lib/widgets/status_bar.dart`.
