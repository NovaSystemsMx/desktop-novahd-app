import 'package:flutter/material.dart';

import '../models/track.dart';
import '../theme/one_dark_pro.dart';

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
              padding: EdgeInsets.all(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_rounded, color: OneDarkPro.fgDim),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Busca una cancion, artista o album para ver resultados.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: OneDarkPro.fgDim),
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
    return ListView.separated(
      itemCount: tracks.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, indent: 16, endIndent: 16),
      itemBuilder: (context, i) {
        final t = tracks[i];
        final queued = queuedIds.contains(t.id);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            hoverColor: OneDarkPro.cardHover,
            onTap: queued ? null : () => onDownload(t),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: t.imageSmall.isNotEmpty
                        ? Image.network(t.imageSmall,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => _coverFallback())
                        : _coverFallback(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: OneDarkPro.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13.5)),
                        const SizedBox(height: 2),
                        Text(t.artistsLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: OneDarkPro.fgDim, fontSize: 12)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(t.album,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: OneDarkPro.fg, fontSize: 12.5)),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(t.durationLabel,
                        style: const TextStyle(
                            color: OneDarkPro.fgDim, fontSize: 12.5)),
                  ),
                  SizedBox(
                    width: 140,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: queued
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: OneDarkPro.blue
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: OneDarkPro.blue
                                        .withValues(alpha: 0.4)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      color: OneDarkPro.blue, size: 16),
                                  SizedBox(width: 6),
                                  Text('En cola',
                                      style: TextStyle(
                                          color: OneDarkPro.blue,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => onDownload(t),
                              icon: const Icon(Icons.download_rounded,
                                  size: 16),
                              label: const Text('Descargar',
                                  style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 14),
                                minimumSize: const Size(0, 44),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
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
      child: const Icon(Icons.music_note_rounded,
          color: OneDarkPro.fgDim, size: 20),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: OneDarkPro.fgDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }
}
