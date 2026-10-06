import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';

enum PlatformTab { spotify }

class Sidebar extends StatelessWidget {
  final PlatformTab selected;
  final ValueChanged<PlatformTab> onSelect;

  const Sidebar({super.key, required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 258,
      decoration: const BoxDecoration(
        color: OneDarkPro.sidebar,
        border: Border(right: BorderSide(color: OneDarkPro.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 8),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: OneDarkPro.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: OneDarkPro.blue.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.download_rounded,
                      color: OneDarkPro.blue, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NOVA HUB',
                        style: TextStyle(
                            color: OneDarkPro.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4)),
                    Text('Downloader',
                        style: AppText.secondary
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Text('PLATAFORMAS',
                style:
                    AppText.caps.copyWith(letterSpacing: 1.1)),
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
              badge: 'Próximamente'),
          _disabledItem(
              icon: Icons.cloud_outlined,
              label: 'SoundCloud',
              badge: 'Próximamente'),
          _disabledItem(
              icon: Icons.album_outlined,
              label: 'Deezer',
              badge: 'Próximamente'),
          const Spacer(),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Consumer<DownloaderService>(
                  builder: (context, dl, _) => OutlinedButton.icon(
                    onPressed: dl.openDownloadsFolder,
                    icon: const Icon(Icons.folder_open_rounded, size: 16),
                    label: const Text('Abrir Descargas',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Nova Hub v0.4',
                    textAlign: TextAlign.center,
                    style: AppText.secondary.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context,
      {required IconData icon,
      required Color color,
      required String label,
      required String subtitle,
      required bool active,
      required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? OneDarkPro.card : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: active ? OneDarkPro.blue.withValues(alpha: 0.45) : Colors.transparent),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppText.title),
                    Text(subtitle,
                        style: AppText.secondary
                            .copyWith(fontSize: 11)),
                  ],
                ),
              ),
              Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: OneDarkPro.blue, shape: BoxShape.circle)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _disabledItem(
      {required IconData icon, required String label, required String badge}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Opacity(
        opacity: 0.45,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, color: OneDarkPro.fgDim, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                    color: OneDarkPro.darker,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OneDarkPro.border)),
                child: Text(badge,
                    style:
                        AppText.caps.copyWith(fontSize: 10)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
