class MediaPipePoseLandmark {
  final int index; // 0..32 per MediaPipe spec
  final double x; // normalized [0,1]
  final double y; // normalized [0,1]
  final double z; // in meters (approx), can be negative
  final double visibility; // [0,1]

  const MediaPipePoseLandmark({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  factory MediaPipePoseLandmark.fromMap(Map<String, dynamic> map) {
    return MediaPipePoseLandmark(
      index: (map['index'] ?? 0) as int,
      x: (map['x'] ?? 0.0).toDouble(),
      y: (map['y'] ?? 0.0).toDouble(),
      z: (map['z'] ?? 0.0).toDouble(),
      visibility: (map['visibility'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
        'index': index,
        'x': x,
        'y': y,
        'z': z,
        'visibility': visibility,
      };
}

class MediaPipePose {
  final List<MediaPipePoseLandmark> landmarks; // expected length 33

  const MediaPipePose({required this.landmarks});

  factory MediaPipePose.fromDynamicList(List<dynamic> items) {
    final list = <MediaPipePoseLandmark>[];
    for (final item in items) {
      if (item is Map) {
        final Map<String, dynamic> casted = {};
        item.forEach((key, value) {
          if (key is String) casted[key] = value;
        });
        list.add(MediaPipePoseLandmark.fromMap(casted));
      }
    }
    return MediaPipePose(landmarks: list);
  }
}

// Landmark indices mapping (reference)
// 0: NOSE, 1: LEFT_EYE_INNER, 2: LEFT_EYE, 3: LEFT_EYE_OUTER,
// 4: RIGHT_EYE_INNER, 5: RIGHT_EYE, 6: RIGHT_EYE_OUTER,
// 7: LEFT_EAR, 8: RIGHT_EAR, 9: MOUTH_LEFT, 10: MOUTH_RIGHT,
// 11: LEFT_SHOULDER, 12: RIGHT_SHOULDER, 13: LEFT_ELBOW, 14: RIGHT_ELBOW,
// 15: LEFT_WRIST, 16: RIGHT_WRIST, 17: LEFT_PINKY, 18: RIGHT_PINKY,
// 19: LEFT_INDEX, 20: RIGHT_INDEX, 21: LEFT_THUMB, 22: RIGHT_THUMB,
// 23: LEFT_HIP, 24: RIGHT_HIP, 25: LEFT_KNEE, 26: RIGHT_KNEE,
// 27: LEFT_ANKLE, 28: RIGHT_ANKLE, 29: LEFT_HEEL, 30: RIGHT_HEEL,
// 31: LEFT_FOOT_INDEX, 32: RIGHT_FOOT_INDEX


