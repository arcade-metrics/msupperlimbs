import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseFeedbackScreen extends StatelessWidget {
  const FnoseFeedbackScreen({super.key, this.result});

  final FnoseGameResult? result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final r = result;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.fnose_feedback_title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                r == null
                    ? l10n.fnose_feedback_noResult
                    : l10n.fnose_feedback_sparksCount(r.totalSparks),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (r != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.fnose_feedback_summary(
                    r.totalTime,
                    r.totalLeftSparks,
                    r.totalRightSparks,
                  ),
                ),
                Text(l10n.fnose_feedback_mode(r.gameMode)),
                if (r.avgAngle != null)
                  Text(
                    l10n.fnose_feedback_avgAngle(
                      r.avgAngle!.toStringAsFixed(1),
                    ),
                  ),
                const SizedBox(height: 16),
                if (r.saved)
                  Text(
                    l10n.fnose_feedback_saved(r.matchId!.substring(0, 8)),
                    style: const TextStyle(color: Colors.green),
                  )
                else if (r.queued)
                  Text(r.saveError!, textAlign: TextAlign.center)
                else if (r.saveError != null)
                  Text(
                    l10n.fnose_feedback_saveFailed(r.saveError!),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                else
                  Text(l10n.fnose_feedback_notSaved),
                Text(
                  l10n.fnose_feedback_logs(
                    r.hitEvents.length,
                    r.poseSamples.length,
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/fnose-gameover', extra: r),
                child: Text(l10n.common_continue),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
