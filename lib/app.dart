import 'package:flutter/material.dart';

import '../theme/one_dark_pro.dart';
import '../views/spotify_view.dart';
import '../widgets/sidebar.dart';
import '../widgets/status_bar.dart';

/// Shell principal: menú lateral + contenido.
class NovadhAppShell extends StatefulWidget {
  const NovadhAppShell({super.key});

  @override
  State<NovadhAppShell> createState() => _NovadhAppShellState();
}

class _NovadhAppShellState extends State<NovadhAppShell> {
  PlatformTab _tab = PlatformTab.spotify;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OneDarkPro.background,
      body: Row(
        children: [
          Sidebar(
            selected: _tab,
            onSelect: (t) => setState(() => _tab = t),
          ),
          Expanded(
            child: Column(
              children: [
                // Barra superior fina estilo desktop.
                Container(
                  height: 44,
                  decoration: const BoxDecoration(
                    color: OneDarkPro.sidebar,
                    border: Border(
                        bottom: BorderSide(color: OneDarkPro.border)),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16),
                  child: const Row(
                    children: [
                      Icon(Icons.download_rounded,
                          size: 14, color: OneDarkPro.green),
                      SizedBox(width: 8),
                      Text('Nova Hub Downloader — Windows · v0.3',
                          style: TextStyle(
                              color: OneDarkPro.fgDim, fontSize: 12)),
                    ],
                  ),
                ),
                const Expanded(child: SpotifyView()),
                const StatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
