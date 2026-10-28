import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:msupperlimbs/features/fnose/motion/utils/pose_frame_data_utils.dart';

class GamePoseLogger {
  static Map<String, dynamic> frameToJson(
    Pose pose,
    int timestamp,
    LandmarkSet? landmarkSet,
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

    // add landmarks to frame
    add('nose', landmarkSet?.nose);
    add('leftShoulder', landmarkSet?.leftShoulder);
    add('rightShoulder', landmarkSet?.rightShoulder);
    add('leftElbow', landmarkSet?.leftElbow);
    add('rightElbow', landmarkSet?.rightElbow);
    add('leftWrist', landmarkSet?.leftWrist);
    add('rightWrist', landmarkSet?.rightWrist);
    add('leftIndex', landmarkSet?.leftIndex);
    add('rightIndex', landmarkSet?.rightIndex);
    add('leftIndexTip', landmarkSet?.leftIndexTip);
    add('rightIndexTip', landmarkSet?.rightIndexTip);

    return {'timestamp_$timestamp': joints};
  }
}
