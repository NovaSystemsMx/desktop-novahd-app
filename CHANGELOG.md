# CHANGELOG - Nova Hub Downloader

## v0.8 — Estándar visual 40/14/64

- Adopta la convergencia M3 / Carbon / Fluent: controles, inputs y
  botones a 40; texto 14/12; headers de card a 40; filas/tiles a 64.
- Reemplaza las métricas de v0.7 (48/36/860) por 40/14/64, status bar 32
  y apilado bajo 820 con reparto 1:1.
- Top bar 48, status bar 32, sidebar 256; página 24 y bloque 16.
- Buscador y botón Buscar con altura exacta de 40; foco y estados
  deshabilitados explícitos.
- Vacíos verticales idénticos (tile 48) en tabla y cola; cola 320/360.
- Barra de estado según vista ("Listo para buscar" / "Sesión y ajustes");
  los estados globales de búsqueda y descarga tienen prioridad.
- Copy con `…`, datos largos truncados con tooltip y labels sin recortar.
- Contrato visual v2 en `docs/reglas-ui.md`; auditoría reducida a
  pendientes y excepciones.

## v0.7 — Autenticación anti-bot + accesibilidad UI

- Ajustes con login de YouTube, pegado de cookies (solo necesarias,
  cifradas) y verificación de vigencia con indicador.
- Cadena por descarga: guardadas → plano, con último uso visible.
- Consola de sesión con exportación a novahd-YYYYMMDD.log.
- Requiere Developer Mode (plugins nativos).
- Rampa de texto AA: `fgMid` para secundarios/caps y variantes
  `greenText`/`blueText`/`redText`; botón primario `#7FA3CC`
  con texto oscuro (6.4:1).
- Foco visible por teclado + `Semantics`/live regions en errores,
  progreso de cola y estados; iconos decorativos excluidos.
- Errores de búsqueda y guardado de cookies con Reintentar, foco
  automático y mensaje inline (el veredicto se oculta a los 5s).
- Tabla sin clic en fila (acción solo en Descargar); headers con
  ellipsis; targets de icon-only a 32px.
- Botón Buscar con texto a 48px; tiles azules en estados vacíos;
  badges "Pronto"; status bar 36px con punto-anillo; tildes en copias.
- Ajustes con flujo ordenado (pasos → acción), cards con header
  full-bleed, campo de cookies con label y Paso 3; login en rojo
  de marca con texto negro.
- Ventana con tamaño inicial y mínimo según escala del display
  (100/125/150/200%) vía `window_manager` + `screen_retriever`.
- Cola apilada bajo 860px de contenido en ventanas angostas.

## v0.6 — Arquitectura limpia

- `YtDlpEngine` extraído: motor yt-dlp reutilizable sin UI.
- `MusicSearchService` (antes `SpotifyService`): fuera Spotify API.
- `AppConfig` central: tiempos, topes, backoffs y calidades.
- Rebuild granular: la tabla solo se reconstruye si cambia la cola.
- Miniaturas con `cached_network_image` (requiere Developer Mode).
- `safeFileName` elimina emojis; herramienta `tool/engine_check.dart`.

## v0.5 — Robustez de descarga + escala tipográfica

- Cancelar una descarga activa mata yt-dlp + ffmpeg y limpia parciales.
- Reintento progresivo: 3 intentos con backoff 5s/15s y mensajes humanos.
- Errores de búsqueda/descarga humanizados (sin códigos ni stderr).
- `safeFileName` elimina emojis conservando tildes y CJK (verificado).
- Escala tipográfica `AppText` (6 niveles) aplicada a toda la UI.
- Campo de búsqueda con nivel `input` 14 + limpieza de warnings.

## v0.4 — Sistema de color + headers sincronizados

- Azul `#5F7EA6` como color primario (botones con texto oscuro,
  progreso, foco, logo, bordes activos, avisos).
- Verde/amarillo/rojo solo para estados de descarga y errores.
- Headers de ambas tablas a 41px exactos, mismo fondo y divisor.
- Botón Descargar 44px, pill "En cola" 36px; hover + clic en fila.
- Barra de estado con avisos transitorios (adiós snackbars).
- Contador de cola suelto en gris con punto medio.
- Scroll pegado al borde, thumb 8px, sin riel visible.
- Destino: carpeta Descargas directa (sin subcarpeta).
- Título nativo "Nova Hub Downloader" (ventana + exe).
- Paleta recortada a 13 colores (fuera spotify/purple/cyan/orange).

## v0.3 — UI sincronizada + estado vivo

- Headers de ambas tablas a 41px exactos, mismo fondo y divisor.
- Contador de cola suelto (`COLA DE DESCARGAS • N`), sin paréntesis.
- Pill "En cola" del mismo tamaño que "Descargar" (36px).
- Barra de estado refleja búsqueda, cola y avisos ("Agregado a la cola").
- Sin snackbars; sin menciones de calidad en estados de cola.
- Marca "Nova Hub" (sidebar, barra, ventana nativa, exe) y versión v0.3.
- Tablas vacías a alto completo con leyenda; headers fijos con scroll.
- Destino: carpeta Descargas directa (sin subcarpeta).

## v0.2 — Réplica del pipeline Python

- Búsqueda vía `youtubei/v1/search` idéntica a `ytmusicapi 1.11.5`
  (params, versión dinámica, continuations hasta 15, parseo por runs).
- Álbum y duración nativos en filas; relleno de duraciones vía `player`.
- Descarga `bestaudio/best` a MP3 máxima calidad + reintento android.
- Etiquetado ID3v2.3 propio (título/artista/álbum/caratula HD).
- Resolución de binarios por ruta absoluta; sin `cookies.txt`.
- Cola lateral con progreso real y reintentos.

## v0.1 — Esqueleto

- Sidebar + vista Spotify (buscador, tabla, cola) + tema One Dark Pro.
- Búsqueda mock/API y descarga simulada o vía yt-dlp básica.
