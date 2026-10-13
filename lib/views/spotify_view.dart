import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/downloader_service.dart';
import '../services/music_search_service.dart';
import '../theme/one_dark_pro.dart';
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
  bool _searched = false;
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
        _searched = true;
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
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: OneDarkPro.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ExcludeSemantics(
                  child: Icon(Icons.music_note_rounded, color: OneDarkPro.blue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spotify Downloader', style: AppText.hero),
                    Text(
                      'MP3 con caratula y etiquetas ID3',
                      style: AppText.secondary.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Buscador
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _search(),
                  textInputAction: TextInputAction.search,
                  style: AppText.input,
                  decoration: InputDecoration(
                    labelText: 'Buscar en Spotify',
                    hintText: 'Busca canción, artista o álbum…',
                    hintStyle: AppText.secondary.copyWith(fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 48,
                child: Tooltip(
                  message: 'Buscar (Enter)',
                  child: ElevatedButton(
                    onPressed: _searching ? null : _search,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: _searching
                        ? Semantics(
                            liveRegion: true,
                            label: 'Buscando',
                            child: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: OneDarkPro.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: OneDarkPro.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasFocus
                              ? OneDarkPro.blueText
                              : OneDarkPro.red.withValues(alpha: 0.4),
                          width: hasFocus ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const ExcludeSemantics(
                            child: Icon(
                              Icons.error_outline_rounded,
                              color: OneDarkPro.redText,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _error!,
                              style: AppText.body.copyWith(
                                color: OneDarkPro.redText,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _searching ? null : _search,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text(
                              'Reintentar',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          if (_error != null) const SizedBox(height: 12),
          // Resultados a la izquierda, cola a la derecha.
          // En ventanas estrechas se apilan para no comprimir la tabla.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final searched = _searched;
                final query = _controller.text.trim();
                final results = Selector<DownloaderService, String>(
                  // La huella incluye el flag local para repintar el
                  // estado vacío tras buscar (no solo con la cola).
                  selector: (_, dl) => '${dl.queueFingerprint}|$searched',
                  builder: (context, _, _) => ResultsTable(
                    tracks: _results,
                    queuedIds: context.read<DownloaderService>().queuedIds,
                    onDownload: (track) {
                      context.read<DownloaderService>().enqueue(track);
                    },
                    searched: searched,
                    lastQuery: query,
                  ),
                );
                const queue = SizedBox(width: 360, child: DownloadQueuePanel());
                if (constraints.maxWidth < 860) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: results),
                      const SizedBox(height: 16),
                      const SizedBox(height: 260, child: DownloadQueuePanel()),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Solo se reconstruye si cambia la membresía de la cola
                    // (huella de ids+estados), no con cada tick de progreso.
                    Expanded(child: results),
                    const SizedBox(width: 16),
                    queue,
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
