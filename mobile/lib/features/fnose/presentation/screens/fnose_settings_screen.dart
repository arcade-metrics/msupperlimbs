import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_providers.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseSettingsScreen extends ConsumerStatefulWidget {
  const FnoseSettingsScreen({super.key});

  @override
  ConsumerState<FnoseSettingsScreen> createState() =>
      _FnoseSettingsScreenState();
}

class _FnoseSettingsScreenState extends ConsumerState<FnoseSettingsScreen> {
  FnoseSettings? _draft;
  bool _saving = false;
  final _controllers = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureDraft(FnoseSettings settings) {
    if (_draft != null) return;
    _draft = settings;
    _controllers
      ..['totalTime'] = TextEditingController(text: '${settings.totalTime}')
      ..['targetSize'] = TextEditingController(
        text: settings.targetSize.toStringAsFixed(2),
      );
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
          .updateSettings(token, draft);
      ref.invalidate(fnoseSettingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_settings_settingsUpdated)),
      );
      context.go('/fnose-intro');
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
          .restoreDefaults(token);
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers.clear();
      setState(() {
        _draft = null;
        _ensureDraft(restored);
      });
      ref.invalidate(fnoseSettingsProvider);
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
    final asyncSettings = ref.watch(fnoseSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.fnose_settings_title)),
        body: Center(child: Text(l10n.common_error('$err'))),
      ),
      data: (settings) {
        _ensureDraft(settings);
        final draft = _draft!;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.fnose_settings_title)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go('/fnose-adv-settings'),
                  icon: const Icon(Icons.tune),
                  label: Text(l10n.fnose_settings_advancedSettings),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(l10n.fnose_settings_showInstructionVideo),
                  value: draft.showInfoVideo,
                  onChanged: (v) =>
                      setState(() => _draft = draft.copyWith(showInfoVideo: v)),
                ),
                const SizedBox(height: 16),
                _numberField(
                  l10n.fnose_settings_totalTime,
                  _controllers['totalTime']!,
                  (v) {
                    final n = int.tryParse(v);
                    if (n != null) {
                      setState(() => _draft = draft.copyWith(totalTime: n));
                    }
                  },
                ),
                _numberField(
                  l10n.fnose_settings_targetSize,
                  _controllers['targetSize']!,
                  (v) {
                    final n = double.tryParse(v);
                    if (n != null) {
                      setState(() => _draft = draft.copyWith(targetSize: n));
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
                      : Text(l10n.common_save),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saving ? null : _restore,
                  child: Text(l10n.restoreDefaults),
                ),
                TextButton(
                  onPressed: () => context.go('/fnose-intro'),
                  child: Text(l10n.common_cancel),
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
