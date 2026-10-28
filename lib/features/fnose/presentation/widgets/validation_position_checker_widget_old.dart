import 'package:flutter/material.dart';

class PositionValidationWidget extends StatelessWidget {
  final bool isDistanceValid;
  final bool isYAligned;
  final bool isZAligned;
  final bool isNoseCentered;
  final bool isLeftHand;

  const PositionValidationWidget({
    super.key,
    required this.isDistanceValid,
    required this.isYAligned,
    required this.isZAligned,
    required this.isNoseCentered,
    required this.isLeftHand,
  });

  bool get allValid =>
      isDistanceValid && isYAligned && isZAligned && isNoseCentered;

  @override
  Widget build(BuildContext context) {
    final hand = isLeftHand ? 'left' : 'right';
    final colour = allValid ? 'green' : 'blue';
    final imagePath = 'lib/assets/avatar-$hand-$colour-950x530.png';

    return Stack(
      children: [
        // Avatar with transparence
        Center(
          child: Opacity(
            opacity: 1.0,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
            ),
          ),
        ),

        // Central message on top
        if (allValid)
          const Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'READY TO START!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 4.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // low left validation indicators
        if (!allValid)
          Positioned(
            bottom: 32,
            left: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildStatus(isDistanceValid, ' Screen Distance'),
                const SizedBox(height: 8),
                _buildStatus(isYAligned, 'Shoulder Y-Align'),
                const SizedBox(height: 8),
                _buildStatus(isZAligned, 'Depth Z-Align'),
                const SizedBox(height: 8),
                _buildStatus(isNoseCentered, 'Position Centered'),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildStatus(bool valid, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: valid ? Colors.greenAccent : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          valid ? '✅' : '⭕',
          style: const TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
