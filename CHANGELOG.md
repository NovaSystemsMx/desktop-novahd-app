# CHANGELOG — Nova Hub Downloader

## No publicado

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
