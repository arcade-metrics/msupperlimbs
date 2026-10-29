import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_providers.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_mode.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseModeSelectionScreen extends ConsumerWidget {
  const FnoseModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final asyncSettings = ref.watch(fnoseSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.fnose_mode_title)),
        body: Center(child: Text(l10n.common_error('$err'))),
      ),
      data: (settings) {
        final current = FnoseGameModeX.fromString(settings.gameMode);
        return Scaffold(
          appBar: AppBar(title: Text(l10n.fnose_mode_title)),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    l10n.fnose_mode_chooseGameMode,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final mode in FnoseGameModeX.selectableModes) ...[
                    _ModeCard(
                      mode: mode,
                      selected: mode == current,
                      onTap: () async {
                        final token = ref.read(authProvider).accessToken;
                        if (token == null) return;
                        await ref
                            .read(fnoseSettingsRepositoryProvider)
                            .patchSettings(token, {'gameMode': mode.apiValue});
                        ref.invalidate(fnoseSettingsProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.go('/fnose-intro'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(l10n.fnose_mode_continue),
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

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final FnoseGameMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color, width: 2),
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mode.label(l10n),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected ? color : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description(l10n),
              style: TextStyle(color: selected ? color : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
