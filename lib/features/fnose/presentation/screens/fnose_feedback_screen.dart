import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';

class FNoseFeedbackScreen extends StatefulWidget {
  const FNoseFeedbackScreen({super.key});

  @override
  State<FNoseFeedbackScreen> createState() => _FNoseFeedbackScreenState();
}

class _FNoseFeedbackScreenState extends State<FNoseFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    lockToLandscape();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/fnose-gameover');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: Colors.green.shade600,
      body: Center(
        child: Text(
          '${l10n.fnose_feedback_wellDone}\n${l10n.fnose_feedback_missionComplete}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 40.0,
            fontWeight: FontWeight.bold,
            height: 1.5,
            fontFamily: 'BebasNeue',
          ),
        ),
      ),
    );
  }
}
