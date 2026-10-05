import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/downloader_service.dart';
import '../services/spotify_service.dart';
import '../theme/one_dark_pro.dart';

/// Barra de estado inferior persistente (patron desktop clasico).
/// Refleja busquedas y descargas en tiempo real.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DownloaderService, SpotifyService>(
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
              ? 'Descargando $downloading de $total...'
              : 'Descargando...';
          dot = OneDarkPro.blue;
        } else if (sp.isSearching) {
          text = sp.lastQuery.isNotEmpty
              ? "Buscando '${sp.lastQuery}'..."
              : 'Buscando...';
          dot = OneDarkPro.blue;
        } else if (queued > 0) {
          text = queued == 1 ? '1 en cola' : '$queued en cola';
          dot = OneDarkPro.yellow;
        } else if (sp.lastSearchError != null) {
          text = 'Error en la busqueda';
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
          height: 30,
          decoration: const BoxDecoration(
            color: OneDarkPro.sidebar,
            border: Border(top: BorderSide(color: OneDarkPro.border)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: OneDarkPro.fgDim, fontSize: 12)),
              ),
            ],
          ),
        );
      },
    );
  }
}
