import 'package:flutter/material.dart';
import 'package:msupperlimbs/gen_l10n/app_localizations.dart';

class RapidHandValidationWidget extends StatelessWidget {
  final bool isHandDetected;
  final String? currentMessage;

  const RapidHandValidationWidget({
    super.key,
    required this.isHandDetected,
    this.currentMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Stack(
      children: [
        // Green overlay when hand is detected
        if (isHandDetected)
          Container(
            color: Colors.green.withOpacity(0.3),
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

        // Message at the bottom
        if (!isHandDetected)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Text(
                    'Place your hand in the center of the screen, about 40-50 cm away',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                      fontFamily: 'BebasNeue',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
