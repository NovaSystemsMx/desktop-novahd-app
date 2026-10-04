// Diagnóstico de formas de respuesta YTM.
// Uso: dart run tool/ytm_shape.dart "bad bunny"
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

Future<void> main(List<String> args) async {
  final q = args.isEmpty ? 'bad bunny' : args.join(' ');
  final now = DateTime.now().toUtc();
  final ver =
      '1.${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.01.00';
  final body = {
    'context': {
      'client': {
        'clientName': 'WEB_REMIX',
        'clientVersion': ver,
        'hl': 'es',
        'gl': 'ES',
      },
      'user': {},
    },
    'query': q,
    'params': 'EgWKAQIIAWoMEA4QChADEAQQCRAF',
  };
  final res = await http.post(
    Uri.parse(
        'https://music.youtube.com/youtubei/v1/search?key=AIzaSyC9XL3ZjWddXya6X74dJoCTL-WEYFDNX30&prettyPrint=false'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );
  final data = jsonDecode(res.body);
  dynamic dig(dynamic o, List<dynamic> p) {
    dynamic c = o;
    for (final k in p) {
      if (k is int) {
        if (c is List && k < c.length) {
          c = c[k];
        } else {
          return null;
        }
      } else {
        if (c is Map && (c).containsKey(k)) {
          c = (c)[k];
        } else {
          return null;
        }
      }
    }
    return c;
  }

  final sections =
      dig(data, ['contents', 'tabbedSearchResultsRenderer', 'tabs', 0, 'tabRenderer', 'content', 'sectionListRenderer', 'contents']);
  if (sections is! List) {
    stdout.writeln('SIN SECCIONES');
    return;
  }
  stdout.writeln('SECCIONES: ${sections.length}');
  var shown = 0;
  for (final s in sections) {
    if (s is! Map) continue;
    final keys = (s).keys.join(',');
    if (keys.contains('musicShelf')) {
      final items = (s['musicShelfRenderer'] as Map)['contents'] as List;
      stdout.writeln('MUSICSHELF items=${items.length}');
    } else if (keys.contains('itemSection')) {
      final items = (s['itemSectionRenderer'] as Map)['contents'] as List;
      for (final it in items) {
        if (shown >= 8) break;
        final r = (it as Map)['musicResponsiveListItemRenderer'];
        if (r is! Map) {
          stdout.writeln('  - [${(it).keys.join(',')}]');
          continue;
        }
        final flex = r['flexColumns'] as List;
        String col(int i) {
          if (i >= flex.length) return '-';
          final runs = (flex[i] as Map)['musicResponsiveListItemFlexColumnRenderer']?['text']?['runs'];
          if (runs is! List) return '?';
          return (runs).map((e) => (e as Map)['text']).join('|');
        }

        final vid = (r['overlay'] as Map?)?['musicItemThumbnailOverlayRenderer']?['content']?['musicPlayButtonRenderer']?['playNavigationEndpoint']?['watchEndpoint']?['videoId'] ?? '';
        stdout.writeln('  [$shown] ${col(0).toString().substring(0, col(0).toString().length.clamp(0, 40))} // ${col(1)} // vid=$vid');
        shown++;
      }
    } else {
      stdout.writeln('OTRA: $keys');
    }
  }
}
