import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_log.dart';
import '../services/auth_store.dart';
import '../services/downloader_service.dart';
import '../theme/one_dark_pro.dart';
import '../theme/ui_tokens.dart';

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
  String? _saveError;

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
    const url =
        'https://accounts.google.com/ServiceLogin'
        '?service=youtube&passive=true&continue=https://www.youtube.com/';
    try {
      // Abre el navegador predeterminado sin plugins extra.
      await Process.run('explorer', [url]);
    } catch (_) {
      try {
        await Process.run('cmd', ['/c', 'start', '', url]);
      } catch (_) {
        AppLog.instance.error('Ajustes', 'No se pudo abrir el navegador');
      }
    }
  }

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
    setState(() {
      _saving = true;
      _saveError = null;
    });
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
        throw Exception(
          'No válidas (${saved.saved} de ${saved.total}): ${r.detail}',
        );
      }
      _cookiesCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guardadas ${saved.saved} de ${saved.total} y válidas.',
          ),
        ),
      );
      setState(() => _storedOk = true);
      await _verify();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _saveError = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        titlePadding: const EdgeInsets.fromLTRB(
          UiTokens.spacePage,
          UiTokens.spacePage,
          UiTokens.spacePage,
          0,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          UiTokens.spacePage,
          UiTokens.spaceEmptyGap,
          UiTokens.spacePage,
          0,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          UiTokens.spacePage,
          0,
          UiTokens.spacePage,
          UiTokens.spaceCard,
        ),
        title: const Text('Cookies guardadas'),
        content: SizedBox(
          width: UiTokens.sizeDialogW,
          height: UiTokens.sizeDialogH,
          child: SingleChildScrollView(
            child: SelectableText(text, style: AppText.mono),
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
    final name = 'novahd-${now.year}${two(now.month)}${two(now.day)}.log';
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Log exportado.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('No se pudo exportar: $e')));
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
                    Icons.settings_rounded,
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
                    Text('Ajustes', style: AppText.hero),
                    Text(
                      'Sesión, descargas y consola',
                      style: AppText.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.spaceBlock),
          _cardWithHeader(
            title: 'AUTENTICACIÓN YOUTUBE',
            trailing: Consumer2<AuthStore, DownloaderService>(
              builder: (context, authTop, dl, _) {
                final base = !authTop.hasStoredCookies
                    ? 'Sin cookies guardadas.'
                    : _storedOk == null
                    ? 'Cookies guardadas, sin verificar.'
                    : _storedOk!
                    ? 'Cookies válidas.'
                    : 'Cookies no válidas.';
                return Tooltip(
                  message: '$base Último uso: ${dl.lastAuthLabel}.',
                  child: Icon(
                    Icons.cookie_rounded,
                    size: UiTokens.iconTileView,
                    color: !authTop.hasStoredCookies || _storedOk == null
                        ? OneDarkPro.fgDim
                        : _storedOk!
                        ? OneDarkPro.greenText
                        : OneDarkPro.redText,
                  ),
                );
              },
            ),
            children: [
              Consumer<AuthStore>(
                builder: (context, auth, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Paso 1: instala la extensión GET COOKIES LOCALLY en tu navegador.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: UiTokens.spaceInline),
                    Text(
                      'Paso 2: abre YouTube con tu sesión iniciada.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: UiTokens.spaceItemH),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: _openLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OneDarkPro.buttonRed,
                          foregroundColor: OneDarkPro.darker,
                        ),
                        icon: const Icon(
                          Icons.play_circle_fill_rounded,
                          size: UiTokens.iconButton,
                        ),
                        label: const Text('Abrir YouTube para iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: UiTokens.spaceInline),
                    Text(
                      'Paso 3: copia las cookies y pégalas abajo.',
                      style: AppText.body,
                    ),
                    const SizedBox(height: UiTokens.spaceItemH),
                    const Text(
                      'COOKIES (FORMATO NETSCAPE)',
                      style: AppText.caps,
                    ),
                    const SizedBox(height: UiTokens.spaceInline),
                    TextField(
                      controller: _cookiesCtrl,
                      maxLines: 4,
                      minLines: 3,
                      style: AppText.input,
                      decoration: const InputDecoration(
                        hintText: 'Pega aquí las cookies exportadas por GET COOKIES LOCALLY…',
                      ),
                    ),
                    const SizedBox(height: UiTokens.spaceInline),
                    if (_saveError != null)
                      Semantics(
                        container: true,
                        liveRegion: true,
                        label: 'Error al guardar cookies: $_saveError',
                        child: Container(
                          margin: const EdgeInsets.only(
                            bottom: UiTokens.spaceInline,
                          ),
                          padding: const EdgeInsets.all(UiTokens.spaceItemH),
                          decoration: BoxDecoration(
                            color: OneDarkPro.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              UiTokens.radiusControl,
                            ),
                            border: Border.all(
                              color: OneDarkPro.red.withValues(alpha: 0.4),
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
                                  _saveError!,
                                  style: AppText.secondary.copyWith(
                                    color: OneDarkPro.redText,
                                  ),
                                ),
                              ),
                              const SizedBox(width: UiTokens.spaceInline),
                              TextButton.icon(
                                onPressed: _saving ? null : _saveCookies,
                                icon: const Icon(
                                  Icons.refresh_rounded,
                                  size: UiTokens.iconButton,
                                ),
                                label: const Text('Reintentar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Wrap(
                      spacing: UiTokens.spaceControlGap,
                      runSpacing: UiTokens.spaceInline,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _saving ? null : _saveCookies,
                          icon: const Icon(
                            Icons.save_rounded,
                            size: UiTokens.iconButton,
                          ),
                          label: const Text('Guardar cookies'),
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
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: UiTokens.iconButton,
                          ),
                          label: const Text('Borrar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: auth.hasStoredCookies
                              ? _viewCookies
                              : null,
                          icon: const Icon(
                            Icons.visibility_rounded,
                            size: UiTokens.iconButton,
                          ),
                          label: const Text('Ver'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _checking || !auth.hasStoredCookies
                              ? null
                              : _verify,
                          icon: const Icon(
                            Icons.verified_rounded,
                            size: UiTokens.iconButton,
                          ),
                          label: const Text('Verificar'),
                        ),
                        if (_checking)
                          const SizedBox(
                            width: UiTokens.iconButton,
                            height: UiTokens.iconButton,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        if (_checkResult != null)
                          Text(
                            _checkOk
                                ? 'Cookies válidas.'
                                : 'Cookies no válidas.',
                            style: AppText.secondary.copyWith(
                              color: _checkOk
                                  ? OneDarkPro.greenText
                                  : OneDarkPro.redText,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.spaceBlock),
          _cardWithHeader(
            title: 'CONSOLA DE SESIÓN',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: 'Limpiar consola',
                  child: IconButton(
                    onPressed: AppLog.instance.clear,
                    icon: const Icon(
                      Icons.cleaning_services_rounded,
                      size: UiTokens.iconHeaderAction,
                    ),
                    color: OneDarkPro.fgDim,
                  ),
                ),
                const SizedBox(width: UiTokens.spaceCluster),
                Tooltip(
                  message: 'Exportar log (novahd-YYYYMMDD.log)',
                  child: IconButton(
                    onPressed: _exportLog,
                    icon: const Icon(
                      Icons.download_rounded,
                      size: UiTokens.iconHeaderAction,
                    ),
                    color: OneDarkPro.blueText,
                  ),
                ),
              ],
            ),
            children: [
              Container(
                height: UiTokens.sizeConsole,
                decoration: BoxDecoration(
                  color: OneDarkPro.darker,
                  borderRadius: BorderRadius.circular(UiTokens.radiusControl),
                  border: Border.all(color: OneDarkPro.border),
                ),
                child: Consumer<AppLog>(
                  builder: (context, log, _) {
                    _followBottom(log.entries.length);
                    if (log.entries.isEmpty) {
                      return const Center(
                        child: Text(
                          'Sin eventos en esta sesión.',
                          style: AppText.secondary,
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(UiTokens.spaceItemH),
                      itemCount: log.entries.length,
                      itemBuilder: (context, i) {
                        final e = log.entries[i];
                        final color = switch (e.level) {
                          LogLevel.error => OneDarkPro.redText,
                          // Excepción documentada: no hay `yellowText` en la
                          // paleta cerrada; el contraste de `yellow` pasa AA.
                          LogLevel.warning => OneDarkPro.yellow,
                          LogLevel.info => OneDarkPro.fgMid,
                        };
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: UiTokens.spaceItemOuterV,
                          ),
                          child: SelectableText(
                            e.line,
                            style: AppText.mono.copyWith(color: color),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: UiTokens.spaceBlock),
          const Padding(
            padding: EdgeInsets.only(left: UiTokens.spaceCard),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONFIGURACIÓN', style: AppText.caps),
                SizedBox(height: UiTokens.spaceInline),
                Text(
                  'Próximamente: carpeta de destino, calidad y concurrencia.',
                  style: AppText.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card con tira de encabezado full-bleed (mismo patrón que las
  /// tablas): título + acciones a la derecha, cuerpo con padding.
  Widget _cardWithHeader({
    required String title,
    required Widget trailing,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: OneDarkPro.sidebar,
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
        border: Border.all(color: OneDarkPro.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(UiTokens.radiusCard),
            ),
            child: Container(
              height: UiTokens.sizeCardHeader,
              padding: UiTokens.paddingCardHeader,
              decoration: const BoxDecoration(
                color: OneDarkPro.darker,
                border: Border(bottom: BorderSide(color: OneDarkPro.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caps,
                    ),
                  ),
                  trailing,
                ],
              ),
            ),
          ),
          Padding(
            padding: UiTokens.paddingCard,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
