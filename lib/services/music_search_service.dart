import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../models/track.dart';
import 'app_log.dart';
import 'binaries.dart';
import 'ytmusic_service.dart';

/// Servicio de búsqueda de música (sin Spotify API).
///
/// Fuente principal: YouTube Music, réplica de
/// `YTMusic().search(filter="songs", limit=15)`. Reserva: búsqueda
/// plana con yt-dlp. También expone el estado para la barra global.
class MusicSearchService extends ChangeNotifier {
  /// Estado de búsqueda para la barra de estado global.
  bool isSearching = false;
  bool hasSearched = false;
  String lastQuery = '';
  int lastResultCount = 0;
  String? lastSearchError;

  /// Búsqueda completa en una sola fase: filas con álbum, duración y
  /// carátula HD antes de pintar (como el pipeline Python: la tabla se
  /// pinta una vez con toda la data). Las carátulas se cargan por fila
  /// en paralelo vía Image.network, igual que los CoverLoaderThread.
  Future<List<Track>> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    isSearching = true;
    lastQuery = q;
    lastSearchError = null;
    notifyListeners();
    try {
      final results = await _searchInner(q);
      lastResultCount = results.length;
      hasSearched = true;
      return results;
    } catch (e) {
      lastSearchError = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    } finally {
      isSearching = false;
      notifyListeners();
    }
  }

  Future<List<Track>> _searchInner(String q) async {
    // Réplica de YTMusic().search(filter="songs", limit=15):
    // filas nativas con álbum y duración (sin enriquecimiento extra).
    // Solo si falla, reserva con ytsearch (con enriquecimiento).
    try {
      final songs = await YouTubeMusicService().searchSongs(q);
      if (songs.isNotEmpty) return songs;
    } catch (e) {
      AppLog.instance.info('Busqueda', 'YTM fallo, usando reserva: $e');
    }
    final flat = await youtubeSearch(q);
    return YouTubeMusicService().enrichTracks(flat);
  }

  /// Completa álbum, duración y carátula HD de [tracks] en paralelo.
  /// Lo que falle conserva el dato base. Para pintar rápido y completar
  /// después sin bloquear la lista.
  Future<List<Track>> enrichTracks(List<Track> tracks) =>
      YouTubeMusicService().enrichTracks(tracks);

  /// Búsqueda real con yt-dlp, sin necesidad de API keys.
  /// Usa `--flat-playlist` (rápido, sin extraer cada video) y construye
  /// las carátulas con el CDN de YouTube (`maxresdefault` = máx. calidad).
  Future<List<Track>> youtubeSearch(String query) async {
    final ytDlp = await Binaries.ytDlp();
    if (ytDlp == null) {
      throw Exception(
          'No se encontró yt-dlp. Reinstala con: winget install yt-dlp.yt-dlp');
    }
    final res = await Process.run(ytDlp, [
      '--flat-playlist',
      '--dump-json',
      '--no-download',
      '--no-playlist',
      'ytsearch15:$query',
    ]).timeout(
      AppConfig.flatSearchTimeout,
      onTimeout: () => throw Exception(
          'La búsqueda tardó demasiado. Revisa tu conexión e inténtalo de nuevo.'),
    );
    if (res.exitCode != 0) {
      throw Exception('La busqueda fallo. Revisa tu conexion.');
    }
    final tracks = <Track>[];
    for (final line in (res.stdout as String).split('\n')) {
      final t = line.trim();
      if (!t.startsWith('{')) continue;
      try {
        final j = jsonDecode(t) as Map<String, dynamic>;
        final id = (j['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final title = (j['title'] ?? 'Sin título').toString();
        final uploader = (j['uploader'] ?? j['channel'] ?? 'YouTube').toString();
        final durationSec = (j['duration'] as num?)?.toDouble() ?? 0;
        // Carátula: mejor thumbnail del resultado (hasta 720p+),
        // con fallback al CDN por convención.
        String small = 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
        String large = 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
        final thumbs = j['thumbnails'];
        if (thumbs is List && thumbs.isNotEmpty) {
          final urls = <String>[];
          var best = '';
          var bestW = -1;
          for (final th in thumbs.whereType<Map>()) {
            final u = (th['url'] ?? '').toString();
            if (u.isEmpty) continue;
            urls.add(u);
            final w = (th['width'] as num?)?.toInt() ?? 0;
            if (w >= bestW) {
              bestW = w;
              best = u;
            }
          }
          if (urls.isNotEmpty) small = urls.first;
          if (best.isNotEmpty) large = best;
        }
        tracks.add(Track(
          id: 'yt_$id',
          title: title,
          artists: [uploader],
          album: 'YouTube',
          durationMs: (durationSec * 1000).toInt(),
          imageSmall: small,
          imageLarge: large,
          spotifyUrl: '',
          youtubeUrl: 'https://www.youtube.com/watch?v=$id',
        ));
      } catch (_) {
        // Ignora líneas que no sean JSON válido.
      }
    }
    if (tracks.isEmpty) {
      throw Exception('Sin resultados para "$query". Prueba con otro texto.');
    }
    return tracks;
  }
}
