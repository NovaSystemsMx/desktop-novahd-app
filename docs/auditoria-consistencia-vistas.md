# Auditoría de consistencia visual — pendientes y excepciones

Fecha: 2026-11-23 · App: Nova Hub Downloader v0.9.1 (Windows/Flutter)
Contrato vigente: 40/14/64 (`docs/reglas-ui.md`)

> Documento reducido: los hallazgos A–I ya aplicados se eliminaron.
> Aquí queda lo pendiente, el registro de la última verificación (P1) y
> las excepciones aceptadas.

---

## Pendiente

### P2 — Contraste sobre `cardHover`

- Ya hay usos reales; medidos: `fgMid` sobre `cardHover` = 4.49:1 (**no**
  pasa AA), `fg` sobre `cardHover` = 5.53:1 y `fgMid` sobre `card` =
  4.96:1.
- Consecuencia aplicada: el hover de fila usa `card` (no `cardHover`) y el
  subtítulo del sidebar sube a `fg` durante el hover.
- Pendiente: medir cualquier combo nuevo antes de usarlo; AA 4.5:1 para
  texto y 3:1 para límites e iconos.
- Archivo de referencia: `lib/theme/one_dark_pro.dart`.

No queda ningún hallazgo A–I pendiente de aplicación; P2 es una regla de
medición, no deuda de implementación. El primario de marca se retiró en
v0.9.1: `Abrir YouTube` usa el azul del tema.

---

## Verificado

### P1 — Hover, foco y pressed (cerrado)

- Hover: fila de tabla (`card`), ítem del sidebar (`cardHover`, también el
  activo) y botones (primario aclara con `white` 15 %;
  outlined/text/icono rellenan `cardHover`), animados con `motionHover`.
- Foco por teclado: borde de 2 px dentro de la forma (`UiTokens.borderFocus`)
  más cambio de relleno. En fondos oscuros el anillo es `blueText`
  (5.60:1 sobre `cardHover`, 7.30:1 sobre `sidebar`); sobre `buttonBlue`
  cae a 1.24:1, así que el primario usa `darker` (6.38:1) y oscurece
  el relleno para que el anillo no se lea como sombra. El resto de botones
  usan `blueText` 12 %.
- Pressed explícito: primario azul `darker` 10 % (oscurece, distinto del
  hover que aclara); outlined/text/icono `blueText` 12 %, el mismo tinte
  del highlight.
- Verificado con captura real a 1440×800 físicos (ventana de 1152×640
  lógicos): campo de búsqueda, `Buscar`, `Descargar`, icono de la cola,
  ítem del sidebar, Ajustes activo y `Abrir descargas`. El anillo del
  `IconButton` sigue la forma circular de su `StadiumBorder`.
- Archivos: `lib/theme/one_dark_pro.dart`, `lib/widgets/sidebar.dart`,
  `lib/views/settings_view.dart`.

### P3 — Primario de marca (retirado en v0.9.1)

- Existió un primario rojo (`buttonRed`, `onBrand`) para `Abrir YouTube`
  con estados propios que oscurecían el relleno para conservar AA.
- A petición de producto se elimina: el botón usa el `ElevatedButton` del
  tema, igual que `Guardar` — `buttonBlue` con texto `darker` (6.38:1 en
  reposo, ~7.0:1 en hover).
- Se retiran los tokens `buttonRed` y `onBrand` y el helper
  `brandButtonOverlay`; no queda ninguna regla de color de marca en el
  contrato (ADR 11 y 20 actualizados).
- Archivos: `lib/theme/one_dark_pro.dart`, `lib/views/settings_view.dart`,
  `docs/reglas-ui.md` (§2.6, §3.6, ADR 11/20).

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

### E11 — El hover opaco tapa el anillo de foco de outlined/text/icono

- `ButtonStyleButton` construye su `Material` con `borderOnForeground:
  false`; el borde de 2 px se pinta debajo del overlay del `InkWell`. El
  hover de estos botones es `cardHover`, opaco, así que con el puntero
  encima de un botón ya enfocado el anillo desaparece.
- El foco sigue siendo perceptible por el relleno (`blueText` 12 %); con
  navegación solo por teclado (puntero fuera) el anillo se ve completo.
- No se cambia el hover a un tinte translúcido para no introducir alfas
  nuevas ni alterar el hover aprobado en v0.9.1. El primario azul con
  `white` 15 % deja ver el anillo `darker`; los outlined/text/icono son
  los únicos afectados.
- Decisión: diferir el arreglo a Fase 4. Al extraer los botones compartidos,
  pintar el anillo en `foregroundDecoration` (misma técnica que el ítem
  del sidebar), que se dibuja por encima del ink. No requiere alfas nuevas.
- Archivos: `lib/theme/one_dark_pro.dart` (ADR 21).
