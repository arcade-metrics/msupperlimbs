import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnoseFeedbackScreen extends StatefulWidget {
  const FnoseFeedbackScreen({super.key, this.result});

  final FnoseGameResult? result;

  @override
  State<FnoseFeedbackScreen> createState() => _FnoseFeedbackScreenState();
}

class _FnoseFeedbackScreenState extends State<FnoseFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final r = widget.result;

    final left = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          r == null
              ? l10n.fnose_feedback_noResult
              : l10n.fnose_feedback_sparksCount(r.totalSparks),
          style: theme.textTheme.headlineMedium,
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
            Text(l10n.fnose_feedback_avgAngle(r.avgAngle!.toStringAsFixed(1))),
        ],
      ],
    );

    final right = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (r != null) ...[
          if (r.saved)
            Text(
              l10n.fnose_feedback_saved(r.matchId!.substring(0, 8)),
              style: const TextStyle(color: Colors.green),
            )
          else if (r.queued)
            Text(r.saveError!)
          else if (r.saveError != null)
            Text(
              l10n.fnose_feedback_saveFailed(r.saveError!),
              style: TextStyle(color: theme.colorScheme.error),
            )
          else
            Text(l10n.fnose_feedback_notSaved),
          const SizedBox(height: 8),
          Text(
            l10n.fnose_feedback_logs(r.hitEvents.length, r.poseSamples.length),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
        ],
        FilledButton(
          onPressed: () => context.go('/fnose-gameover', extra: r),
          child: Text(l10n.common_continue),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fnose_feedback_title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) => Center(
              // Safety net: scales down instead of scrolling or overflowing.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: constraints.maxWidth,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: left),
                      const SizedBox(width: 32),
                      Expanded(child: right),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
