import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_providers.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_mode.dart';

class RapidIntroScreen extends ConsumerWidget {
  const RapidIntroScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSettings = ref.watch(rapidSettingsProvider);

    return asyncSettings.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Rapid Challenge')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Erro ao carregar settings: $err'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref.invalidate(rapidSettingsProvider),
                  child: const Text('Tentar de novo'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (settings) {
        final mode = RapidGameModeX.fromString(settings.gameMode);
        return Scaffold(
          appBar: AppBar(title: const Text('Rapid Challenge')),
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
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.play_circle_fill, size: 72),
                              SizedBox(height: 8),
                              Text('Vídeo de instrução'),
                              Text(
                                '(ainda não implementado)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Não mostrar da próxima vez'),
                      value: !settings.showInfoVideo,
                      onChanged: (value) async {
                        if (value == null) return;
                        final token = ref.read(authProvider).accessToken;
                        if (token == null) return;
                        await ref
                            .read(rapidSettingsRepositoryProvider)
                            .patchSettings(token, {'showInfoVideo': !value});
                        ref.invalidate(rapidSettingsProvider);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/rapid-mode'),
                    icon: const Icon(Icons.back_hand_outlined),
                    label: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Alterar modo de jogo',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/rapid-game'),
                    icon: const Icon(Icons.play_arrow, size: 28),
                    label: const Text('START'),
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
                    onPressed: () => context.go('/rapid-settings'),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Voltar'),
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
