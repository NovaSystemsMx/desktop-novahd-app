import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/downloader_service.dart';
import '../services/music_search_service.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';

/// Barra de estado inferior de Spotify (patrón desktop clásico).
/// Refleja búsquedas y descargas en tiempo real. Ajustes no la usa.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloaderService, MusicSearchService>(
      builder: (context, dl, sp, _) {
        final downloading = dl.downloadingCount;
        final queued = dl.queuedCount;
        final completed = dl.completedCount;
        final failed = dl.failedCount;

        String text;
        Color dot;
        if (dl.notice != null) {
          text = dl.notice!;
          dot = OneDarkPro.blue;
        } else if (downloading > 0) {
          final total = downloading + queued;
          text = total > 1
              ? 'Descargando $downloading de $total…'
              : 'Descargando…';
          dot = OneDarkPro.blue;
        } else if (sp.isSearching) {
          text = sp.lastQuery.isNotEmpty
              ? "Buscando '${sp.lastQuery}'…"
              : 'Buscando…';
          dot = OneDarkPro.blue;
        } else if (queued > 0) {
          text = queued == 1 ? '1 en cola' : '$queued en cola';
          dot = OneDarkPro.yellow;
        } else if (sp.lastSearchError != null) {
          text = 'Error en la búsqueda';
          dot = OneDarkPro.red;
        } else if (failed > 0) {
          text = failed == 1
              ? '1 descarga con error'
              : '$failed descargas con error';
          dot = OneDarkPro.red;
        } else if (sp.hasSearched && sp.lastResultCount > 0) {
          text = sp.lastResultCount == 1
              ? "1 resultado para '${sp.lastQuery}'"
              : "${sp.lastResultCount} resultados para '${sp.lastQuery}'";
          dot = OneDarkPro.blue;
        } else if (completed > 0) {
          text = completed == 1
              ? '1 archivo descargado'
              : '$completed archivos descargados';
          dot = OneDarkPro.green;
        } else {
          text = 'Listo para buscar';
          dot = OneDarkPro.blue;
        }

        return Container(
          height: UiTokens.sizeStatusBar,
          decoration: const BoxDecoration(
            color: OneDarkPro.sidebar,
            border: Border(top: BorderSide(color: OneDarkPro.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: UiTokens.spaceCard),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: UiTokens.sizeStatusDot,
                  height: UiTokens.sizeStatusDot,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: dot.withValues(alpha: 0.45),
                      width: UiTokens.borderWidth,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: UiTokens.sizeStatusDotInner,
                      height: UiTokens.sizeStatusDotInner,
                      decoration: BoxDecoration(
                        color: dot,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UiTokens.spaceInline),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
