import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_adv_settings_model.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';

class NoseAlignmentIndicatorWidget extends StatelessWidget {
  final FNoseAdvSettingsModel advSettings;
  final FNoseGameMode gameMode;
  final Size screenSize;
  final Offset? currentNosePosition; // Optional: current nose position for feedback

  const NoseAlignmentIndicatorWidget({
    super.key,
    required this.advSettings,
    required this.gameMode,
    required this.screenSize,
    this.currentNosePosition,
  });

  @override
  Widget build(BuildContext context) {
    final isLeftHand = gameMode == FNoseGameMode.leftHand;
    final noseAlignmentTargetX = advSettings.getNoseAlignmentXCoordinate(isLeftHand);
    final noseAlignmentTargetY = advSettings.yNoseAlignment;
    final threshold = advSettings.noseAlignmentThreshold;
    final targetRadius = advSettings.noseAlignmentTargetRadius;

    // Calculate position in pixels
    final centerX = noseAlignmentTargetX * screenSize.width;
    final centerY = noseAlignmentTargetY * screenSize.height;
    final radius = targetRadius * screenSize.width; // Use width for consistent scaling

    // Determine color based on current nose position
    Color circleColor = Colors.blue.withOpacity(0.6);
    double borderWidth = 2.0;
    
    if (currentNosePosition != null) {
      final distance = (currentNosePosition! - Offset(centerX, centerY)).distance;
      final thresholdRadius = threshold * screenSize.width;
      final normalizedDistance = distance / thresholdRadius;
      
      if (normalizedDistance <= 1.0) {
        // Nose is within the target area
        circleColor = Colors.green.withOpacity(0.8);
        borderWidth = 3.0;
      } else if (normalizedDistance <= 1.5) {
        // Nose is close to the target area
        circleColor = Colors.orange.withOpacity(0.7);
        borderWidth = 2.5;
      } else {
        // Nose is far from the target area
        circleColor = Colors.red.withOpacity(0.6);
        borderWidth = 2.0;
      }
    }

    return Stack(
      children: [
        Positioned(
          left: centerX - radius,
          top: centerY - radius,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: circleColor,
                width: borderWidth,
              ),
              color: circleColor.withOpacity(0.1),
            ),
            child: Center(
              child: Icon(
                Icons.face,
                color: circleColor,
                size: radius * 0.5,
              ),
            ),
          ),
        ),
        if (currentNosePosition != null)
          Positioned(
            left: currentNosePosition!.dx - 12,
            top: currentNosePosition!.dy - 12,
            child: Icon(
              Icons.face,
              color: circleColor,
              size: 24,
            ),
          ),
      ],
    );
  }
} 