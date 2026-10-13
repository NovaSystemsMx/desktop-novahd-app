import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Autenticación anti-bot sin archivos sueltos.
///
/// Las cookies pegadas (solo las necesarias) se guardan cifradas y se
/// materializan a un temporal solo durante la descarga.
class AuthStore extends ChangeNotifier {
  AuthStore._();

  /// Instancia compartida (lógica sin contexto + UI reactiva vía provider).
  static final AuthStore instance = AuthStore._();

  static const _cookiesKey = 'novahd.auth.cookies';

  static const storage = FlutterSecureStorage();

  bool hasStoredCookies = false;

  Future<void> load() async {
    hasStoredCookies =
        (await storage.read(key: _cookiesKey))?.isNotEmpty ?? false;
    notifyListeners();
  }
  /// Lee las cookies guardadas (para vista de solo lectura).
  Future<String?> readStoredCookies() =>
      storage.read(key: _cookiesKey);

  /// Numero de cookies guardadas (para mostrar el filtrado).
  Future<int> storedCount() async {
    final text = await storage.read(key: _cookiesKey);
    if (text == null || text.isEmpty) return 0;
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && !l.startsWith('#') )
        .length;
  }
  /// Nombres que yt-dlp necesita (sesion + preferencias). Todo lo
  /// demas (analitica, rollout, tokens de sesion unica) se descarta.
  static const neededCookies = {
    'SID', 'HSID', 'SSID', 'APISID', 'SAPISID', 'LOGIN_INFO', 'PREF', 'YSC',
    'SIDCC', 'VISITOR_INFO1_LIVE', '__Secure-1PSID', '__Secure-3PSID',
    '__Secure-1PAPISID', '__Secure-3PAPISID', '__Secure-1PSIDCC', '__Secure-3PSIDCC',
  };

  /// Guarda solo las cookies necesarias. Devuelve (guardadas, pegadas).
  /// Reemplaza las anteriores.
  Future<({int saved, int total})> saveCookies(String text) async {
    final cleaned = text.trim();
    if (cleaned.isEmpty) throw Exception('Pega el contenido primero.');
    final kept = <String>[];
    var total = 0;
    for (final raw in cleaned.split('\n')) {
      final l = raw.trim();
      if (l.isEmpty || l.startsWith('#') ) continue;
      final cols = l.split('\t');
      if (cols.length < 6) {
        throw Exception('Formato invalido: se espera Netscape (tabulado).');
      }
      total++;
      if (neededCookies.contains(cols[5])) kept.add(l);
    }
    if (kept.isEmpty) throw Exception('Ninguna cookie util encontrada.');
    await storage.write(key: _cookiesKey, value: kept.join('\n'));
    hasStoredCookies = true;
    notifyListeners();
    return (saved: kept.length, total: total);
  }

  Future<void> clearCookies() async {
    await storage.delete(key: _cookiesKey);
    hasStoredCookies = false;
    notifyListeners();
  }

  /// Materializa las cookies a un temporal para `--cookiefile`.
  /// El llamador debe borrarlo con [discardCookieFile].
  Future<File?> materializeCookieFile() async {
    final text = await storage.read(key: _cookiesKey);
    if (text == null || text.isEmpty) return null;
    final dir = await Directory.systemTemp.createTemp('novahd_cookies');
    final file = File('${dir.path}\\cookies.txt');
    await file.writeAsString(text, flush: true);
    return file;
  }

  Future<void> discardCookieFile(File? file) async {
    if (file == null) return;
    try {
      final dir = file.parent;
      if (await file.exists()) await file.delete();
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  /// Pares `nombre=valor` del formato Netscape para cabecera Cookie.
  static String cookieHeader(String text) {
    final pairs = <String>[];
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final cols = t.split('\t');
      if (cols.length >= 7 && cols[5].isNotEmpty) {
        pairs.add('${cols[5]}=${cols[6]}');
      }
    }
    return pairs.join('; ');
  }

  /// Mayor expiración (epoch, col 5) de las cookies guardadas, si hay.
  Future<DateTime?> storedExpiry() async {
    final text = await storage.read(key: _cookiesKey);
    if (text == null || text.isEmpty) return null;
    var max = 0;
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#')) continue;
      final cols = t.split('\t');
      if (cols.length >= 7) {
        final exp = int.tryParse(cols[4].trim()) ?? 0;
        if (exp > max) max = exp;
      }
    }
    if (max <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(max * 1000);
  }

  /// Valida las cookies guardadas SIN llamar a endpoints con login
  /// (el menu de cuenta ignora la sesion via API; probado con sesion real).
  /// Revisa formato Netscape, cookies de sesion presentes y expiraciones.
  /// La validez final se confirma al descargar (ver Ultimo uso).
  /// Devuelve (ok, detalle).
  Future<({bool ok, String detail})> checkStoredCookies() async {
    final text = await storage.read(key: _cookiesKey);
    if (text == null || text.isEmpty) {
      return (ok: false, detail: 'Sin cookies guardadas.');
    }
    final names = <String>{};
    var maxExp = 0;
    var rows = 0;
    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.isEmpty || t.startsWith('#') ) continue;
      final cols = t.split('\t');
      if (cols.length < 7) {
        return (ok: false, detail: 'Formato invalido en una linea.');
      }
      rows++;
      names.add(cols[5]);
      final exp = int.tryParse(cols[4].trim()) ?? 0;
      if (exp > maxExp) maxExp = exp;
    }
    if (rows == 0) return (ok: false, detail: 'Sin cookies guardadas.');
    const session = {'SID', 'HSID', 'SSID', 'APISID', 'LOGIN_INFO'};
    final missing = session.where((s) => !names.contains(s)).toList();
    if (missing.isNotEmpty) {
      return (ok: false, detail: 'Faltan: ${missing.join(', ')}');
    }
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (maxExp > 0 && maxExp < nowSec) {
      return (ok: false, detail: 'Expiradas. Pega unas nuevas.');
    }
    final expStr = maxExp <= 0
        ? ''
        : ' vigentes hasta ${_shortDate(DateTime.fromMillisecondsSinceEpoch(maxExp * 1000))}';
    return (ok: true, detail: 'Formato valido, $rows cookies$expStr.');
  }

  static String _shortDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
