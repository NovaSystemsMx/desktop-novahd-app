import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

/// Etiquetado ID3v2.3 de MP3 (equivale a `mutagen` en el pipeline Python).
///
/// Escribe título (TIT2), artista (TPE1), álbum (TALB) y carátula (APIC),
/// con texto en UTF-16 (máxima compatibilidad con reproductores Windows).
/// Elimina cualquier etiqueta ID3 previa para que el resultado sea
/// determinista.
class AudioTagger {
  /// Descarga la primera carátula válida de la lista de candidatas
  /// (ordenadas de mayor a menor calidad esperada).
  /// Devuelve null si ninguna responde con imagen válida.
  static Future<Uint8List?> downloadCovers(List<String> urls) async {
    // WebP al final: mal soporte como APIC en reproductores.
    final ordered = [...urls]
      ..sort((a, b) {
        final wa = a.toLowerCase().contains('webp') ? 1 : 0;
        final wb = b.toLowerCase().contains('webp') ? 1 : 0;
        return wa.compareTo(wb);
      });
    for (final url in ordered) {
      if (url.isEmpty) continue;
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 20));
        if (res.statusCode == 200 && res.bodyBytes.length > 512) {
          return res.bodyBytes;
        }
      } catch (_) {}
    }
    return null;
  }

  /// Descarga la carátula probando [primary] y luego [fallback].
  /// Devuelve null si ninguna responde con imagen válida.
  static Future<Uint8List?> downloadCover(String primary,
          {String fallback = ''}) =>
      downloadCovers([primary, fallback]);

  /// Escribe las etiquetas en [mp3Path] junto con [coverBytes].
  static Future<void> writeTags({
    required String mp3Path,
    required String title,
    required String artist,
    required String album,
    required Uint8List coverBytes,
  }) async {
    final file = File(mp3Path);
    final original = await file.readAsBytes();
    final audio = _stripExistingId3(original);
    final tag = _buildId3v23(
      title: title,
      artist: artist,
      album: album,
      cover: coverBytes,
    );
    await file.writeAsBytes([...tag, ...audio], flush: true);
  }

  /// Quita la etiqueta ID3v2 previa (si existe) para reescribirla limpia.
  static Uint8List _stripExistingId3(Uint8List bytes) {
    if (bytes.length > 10 &&
        bytes[0] == 0x49 && // I
        bytes[1] == 0x44 && // D
        bytes[2] == 0x33) {
      // 3
      final size = _decodeSyncsafe(bytes, 6);
      final total = 10 + size;
      if (total > 0 && total < bytes.length) {
        return bytes.sublist(total);
      }
    }
    return bytes;
  }

  static Uint8List _buildId3v23({
    required String title,
    required String artist,
    required String album,
    required Uint8List cover,
  }) {
    final frames = <int>[];
    frames.addAll(_textFrame('TIT2', title));
    frames.addAll(_textFrame('TPE1', artist));
    frames.addAll(_textFrame('TALB', album));
    if (cover.isNotEmpty) {
      frames.addAll(_apicFrame(cover));
    }
    final header = <int>[
      0x49, 0x44, 0x33, // "ID3"
      0x03, 0x00, // versión 2.3.0
      0x00, // flags
      ..._encodeSyncsafe(frames.length),
    ];
    return Uint8List.fromList([...header, ...frames]);
  }

  /// Frame de texto con codificación UTF-16 + BOM (0x01).
  static List<int> _textFrame(String id, String value) {
    final payload = <int>[0x01, 0xFF, 0xFE, ..._utf16le(value)];
    return _frame(id, payload);
  }

  /// Frame APIC (carátula frontal). Detecta JPEG/PNG por magic bytes.
  static List<int> _apicFrame(Uint8List image) {
    final isPng = image.length > 4 &&
        image[0] == 0x89 &&
        image[1] == 0x50 &&
        image[2] == 0x4E &&
        image[3] == 0x47;
    final mime = isPng ? 'image/png' : 'image/jpeg';
    final payload = <int>[
      0x00, // encoding latin-1 para los campos de texto del APIC
      ...mime.codeUnits,
      0x00,
      0x03, // tipo: portada frontal
      0x00, // descripción vacía
      ...image,
    ];
    return _frame('APIC', payload);
  }

  static List<int> _frame(String id, List<int> payload) {
    assert(id.length == 4);
    final size = payload.length;
    return [
      ...id.codeUnits,
      (size >> 24) & 0xFF,
      (size >> 16) & 0xFF,
      (size >> 8) & 0xFF,
      size & 0xFF,
      0x00,
      0x00, // flags
      ...payload,
    ];
  }

  static List<int> _utf16le(String s) {
    final out = <int>[];
    for (final unit in s.codeUnits) {
      out.add(unit & 0xFF);
      out.add((unit >> 8) & 0xFF);
    }
    return out;
  }

  static List<int> _encodeSyncsafe(int size) => [
        (size >> 21) & 0x7F,
        (size >> 14) & 0x7F,
        (size >> 7) & 0x7F,
        size & 0x7F,
      ];

  static int _decodeSyncsafe(Uint8List bytes, int offset) =>
      ((bytes[offset] & 0x7F) << 21) |
      ((bytes[offset + 1] & 0x7F) << 14) |
      ((bytes[offset + 2] & 0x7F) << 7) |
      (bytes[offset + 3] & 0x7F);
}
