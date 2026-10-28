import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/presentation/widgets/validation_position_checker_widget.dart';

class FNoseValidationOverlay extends StatelessWidget {
  final bool show;
  final bool isDistanceValid;
  final bool isYAligned;
  final bool isZAligned;
  final bool isNoseCentered;
  final bool isLeftHand;
  final String? currentValidationMessage;

  const FNoseValidationOverlay({
    super.key,
    required this.show,
    required this.isDistanceValid,
    required this.isYAligned,
    required this.isZAligned,
    required this.isNoseCentered,
    required this.isLeftHand,
    this.currentValidationMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: show ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        child: PositionValidationWidget(
          isDistanceValid: isDistanceValid,
          isYAligned: isYAligned,
          isZAligned: isZAligned,
          isNoseCentered: isNoseCentered,
          isLeftHand: isLeftHand,
          currentValidationMessage: currentValidationMessage,
        ),
      ),
    );
  }
}
