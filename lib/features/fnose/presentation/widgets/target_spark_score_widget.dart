import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';

class SparkScoreWidget extends StatelessWidget {
  final int count;
  final FNoseGameMode gameMode;
  final String label;
  final Color color;

  const SparkScoreWidget({
    super.key,
    required this.count,
    required this.gameMode,
    this.label = 'Sparks',
    this.color = Colors.lightGreenAccent,
  });

  @override
  Widget build(BuildContext context) {
    final alignLeft = gameMode == FNoseGameMode.rightHand;

    return Align(
      alignment: alignLeft ? Alignment.topLeft : Alignment.topRight,
      child: Container(
        margin: EdgeInsets.only(
          top: 100,
          left: alignLeft ? 24 : 12,
          right: alignLeft ? 12 : 24,
          bottom: 10,
        ),
        child: Column(
          crossAxisAlignment:
              alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withAlpha((0.8 * 255).round()),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
