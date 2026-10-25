import 'package:flutter/material.dart';

import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';
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
                  height: UiTokens.sizeTopBar,
                  decoration: const BoxDecoration(
                    color: OneDarkPro.sidebar,
                    border: Border(
                      bottom: BorderSide(color: OneDarkPro.border),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: UiTokens.spaceCard,
                  ),
                  child: Row(
                    children: [
                      const ExcludeSemantics(
                        child: Icon(
                          Icons.download_rounded,
                          size: UiTokens.iconInline,
                          color: OneDarkPro.blue,
                        ),
                      ),
                      const SizedBox(width: UiTokens.spaceInline),
                      Expanded(
                        child: Text(
                          'Nova Hub Downloader — Windows v0.9',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caption,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _tab == PlatformTab.settings
                      ? const SettingsView()
                      : const SpotifyView(),
                ),
                // La barra de estado pertenece a Spotify (búsqueda y cola).
                // Ajustes no la muestra: su chrome termina en la top bar.
                if (_tab == PlatformTab.spotify) const StatusBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
