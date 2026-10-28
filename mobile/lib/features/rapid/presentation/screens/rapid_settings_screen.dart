import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_providers.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';

class RapidSettingsScreen extends ConsumerStatefulWidget {
  const RapidSettingsScreen({super.key});

  @override
  ConsumerState<RapidSettingsScreen> createState() =>
      _RapidSettingsScreenState();
}

class _RapidSettingsScreenState extends ConsumerState<RapidSettingsScreen> {
  RapidSettings? _draft;
  bool _saving = false;
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureDraft(RapidSettings settings) {
    if (_draft != null) return;
    _draft = settings;
    _controllers
      ..['totalTime'] = TextEditingController(text: '${settings.totalTime}')
      ..['tapSensitivity'] = TextEditingController(
        text: '${settings.tapSensitivity}',
      )
      ..['tapCooldownMs'] = TextEditingController(
        text: '${settings.tapCooldownMs}',
      )
      ..['maxPoints'] = TextEditingController(text: '${settings.maxPoints}')
      ..['baseline'] = TextEditingController(text: '${settings.baseline}')
      ..['gravityPerSecond'] = TextEditingController(
        text: '${settings.gravityPerSecond}',
      )
      ..['impulseStrength'] = TextEditingController(
        text: '${settings.impulseStrength}',
      );
  }

  Future<void> _save() async {
    final draft = _draft;
    final token = ref.read(authProvider).accessToken;
    if (draft == null || token == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(rapidSettingsRepositoryProvider)
          .updateSettings(token, draft);
      ref.invalidate(rapidSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settings guardados')));
      context.go('/rapid-intro');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restore() async {
    final token = ref.read(authProvider).accessToken;
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final restored = await ref
          .read(rapidSettingsRepositoryProvider)
          .restoreDefaults(token);
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      setState(() {
        _draft = null;
        _ensureDraft(restored);
      });
      ref.invalidate(rapidSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Defaults restaurados')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSettings = ref.watch(rapidSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Rapid Settings')),
        body: Center(child: Text('Erro: $err')),
      ),
      data: (settings) {
        _ensureDraft(settings);
        final draft = _draft!;
        return Scaffold(
          appBar: AppBar(title: const Text('Rapid Settings')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  title: const Text('Mostrar vídeo de instrução'),
                  value: draft.showInfoVideo,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(showInfoVideo: v)),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Visualização',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'line', label: Text('Linha')),
                    ButtonSegment(value: 'bar', label: Text('Barra')),
                    ButtonSegment(value: 'circle', label: Text('Círculo')),
                  ],
                  selected: {draft.visualizationType},
                  onSelectionChanged: (values) {
                    setState(
                      () => _draft = draft.copyWith(
                        visualizationType: values.first,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _numberField('Tempo total (s)', _controllers['totalTime']!, (
                  v,
                ) {
                  final n = int.tryParse(v);
                  if (n != null) {
                    setState(() => _draft = draft.copyWith(totalTime: n));
                  }
                }),
                _numberField(
                  'Sensibilidade do tap (0–1 MediaPipe)',
                  _controllers['tapSensitivity']!,
                  (v) {
                    final n = double.tryParse(v);
                    if (n != null) {
                      setState(
                        () => _draft = draft.copyWith(tapSensitivity: n),
                      );
                    }
                  },
                ),
                _numberField(
                  'Cooldown do tap (ms)',
                  _controllers['tapCooldownMs']!,
                  (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      setState(() => _draft = draft.copyWith(tapCooldownMs: n));
                    }
                  },
                ),
                _numberField(
                  'Max points (janela)',
                  _controllers['maxPoints']!,
                  (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      setState(() => _draft = draft.copyWith(maxPoints: n));
                    }
                  },
                ),
                _numberField('Baseline', _controllers['baseline']!, (v) {
                  final n = double.tryParse(v);
                  if (n != null) {
                    setState(() => _draft = draft.copyWith(baseline: n));
                  }
                }),
                _numberField('Gravity / s', _controllers['gravityPerSecond']!, (
                  v,
                ) {
                  final n = double.tryParse(v);
                  if (n != null) {
                    setState(
                      () => _draft = draft.copyWith(gravityPerSecond: n),
                    );
                  }
                }),
                _numberField(
                  'Impulse por tap',
                  _controllers['impulseStrength']!,
                  (v) {
                    final n = double.tryParse(v);
                    if (n != null) {
                      setState(
                        () => _draft = draft.copyWith(impulseStrength: n),
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Guardar'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _restore,
                  child: const Text('Restaurar defaults'),
                ),
                TextButton(
                  onPressed: () => context.go('/rapid-intro'),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _numberField(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
