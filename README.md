# Nova Hub Downloader — v0.5 (Windows + Flutter)

Downloader de escritorio para Windows. Módulo actual: **Spotify**
(búsqueda y metadatos vía YouTube Music, réplica del pipeline Python
`NovaHub-Downloader`).

## Qué hace

- Sidebar con plataformas: Spotify activo; YouTube Music, SoundCloud y
  Deezer como "Próximamente".
- Buscador con tabla de resultados (portada, título/artista, álbum,
  duración, acción con header fijo) y cola de descargas lateral con
  progreso real, iconos con tooltip y ruta destino como pie.
- Barra de estado persistente: refleja búsquedas, cola y avisos
  ("Agregado a la cola") sin popups.
- Tema One Dark Pro con azul `#5F7EA6` como color primario; verde,
  amarillo y rojo solo para estados de descarga y errores.
- Destino: carpeta Descargas de Windows (`%USERPROFILE%\Downloads`),
  archivos `Artista - Título.mp3`.

## Pipeline híbrido (réplica de `downloaders/spotify.py`)

1. **Metadatos** (`lib/services/ytmusic_service.dart`): POST directo a
   `youtubei/v1/search` con el cálculo exacto de `ytmusicapi 1.11.5`
   (`get_search_params` filtro songs, versión de cliente dinámica
   `1.YYYYMMDD.01.00`, contexto con `user: {}`). Solo estante
   "Canciones" + `musicShelfContinuation` hasta 15. Parseo equivalente a
   `parse_song_runs`: artistas por `browseEndpoint` UC, álbum por MPRE,
   duración por regex; duraciones ausentes se rellenan vía `player`.
2. **Audio** (`lib/services/downloader_service.dart`): `yt-dlp` con
   `format bestaudio/best`, `-x --audio-format mp3 --audio-quality 0`
   (VBR ~320kbps), `--no-warnings`, reintento con
   `player_client=android` ante 403. Sin `cookies.txt` (pendiente otro
   enfoque anti-bot). Reintento progresivo: 3 intentos con esperas de
   5s/15s; quitar una descarga activa mata yt-dlp + ffmpeg y limpia
   parciales (en fallo se conservan para reanudar).
3. **Etiquetado** (`lib/services/audio_tagger.dart`): ID3v2.3 propio
   (TIT2/TPE1/TALB/APIC, UTF-16) equivale a `mutagen` (ellos usan
   `encoding=3`; aquí UTF-16 por compatibilidad con Explorer/WMP).
   Cadena de carátula: player HD → thumb YTM (forzado `=w1080-h1080`)
   → `maxresdefault` → respaldo; WebP depriorizado. Reserva con ffmpeg.
4. **Binarios** (`lib/services/binaries.dart`): resuelve `yt-dlp`/`ffmpeg`
   por ruta absoluta (PATH, paquetes winget, rutas comunes) sin depender
   del PATH heredado por el proceso.

## Requisitos

- Flutter stable + Visual Studio Build Tools 2022 con workload
  `Desktop development with C++` (MSVC v142, CMake, Windows 10 SDK).
- `winget install yt-dlp.yt-dlp` y `winget install Gyan.FFmpeg`
  (Node.js existente se usa solo para retos JS de yt-dlp).

## Ejecutar / compilar

```powershell
cd desktop_novadh_app
flutter pub get
flutter run -d windows      # debug con hot-reload
flutter build windows --debug   # exe en build\windows\x64\runner\Debug\
```

## Estructura

```
lib/
  main.dart
  app.dart                        # shell: sidebar + vista + status bar
  theme/one_dark_pro.dart         # paleta + primario azul #5F7EA6
  models/track.dart               # pista + copyWith + safeFileName
  models/download_task.dart       # tarea de cola + estados
  services/spotify_service.dart   # orquesta busqueda + estado global
  services/ytmusic_service.dart   # replica ytmusicapi (search/continuations/player)
  services/downloader_service.dart# cola + yt-dlp + etiquetado + avisos
  services/audio_tagger.dart      # ID3v2.3 (equivale a mutagen)
  services/binaries.dart          # localiza yt-dlp/ffmpeg
  widgets/sidebar.dart
  widgets/results_table.dart      # header fijo + scroll + hover + pill
  widgets/download_queue_panel.dart
  widgets/status_bar.dart
  views/spotify_view.dart
tool/
  ytm_check.dart   # verifica busqueda YTM en vivo
  ytm_shape.dart   # diagnostico de formas de respuesta YTM
  tag_check.dart   # verifica etiquetado ID3 en un MP3 real
  emoji_check.dart # verifica safeFileName (ilegales y emojis)
docs/
  AUDITORIA_BETA.md    # auditoria pre-beta (producto)
  AUDITORIA_CODIGO.md  # auditoria de arquitectura y optimizacion
windows/runner/   # titulo nativo "Nova Hub Downloader"
```

## Sistema visual

Paleta One Dark Pro recortada a 13 colores
(`lib/theme/one_dark_pro.dart`): 6 fondos/grises + blanco, primario
azul `#5F7EA6`, y verde/amarillo/rojo solo para estados de descarga
y errores. Sin colores por plataforma.

Escala tipográfica única (`AppText`, misma familia base):

| Nivel | Uso |
|---|---|
| `hero` 18/w800 | título principal de vista |
| `title` 13.5/w600 | canciones, items, títulos de panel |
| `body` 12 | texto funcional (botones, álbumes) |
| `secondary` 12.5 | artistas, hints, mensajes |
| `caps` 11/w700 + tracking | headers, badges, secciones |
| `input` 14 | campo de búsqueda |

## Notas

- La cola de descargas vive solo en memoria: al cerrar la app se pierde
  (limitación conocida, sin persistencia en beta).
- Ventana maximizada con tamaño mínimo requiere plugin + Developer
  Mode de Windows (pendiente).
- Selector de carpeta destino pendiente (diseño en discusión).
- Ver `CHANGELOG.md` para el historial.
