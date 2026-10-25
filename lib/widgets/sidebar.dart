import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';

enum PlatformTab { spotify, settings }

class Sidebar extends StatelessWidget {
  final PlatformTab selected;
  final ValueChanged<PlatformTab> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: UiTokens.sizeSidebar,
      decoration: const BoxDecoration(
        color: OneDarkPro.sidebar,
        border: Border(right: BorderSide(color: OneDarkPro.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              UiTokens.spaceCard,
              UiTokens.spaceCard,
              UiTokens.spaceCard,
              UiTokens.spaceInline,
            ),
            child: Row(
              children: [
                Container(
                  width: UiTokens.sizeTileSidebar,
                  height: UiTokens.sizeTileSidebar,
                  decoration: BoxDecoration(
                    color: OneDarkPro.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(UiTokens.radiusControl),
                    border: Border.all(
                      color: OneDarkPro.blue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const ExcludeSemantics(
                    child: Icon(
                      Icons.download_rounded,
                      color: OneDarkPro.blue,
                      size: UiTokens.iconTileSidebar,
                    ),
                  ),
                ),
                const SizedBox(width: UiTokens.spaceInline),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOVA HUB', style: AppText.brand),
                    Text('Downloader', style: AppText.caption),
                  ],
                ),
              ],
            ),
          ),
          const Padding(
            padding: UiTokens.paddingSidebarLabel,
            child: Text('PLATAFORMAS', style: AppText.caps),
          ),
          _item(
            context,
            icon: Icons.music_note_rounded,
            color: OneDarkPro.blue,
            label: 'Spotify',
            subtitle: 'Downloader activo',
            active: selected == PlatformTab.spotify,
            onTap: () => onSelect(PlatformTab.spotify),
          ),
          _disabledItem(
            icon: Icons.play_circle_outline_rounded,
            label: 'YouTube Music',
            badge: 'Pronto',
          ),
          _disabledItem(
            icon: Icons.cloud_outlined,
            label: 'SoundCloud',
            badge: 'Pronto',
          ),
          _disabledItem(
            icon: Icons.album_outlined,
            label: 'Deezer',
            badge: 'Pronto',
          ),
          const Spacer(),
          const Divider(height: UiTokens.borderWidth),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: UiTokens.spaceItemOuterH,
              vertical: UiTokens.spaceItemH,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  selected: selected == PlatformTab.settings,
                  child: OutlinedButton.icon(
                    onPressed: () => onSelect(PlatformTab.settings),
                    style: selected == PlatformTab.settings
                        ? OutlinedButton.styleFrom(
                            backgroundColor: OneDarkPro.card,
                            foregroundColor: OneDarkPro.white,
                            side: BorderSide(
                              color: OneDarkPro.blue.withValues(alpha: 0.45),
                            ),
                          )
                        : null,
                    icon: Icon(
                      Icons.settings_rounded,
                      size: UiTokens.iconButton,
                      color: selected == PlatformTab.settings
                          ? OneDarkPro.blue
                          : null,
                    ),
                    label: const Text('Ajustes'),
                  ),
                ),
                const SizedBox(height: UiTokens.spaceInline),
                Consumer<DownloaderService>(
                  builder: (context, dl, _) => OutlinedButton.icon(
                    onPressed: dl.openDownloadsFolder,
                    icon: const Icon(
                      Icons.folder_open_rounded,
                      size: UiTokens.iconButton,
                    ),
                    label: const Text('Abrir descargas'),
                  ),
                ),
                const SizedBox(height: UiTokens.spaceInline),
                const Text(
                  'Nova Hub v0.9',
                  textAlign: TextAlign.center,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required bool active,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UiTokens.spaceItemOuterH,
        vertical: UiTokens.spaceItemOuterV,
      ),
      child: Semantics(
        button: true,
        selected: active,
        label: active ? '$label, seleccionado' : label,
        child: InkWell(
          borderRadius: BorderRadius.circular(UiTokens.radiusControl),
          focusColor: OneDarkPro.blueText.withValues(alpha: 0.22),
          hoverColor: OneDarkPro.cardHover,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UiTokens.spaceItemH,
              vertical: UiTokens.spaceItemV,
            ),
            decoration: BoxDecoration(
              color: active ? OneDarkPro.card : Colors.transparent,
              borderRadius: BorderRadius.circular(UiTokens.radiusControl),
              border: Border.all(
                color: active
                    ? OneDarkPro.blue.withValues(alpha: 0.45)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: color,
                    size: UiTokens.iconTileSidebar,
                  ),
                ),
                const SizedBox(width: UiTokens.spaceInline),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message: label,
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title,
                        ),
                      ),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _disabledItem({
    required IconData icon,
    required String label,
    required String badge,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UiTokens.spaceItemOuterH,
        vertical: UiTokens.spaceItemOuterV,
      ),
      child: Semantics(
        enabled: false,
        label: '$label, próximamente',
        child: Tooltip(
          message: '$label (próximamente)',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: UiTokens.spaceItemH,
              vertical: UiTokens.spaceItemV,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiTokens.radiusControl),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    color: OneDarkPro.fgDim,
                    size: UiTokens.iconTileSidebar,
                  ),
                ),
                const SizedBox(width: UiTokens.spaceInline),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title.copyWith(color: OneDarkPro.fgDim),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: UiTokens.spaceBadgeH,
                    vertical: UiTokens.spaceBadgeV,
                  ),
                  decoration: BoxDecoration(
                    color: OneDarkPro.darker,
                    borderRadius: BorderRadius.circular(UiTokens.radiusSmall),
                    border: Border.all(color: OneDarkPro.border),
                  ),
                  child: Text(badge, style: AppText.caps),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
