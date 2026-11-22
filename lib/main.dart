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

  // Mínimo plano 1152×640 lógicos: el marco de Windows se come ~16 lógicos
  // de ancho, así que el contenido queda en ~833, por encima de
  // `stackBelow` (820): la cola siempre se ve al lado de la tabla y el
  // apilado queda solo como red de seguridad. Antes el mínimo bajaba a
  // 1100/1120 en 125%/200%, justo por debajo del umbral, y la vista
  // cambiaba de layout. El tamaño inicial se recorta al área visible y la
  // ventana arranca centrada.
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

/// Mínimo de ventana (lógicos). 1152 dan ~833 de contenido: `stackBelow`
/// es 820, así que la cola nunca se apila en uso normal. La holgura de
/// ~13 px cubre el marco de Windows (medido: 18 px físicos a 125%) y el
/// redondeo de escalas fraccionarias. El alto 640 deja ~602 de cliente, por
/// encima del mínimo ya validado con el footer fijo de la cola (E9).
const Size _minWindow = Size(1152, 640);

Future<WindowOptions> _windowOptions() async {
  const fallback = WindowOptions(
    size: Size(1200, 660),
    minimumSize: _minWindow,
    center: true,
    title: 'Nova Hub Downloader',
  );
  try {
    final display = await screenRetriever.getPrimaryDisplay();
    final scale = (display.scaleFactor ?? 1).toDouble();
    final visible = display.visibleSize ?? display.size;
    // `screen_retriever` devuelve píxeles físicos; `WindowOptions` trabaja
    // en lógicos. Sin esta conversión, a 125% la ventana inicial (1200)
    // se convierte en 1500 físicos y no cabe en una pantalla de 1536.
    final visibleLogical = Size(
      visible.width / scale,
      visible.height / scale,
    );
    double fit(double want, double minSide, double visibleSide) {
      final maxSide = math.max(minSide, visibleSide - 80);
      return want.clamp(minSide, maxSide).toDouble();
    }

    return WindowOptions(
      size: Size(
        fit(1200, _minWindow.width, visibleLogical.width),
        fit(660, _minWindow.height, visibleLogical.height),
      ),
      minimumSize: _minWindow,
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
