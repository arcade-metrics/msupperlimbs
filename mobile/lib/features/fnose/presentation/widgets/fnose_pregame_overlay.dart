import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

class FnosePregameOverlay extends StatelessWidget {
  const FnosePregameOverlay({
    super.key,
    required this.phase,
    required this.holdProgress,
    required this.pitch,
    required this.roll,
    required this.pitchMin,
    required this.pitchMax,
    required this.rollMin,
    required this.rollMax,
  });

  final FnoseGamePhase phase;
  final double holdProgress;
  final double pitch;
  final double roll;
  final double pitchMin;
  final double pitchMax;
  final double rollMin;
  final double rollMax;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pregame = phase.index <= FnoseGamePhase.calibrateFinger.index;
    if (!pregame) return const SizedBox.shrink();

    final (icon, message, showBar) = switch (phase) {
      FnoseGamePhase.deviceStill => (
        Icons.phonelink_setup,
        l10n.fnose_pregame_surface,
        true,
      ),
      FnoseGamePhase.deviceRoll => (
        Icons.stay_current_landscape,
        roll < rollMin
            ? l10n.fnose_pregame_raiseRight
            : roll > rollMax
            ? l10n.fnose_pregame_raiseLeft
            : l10n.fnose_pregame_rollOk,
        true,
      ),
      FnoseGamePhase.devicePitch => (
        Icons.screen_rotation,
        pitch < pitchMin
            ? l10n.fnose_pregame_tiltForward
            : pitch > pitchMax
            ? l10n.fnose_pregame_tiltBack
            : l10n.fnose_pregame_pitchOk,
        true,
      ),
      FnoseGamePhase.alignNose => (
        Icons.face,
        l10n.fnose_pregame_alignNose,
        true,
      ),
      FnoseGamePhase.calibrateFinger => (
        Icons.touch_app,
        l10n.fnose_pregame_alignFinger,
        true,
      ),
      _ => (Icons.info, '', false),
    };

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: Colors.lightBlueAccent),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showBar) ...[
                  const SizedBox(height: 20),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: holdProgress,
                      minHeight: 10,
                      backgroundColor: Colors.white24,
                      color: Colors.greenAccent,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
