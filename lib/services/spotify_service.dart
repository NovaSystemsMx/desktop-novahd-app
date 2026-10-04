import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/track.dart';
import 'binaries.dart';
import 'ytmusic_service.dart';

/// Servicio de búsqueda.
///
/// - Con credenciales de Spotify: API oficial (carátulas 640px).
/// - Sin credenciales: búsqueda directa con yt-dlp (`ytsearch`),
///   100% funcional sin keys. La carátula es el thumbnail HD de YouTube
///   (`maxresdefault`, hasta 1280px) y se incrusta en el MP3.
class SpotifyService extends ChangeNotifier {
  String _clientId = '';
  String _clientSecret = '';
  String? _token;
  DateTime? _tokenExpiry;

  /// Estado de búsqueda para la barra de estado global.
  bool isSearching = false;
  bool hasSearched = false;
  String lastQuery = '';
  int lastResultCount = 0;
  String? lastSearchError;

  String get clientId => _clientId;
  bool get hasCredentials => _clientId.isNotEmpty && _clientSecret.isNotEmpty;

  void setCredentials(String id, String secret) {
    _clientId = id.trim();
    _clientSecret = secret.trim();
    _token = null;
    _tokenExpiry = null;
    notifyListeners();
  }

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
    if (!hasCredentials) {
      // Réplica de YTMusic().search(filter="songs", limit=15):
      // filas nativas con álbum y duración (sin enriquecimiento extra).
      // Solo si falla, reserva con ytsearch (con enriquecimiento).
      try {
        final songs = await YouTubeMusicService().searchSongs(q);
        if (songs.isNotEmpty) return songs;
      } catch (_) {
        // Cae al fallback de yt-dlp.
      }
      final flat = await youtubeSearch(q);
      return YouTubeMusicService().enrichTracks(flat);
    }
    final token = await _accessToken();
    final uri = Uri.https('api.spotify.com', '/v1/search', {
      'q': q,
      'type': 'track',
      'limit': '20',
      'market': 'ES',
    });
    final res = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
    if (res.statusCode != 200) {
      throw Exception('Spotify respondió ${res.statusCode}: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data['tracks']?['items'] as List?) ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(_fromJson)
        .toList();
  }

  /// Completa álbum, duración y carátula HD de [tracks] en paralelo.
  /// Lo que falle conserva el dato base. Para pintar rápido y completar
  /// después sin bloquear la lista.
  Future<List<Track>> enrichTracks(List<Track> tracks) =>
      YouTubeMusicService().enrichTracks(tracks);

  Future<String> _accessToken() async {
    if (_token != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _token!;
    }
    final basic = base64Encode(utf8.encode('$_clientId:$_clientSecret'));
    final res = await http.post(
      Uri.https('accounts.spotify.com', '/api/token'),
      headers: {
        'Authorization': 'Basic $basic',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {'grant_type': 'client_credentials'},
    );
    if (res.statusCode != 200) {
      throw Exception(
        'No se pudo obtener token de Spotify. Revisa Client ID/Secret.',
      );
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    _token = data['access_token'] as String;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
    _tokenExpiry =
        DateTime.now().add(Duration(seconds: expiresIn - 60));
    return _token!;
  }

  Track _fromJson(Map<String, dynamic> j) {
    final images = (j['album']?['images'] as List?) ?? [];
    // Spotify devuelve imágenes de mayor a menor; la última suele ser 64px,
    // la primera 640px (máxima calidad de carátula vía API).
    String pick(int index, String fallback) {
      if (images.isEmpty) return fallback;
      if (index < images.length) {
        return (images[index]['url'] ?? fallback) as String;
      }
      return (images.first['url'] ?? fallback) as String;
    }
    final artists = ((j['artists'] as List?) ?? [])
        .map((a) => (a['name'] ?? 'Desconocido').toString())
        .toList();
    return Track(
      id: (j['id'] ?? DateTime.now().microsecondsSinceEpoch.toString()).toString(),
      title: (j['name'] ?? 'Sin título').toString(),
      artists: artists.isEmpty ? ['Desconocido'] : artists,
      album: (j['album']?['name'] ?? 'Single').toString(),
      durationMs: (j['duration_ms'] as num?)?.toInt() ?? 0,
      imageSmall: pick(images.length - 1, ''),
      imageLarge: pick(0, ''),
      spotifyUrl: ((j['external_urls']?['spotify']) ?? '').toString(),
    );
  }

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
      const Duration(seconds: 40),
      onTimeout: () => throw Exception(
          'La búsqueda tardó demasiado. Revisa tu conexión e inténtalo de nuevo.'),
    );
    if (res.exitCode != 0) {
      throw Exception('yt-dlp falló en la búsqueda: ${res.stderr}');
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
