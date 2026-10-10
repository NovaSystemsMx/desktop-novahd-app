import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'services/downloader_service.dart';
import 'services/music_search_service.dart';
import 'theme/one_dark_pro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicSearchService()),
        ChangeNotifierProvider(create: (_) => DownloaderService()),
      ],
      child: const NovadhApp(),
    ),
  );
}

class NovadhApp extends StatelessWidget {
  const NovadhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Novadh Downloader',
      debugShowCheckedModeBanner: false,
      theme: buildNovadhTheme(),
      home: const NovadhAppShell(),
    );
  }
}
