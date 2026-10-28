import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

class RapidGameOverScreen extends StatelessWidget {
  const RapidGameOverScreen({super.key, this.result});

  final RapidGameResult? result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Scaffold(
      appBar: AppBar(title: const Text('Rapid Game Over')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Partida terminada',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              if (r != null) ...[
                const SizedBox(height: 12),
                Text('${r.tapCount} taps em ${r.durationSeconds}s'),
                if (r.saved)
                  Text(
                    'Sessão ${r.sessionId!.substring(0, 8)}…',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/rapid-game'),
                child: const Text('Jogar outra vez'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
