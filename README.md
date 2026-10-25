# Nova Hub Downloader — v0.8 (Windows + Flutter)

Downloader de escritorio para Windows. Módulo actual: **Spotify**
(búsqueda y metadatos vía YouTube Music, réplica del pipeline Python
`NovaHub-Downloader`).

## Qué hace

- Sidebar con plataformas: Spotify activo; YouTube Music, SoundCloud y
  Deezer como "Pronto".
- Buscador con tabla de resultados (portada, título/artista, álbum,
  duración, acción con header fijo) y cola de descargas lateral con
  progreso real, iconos con tooltip y ruta destino cuando hay descargas.
- Barra de estado persistente (32px): refleja búsquedas, cola y avisos
  ("Agregado a la cola") sin popups.
- Ventana con tamaño inicial y mínimo según la escala del display
  (100/125/150/200%), recortada al área visible y centrada
  (`window_manager` + `screen_retriever`).
- Tema One Dark Pro con azul `#5F7EA6` como color primario; verde,
  amarillo y rojo solo para estados de descarga y errores. Rampa de
  texto AA (`fgMid`, variantes `*Text`, botón `#7FA3CC` con texto
  oscuro): secundarios y etiquetas ≥5.3:1 en los tres fondos.
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
   `player_client=android` ante 403. Anti-bot opcional desde Ajustes:
   cookies pegadas (solo necesarias, cifradas) con cadena
   guardadas → plano y registro del último uso. Reintento progresivo: 3 intentos con esperas de
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
- Developer Mode de Windows activado (lo exigen los plugins nativos
  al compilar: `cached_network_image`, `path_provider`, etc.).
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
  theme/one_dark_pro.dart         # paleta + tema M3 + escala AppText
  theme/ui_tokens.dart            # espacio, tamaño, radio y breakpoints
  config/app_config.dart          # tiempos, topes y calidades centrales
  models/track.dart               # pista + copyWith + safeFileName
  models/download_task.dart       # tarea de cola + estados
  services/music_search_service.dart # búsqueda + estado global
  services/ytmusic_service.dart   # réplica ytmusicapi (search/continuations/player)
  services/downloader_service.dart# cola + reintentos + etiquetado + avisos
  services/yt_dlp_engine.dart   # motor yt-dlp reutilizable (audio/JSON/procesos)
  services/app_log.dart           # bitácora de sesión ([Fuente] HH:MM:SS)
  services/audio_tagger.dart      # ID3v2.3 (equivale a mutagen)
  services/auth_store.dart        # cookies cifradas + vigencia (sin archivos)
  services/binaries.dart          # localiza yt-dlp/ffmpeg
  widgets/sidebar.dart
  widgets/results_table.dart      # header fijo + scroll + pill "En cola";
                                  # acción solo en botón Descargar (sin clic en fila)
  widgets/download_queue_panel.dart # cola de descargas + ruta si hay tareas
  widgets/empty_icon_tile.dart    # tile azul para estados vacíos
  widgets/status_bar.dart         # barra de estado 32px + avisos
  views/spotify_view.dart
  views/settings_view.dart        # ajustes: auth, consola, configuración
tool/
  ytm_check.dart   # verifica búsqueda YTM en vivo
  ytm_shape.dart   # diagnóstico de formas de respuesta YTM
  tag_check.dart   # verifica etiquetado ID3 en un MP3 real
  emoji_check.dart # verifica safeFileName (ilegales y emojis)
  engine_check.dart # verifica motor yt-dlp reutilizable
docs/
  reglas-ui.md                    # contrato visual 40/14/64
  auditoria-consistencia-vistas.md # pendientes y excepciones de UI
  AUDITORIA_BETA.md               # auditoría pre-beta (producto)
windows/runner/   # título nativo "Nova Hub Downloader"
```

## Sistema visual

Paleta One Dark Pro en 19 colores (`lib/theme/one_dark_pro.dart`):
13 base (6 fondos/grises + blanco, primario azul `#5F7EA6`,
verde/amarillo/rojo de estados) + rampa de texto AA: `fgMid`
`#9AA0AB` para secundarios y etiquetas, variantes `greenText` /
`blueText` / `redText` para texto en color, botón primario
`#7FA3CC` con texto oscuro (6.4:1) y botón de marca `buttonRed`
`#AB646A` con texto negro (4.8:1). Sin colores por plataforma.

Escala tipográfica única (`AppText`, 9 estilos, familia Segoe UI):

| Nivel | Uso |
|---|---|
| `hero` 20/w700 | título principal de vista |
| `brand` 14/w800 | wordmark de la marca |
| `title` 14/w600 | canciones, ítems, títulos de panel |
| `body` / `input` 14 | texto funcional y campo de búsqueda |
| `secondary` / `caption` 12 | artistas, pistas, mensajes, status |
| `caps` 12/w600 + tracking | headers, badges, secciones |
| `mono` 12 | consola y visor de cookies |

Controles a 40, headers de card a 40, filas/tiles a 64, top bar 48,
status bar 32 y sidebar 256. Cola de 320/360; layout responsive con
apilado bajo 820px de contenido y reparto 1:1.

Accesibilidad (desktop): foco por teclado, `Semantics` con live
regions en errores y progreso, iconos decorativos excluidos del árbol,
tooltips en botones icon-only. Errores de búsqueda y guardado con botón
Reintentar, foco automático y mensaje inline persistente. Los pendientes
de hover/focus y contraste sobre `cardHover` están en
`docs/auditoria-consistencia-vistas.md`.

## Notas

- La cola de descargas vive solo en memoria: al cerrar la app se pierde
  (limitación conocida, sin persistencia en beta).
- Selector de carpeta destino pendiente.
- Ver `CHANGELOG.md` para el historial.
