// Suite de capturas UX (no asserts): renderiza las vistas reales en
// tamaño desktop y guarda PNG para revisión visual.
//
// Uso: flutter test --update-goldens test/ux_screenshots_test.dart
// Salida: test/goldens/*.png
import 'package:desktop_novadh_app/app.dart';
import 'package:desktop_novadh_app/models/track.dart';
import 'package:desktop_novadh_app/services/app_log.dart';
import 'package:desktop_novadh_app/services/auth_store.dart';
import 'package:desktop_novadh_app/services/downloader_service.dart';
import 'package:desktop_novadh_app/services/music_search_service.dart';
import 'package:desktop_novadh_app/theme/one_dark_pro.dart';
import 'package:desktop_novadh_app/views/settings_view.dart';
import 'package:desktop_novadh_app/widgets/results_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

const _tracks = [
  Track(
    id: 'yt_aaa',
    title: 'Bohemian Rhapsody (Remastered 2011)',
    artists: ['Queen'],
    album: 'A Night At The Opera (Deluxe Remastered Version)',
    durationMs: 354000,
    imageSmall: '',
    imageLarge: '',
    spotifyUrl: '',
    youtubeUrl: 'https://www.youtube.com/watch?v=aaa',
  ),
  Track(
    id: 'yt_bbb',
    title: 'Stairway to Heaven',
    artists: ['Led Zeppelin'],
    album: 'Led Zeppelin IV',
    durationMs: 482000,
    imageSmall: '',
    imageLarge: '',
    spotifyUrl: '',
    youtubeUrl: 'https://www.youtube.com/watch?v=bbb',
  ),
  Track(
    id: 'yt_ccc',
    title: 'Canción con un título extremadamente largo que fuerza el ellipsis en la fila de resultados',
    artists: ['Artista Uno', 'Artista Dos', 'Artista Tres'],
    album: 'Álbum con nombre también muy largo para probar truncado',
    durationMs: 0,
    imageSmall: '',
    imageLarge: '',
    spotifyUrl: '',
    youtubeUrl: '',
  ),
];

Widget _wrap(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => MusicSearchService()),
      ChangeNotifierProvider(create: (_) => DownloaderService()),
      ChangeNotifierProvider.value(value: AppLog.instance),
      ChangeNotifierProvider.value(value: AuthStore.instance),
    ],
    child: MaterialApp(theme: buildNovadhTheme(), home: child),
  );
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$name.png'),
  );
}

void main() {
  testWidgets('shell spotify vacio', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 810));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(_wrap(const Scaffold(body: NovadhAppShell())));
    await _shot(tester, 'shell_spotify_empty');
  });

  testWidgets('tabla con resultados', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 810));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(22),
            child: ResultsTable(
              tracks: _tracks,
              queuedIds: {'yt_bbb'},
              onDownload: _noop,
            ),
          ),
        ),
      ),
    );
    await _shot(tester, 'results_with_data');
  });

  testWidgets('ajustes', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 810));
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await tester.pumpWidget(
      _wrap(
        const Scaffold(
          body: Row(
            children: [
              SizedBox(width: 258),
              Expanded(child: SettingsView()),
            ],
          ),
        ),
      ),
    );
    await _shot(tester, 'settings');
  });
}

void _noop(Track _) {}
