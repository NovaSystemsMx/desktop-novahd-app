# Auditoría de consistencia visual — pendientes y excepciones

Fecha: 2026-11-17 · App: Nova Hub Downloader v0.9.1 (Windows/Flutter)
Contrato vigente: 40/14/64 (`docs/reglas-ui.md`)

> Documento reducido: los hallazgos A–I ya aplicados se eliminaron.
> Aquí solo queda lo que falta verificar y las excepciones aceptadas.

---

## Pendiente

### P1 — Estados hover/focus sin verificar

- Hover resuelto y verificado con captura real: fila de tabla (relleno
  `card`), ítem del sidebar (`cardHover`, también el activo) y botones
  (primarios aclaran con `white` 15 %; outlined/text/icono rellenan
  `cardHover`), todos animados con `motionHover`. El overlay derivado por
  M3 al 8 % no se percibía sobre rellenos sólidos.
- Pendiente: foco visible por teclado y estado pressed en botones. No se
  sobrescriben: usan `highlightColor` y `focusColor` del tema; falta
  confirmarlos con captura.
- No introducir tonos ni alphas fuera de la paleta aprobada.
- Archivos: `lib/theme/one_dark_pro.dart`, `lib/widgets/sidebar.dart`,
  `lib/widgets/results_table.dart`.

### P2 — Contraste sobre `cardHover`

- Ya hay usos reales; medidos: `fgMid` sobre `cardHover` = 4.49:1 (**no**
  pasa AA), `fg` sobre `cardHover` = 5.53:1 y `fgMid` sobre `card` =
  4.96:1.
- Consecuencia aplicada: el hover de fila usa `card` (no `cardHover`) y el
  subtítulo del sidebar sube a `fg` durante el hover.
- Pendiente: medir cualquier combo nuevo antes de usarlo; AA 4.5:1 para
  texto y 3:1 para límites e iconos.
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

### E8 — El aviso `En cola` mide como el botón `Descargar`

- La acción de la tabla reserva `colAction` × `sizeControl` (128 × 40) en
  ambos estados, con el contenido centrado.
- Excepción al tamaño natural del chip: evita el salto de ancho/alto al
  encolar una pista. Decisión de producto pedida explícitamente.
- Archivos: `lib/widgets/results_table.dart`, `docs/reglas-ui.md` §3.8.

### E9 — La ruta de descargas se muestra con la cola vacía

- El footer de la cola (divider + ruta `caption` con ellipsis y tooltip) se
  pinta siempre, también sin tareas: da contexto del destino antes de
  descargar.
- Excepción a ocultar el footer en vacío; la ruta se trunca y no empuja el
  alto del panel.
- Con el footer fijo, el vacío de la cola va sin inset vertical y con
  scroll de seguridad: no desborda ni por debajo del mínimo (probado a
  1100×630).
- Archivos: `lib/widgets/download_queue_panel.dart`, `docs/reglas-ui.md`
  §3.9.

### E10 — Mínimo de ventana plano de 1152×640

- Se sustituye el mínimo por escala (1100/1120/1200) por uno solo:
  1152×640 lógicos. Descontado el marco de Windows, el contenido mínimo
  queda en ~833 > `stackBelow` (820), así que la cola siempre se ve al
  lado de la tabla.
- Efecto buscado: la vista no cambia de forma al redimensionar; el
  apilado queda como red de seguridad y no se alcanza en uso normal.
- Coste aceptado: en pantallas con área lógica menor que 1152 de ancho
  (p. ej. 1366×768 a 125%) la ventana ya no cabe entera; antes se apilaba.
- Archivos: `lib/main.dart`, `docs/reglas-ui.md` §2.7.
