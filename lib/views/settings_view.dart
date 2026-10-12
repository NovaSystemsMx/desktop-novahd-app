import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_log.dart';
import '../services/auth_store.dart';
import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';

/// Vista de Ajustes: autenticación, consola de sesión y espacio futuro.
class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final _cookiesCtrl = TextEditingController();
  final _scroll = ScrollController();
  int _seen = 0;
  bool _checking = false;
  String? _checkResult;
  bool _checkOk = false;
  bool? _storedOk;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Punto 7: al abrir, si hay guardadas se verifican solas.
    if (AuthStore.instance.hasStoredCookies) {
      Future.microtask(_silentStoredCheck);
    }
  }
  @override
  void dispose() {
    _cookiesCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _openLogin() async {
    // Flujo oficial de login para YouTube (estable, sin parámetros
    // de sesión capturados que caducan).
    const url = 'https://accounts.google.com/ServiceLogin'
        '?service=youtube&passive=true&continue=https://www.youtube.com/';
    try {
      // Abre el navegador predeterminado sin plugins extra.
      await Process.run('explorer', [url]);
    } catch (_) {
      try {
        await Process.run(
            'cmd', ['/c', 'start', '', url]);
      } catch (e) {
        AppLog.instance.error('Ajustes', 'No se pudo abrir el navegador');
      }
    }
  }

  // Punto 5: verifica SOLO las guardadas, con veredicto claro.
  // Punto 5: verifica SOLO las guardadas, con veredicto claro.
  // El texto solo aparece tras clic; el punto usa _storedOk siempre.
  Future<void> _verify() async {
    final auth = AuthStore.instance;
    if (!auth.hasStoredCookies) return;
    setState(() {
      _checking = true;
      _checkResult = null;
    });
    final r = await auth.checkStoredCookies();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkOk = r.ok;
      _storedOk = r.ok;
      _checkResult = 'done';
    });
    // El veredicto se oculta solo tras unos segundos (el punto queda).
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() => _checkResult = null);
    });
  }

  // Chequeo silencioso de entrada (punto 7): solo el punto.
  Future<void> _silentStoredCheck() async {
    final r = await AuthStore.instance.checkStoredCookies();
    if (!mounted) return;
    setState(() => _storedOk = r.ok);
  }


  // Punto 3: valida antes de guardar; si falla, restaura las previas.
  Future<void> _saveCookies() async {
    final auth = AuthStore.instance;
    setState(() => _saving = true);
    String? previous;
    try {
      previous = await auth.readStoredCookies();
      final saved = await auth.saveCookies(_cookiesCtrl.text);
      final r = await auth.checkStoredCookies();
      if (!r.ok) {
        if (previous == null || previous.isEmpty) {
          await auth.clearCookies();
        } else {
          await auth.saveCookies(previous);
        }
        throw Exception('No validas (${saved.saved} de ${saved.total}): ${r.detail}');
      }
      _cookiesCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardadas ${saved.saved} de ${saved.total} y validas.')),
      );
      setState(() => _storedOk = true);
      await _verify();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Punto 6: vista de solo lectura (deshabilitado si no hay).
  Future<void> _viewCookies() async {
    final text = await AuthStore.instance.readStoredCookies();
    if (!mounted || text == null || text.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: OneDarkPro.card,
        title: const Text('Cookies guardadas',
            style: TextStyle(color: OneDarkPro.white)),
        content: SizedBox(
          width: 520,
          height: 300,
          child: SingleChildScrollView(
            child: SelectableText(
              text,
              style: const TextStyle(
                  color: OneDarkPro.fg, fontSize: 11, fontFamily: 'Consolas'),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
  Future<void> _exportLog() async {
    final log = AppLog.instance;
    if (log.entries.isEmpty) return;
    final now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final name =
        'novahd-${now.year}${two(now.month)}${two(now.day)}.log';
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'log', extensions: ['log', 'txt']),
      ],
    );
    if (location == null) return;
    try {
      await File(location.path).writeAsString(log.exportText());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Log exportado.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo exportar: $e')),
      );
    }
  }

  void _followBottom(int count) {
    if (count == _seen) return;
    _seen = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('Ajustes',
                  style: TextStyle(
                      color: OneDarkPro.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 18),
          _section('AUTENTICACION YOUTUBE'),
          const SizedBox(height: 8),
          _card([
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Text(
                    'Si YouTube bloquea descargas, el pipeline usa tus cookies guardadas.',
                    style: TextStyle(
                        color: OneDarkPro.fgDim, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Consumer<AuthStore>(
                  builder: (context, authTop, _) => Tooltip(
                    message: !authTop.hasStoredCookies
                        ? 'Sin cookies guardadas.'
                        : _storedOk == null
                            ? 'Cookies guardadas, sin verificar.'
                            : _storedOk!
                                ? 'Cookies validas.'
                                : 'Cookies no validas.',
                    child: Icon(
                      Icons.cookie_rounded,
                      size: 20,
                      color: !authTop.hasStoredCookies || _storedOk == null
                          ? OneDarkPro.fgDim
                          : _storedOk!
                              ? OneDarkPro.green
                              : OneDarkPro.red,
                    ),
                  ),
                  ),
                ],
                ),
            Wrap(
              spacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: _openLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE62117),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.play_circle_fill_rounded,
                      size: 18),
                  label: const Text('Iniciar Sesion',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Consumer<AuthStore>(
              builder: (context, auth, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Paso 1: instala la extension GET COOKIES LOCALLY en tu navegador.' ,
                    style: TextStyle(
                        color: OneDarkPro.fg, fontSize: 12.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Paso 2: abre YouTube con tu sesion iniciada, copia las cookies y pegalas abajo.',
                    style: TextStyle(
                        color: OneDarkPro.fg, fontSize: 12.5),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _cookiesCtrl,
                    maxLines: 4,
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText:
                          'Pega aquí las cookies (formato Netscape, ej. de GET COOKIES LOCALLY)...',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed:
                            _saving ? null : _saveCookies,
                        icon: const Icon(Icons.save_rounded,
                            size: 16),
                        label: const Text('Guardar cookies',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed: auth.hasStoredCookies
                            ? () {
                                auth.clearCookies();
                                setState(() {
                                  _checkResult = null;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 16),
                        label: const Text('Borrar',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed: auth.hasStoredCookies
                            ? _viewCookies
                            : null,
                        icon: const Icon(Icons.visibility_rounded,
                            size: 16),
                        label: const Text('Ver',
                            style: TextStyle(fontSize: 12)),
                      ),
                      OutlinedButton.icon(
                        onPressed:
                            _checking || !auth.hasStoredCookies ? null : _verify,
                        icon: const Icon(Icons.verified_rounded,
                            size: 16),
                        label: const Text('Verificar',
                            style: TextStyle(fontSize: 12)),
                      ),
                      if (_checking)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2),
                        ),
                      if (_checkResult != null)
                        Text(
                          _checkOk ? 'Cookies validas.' : 'Cookies invalidas.',
                          style: TextStyle(
                              color: _checkOk
                                  ? OneDarkPro.green
                                  : OneDarkPro.red,
                              fontSize: 12),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Consumer<DownloaderService>(
                    builder: (context, dl, _) => Text(
                      'Último uso: ${dl.lastAuthLabel}'
                      '${dl.lastAuthOk ? ' · funcionó' : ''}',
                      style: const TextStyle(
                          color: OneDarkPro.fgDim, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _section('CONSOLA DE SESIÓN'),
          const SizedBox(height: 8),
          _card([
            Row(
              children: [
                const Spacer(),
                Tooltip(
                  message: 'Limpiar consola',
                  child: IconButton(
                    onPressed: AppLog.instance.clear,
                    icon: const Icon(
                        Icons.cleaning_services_rounded,
                        size: 18),
                    color: OneDarkPro.fgDim,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                ),
                Tooltip(
                  message: 'Exportar log (novahd-YYYYMMDD.log)',
                  child: IconButton(
                    onPressed: _exportLog,
                    icon: const Icon(Icons.download_rounded,
                        size: 18),
                    color: OneDarkPro.blue,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 28, minHeight: 28),
                  ),
                ),
              ],
            ),
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: OneDarkPro.darker,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: OneDarkPro.border),
              ),
              child: Consumer<AppLog>(
                builder: (context, log, _) {
                  _followBottom(log.entries.length);
                  if (log.entries.isEmpty) {
                    return const Center(
                      child: Text(
                        'Sin eventos en esta sesión.',
                        style: TextStyle(
                            color: OneDarkPro.fgDim,
                            fontSize: 12),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(10),
                    itemCount: log.entries.length,
                    itemBuilder: (context, i) {
                      final e = log.entries[i];
                      final color = switch (e.level) {
                        LogLevel.error => OneDarkPro.red,
                        LogLevel.warning => OneDarkPro.yellow,
                        LogLevel.info => OneDarkPro.fgDim,
                      };
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 1.5),
                        child: SelectableText(
                          e.line,
                          style: TextStyle(
                              color: color,
                              fontSize: 11.5,
                              fontFamily: 'Consolas'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ]),
          const SizedBox(height: 18),
          _section('CONFIGURACIÓN'),
          const SizedBox(height: 8),
          _card(const [
            Text(
              'Próximamente: carpeta destino, calidad y concurrencia.',
              style:
                  TextStyle(color: OneDarkPro.fgDim, fontSize: 12),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _section(String text) {
    return Text(text,
        style: const TextStyle(
            color: OneDarkPro.fgDim,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OneDarkPro.sidebar,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: OneDarkPro.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

