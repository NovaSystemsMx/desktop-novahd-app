import 'package:flutter/material.dart';

import '../theme/one_dark_pro.dart';
import '../views/settings_view.dart';
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
          Sidebar(selected: _tab, onSelect: (t) => setState(() => _tab = t)),
          Expanded(
            child: Column(
              children: [
                // Barra superior fina estilo desktop.
                Container(
                  height: 44,
                  decoration: const BoxDecoration(
                    color: OneDarkPro.sidebar,
                    border: Border(
                      bottom: BorderSide(color: OneDarkPro.border),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.download_rounded,
                          size: 14,
                          color: OneDarkPro.blue,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Nova Hub Downloader - Windows v0.6',
                        style: AppText.secondary.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == PlatformTab.settings
                      ? const SettingsView()
                      : const SpotifyView(),
                ),
                const StatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
