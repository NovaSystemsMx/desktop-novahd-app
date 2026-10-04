import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/track.dart';
import 'binaries.dart';

/// Metadatos vía API interna de YouTube Music (equivale a `ytmusicapi`).
///
/// Busca como el filtro "Canciones": devuelve pistas de estudio
/// (título, artista, álbum, carátula HD e ID de video), evitando videoclips.
/// No requiere API keys.
class YouTubeMusicService {
  static const _key = 'AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30';

  /// Params del filtro "Songs", cálculo idéntico a ytmusicapi 1.11.5
  /// (`get_search_params`: "EgWKAQ" + "II" + "AWoMEA4QChADEAQQCRAF").
  static const _songsParams = 'EgWKAQIIAWoMEA4QChADEAQQCRAF';

  /// Tope de resultados (equivale a limit=15).
  static const searchLimit = 15;

  /// Versión de cliente dinámica como la librería: 1.YYYYMMDD.01.00.
  String get _clientVersion {
    final now = DateTime.now().toUtc();
    final ymd = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    return '1.$ymd.01.00';
  }

  Map<String, dynamic> _contextBody(String query) => {
        'context': {
          'client': {
            'clientName': 'WEB_REMIX',
            'clientVersion': _clientVersion,
            'hl': 'es',
            'gl': 'ES',
          },
          'user': {},
        },
        'query': query,
        'params': _songsParams,
      };

