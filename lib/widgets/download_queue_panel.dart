import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/download_task.dart';
import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';

/// Panel lateral con la cola de descargas.
/// Cabecera de una sola fila (misma altura que la tabla de resultados),
/// lista con scroll propio y ruta destino como pie.
class DownloadQueuePanel extends StatelessWidget {
  const DownloadQueuePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloaderService>(
      builder: (context, dl, _) {
        final q = dl.queue;
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: OneDarkPro.sidebar,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: OneDarkPro.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.fromLTRB(16, 8, 8, 8),
                  decoration: const BoxDecoration(
                    color: OneDarkPro.darker,
                    border: Border(
                        bottom: BorderSide(color: OneDarkPro.border)),
                  ),
                  child: SizedBox(
                    height: 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Text(
                                'COLA DE DESCARGAS',
                                style: TextStyle(
                                    color: OneDarkPro.fgDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '•',
                                style: TextStyle(
                                    color: OneDarkPro.fgDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                q.length.toString(),
                                style: const TextStyle(
                                    color: OneDarkPro.fgDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8),
                              ),
                            ],
                          ),
                        ),
                        Tooltip(
                          message: 'Abrir carpeta de descargas',
                          child: IconButton(
                            onPressed: dl.openDownloadsFolder,
                            icon: const Icon(Icons.folder_open_rounded,
                                size: 16),
                            color: OneDarkPro.blue,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Limpiar terminadas',
                          child: IconButton(
                            onPressed:
                                q.isEmpty ? null : dl.clearFinished,
                            icon: const Icon(
                                Icons.cleaning_services_rounded,
                                size: 16),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 24, minHeight: 24),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (q.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.downloading_rounded,
                                color: OneDarkPro.fgDim, size: 30),
                            SizedBox(height: 10),
                            Text(
                              'La cola esta vacia.\nDescarga cualquier resultado y aparecera aqui con su progreso.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: OneDarkPro.fgDim,
                                  fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: q.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, i) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        child: _QueueTile(task: q[i]),
                      ),
                    ),
                  ),
                const Divider(height: 1),
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(16, 6, 16, 8),
                  child: Tooltip(
                    message: dl.downloadDir.path,
                    child: Text(
                      dl.downloadDir.path,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: OneDarkPro.fgDim, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _QueueTile extends StatelessWidget {
  final DownloadTask task;
  const _QueueTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final dl = context.read<DownloaderService>();
    Color statusColor;
    IconData statusIcon;
    switch (task.status) {
      case DownloadStatus.queued:
        statusColor = OneDarkPro.yellow;
        statusIcon = Icons.schedule_rounded;
        break;
      case DownloadStatus.downloading:
        statusColor = OneDarkPro.blue;
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadStatus.completed:
        statusColor = OneDarkPro.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.failed:
        statusColor = OneDarkPro.red;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: OneDarkPro.darker,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: OneDarkPro.border),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${task.track.artistsLabel} - ${task.track.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: OneDarkPro.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: task.status == DownloadStatus.queued
                        ? 0
                        : task.progress.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: OneDarkPro.border,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                ),
                const SizedBox(height: 4),
                Text(task.message,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: OneDarkPro.fgDim, fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (task.status == DownloadStatus.failed)
            Tooltip(
              message: 'Reintentar',
              child: IconButton(
                onPressed: () => dl.retry(task),
                icon: const Icon(Icons.refresh_rounded,
                    color: OneDarkPro.yellow, size: 18),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                    minWidth: 28, minHeight: 28),
              ),
            ),
          Tooltip(
            message: 'Quitar de la cola',
            child: IconButton(
              onPressed: () => dl.remove(task.id),
              icon: const Icon(Icons.close_rounded,
                  color: OneDarkPro.fgDim, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                  minWidth: 28, minHeight: 28),
            ),
          ),
        ],
      ),
    );
  }
}
