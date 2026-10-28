import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:msupperlimbs/features/fnose/application/fnose-game-state.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/normalised_offset_utils.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/touch_logger_utils.dart';

class FNoseGameController {
  FNoseGameState gameState = FNoseGameState.waitingStableDevice;
  int score = 0;
  int remainingTime = 0;
  Timer? gameTimer;
  bool isPositionValidated = false;

  void startGame({
    required VoidCallback onEndGame,
    required int totalTime,
    required void Function(FNoseGameState) updateState,
  }) {
    gameState = FNoseGameState.touchNose;
    score = 0;
    remainingTime = totalTime;

    updateState(FNoseGameState.touchNose);

    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingTime--;
      if (remainingTime <= 0) {
        timer.cancel();
        onEndGame();
      }
    });
  }

  void endGame(BuildContext context) {
    gameTimer?.cancel();
    context.go('/fnose-feedback');
  }

  void dispose() {
    gameTimer?.cancel();
  }

  static bool isTouchInsideTarget({
    required Offset mark,
    required bool isLeft,
    required Size screenSize,
    required double xTargetPosition,
    required double yTargetPosition,
    required double targetScale,
  }) {
    // Novo cálculo: xTargetPosition representa a distância da borda da tela até a borda do alvo
    final imageSize = screenSize.shortestSide * targetScale;
    final xPos = isLeft 
        ? screenSize.width * xTargetPosition + (imageSize / 2)  // Borda esquerda do alvo
        : screenSize.width * (1 - xTargetPosition) - (imageSize / 2);  // Borda direita do alvo
    final yPos = screenSize.height * yTargetPosition;
    final Offset targetCenter = Offset(xPos, yPos);

    final double targetRadius = screenSize.shortestSide * 0.5 * targetScale;

    final double distance = (mark - targetCenter).distance;

    return distance <= targetRadius;
  }

  static TouchLog buildTouchLog({
    required Offset mark,
    required Offset nose,
    required bool isLeft,
    required Size screenSize,
    required double xTargetPosition,
    required double yTargetPosition,
    required double targetScale,
    required int timestamp,
    required FNoseGameMode gameMode,
  }) {
    // Novo cálculo: xTargetPosition representa a distância da borda da tela até a borda do alvo
    final imageSize = screenSize.shortestSide * targetScale;
    final xPos = isLeft 
        ? screenSize.width * xTargetPosition + (imageSize / 2)  // Borda esquerda do alvo
        : screenSize.width * (1 - xTargetPosition) - (imageSize / 2);  // Borda direita do alvo
    final yPos = screenSize.height * yTargetPosition;
    final Offset targetCenterPx = Offset(xPos, yPos);

    final double targetRadiusPx = screenSize.shortestSide * 0.5 * targetScale;
    final double distancePx = (mark - targetCenterPx).distance;

    final markNorm = NormalisedOffset.fromOffset(mark, screenSize);
    final noseNorm = NormalisedOffset.fromOffset(nose, screenSize);
    final targetCenterNorm =
        NormalisedOffset.fromOffset(targetCenterPx, screenSize);
    final targetRadiusNorm = targetRadiusPx / screenSize.shortestSide;
    final distanceNorm = distancePx / screenSize.shortestSide;

    return TouchLog(
      timestamp: timestamp,
      targetCenter: targetCenterNorm,
      targetRadius: targetRadiusNorm,
      markPosition: markNorm,
      isInsideTarget: distanceNorm <= targetRadiusNorm,
      distanceToTarget: distanceNorm,
      isLeftHand: isLeft,
      gameMode: gameMode,
      nose: noseNorm,
    );
  }
}
