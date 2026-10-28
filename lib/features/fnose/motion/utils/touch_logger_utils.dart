import 'package:msupperlimbs/features/fnose/data/models/enums/fnose_game_mode_enum.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/normalised_offset_utils.dart';

class TouchLog {
  final int timestamp;
  final NormalisedOffset targetCenter;
  final double targetRadius; // permanece em pixels
  final NormalisedOffset markPosition;
  final bool isInsideTarget;
  final double distanceToTarget;
  final bool isLeftHand;
  final FNoseGameMode gameMode;
  final NormalisedOffset nose;

  TouchLog({
    required this.timestamp,
    required this.targetCenter,
    required this.targetRadius,
    required this.markPosition,
    required this.isInsideTarget,
    required this.distanceToTarget,
    required this.isLeftHand,
    required this.gameMode,
    required this.nose,
  });

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp,
        'targetCenter': targetCenter.toJson(),
        'targetRadius': targetRadius,
        'markPosition': markPosition.toJson(),
        'isInsideTarget': isInsideTarget,
        'distanceToTarget': distanceToTarget,
        'isLeftHand': isLeftHand,
        'gameMode': gameMode.name,
        'nose': nose.toJson(),
      };

  factory TouchLog.fromMap(Map<String, dynamic> map) {
    return TouchLog(
      timestamp: map['timestamp'],
      targetCenter: NormalisedOffset.fromJson(map['targetCenter']),
      targetRadius: (map['targetRadius'] as num).toDouble(),
      markPosition: NormalisedOffset.fromJson(map['markPosition']),
      isInsideTarget: map['isInsideTarget'],
      distanceToTarget: (map['distanceToTarget'] as num).toDouble(),
      isLeftHand: map['isLeftHand'],
      gameMode:
          FNoseGameModeX.fromString(map['gameMode']) ?? FNoseGameMode.leftHand,
      nose: NormalisedOffset.fromJson(map['nose']),
    );
  }
}
