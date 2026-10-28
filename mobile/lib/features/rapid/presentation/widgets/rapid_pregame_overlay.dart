import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_phase.dart';

class RapidPregameOverlay extends StatelessWidget {
  const RapidPregameOverlay({
    super.key,
    required this.phase,
    required this.holdProgress,
    required this.handPresent,
  });

  final RapidGamePhase phase;
  final double holdProgress;
  final bool handPresent;

  @override
  Widget build(BuildContext context) {
    if (phase != RapidGamePhase.waitingHand &&
        phase != RapidGamePhase.holdingHand) {
      return const SizedBox.shrink();
    }

    final waiting = phase == RapidGamePhase.waitingHand;
    final message = waiting
        ? 'Posicione a mão no centro da câmara'
        : (handPresent
              ? 'Mão detetada — mantenha a posição…'
              : 'Mão perdida — volte a posicionar');

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  waiting ? Icons.back_hand_outlined : Icons.pan_tool_alt,
                  size: 56,
                  color: waiting ? Colors.lightBlueAccent : Colors.greenAccent,
                ),
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
                if (phase == RapidGamePhase.holdingHand) ...[
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
