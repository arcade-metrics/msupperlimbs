import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings_model.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/presentation/widgets/app_header.dart';

class FNoseSettingsScreen extends ConsumerStatefulWidget {
  const FNoseSettingsScreen({super.key});

  @override
  ConsumerState<FNoseSettingsScreen> createState() =>
      _FNoseSettingsScreenState();
}

class _FNoseSettingsScreenState extends ConsumerState<FNoseSettingsScreen> {
  final _controllers = <String, TextEditingController>{};

  void _initControllers(FNoseSettingsModel settings) {
    _controllers['totalTime'] =
        TextEditingController(text: settings.totalTime.toString());
    //_controllers['targetSize'] =
    //    TextEditingController(text: settings.targetSize.toString());
  }

  @override
  void initState() {
    super.initState();
    lockToPortrait();
    Future.microtask(() async {
      final user = ref.read(userProvider);
      if (user != null) {
        final settings = await ref.read(fnoseSettingsProvider(user.uid).future);
        ref.read(fnoseSettingsStateProvider.notifier).state = settings;
        if (mounted) {
          setState(() => _initControllers(settings));
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updateSettings(String uid) async {
    final current = ref.read(fnoseSettingsStateProvider);
    if (current == null) return;

    await ref.read(fnoseSettingsServiceProvider).updateFNoseSettings(current);
    ref.invalidate(fnoseSettingsProvider(uid));
    ref.read(fnoseSettingsStateProvider.notifier).state =
        await ref.read(fnoseSettingsProvider(uid).future);

    if (mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fnose_settings_settingsUpdated)),
      );
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) {
        context.go('/fnose-intro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final fnoseSettings = ref.watch(fnoseSettingsStateProvider);
    final l10n = AppLocalizations.of(context)!;

    if (userState == null || fnoseSettings == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final uid = userState.uid;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppHeader(title: l10n.fnose_settings_title),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => context.go('/fnose-adv-settings'),
                      icon: const Icon(Icons.tune),
                      label: Text(l10n.fnose_settings_advancedSettings),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0, vertical: 12.0),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: Text(l10n.fnose_settings_showInstructionVideo),
                      value: fnoseSettings.showInfoVideo,
                      onChanged: (value) {
                        ref.read(fnoseSettingsStateProvider.notifier).state =
                            fnoseSettings.copyWith(showInfoVideo: value);
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildNumberField(
                        l10n.totalTimeSec, _controllers['totalTime']!, (val) {
                      final newVal =
                          int.tryParse(val) ?? fnoseSettings.totalTime;
                      ref.read(fnoseSettingsStateProvider.notifier).state =
                          fnoseSettings.copyWith(totalTime: newVal);
                    }),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () => context.go('/fnose-intro'),
                          icon: const Icon(Icons.arrow_back),
                          label: Text(l10n.common_back),
                        ),
                        ElevatedButton(
                          onPressed: () => _updateSettings(uid),
                          child: Text(l10n.update),
                        )
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () async {
                        final newDefaults = await ref
                            .read(fnoseSettingsServiceProvider)
                            .restoreDefaults(uid);
                        ref.read(fnoseSettingsStateProvider.notifier).state =
                            newDefaults;
                        setState(() {
                          _initControllers(newDefaults);
                        });
                      },
                      child: Text(
                        l10n.restoreDefaults,
                        style: const TextStyle(
                            decoration: TextDecoration.underline),
                      ),
                    ),
                    // Adição dos botões de privacidade ao final da tela
                    // const SizedBox(height: 32),
                    // const Divider(),
                    // const SizedBox(height: 16),
                    // Text(
                    //   l10n.dataPrivacy,
                    //   style: Theme.of(context).textTheme.titleMedium,
                    // ),
                    // const SizedBox(height: 16),
                    // OutlinedButton.icon(
                    //   onPressed: () async {
                    //     await ref.read(userProvider.notifier).revokeConsent();
                    //     if (context.mounted) {
                    //       ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(content: Text(l10n.fnose_settings_consentRevoked)),
                    //       );
                    //     }
                    //   },
                    //   icon: const Icon(Icons.block, color: Colors.orange),
                    //   label: Text(l10n.revokeMyConsent),
                    //   style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
                    // ),
                    // const SizedBox(height: 8),
                    // OutlinedButton.icon(
                    //   onPressed: null, // TODO: Implementar
                    //   icon: const Icon(Icons.delete_forever, color: Colors.grey),
                    //   label: Text(l10n.fnose_settings_removeFromPlatform),
                    // ),
                    // const SizedBox(height: 8),
                    // OutlinedButton.icon(
                    //   onPressed: null, // TODO: Implementar
                    //   icon: const Icon(Icons.download, color: Colors.grey),
                    //   label: Text(l10n.fnose_settings_exportMyData),
                    // ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    TextEditingController controller,
    Function(String) onChanged, {
    String? helperText,
    double fieldWidth = 100,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              SizedBox(
                width: fieldWidth,
                child: TextFormField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  onChanged: onChanged,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          if (helperText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                helperText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
        ],
      ),
    );
  }
}
