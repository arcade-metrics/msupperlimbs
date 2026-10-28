enum FnoseSparkState { idle, armed, aiming, fire }

enum FnoseGamePhase {
  deviceStill,
  deviceRoll,
  devicePitch,
  alignNose,
  calibrateFinger,
  countdown,
  playing,
  finished,
}

/// MediaPipe Pose landmark indices used by FNose.
class PoseIdx {
  static const nose = 0;
  static const leftShoulder = 11;
  static const rightShoulder = 12;
  static const leftElbow = 13;
  static const rightElbow = 14;
  static const leftWrist = 15;
  static const rightWrist = 16;
  static const leftIndex = 19;
  static const rightIndex = 20;
}
