import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/track.dart';
import '../services/downloader_service.dart';
import '../services/spotify_service.dart';
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
  List<Track> _results = [];
  bool _searching = false;
  String? _error;
  bool _hasSearched = false;

  @override
  void dispose() {
    _controller.dispose();
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
      final tracks = await context.read<SpotifyService>().search(q);
      if (!mounted) return;
      setState(() {
        _results = tracks;
        _hasSearched = true;
        _searching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _hasSearched = true;
        _searching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final downloader = context.watch<DownloaderService>();
    final queuedIds = downloader.queue.map((t) => t.track.id).toSet();

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
                  color: OneDarkPro.spotify.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.music_note_rounded,
                    color: OneDarkPro.spotify),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spotify Downloader',
                        style: TextStyle(
                            color: OneDarkPro.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    Text('MP3 con caratula y etiquetas ID3',
                        style: TextStyle(
                            color: OneDarkPro.fgDim, fontSize: 12)),
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
                  decoration: const InputDecoration(
                    hintText: 'Busca canción, artista o álbum…',
                    prefixIcon: Icon(Icons.search_rounded),
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
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black87))
                        : const Icon(Icons.search_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: OneDarkPro.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: OneDarkPro.red.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: OneDarkPro.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(
                            color: OneDarkPro.red, fontSize: 12.5)),
                  ),
                ],
              ),
            ),
          if (_error != null) const SizedBox(height: 12),
          // Resultados a la izquierda, cola a la derecha.
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ResultsTable(
                    tracks: _results,
                    queuedIds: queuedIds,
                    onDownload: (track) {
                      context.read<DownloaderService>().enqueue(track);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                const SizedBox(
                  width: 360,
                  child: DownloadQueuePanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
