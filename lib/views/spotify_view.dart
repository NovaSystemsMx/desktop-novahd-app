import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/downloader_service.dart';
import '../services/music_search_service.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';
import '../widgets/download_queue_panel.dart';
import '../widgets/results_table.dart';

/// Vista principal del downloader de Spotify:
/// buscador + tabla de resultados + cola de descargas.
class SpotifyView extends StatefulWidget {
  const SpotifyView({super.key});

  @override
  State<SpotifyView> createState() => _SpotifyViewState();
}

class _SpotifyViewState extends State<SpotifyView> {
  final _controller = TextEditingController();
  final _errorFocus = FocusNode();
  List<Track> _results = [];
  bool _searching = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    _errorFocus.dispose();
    super.dispose();
  }

  /// Una sola fase: espera la data completa (álbum, duración, carátula)
  /// y pinta la tabla una vez, como el proyecto Python.
  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty || _searching) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final tracks = await context.read<MusicSearchService>().search(q);
      if (!mounted) return;
      setState(() {
        _results = tracks;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _searching = false;
      });
      // Lleva el foco al error para que el teclado/lector lo encuentren.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _errorFocus.requestFocus();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: UiTokens.paddingPage,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: UiTokens.sizeTileView,
                height: UiTokens.sizeTileView,
                decoration: BoxDecoration(
                  color: OneDarkPro.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(UiTokens.radiusCard),
                ),
                child: const ExcludeSemantics(
                  child: Icon(
                    Icons.music_note_rounded,
                    color: OneDarkPro.blueText,
                    size: UiTokens.iconTileView,
                  ),
                ),
              ),
              const SizedBox(width: UiTokens.spaceHeaderGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spotify Downloader', style: AppText.hero),
                    Text(
                      'MP3 con carátula y etiquetas ID3',
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.spaceBlock),
          // Buscador
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: UiTokens.sizeControl,
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _search(),
                    textInputAction: TextInputAction.search,
                    style: AppText.input,
                    decoration: const InputDecoration(
                      hintText: 'Busca una canción, artista o álbum…',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: UiTokens.iconInline,
                      ),
                      prefixIconConstraints: BoxConstraints(
                        minWidth: UiTokens.sizeControl,
                        minHeight: UiTokens.sizeControl,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: UiTokens.spaceControlGap),
              SizedBox(
                height: UiTokens.sizeButton,
                child: Tooltip(
                  message: 'Buscar (Enter)',
                  child: ElevatedButton.icon(
                    onPressed: _searching ? null : _search,
                    icon: _searching
                        ? Semantics(
                            liveRegion: true,
                            label: 'Buscando',
                            child: const SizedBox(
                              width: UiTokens.iconButton,
                              height: UiTokens.iconButton,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: OneDarkPro.blueText,
                              ),
                            ),
                          )
                        : const Icon(
                            Icons.search_rounded,
                            size: UiTokens.iconButton,
                          ),
                    label: const Text('Buscar'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.spaceBlock),
          if (_error != null)
            Focus(
              focusNode: _errorFocus,
              child: Builder(
                builder: (context) {
                  final hasFocus = Focus.of(context).hasFocus;
                  return Semantics(
                    container: true,
                    liveRegion: true,
                    label: 'Error de búsqueda: $_error',
                    child: Container(
                      padding: const EdgeInsets.all(UiTokens.spaceItemH),
                      decoration: BoxDecoration(
                        color: OneDarkPro.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          UiTokens.radiusControl,
                        ),
                        border: Border.all(
                          color: hasFocus
                              ? OneDarkPro.blueText
                              : OneDarkPro.red.withValues(alpha: 0.4),
                          width: hasFocus
                              ? UiTokens.borderFocus
                              : UiTokens.borderWidth,
                        ),
                      ),
                      child: Row(
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: OneDarkPro.redText,
                              size: UiTokens.iconInline,
                            ),
                          ),
                          const SizedBox(width: UiTokens.spaceInline),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppText.secondary.copyWith(
                                color: OneDarkPro.redText,
                              ),
                            ),
                          ),
                          const SizedBox(width: UiTokens.spaceInline),
                          TextButton.icon(
                            onPressed: _searching ? null : _search,
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: UiTokens.iconButton,
                            ),
                            label: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_error != null) const SizedBox(height: UiTokens.spaceEmptyGap),
          // Resultados a la izquierda, cola a la derecha.
          // En ventanas estrechas se apilan para no comprimir la tabla.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final results = Selector<DownloaderService, String>(
                  selector: (_, dl) => dl.queueFingerprint,
                  builder: (context, _, _) => ResultsTable(
                    tracks: _results,
                    queuedIds: context.read<DownloaderService>().queuedIds,
                    onDownload: (track) {
                      context.read<DownloaderService>().enqueue(track);
                    },
                  ),
                );
                if (constraints.maxWidth < UiTokens.stackBelow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 1, child: results),
                      const SizedBox(height: UiTokens.spaceBlock),
                      const Expanded(flex: 1, child: DownloadQueuePanel()),
                    ],
                  );
                }
                final queueWidth =
                    constraints.maxWidth >= UiTokens.queueWideFrom
                    ? UiTokens.queueWide
                    : UiTokens.queueNarrow;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Solo se reconstruye si cambia la membresía de la cola
                    // (huella de ids+estados), no con cada tick de progreso.
                    Expanded(child: results),
                    const SizedBox(width: UiTokens.spaceBlock),
                    SizedBox(
                      width: queueWidth,
                      child: const DownloadQueuePanel(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
