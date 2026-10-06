# Auditoría de código — Nova Hub Downloader v0.4

Fecha: 2026-10-06. Ejes: arquitectura y optimización.

## Arquitectura

### 1. `SpotifyService` mezcla tres fuentes + estado de UI
Búsqueda Spotify API (muerta: sin UI de credenciales), YouTube Music,
fallback ytsearch y encima estado para la status bar (`isSearching`,
contadores). Cambiar una fuente toca todo.

**Solución propuesta:** interfaz `SearchProvider` con implementaciones
`YouTubeMusicProvider` (y `SpotifyProvider` si reviven las keys), más
un `SearchState` aparte para lo que muestra la UI.

### 2. `DownloaderService` (~560 líneas) hace de todo
Cola, procesos, progreso, tagging, avisos y carpeta en una sola clase.
Funciona, pero no se puede testear por partes.

**Solución propuesta:** extraer `YtDlpEngine` (solo lanzar/matar
procesos y parsear progreso) y dejar al servicio la cola y el estado.

### 3. Código muerto embarcado
`_accessToken`, `_fromJson`, `setCredentials` y todo el path de
Spotify API nunca se ejecutan. Peso y confusión.

**Solución propuesta:** revivirlo con UI de keys o borrarlo. No dejar
un tercer camino.

### 4. `catch (_) {}` en ~20 sitios sin diagnóstico
La resiliencia está bien, pero en campo un fallo no deja rastro.

**Solución propuesta:** `debugPrint` con contexto como mínimo; ideal,
log rotativo a archivo en beta para reportes de usuario.

### 5. Números mágicos regados
Timeouts (25/20/30/12/8/5s), `searchLimit=15`, `maxAttempts=3`,
backoffs y `audioQuality='0'` repartidos por servicios.

**Solución propuesta:** clase `AppConfig` central con esos valores.

## Optimización

### 6. Cada tick de progreso reconstruye la vista de búsqueda
`SpotifyView` observa `DownloaderService` y yt-dlp emite % varias
veces por segundo: rebuild de tabla + 15 imágenes por tick. Único
punto que aplicaría ya.

**Solución propuesta:** `Selector` limitado a `queuedIds` en la vista,
o separar el consumer de la tabla del de la cola.

### 7. El panel de cola reconstruye todos los tiles por tick
Barato hoy, pero no escala.

**Solución propuesta:** `Selector` por tarea (cada tile escucha solo
su `DownloadTask`).

### 8. Enriquecimiento: ~30 procesos con 15 filas (path fallback)
Cada `dump-json` cuesta ~4.6s por arranque de proceso en Windows;
en paralelo queda en ~6-8s totales. Es el techo de la búsqueda.

**Solución propuesta:** nada por ahora; si duele, cachear metadatos
por `videoId` en memoria/sesion.

### 9. Imágenes sin caché en disco
`Image.network` recarga miniaturas en cada arranque.

**Solución propuesta:** `cached_network_image` para persistirlas
(menos red, scroll instantáneo en sesiones repetidas).

### 10. Regex por chunk + notify por %
Corre en el UI isolate a ~10 chunks/s: despreciable.

**Solución propuesta:** no tocar.
