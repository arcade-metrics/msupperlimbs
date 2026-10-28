import 'package:flutter/material.dart';

enum SavingPhase {
  savingPoseData,
  savingTapData,
  savingPulseStateData,
  calculatingStats,
  updatingMatch,
}

class RapidSavingOverlay extends StatefulWidget {
  final SavingPhase currentPhase;
  final double progress;

  const RapidSavingOverlay({
    super.key,
    required this.currentPhase,
    required this.progress,
  });

  @override
  State<RapidSavingOverlay> createState() => _RapidSavingOverlayState();
}

class _RapidSavingOverlayState extends State<RapidSavingOverlay> {
  String _getPhaseText(SavingPhase phase) {
    switch (phase) {
      case SavingPhase.savingPoseData:
        return 'Getting your movement data...';
      case SavingPhase.savingTapData:
        return 'Saving your tapping data...';
      case SavingPhase.savingPulseStateData:
        return 'Saving pulse line data...';
      case SavingPhase.calculatingStats:
        return 'Analyzing your performance...';
      case SavingPhase.updatingMatch:
        return 'Processing your results...';
    }
  }

  double _getPhaseProgress(SavingPhase phase, double progress) {
    switch (phase) {
      case SavingPhase.savingPoseData:
        return progress * 0.2; // 0-20%
      case SavingPhase.savingTapData:
        return 0.2 + (progress * 0.2); // 20-40%
      case SavingPhase.savingPulseStateData:
        return 0.4 + (progress * 0.2); // 40-60%
      case SavingPhase.calculatingStats:
        return 0.6 + (progress * 0.2); // 60-80%
      case SavingPhase.updatingMatch:
        return 0.8 + (progress * 0.2); // 80-100%
    }
  }

  String _getPhaseEmoji(SavingPhase phase) {
    switch (phase) {
      case SavingPhase.savingPoseData:
        return '👤';
      case SavingPhase.savingTapData:
        return '👆';
      case SavingPhase.savingPulseStateData:
        return '📈';
      case SavingPhase.calculatingStats:
        return '📊';
      case SavingPhase.updatingMatch:
        return '🎯';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji da fase actual
              Text(
                _getPhaseEmoji(widget.currentPhase),
                style: const TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              
              // Progress bar
              Container(
                width: 300,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _getPhaseProgress(widget.currentPhase, widget.progress),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lightGreenAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Texto da fase actual
              Text(
                _getPhaseText(widget.currentPhase),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'BebasNeue',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              
              // Percentagem
              Text(
                '${(_getPhaseProgress(widget.currentPhase, widget.progress) * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
