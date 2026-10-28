import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';

class GameModeHandsIndicator extends StatelessWidget {
  final FNoseGameMode gameMode;
  final double size;

  const GameModeHandsIndicator({
    super.key,
    required this.gameMode,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final isRight = gameMode == FNoseGameMode.rightHand;

    return Row(
      children: [
        Image.asset(
          isRight
              ? 'lib/assets/game_mode/left-hand-disabled-100x100.png'
              : 'lib/assets/game_mode/left-hand-enabled-100x100.png',
          width: size,
          height: size,
        ),
        const SizedBox(width: 8),
        Image.asset(
          isRight
              ? 'lib/assets/game_mode/right-hand-enabled-100x100.png'
              : 'lib/assets/game_mode/right-hand-disabled-100x100.png',
          width: size,
          height: size,
        ),
      ],
    );
  }
}
