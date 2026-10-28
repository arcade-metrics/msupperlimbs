import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_providers.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_mode.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseIntroScreen extends ConsumerWidget {
  const FnoseIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncSettings = ref.watch(fnoseSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.fnose_intro_title)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.fnose_intro_errorLoadingSettings('$err')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(fnoseSettingsProvider),
                  child: Text(l10n.common_retry),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (settings) {
        final mode = FnoseGameModeX.fromString(settings.gameMode);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.fnose_intro_title)),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (settings.showInfoVideo) ...[
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_circle_fill, size: 72),
                              const SizedBox(height: 8),
                              Text(l10n.fnose_intro_instructionVideo),
                              Text(
                                l10n.fnose_intro_notImplemented,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.fnose_intro_hideOnNextTime),
                      value: !settings.showInfoVideo,
                      onChanged: (value) async {
                        if (value == null) return;
                        final token = ref.read(authProvider).accessToken;
                        if (token == null) return;
                        await ref
                            .read(fnoseSettingsRepositoryProvider)
                            .patchSettings(token, {'show_info_video': !value});
                        ref.invalidate(fnoseSettingsProvider);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/fnose-mode'),
                    icon: const Icon(Icons.accessibility_new),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label(l10n),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          l10n.fnose_intro_changeGameMode,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/fnose-game'),
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: Text(l10n.fnose_intro_start),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/fnose-settings'),
                    icon: const Icon(Icons.settings),
                    label: Text(l10n.fnose_intro_settings),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.common_back),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
