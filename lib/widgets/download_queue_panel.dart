import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/download_task.dart';
import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';
import 'empty_icon_tile.dart';

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
          borderRadius: BorderRadius.circular(UiTokens.radiusCard),
          child: Container(
            decoration: BoxDecoration(
              color: OneDarkPro.sidebar,
              borderRadius: BorderRadius.circular(UiTokens.radiusCard),
              border: Border.all(color: OneDarkPro.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: UiTokens.sizeCardHeader,
                  padding: const EdgeInsets.fromLTRB(
                    UiTokens.spaceCard,
                    UiTokens.spaceCluster,
                    UiTokens.spaceCard,
                    UiTokens.spaceCluster,
                  ),
                  decoration: const BoxDecoration(
                    color: OneDarkPro.darker,
                    border: Border(
                      bottom: BorderSide(color: OneDarkPro.border),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'COLA DE DESCARGAS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.caps,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: UiTokens.spaceBadgeH,
                          vertical: UiTokens.spaceBadgeV,
                        ),
                        decoration: BoxDecoration(
                          color: OneDarkPro.sidebar,
                          borderRadius: BorderRadius.circular(
                            UiTokens.radiusSmall,
                          ),
                          border: Border.all(color: OneDarkPro.border),
                        ),
                        child: Text(
                          '${q.length}',
                          style: AppText.caps.copyWith(color: OneDarkPro.white),
                        ),
                      ),
                      const SizedBox(width: UiTokens.spaceInline),
                      Tooltip(
                        message: 'Abrir carpeta de descargas',
                        child: IconButton(
                          onPressed: dl.openDownloadsFolder,
                          icon: const Icon(
                            Icons.folder_open_rounded,
                            size: UiTokens.iconHeaderAction,
                          ),
                          color: OneDarkPro.blueText,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: UiTokens.sizeHeaderAction,
                            minHeight: UiTokens.sizeHeaderAction,
                          ),
                        ),
                      ),
                      const SizedBox(width: UiTokens.spaceCluster),
                      Tooltip(
                        message: 'Limpiar terminadas',
                        child: IconButton(
                          onPressed: q.isEmpty ? null : dl.clearFinished,
                          icon: const Icon(
                            Icons.cleaning_services_rounded,
                            size: UiTokens.iconHeaderAction,
                          ),
                          // Deshabilitado apenas perceptible en vez de
                          // invisible: mantiene el patrón sin ruido.
                          disabledColor: OneDarkPro.fgDim.withValues(
                            alpha: 0.55,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: UiTokens.sizeHeaderAction,
                            minHeight: UiTokens.sizeHeaderAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (q.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(UiTokens.spaceBlock),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ExcludeSemantics(
                              child: EmptyIconTile(
                                icon: Icons.downloading_rounded,
                              ),
                            ),
                            SizedBox(height: UiTokens.spaceEmptyGap),
                            Text(
                              'La cola está vacía. Descarga cualquier resultado y aparecerá aquí con su progreso.',
                              textAlign: TextAlign.center,
                              style: AppText.secondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: UiTokens.spaceCard,
                        vertical: UiTokens.spaceInline,
                      ),
                      itemCount: q.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: UiTokens.spaceInline),
                      itemBuilder: (context, i) =>
                          _QueueTile(key: ValueKey(q[i].id), task: q[i]),
                    ),
                  ),
                if (q.isNotEmpty) ...[
                  const Divider(height: UiTokens.borderWidth),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      UiTokens.spaceCard,
                      UiTokens.spaceBadgeH,
                      UiTokens.spaceCard,
                      UiTokens.spaceInline,
                    ),
                    child: Tooltip(
                      message: dl.downloadDir.path,
                      child: Text(
                        dl.downloadDir.path,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.caption,
                      ),
                    ),
                  ),
                ],
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
  const _QueueTile({super.key, required this.task});

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
        statusColor = OneDarkPro.blueText;
        statusIcon = Icons.downloading_rounded;
        break;
      case DownloadStatus.completed:
        statusColor = OneDarkPro.greenText;
        statusIcon = Icons.check_circle_rounded;
        break;
      case DownloadStatus.failed:
        statusColor = OneDarkPro.redText;
        statusIcon = Icons.error_outline_rounded;
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(UiTokens.radiusControl),
      child: Stack(
        children: [
          Container(
            height: UiTokens.sizeRow,
            padding: const EdgeInsets.symmetric(
              horizontal: UiTokens.spaceItemH,
              vertical: UiTokens.spaceRowV,
            ),
            decoration: BoxDecoration(
              color: OneDarkPro.darker,
              borderRadius: BorderRadius.circular(UiTokens.radiusControl),
              border: Border.all(color: OneDarkPro.border),
            ),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: UiTokens.iconTileSidebar,
                  ),
                ),
                const SizedBox(width: UiTokens.spaceInline),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Tooltip(
                        message:
                            '${task.track.artistsLabel} — ${task.track.title}',
                        child: Text(
                          '${task.track.artistsLabel} — ${task.track.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.title,
                        ),
                      ),
                      const SizedBox(height: UiTokens.spaceTextGap),
                      Tooltip(
                        message: task.message,
                        child: Text(
                          task.message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: UiTokens.spaceBadgeH),
                if (task.status == DownloadStatus.failed)
                  Tooltip(
                    message: 'Reintentar',
                    child: IconButton(
                      onPressed: () => dl.retry(task),
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: OneDarkPro.yellow,
                        size: UiTokens.iconButton,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: UiTokens.sizeHeaderAction,
                        minHeight: UiTokens.sizeHeaderAction,
                      ),
                    ),
                  ),
                Tooltip(
                  message: 'Quitar de la cola',
                  child: IconButton(
                    onPressed: () => dl.remove(task.id),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: OneDarkPro.fgDim,
                      size: UiTokens.iconButton,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: UiTokens.sizeHeaderAction,
                      minHeight: UiTokens.sizeHeaderAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (task.status == DownloadStatus.downloading)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: LinearProgressIndicator(
                value: task.progress.clamp(0, 1),
                minHeight: UiTokens.sizeProgress,
                backgroundColor: OneDarkPro.border,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                semanticsLabel: '${task.track.title}: ${task.message}',
                semanticsValue:
                    '${(task.progress.clamp(0, 1) * 100).round()} por ciento',
              ),
            ),
        ],
      ),
    );
  }
}