  Uri _searchUri([String additionalParams = '']) => Uri.parse(
      'https://music.youtube.com/youtubei/v1/search?key=$_key&prettyPrint=false$additionalParams');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Origin': 'https://music.youtube.com',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36',
      };

  /// Búsqueda de canciones como `YTMusic().search(filter="songs", limit=15)`:
  /// estante "Canciones" + continuations hasta 15, álbum y duración nativos
  /// en las filas (sin enriquecimiento extra por fila).
  Future<List<Track>> searchSongs(String query) async {
    final body = _contextBody(query);
    final res = await http
        .post(_searchUri(), headers: _headers, body: jsonEncode(body))
        .timeout(
          const Duration(seconds: 25),
          onTimeout: () =>
              throw Exception('YouTube Music no respondió a tiempo.'),
        );
    if (res.statusCode != 200) {
      throw Exception('YouTube Music respondió ${res.statusCode}.');
    }
    final data = jsonDecode(res.body);
    final tracks = _parseSongs(data);
    // Continuations del estante hasta el tope (como get_continuations).
    // Un fallo de continuación no invalida lo ya obtenido.
    var shelf = _findMusicShelf(data);
    while (tracks.length < searchLimit) {
      final token = _dig(shelf, [
        'continuations',
        0,
        'nextContinuationData',
        'continuation',
      ]);
      if (token is! String || token.isEmpty) break;
      Map<String, dynamic>? cont;
      try {
        cont = await _fetchContinuation(token, body);
      } catch (_) {
        break;
      }
      final items = _dig(cont, ['contents']);
      if (items is! List || items.isEmpty) break;
      var added = 0;
      for (final item in items) {
        if (tracks.length >= searchLimit) break;
        final t = _parseItem(item);
        if (t != null && !tracks.any((e) => e.youtubeUrl == t.youtubeUrl)) {
          tracks.add(t);
          added++;
        }
      }
      if (added == 0) break;
      shelf = cont;
    }
    // Tope 15 como limit=15 de la librería.
    final capped = tracks.take(searchLimit).toList();
    await _fillMissingDurations(capped);
    return capped;
  }

  /// Completa duraciones ausentes vía endpoint `player` en paralelo.
  /// Límite global ~12s; lo que falle queda como '—'.
  Future<void> _fillMissingDurations(List<Track> tracks) async {
    final missing = tracks
        .where((t) => t.durationMs <= 0 && t.youtubeUrl.isNotEmpty)
        .toList();
    if (missing.isEmpty) return;
    Future<void> fillOne(Track t) async {
      try {
        final videoId = _videoIdFromUrl(t.youtubeUrl);
        if (videoId.isEmpty) return;
        final d = await fetchVideoDetails(videoId);
        if (d.durationMs > 0) {
          final i = tracks.indexWhere((e) => e.id == t.id);
          if (i != -1) tracks[i] = tracks[i].copyWith(durationMs: d.durationMs);
        }
      } catch (_) {}
    }

    try {
      await Future.wait(missing.map(fillOne))
          .timeout(const Duration(seconds: 12));
    } catch (_) {}
  }

  /// Hace una petición de continuation (ctoken + continuation).
  Future<Map<String, dynamic>> _fetchContinuation(
      String token, Map<String, dynamic> body) async {
    final res = await http
        .post(
          _searchUri('&ctoken=$token&continuation=$token'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('continuation ${res.statusCode}');
    final data = jsonDecode(res.body);
    dynamic shelf;
    if (data is Map) {
      final cc = (data)['continuationContents'];
      if (cc is Map) shelf = (cc)['musicShelfContinuation'];
    }
    if (shelf is! Map<String, dynamic>) throw Exception('sin estante');
    return shelf;
  }

  /// Localiza el primer musicShelfRenderer de la respuesta inicial.
  Map<String, dynamic>? _findMusicShelf(dynamic data) {
    final tabs = _dig(data, [
      'contents',
      'tabbedSearchResultsRenderer',
      'tabs',
    ]);
    if (tabs is! List) return null;
    for (final tab in tabs) {
      final sections = _dig(tab, [
        'tabRenderer',
        'content',
        'sectionListRenderer',
        'contents',
      ]);
      if (sections is! List) continue;
      for (final section in sections) {
        if (section is Map<String, dynamic> &&
            section['musicShelfRenderer'] is Map) {
          return section['musicShelfRenderer'] as Map<String, dynamic>;
        }
      }
    }
    return null;
  }

  /// Detalle de un video: mejor carátula + duración exacta.
  /// Se usa al descargar para carátula HD (hasta 1280px) sin coste por fila.
  Future<({String cover, int coverWidth, int durationMs})> fetchVideoDetails(
      String videoId) async {
    final uri = Uri.https(
      'music.youtube.com',
      '/youtubei/v1/player',
      {'prettyPrint': 'false', 'key': _key},
    );
    final res = await http
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Origin': 'https://music.youtube.com',
          },
          body: jsonEncode({
            'context': {
              'client': {
                'clientName': 'WEB_REMIX',
                'clientVersion': _clientVersion,
                'hl': 'es',
                'gl': 'ES',
              },
            },
            'videoId': videoId,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw Exception('player ${res.statusCode}');
    final vd = (jsonDecode(res.body) as Map)['videoDetails'];
    if (vd is! Map) throw Exception('sin videoDetails');
    final thumbs = (vd['thumbnail']?['thumbnails'] as List?) ?? [];
    var best = '';
    var bestW = -1;
    for (final t in thumbs.whereType<Map>()) {
      final u = (t['url'] ?? '').toString();
      final w = (t['width'] as num?)?.toInt() ?? 0;
      if (u.isNotEmpty && w >= bestW) {
        bestW = w;
        best = u;
      }
    }
    final len = int.tryParse((vd['lengthSeconds'] ?? '0').toString()) ?? 0;
    return (cover: best, coverWidth: bestW, durationMs: len * 1000);
  }

  /// Enriquece filas de búsqueda en paralelo: álbum y thumbs vía
  /// `yt-dlp --dump-json`, duración exacta vía endpoint `player`.
  /// Lo que falle conserva el dato original. Límite global ~30s.
  Future<List<Track>> enrichTracks(List<Track> tracks) async {
    if (tracks.isEmpty) return tracks;
    Future<Track> enrichOne(Track t) async {
      if (t.youtubeUrl.isEmpty) return t;
      // Álbum+thumbs (yt-dlp) y duración+cover (player) en concurrente.
      final dumpFuture = _dumpJson(t.youtubeUrl);
      final videoId = _videoIdFromUrl(t.youtubeUrl);
      final playerFuture =
          videoId.isNotEmpty ? fetchVideoDetails(videoId) : null;
      String? album;
      int? durationMs;
      String? bestThumb;
      int bestThumbW = -1;
      try {
        final dump = await dumpFuture;
        final a = (dump['album'] ?? '').toString().trim();
        if (a.isNotEmpty) album = a;
        final thumbs = dump['thumbnails'];
        if (thumbs is List) {
          for (final th in thumbs.whereType<Map>()) {
            final u = (th['url'] ?? '').toString();
            final w = (th['width'] as num?)?.toInt() ?? 0;
            if (u.isNotEmpty && w > bestThumbW) {
              bestThumbW = w;
              bestThumb = u;
            }
          }
        }
      } catch (_) {}
      try {
        if (playerFuture != null) {
          final d = await playerFuture;
          if (d.durationMs > 0) durationMs = d.durationMs;
          if (d.cover.isNotEmpty && d.coverWidth > bestThumbW) {
            bestThumbW = d.coverWidth;
            bestThumb = d.cover;
          }
        }
      } catch (_) {}
      if (album == null && durationMs == null && bestThumb == null) {
        return t;
      }
      return t.copyWith(
        album: album,
        durationMs: durationMs,
        imageLarge: bestThumb,
      );
    }

    try {
      return await Future.wait(tracks.map(enrichOne))
          .timeout(const Duration(seconds: 30));
    } catch (_) {
      return tracks;
    }
  }

  /// Metadatos completos de un video vía yt-dlp (álbum, thumbs, …).
  Future<Map<String, dynamic>> _dumpJson(String url) async {
    final ytDlp = await Binaries.ytDlp();
    if (ytDlp == null) throw Exception('yt-dlp no localizado');
    final res = await Process.run(ytDlp, [
      '--dump-json',
      '--skip-download',
      '--no-playlist',
      '--no-check-formats',
      url,
    ]).timeout(const Duration(seconds: 20));
    if (res.exitCode != 0) throw Exception('dump-json falló');
    final lines = (res.stdout as String)
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.startsWith('{'))
        .toList();
    if (lines.isEmpty) throw Exception('dump-json vacío');
    return jsonDecode(lines.first) as Map<String, dynamic>;
  }

  String _videoIdFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '';
    final v = uri.queryParameters['v'];
    if (v != null && v.isNotEmpty) return v;
    if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return '';
  }

  List<Track> _parseSongs(dynamic data) {
    final tracks = <Track>[];
    try {
      final tabs = _dig(data, [
        'contents',
        'tabbedSearchResultsRenderer',
        'tabs',
      ]);
      if (tabs is! List) return tracks;
      for (final tab in tabs) {
        final content = _dig(tab, ['tabRenderer', 'content']);
        final sections = _dig(content, [
          'sectionListRenderer',
          'contents',
        ]);
        if (sections is! List) continue;
        for (final section in sections) {
          if (section is! Map) continue;
          // Forma A: musicShelfRenderer.contents (clásico).
          final shelf = section['musicShelfRenderer'];
          if (shelf is Map && shelf['contents'] is List) {
            for (final item in shelf['contents'] as List) {
              final t = _parseItem(item);
              if (t != null) tracks.add(t);
            }
          }
          // Forma B: itemSectionRenderer.contents con items directos.
          final itemSection = section['itemSectionRenderer'];
          if (itemSection is Map && itemSection['contents'] is List) {
            for (final item in itemSection['contents'] as List) {
              final t = _parseItem(item);
              if (t != null) tracks.add(t);
            }
          }
        }
      }
    } catch (_) {
      // Respuesta con forma inesperada: se devuelve lo acumulado.
    }
    return tracks;
  }

  Track? _parseItem(dynamic item) {
    if (item is! Map) return null;
    final renderer = item['musicResponsiveListItemRenderer'];
    if (renderer is! Map) return null;

    final videoId = _extractVideoId(renderer);
    if (videoId.isEmpty) return null;

    final flex = renderer['flexColumns'];
    if (flex is! List || flex.isEmpty) return null;

    final title = _firstText(_dig(flex, [0, 'musicResponsiveListItemFlexColumnRenderer', 'text']));
    if (title.isEmpty) return null;

    // Segunda columna. Formatos observados:
    //  A) "Artista • Álbum • Duración" (con álbum y duración).
    //  B) "Canción | Artista1 | , | Artista2" (solo tipo + artistas).
    final rawSubs = _rawRuns(_dig(flex, [
      1,
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
    ]));
    if (rawSubs.isEmpty) return null;

    // Como la librería: si hay segunda columna flexible, se anexa
    // (puede traer álbum/duración extra).
    final flex2 = _rawRuns(_dig(flex, [
      2,
      'musicResponsiveListItemFlexColumnRenderer',
      'text',
    ]));
    final allSubs = [...rawSubs, ...flex2];

    // Solo pistas de estudio: si el primer run declara un tipo que NO es
    // canción (artista, álbum, vídeo, lista…), se descarta. Sin badge
    // declarado se acepta si trae videoId + título (estante filtrado).
    final kind =
        (allSubs.first['text'] ?? '').toString().trim().toLowerCase();
    const notSongKinds = {
      'artista', 'artist', 'álbum', 'album', 'single', 'ep',
      'vídeo', 'video', 'lista', 'playlist', 'podcast', 'episodio',
      'episode', 'perfil', 'profile', 'emisora', 'station',
    };
    if (notSongKinds.contains(kind)) return null;

    // Se quita el badge de tipo solo cuando existe ("Canción" • …).
    // Sin badge, todas las runs son datos (formato del estante filtrado).
    const songKinds = {'canción', 'cancion', 'song'};
    var body = allSubs;
    if (body.isNotEmpty &&
        songKinds.contains(
            (body.first['text'] ?? '').toString().trim().toLowerCase())) {
      body = body.skip(1).toList();
    }
    while (body.isNotEmpty &&
        _isBullet((body.first['text'] ?? '').toString())) {
      body = body.skip(1).toList();
    }
    // Grupos separados por bullets: [artistas] • [álbum] • [duración].
    final groups = <List<Map>>[[]];
    for (final r in body) {
      if (_isBullet((r['text'] ?? '').toString())) {
        groups.add([]);
      } else {
        groups.last.add(r);
      }
    }

    var artists = _artistsFromRuns(groups.first);
    var album = 'Single';
    var durationMs = 0;
    if (groups.length > 1) {
      var tail = groups.sublist(1);
      final lastText = tail.last
          .map((r) => (r['text'] ?? '').toString().trim())
          .join(' ');
      if (_looksLikeDuration(lastText)) {
        durationMs = _parseDuration(lastText);
        tail = tail.sublist(0, tail.length - 1);
      }
      // Álbum: se prefiere el run con browseId de álbum (MPRE).
      String? mpre;
      for (final g in tail) {
        for (final r in g) {
          final browse =
              _dig(r, ['navigationEndpoint', 'browseEndpoint', 'browseId']);
          if (browse is String && browse.startsWith('MPRE')) {
            mpre = (r['text'] ?? '').toString().trim();
          }
        }
      }
      if (mpre != null && mpre.isNotEmpty) {
        album = mpre;
      } else {
        final joined = tail
            .map((g) => g
                .map((r) => (r['text'] ?? '').toString().trim())
                .where((s) => s.isNotEmpty && !_isSeparator(s))
                .join(' '))
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .join(' • ');
        if (joined.isNotEmpty) album = joined;
      }
    }
    if (artists.isEmpty) artists = ['Desconocido'];
    // Duración también puede venir en columna fija.
    if (durationMs == 0) {
      final fixed = renderer['fixedColumns'];
      if (fixed is List && fixed.isNotEmpty) {
        final d = _firstText(_dig(fixed, [0, 'musicResponsiveListItemFixedColumnRenderer', 'text']));
        if (_looksLikeDuration(d)) durationMs = _parseDuration(d);
      }
    }

    final thumbs = _extractThumbs(renderer);
    final small = thumbs.isNotEmpty ? thumbs.first : '';
    final large = thumbs.isNotEmpty ? thumbs.last : '';

    return Track(
      id: 'ytm_$videoId',
      title: title,
      artists: artists,
      album: album,
      durationMs: durationMs,
      imageSmall: small,
      imageLarge: large,
      spotifyUrl: '',
      youtubeUrl: 'https://www.youtube.com/watch?v=$videoId',
    );
  }

  /// Artistas de un grupo de runs: primero por endpoint de canal (UC),
  /// con reserva por texto (coma) si no hay endpoints.
  List<String> _artistsFromRuns(List<Map> runs) {
    final nav = <String>[];
    for (final r in runs) {
      final browse =
          _dig(r, ['navigationEndpoint', 'browseEndpoint', 'browseId']);
      final text = (r['text'] ?? '').toString().trim();
      if (browse is String && browse.startsWith('UC') && text.isNotEmpty) {
        nav.add(text);
      }
    }
    if (nav.isNotEmpty) return nav;
    final joined = runs
        .map((r) => (r['text'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty && !_isSeparator(s))
        .join(' ');
    return joined
        .split(',')
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  bool _isBullet(String s) => s.trim() == '•';

  /// Detecta runs separadores entre artistas (",", "y", "e", "&", "•", …).
  bool _isSeparator(String run) {
    final t = run.trim().toLowerCase();
    if (t.isEmpty) return true;
    if (RegExp(r'^[,•&/\\|]+$').hasMatch(t)) return true;
    return {'y', 'e', 'and', 'con', 'feat.', 'feat', 'ft.', 'ft', 'with'}
        .contains(t);
  }

  String _extractVideoId(Map renderer) {
    // 1) Overlay del botón play.
    final overlayId = _dig(renderer, [
      'overlay',
      'musicItemThumbnailOverlayRenderer',
      'content',
      'musicPlayButtonRenderer',
      'playNavigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]);
    if (overlayId is String && overlayId.isNotEmpty) return overlayId;
    // 2) Endpoint de navegación del item.
    final navId = _dig(renderer, [
      'navigationEndpoint',
      'watchEndpoint',
      'videoId',
    ]);
    if (navId is String && navId.isNotEmpty) return navId;
    return '';
  }

  /// Thumbnails ordenados de menor a mayor resolución.
  /// Como el pipeline Python, se fuerza `=w1080-h1080` en URLs de
  /// Google (thumbnails[-1] en máxima resolución pedida).
  List<String> _extractThumbs(Map renderer) {
    final list = _dig(renderer, [
      'thumbnail',
      'musicThumbnailRenderer',
      'thumbnail',
      'thumbnails',
    ]);
    if (list is! List) return [];
    final entries = <({int w, String url})>[];
    for (final t in list) {
      if (t is! Map) continue;
      final url = (t['url'] ?? '').toString();
      if (url.isEmpty) continue;
      entries.add((w: (t['width'] as num?)?.toInt() ?? 0, url: url));
    }
    entries.sort((a, b) => a.w.compareTo(b.w));
    return entries.map((e) => _force1080(e.url)).toList();
  }

  /// Fuerza la resolución pedida a 1080px en URLs `=wNN-hNN-…` de Google,
  /// igual que el pipeline Python (`thumbnails[-1]` a `w1080-h1080`).
  String _force1080(String url) => url.replaceAllMapped(
        RegExp(r'=w\d+-h\d+'),
        (_) => '=w1080-h1080',
      );

  List<String> _runs(dynamic textObj) {
    return _rawRuns(textObj)
        .map((r) => (r['text'] ?? '').toString())
        .toList();
  }

  List<Map> _rawRuns(dynamic textObj) {
    if (textObj is! Map) return [];
    final runs = textObj['runs'];
    if (runs is! List) return [];
    return runs.whereType<Map>().toList();
  }

  String _firstText(dynamic textObj) {
    final runs = _runs(textObj);
    return runs.isEmpty ? '' : runs.first;
  }

  bool _looksLikeDuration(String s) =>
      RegExp(r'^\d{1,3}:\d{2}(?::\d{2})?$').hasMatch(s.trim());

  int _parseDuration(String s) {
    final parts =
        s.trim().split(':').map(int.tryParse).toList();
    if (parts.any((p) => p == null)) return 0;
    final nums = parts.cast<int>();
    var total = 0;
    for (final n in nums) {
      total = total * 60 + n;
    }
    return total * 1000;
  }

  /// Navegación segura por mapas/listas. Los índices de lista van como int.
  dynamic _dig(dynamic obj, List<dynamic> path) {
    dynamic cur = obj;
    for (final key in path) {
      if (key is int) {
        if (cur is List && key < cur.length) {
          cur = cur[key];
        } else {
          return null;
        }
      } else {
        if (cur is Map && cur.containsKey(key)) {
          cur = cur[key];
        } else {
          return null;
        }
      }
    }
    return cur;
  }
}
