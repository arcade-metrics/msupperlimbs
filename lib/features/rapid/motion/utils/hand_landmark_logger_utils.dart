import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:msupperlimbs/features/rapid/motion/utils/hand_frame_data_utils.dart';

class HandLandmarkLogger {
  static Map<String, dynamic> frameToJson(
    Pose pose,
    int timestamp,
    HandLandmarkSet? landmarkSet,
  ) {
    final joints = <String, Map<String, dynamic>>{};

    void add(String name, PoseLandmark? lm) {
      if (lm == null) return;
      joints[name] = {
        'x': lm.x,
        'y': lm.y,
        'z': lm.z,
        'likelihood': lm.likelihood,
      };
    }

    // Adiciona landmarks da mão esquerda com formato conciso (left_0 até left_20)
    add('left_0', landmarkSet?.leftWrist);
    add('left_1', landmarkSet?.leftThumbCMC);
    add('left_2', landmarkSet?.leftThumbMCP);
    add('left_3', landmarkSet?.leftThumbIP);
    add('left_4', landmarkSet?.leftThumbTip);
    add('left_5', landmarkSet?.leftIndexMCP);
    add('left_6', landmarkSet?.leftIndexPIP);
    add('left_7', landmarkSet?.leftIndexDIP);
    add('left_8', landmarkSet?.leftIndexTip);
    add('left_9', landmarkSet?.leftMiddleMCP);
    add('left_10', landmarkSet?.leftMiddlePIP);
    add('left_11', landmarkSet?.leftMiddleDIP);
    add('left_12', landmarkSet?.leftMiddleTip);
    add('left_13', landmarkSet?.leftRingMCP);
    add('left_14', landmarkSet?.leftRingPIP);
    add('left_15', landmarkSet?.leftRingDIP);
    add('left_16', landmarkSet?.leftRingTip);
    add('left_17', landmarkSet?.leftPinkyMCP);
    add('left_18', landmarkSet?.leftPinkyPIP);
    add('left_19', landmarkSet?.leftPinkyDIP);
    add('left_20', landmarkSet?.leftPinkyTip);
    
    // Adiciona landmarks da mão direita com formato conciso (right_0 até right_20)
    add('right_0', landmarkSet?.rightWrist);
    add('right_1', landmarkSet?.rightThumbCMC);
    add('right_2', landmarkSet?.rightThumbMCP);
    add('right_3', landmarkSet?.rightThumbIP);
    add('right_4', landmarkSet?.rightThumbTip);
    add('right_5', landmarkSet?.rightIndexMCP);
    add('right_6', landmarkSet?.rightIndexPIP);
    add('right_7', landmarkSet?.rightIndexDIP);
    add('right_8', landmarkSet?.rightIndexTip);
    add('right_9', landmarkSet?.rightMiddleMCP);
    add('right_10', landmarkSet?.rightMiddlePIP);
    add('right_11', landmarkSet?.rightMiddleDIP);
    add('right_12', landmarkSet?.rightMiddleTip);
    add('right_13', landmarkSet?.rightRingMCP);
    add('right_14', landmarkSet?.rightRingPIP);
    add('right_15', landmarkSet?.rightRingDIP);
    add('right_16', landmarkSet?.rightRingTip);
    add('right_17', landmarkSet?.rightPinkyMCP);
    add('right_18', landmarkSet?.rightPinkyPIP);
    add('right_19', landmarkSet?.rightPinkyDIP);
    add('right_20', landmarkSet?.rightPinkyTip);

    // Adicionar informação sobre quais mãos foram detectadas
    joints['handDetection'] = {
      'leftHandDetected': landmarkSet?.leftWrist != null,
      'rightHandDetected': landmarkSet?.rightWrist != null,
    };

    return {'timestamp_$timestamp': joints};
  }
}
