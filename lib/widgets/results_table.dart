import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';
import 'empty_icon_tile.dart';

/// Tabla de resultados de búsqueda.
/// La cabecera queda fija arriba; solo las filas hacen scroll.
/// Sin resultados ocupa todo el alto disponible con la cabecera visible.
class ResultsTable extends StatelessWidget {
  final List<Track> tracks;
  final Set<String> queuedIds;
  final ValueChanged<Track> onDownload;

  const ResultsTable({
    super.key,
    required this.tracks,
    required this.queuedIds,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(UiTokens.radiusCard),
      child: Container(
        decoration: BoxDecoration(
          color: OneDarkPro.sidebar,
          borderRadius: BorderRadius.circular(UiTokens.radiusCard),
          border: Border.all(color: OneDarkPro.border),
        ),
        child: tracks.isEmpty ? _emptyBody() : _fullBody(),
      ),
    );
  }

  Widget _emptyBody() {
    return Column(
      children: [
        _tableHeader(),
        const Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(UiTokens.spaceBlock),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: EmptyIconTile(icon: Icons.search_rounded),
                  ),
                  SizedBox(height: UiTokens.spaceEmptyGap),
                  Text(
                    'Busca una canción, artista o álbum para ver resultados.',
                    textAlign: TextAlign.center,
                    style: AppText.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fullBody() {
    return Column(
      children: [
        _tableHeader(),
        Expanded(child: _rowsList()),
      ],
    );
  }

  Widget _tableHeader() {
    return Container(
      height: UiTokens.sizeCardHeader,
      padding: UiTokens.paddingCardHeader,
      decoration: const BoxDecoration(
        color: OneDarkPro.darker,
        border: Border(bottom: BorderSide(color: OneDarkPro.border)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: UiTokens.colCover),
          SizedBox(width: UiTokens.colCoverGap),
          Expanded(flex: 3, child: _Header('CANCIÓN')),
          Expanded(flex: 3, child: _Header('ÁLBUM')),
          SizedBox(width: UiTokens.colDuration, child: _Header('DURACIÓN')),
          SizedBox(
            width: UiTokens.colAction,
            child: Align(
              alignment: Alignment.centerRight,
              child: _Header('ACCIÓN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowsList() {
    // Nota: ListView.separated no admite itemExtent; las filas igual
    // usan altura uniforme (64) y ValueKey para un diff barato.
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) => const Divider(
        height: UiTokens.borderWidth,
        indent: UiTokens.spaceRowH,
        endIndent: UiTokens.spaceRowH,
      ),
      itemBuilder: (context, i) {
        final t = tracks[i];
        final queued = queuedIds.contains(t.id);
        // Fila no interactiva: la única acción vive en el botón
        // "Descargar" (evita doble tab-stop y toques accidentales).
        return Container(
          key: ValueKey(t.id),
          height: UiTokens.sizeRow,
          color: Colors.transparent,
          padding: UiTokens.paddingRow,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(UiTokens.radiusControl),
                child: t.imageSmall.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: t.imageSmall,
                        width: UiTokens.colCover,
                        height: UiTokens.colCover,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _coverFallback(),
                        errorWidget: (_, _, _) => _coverFallback(),
                      )
                    : _coverFallback(),
              ),
              const SizedBox(width: UiTokens.colCoverGap),
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: t.title,
                      child: Text(
                        t.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title,
                      ),
                    ),
                    const SizedBox(height: UiTokens.spaceTextGap),
                    Tooltip(
                      message: t.artistsLabel,
                      child: Text(
                        t.artistsLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Tooltip(
                  message: t.album,
                  child: Text(
                    t.album,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body,
                  ),
                ),
              ),
              SizedBox(
                width: UiTokens.colDuration,
                child: Text(t.durationLabel, style: AppText.body),
              ),
              SizedBox(
                width: UiTokens.colAction,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: queued
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: UiTokens.spaceItemH,
                            vertical: UiTokens.spaceControlV,
                          ),
                          decoration: BoxDecoration(
                            color: OneDarkPro.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(
                              UiTokens.radiusControl,
                            ),
                            border: Border.all(
                              color: OneDarkPro.blue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ExcludeSemantics(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: OneDarkPro.blueText,
                                  size: UiTokens.iconButton,
                                ),
                              ),
                              const SizedBox(width: UiTokens.spaceBadgeH),
                              Text(
                                'En cola',
                                style: AppText.body.copyWith(
                                  color: OneDarkPro.blueText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => onDownload(t),
                          icon: const Icon(
                            Icons.download_rounded,
                            size: UiTokens.iconButton,
                          ),
                          label: const Text('Descargar'),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _coverFallback() {
    return Container(
      width: UiTokens.colCover,
      height: UiTokens.colCover,
      color: OneDarkPro.darker,
      child: const ExcludeSemantics(
        child: Icon(
          Icons.music_note_rounded,
          color: OneDarkPro.fgDim,
          size: UiTokens.iconTileView,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppText.caps,
    );
  }
}
