import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'services/app_log.dart';
import 'services/auth_store.dart';
import 'services/downloader_service.dart';
import 'services/music_search_service.dart';
import 'theme/one_dark_pro.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  await AuthStore.instance.load();

  // Ventana según escala del display primario (100/125/150/200%):
  // el mínimo lógico × escala cabe en pantallas comunes de ese tramo
  // (1366px@100%, 1536px@125%, 1080p@150%, QHD/4K@200%). El tamaño
  // inicial además se recorta al área visible. Centrada al arrancar.
  await windowManager.waitUntilReadyToShow(
    await _windowOptions(),
    () async => windowManager.show(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MusicSearchService()),
        ChangeNotifierProvider(create: (_) => DownloaderService()),
        ChangeNotifierProvider.value(value: AppLog.instance),
        ChangeNotifierProvider.value(value: AuthStore.instance),
      ],
      child: const NovadhApp(),
    ),
  );
}

/// Mínimo de ventana por escala del display (lógicos): el mínimo ×
/// escala cabe en pantallas comunes de cada tramo.
Size _minWindowForScale(double scale) {
  if (scale >= 1.75) return const Size(1120, 610); // 200%
  if (scale >= 1.4) return const Size(1200, 630); // 150%
  if (scale >= 1.15) return const Size(1100, 630); // 125%
  return const Size(1100, 660); // 100%
}

Future<WindowOptions> _windowOptions() async {
  const fallback = WindowOptions(
    size: Size(1200, 660),
    minimumSize: Size(1100, 630),
    center: true,
    title: 'Nova Hub Downloader',
  );
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    final scale = (display.scaleFactor ?? 1).toDouble();
    final min = _minWindowForScale(scale);
    final visible = display.visibleSize ?? display.size;
    double fit(double want, double minSide, double visibleSide) {
      final maxSide = math.max(minSide, visibleSide - 80);
      return want.clamp(minSide, maxSide).toDouble();
    }

    return WindowOptions(
      size: Size(
        fit(1200, min.width, visible.width),
        fit(660, min.height, visible.height),
      ),
      minimumSize: min,
      center: true,
      title: 'Nova Hub Downloader',
    );
  } catch (_) {
    return fallback;
  }
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
