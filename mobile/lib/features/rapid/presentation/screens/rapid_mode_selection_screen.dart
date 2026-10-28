import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_providers.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_mode.dart';

class RapidModeSelectionScreen extends ConsumerWidget {
  const RapidModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(rapidSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Modo de jogo')),
        body: Center(child: Text('Erro: $err')),
      ),
      data: (settings) {
        final current = RapidGameModeX.fromString(settings.gameMode);
        return Scaffold(
          appBar: AppBar(title: const Text('Modo de jogo')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text(
                    'Escolha o modo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  for (final mode in RapidGameMode.values) ...[
                    _ModeCard(
                      mode: mode,
                      selected: mode == current,
                      onTap: () async {
                        final token = ref.read(authProvider).accessToken;
                        if (token == null) return;
                        await ref
                            .read(rapidSettingsRepositoryProvider)
                            .patchSettings(token, {'game_mode': mode.apiValue});
                        ref.invalidate(rapidSettingsProvider);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Spacer(),
                  FilledButton(
                    onPressed: () => context.go('/rapid-intro'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: const Text('Continuar'),
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

  final RapidGameMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              mode.label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: selected ? color : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              mode.description,
              style: TextStyle(color: selected ? color : Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
