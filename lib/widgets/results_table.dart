import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/one_dark_pro.dart';
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: OneDarkPro.sidebar,
          borderRadius: BorderRadius.circular(12),
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
              padding: EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: EmptyIconTile(icon: Icons.search_rounded),
                  ),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      'Busca una canción, artista o álbum para ver resultados.',
                      textAlign: TextAlign.center,
                      style: AppText.secondary,
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: OneDarkPro.darker,
        border: Border(bottom: BorderSide(color: OneDarkPro.border)),
      ),
      child: const SizedBox(
        height: 24,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 44),
            SizedBox(width: 12),
            Expanded(flex: 3, child: _Header('TITULO / ARTISTA')),
            Expanded(flex: 3, child: _Header('ALBUM')),
            SizedBox(width: 70, child: _Header('DURACION')),
            SizedBox(
              width: 140,
              child: Align(
                alignment: Alignment.centerRight,
                child: _Header('ACCION'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowsList() {
    // Nota: ListView.separated no admite itemExtent; las filas igual
    // usan altura uniforme (64) y ValueKey para un diff barato.
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) {
        final t = tracks[i];
        final queued = queuedIds.contains(t.id);
        // Fila no interactiva: la única acción vive en el botón
        // "Descargar" (evita doble tab-stop y toques accidentales).
        return Container(
          key: ValueKey(t.id),
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: t.imageSmall.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: t.imageSmall,
                        width: 44,
                        height: 44,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => _coverFallback(),
                        errorWidget: (_, _, _) => _coverFallback(),
                      )
                    : _coverFallback(),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.title,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.artistsLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.secondary.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  t.album,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontSize: 12.5),
                ),
              ),
              SizedBox(
                width: 70,
                child: Text(t.durationLabel, style: AppText.secondary),
              ),
              SizedBox(
                width: 140,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: queued
                      ? Container(
                          width: 120,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: OneDarkPro.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: OneDarkPro.blue.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.check_circle_rounded,
                                  color: OneDarkPro.blueText,
                                  size: 16,
                                ),
                              ),
                              SizedBox(width: 6),
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
                      : SizedBox(
                          width: 120,
                          child: ElevatedButton.icon(
                            onPressed: () => onDownload(t),
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text(
                              'Descargar',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              minimumSize: const Size(0, 44),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
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
      width: 44,
      height: 44,
      color: OneDarkPro.darker,
      child: const ExcludeSemantics(
        child: Icon(
          Icons.music_note_rounded,
          color: OneDarkPro.fgDim,
          size: 20,
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
