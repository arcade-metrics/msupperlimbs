import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseGameOverScreen extends StatelessWidget {
  const FnoseGameOverScreen({super.key, this.result});

  final FnoseGameResult? result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fnose_gameover_title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.fnose_gameover_finished,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (r != null) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.fnose_gameover_sparksInTime(r.totalSparks, r.totalTime),
                ),
                if (r.saved)
                  Text(
                    l10n.fnose_gameover_session(r.sessionId!.substring(0, 8)),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/fnose-game'),
                child: Text(l10n.fnose_gameover_playAgain),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.fnose_gameover_home),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
