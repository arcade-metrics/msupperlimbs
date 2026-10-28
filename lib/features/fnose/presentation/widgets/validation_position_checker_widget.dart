import 'package:flutter/material.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';

class PositionValidationWidget extends StatelessWidget {
  final bool isDistanceValid;
  final bool isYAligned;
  final bool isZAligned;
  final bool isNoseCentered;
  final bool isLeftHand;
  final String? currentValidationMessage;

  const PositionValidationWidget({
    super.key,
    required this.isDistanceValid,
    required this.isYAligned,
    required this.isZAligned,
    required this.isNoseCentered,
    required this.isLeftHand,
    this.currentValidationMessage,
  });

  bool get allValid =>
      isDistanceValid && isYAligned && isZAligned && isNoseCentered;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hand = isLeftHand ? 'left' : 'right';
    final colour = allValid ? 'green' : 'blue';

    return Stack(
      children: [
        // Green overlay when all valid
        if (allValid)
          Container(
            color: Colors.green.withOpacity(0.7),
            child: Center(
              child: Text(
                l10n.validation_positionFound,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'BebasNeue',
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

        // Full width black background at bottom
        if (!allValid)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 200,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Row(
                children: [
                  // Validation indicators on the side
                  if (isLeftHand)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatus(isDistanceValid, l10n.validation_screenDistance),
                            const SizedBox(height: 8),
                            _buildStatus(isYAligned, l10n.validation_shoulderYAlign),
                            const SizedBox(height: 8),
                            _buildStatus(isZAligned, l10n.validation_depthZAlign),
                            const SizedBox(height: 8),
                            _buildStatus(isNoseCentered, l10n.validation_positionCentered),
                          ],
                        ),
                      ),
                    ),
                  
                  // Messages in the center
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l10n.validation_adjustYourPosition,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'BebasNeue',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (currentValidationMessage != null && currentValidationMessage!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                currentValidationMessage!,
                                style: TextStyle(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontFamily: 'BebasNeue',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Validation indicators on the side
                  if (!isLeftHand)
                    Expanded(
                      flex: 1,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 48.0, 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildStatus(isDistanceValid, l10n.validation_screenDistance),
                            const SizedBox(height: 8),
                            _buildStatus(isYAligned, l10n.validation_shoulderYAlign),
                            const SizedBox(height: 8),
                            _buildStatus(isZAligned, l10n.validation_depthZAlign),
                            const SizedBox(height: 8),
                            _buildStatus(isNoseCentered, l10n.validation_positionCentered),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatus(bool valid, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isLeftHand) ...[
          Text(
            valid ? '✅' : '⭕',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 20,
              color: valid ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'BebasNeue',
            ),
            textAlign: isLeftHand ? TextAlign.left : TextAlign.right,
          ),
        ),
        if (isLeftHand) ...[
          const SizedBox(width: 8),
          Text(
            valid ? '✅' : '⭕',
            style: const TextStyle(fontSize: 22),
          ),
        ],
      ],
    );
  }
}
