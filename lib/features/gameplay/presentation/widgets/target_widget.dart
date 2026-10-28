import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';

class TargetWidget extends StatelessWidget {
  final int targetNumber;
  final double xPercent;
  final double yPercent;
  final double scale;
  final FNoseGameMode gameMode;
  final bool useCalibrationImage;

  TargetWidget({
    super.key,
    required this.targetNumber,
    required this.xPercent,
    required this.yPercent,
    required this.scale,
    required this.gameMode,
    this.useCalibrationImage = false,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final imageSize = screenSize.shortestSide * scale;

    final imagePath = useCalibrationImage
        ? 'lib/assets/targets/target-calibration-720x720.png'
        : 'lib/assets/targets/target-$targetNumber-720x720.png';

    // Novo cálculo: xPercent representa a distância da borda da tela até a borda do alvo
    final isLeftHand = gameMode == FNoseGameMode.leftHand;
    final xPos = isLeftHand 
        ? screenSize.width * xPercent + (imageSize / 2)  // Borda esquerda do alvo
        : screenSize.width * (1 - xPercent) - (imageSize / 2);  // Borda direita do alvo

    return Positioned(
      left: xPos - imageSize / 2,
      top: screenSize.height * yPercent - imageSize / 2,
      child: Image.asset(
        imagePath,
        width: imageSize,
        height: imageSize,
        fit: BoxFit.contain,
      ),
    );
  }
}
