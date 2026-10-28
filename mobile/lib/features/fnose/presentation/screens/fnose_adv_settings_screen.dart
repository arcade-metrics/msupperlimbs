import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_providers.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_adv_catalog.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseAdvSettingsScreen extends ConsumerStatefulWidget {
  const FnoseAdvSettingsScreen({super.key});

  @override
  ConsumerState<FnoseAdvSettingsScreen> createState() =>
      _FnoseAdvSettingsScreenState();
}

class _FnoseAdvSettingsScreenState
    extends ConsumerState<FnoseAdvSettingsScreen> {
  FnoseAdvSettings? _draft;
  bool _saving = false;
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureDraft(FnoseAdvSettings settings) {
    if (_draft != null) return;
    _draft = settings;
    for (final entry in settings.data.entries) {
      _controllers[entry.key] = TextEditingController(text: '${entry.value}');
    }
  }

  void _resetControllers(FnoseAdvSettings settings) {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _draft = null;
    _ensureDraft(settings);
  }

  Future<void> _save() async {
    final draft = _draft;
    final token = ref.read(authProvider).accessToken;
    final l10n = AppLocalizations.of(context);
    if (draft == null || token == null) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(fnoseSettingsRepositoryProvider)
          .updateAdvSettings(token, draft.data);
      ref.invalidate(fnoseAdvSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.fnose_adv_settings_updated)));
      context.go('/fnose-settings');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_settings_saveError('$e'))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _restore() async {
    final token = ref.read(authProvider).accessToken;
    final l10n = AppLocalizations.of(context);
    if (token == null) return;
    setState(() => _saving = true);
    try {
      final restored = await ref
          .read(fnoseSettingsRepositoryProvider)
          .restoreAdvDefaults(token);
      setState(() => _resetControllers(restored));
      ref.invalidate(fnoseAdvSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_settings_defaultsRestored)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.common_error('$e'))));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final asyncAdv = ref.watch(fnoseAdvSettingsProvider);

    return asyncAdv.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.fnose_adv_settings_title)),
        body: Center(child: Text(l10n.common_error('$err'))),
      ),
      data: (settings) {
        _ensureDraft(settings);
        final draft = _draft!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.fnose_adv_settings_title)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in FnoseAdvSection.values) ...[
                  Text(
                    section.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final field in fnoseAdvCatalog.where(
                    (f) => f.section == section,
                  )) ...[
                    _numberField(
                      label: field.label,
                      helper:
                          '${field.description}${field.unit.isEmpty ? '' : ' Unidade: ${field.unit}.'}\nEspaço: ${field.space.label} • Chave: ${field.key} • Padrão: ${field.defaultValue}',
                      controller: _controllers.putIfAbsent(
                        field.key,
                        () => TextEditingController(
                          text:
                              '${draft.data[field.key] ?? field.defaultValue}',
                        ),
                      ),
                      isInt: field.isInteger,
                      onChanged: (v) {
                        final current = _draft;
                        if (current == null) return;
                        final n = field.isInteger
                            ? int.tryParse(v)
                            : double.tryParse(v);
                        if (n == null) return;
                        setState(
                          () => _draft = current.withValue(field.key, n),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                ],
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.common_save),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _restore,
                  child: Text(l10n.restoreDefaults),
                ),
                TextButton(
                  onPressed: () => context.go('/fnose-settings'),
                  child: Text(l10n.common_back),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _numberField({
    required String label,
    required String helper,
    required TextEditingController controller,
    required bool isInt,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.numberWithOptions(
          decimal: !isInt,
          signed: true,
        ),
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 4,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
