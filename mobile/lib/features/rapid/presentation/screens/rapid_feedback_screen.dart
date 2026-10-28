import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

class RapidFeedbackScreen extends StatelessWidget {
  const RapidFeedbackScreen({super.key, this.result});

  final RapidGameResult? result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Scaffold(
      appBar: AppBar(title: const Text('Rapid Feedback')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r == null ? 'Sem resultado' : '${r.tapCount} taps',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (r != null) ...[
                const SizedBox(height: 8),
                Text(
                  '${r.durationSeconds}s · ${r.tapsPerSecond.toStringAsFixed(2)} taps/s',
                ),
                Text('Modo: ${r.gameMode} · viz: ${r.visualizationType}'),
                const SizedBox(height: 16),
                if (r.saved)
                  Text(
                    'Guardado · match ${r.matchId!.substring(0, 8)}…',
                    style: const TextStyle(color: Colors.green),
                  )
                else if (r.saveError != null)
                  Text(
                    'Falha ao guardar: ${r.saveError}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else
                  const Text('Não guardado'),
                Text(
                  'logs: ${r.tapEvents.length} taps · '
                  '${r.pulseEvents.length} pulse · '
                  '${r.poseSamples.length} pose',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/rapid-gameover', extra: r),
                child: const Text('Continuar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
