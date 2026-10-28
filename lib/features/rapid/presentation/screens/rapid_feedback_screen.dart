import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';
import 'package:msupperlimbs/core/utils/screen_orientation.dart';

class RapidFeedbackScreen extends StatefulWidget {
  const RapidFeedbackScreen({super.key});

  @override
  State<RapidFeedbackScreen> createState() => _RapidFeedbackScreenState();
}

class _RapidFeedbackScreenState extends State<RapidFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    lockToLandscape();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/rapid-gameover');
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
          'Great Tapping!\nMission Complete',
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
