/// MediaPipe Hands fingertip landmark indices.
class MpTipIndex {
  static const int thumb = 4;
  static const int index = 8;
  static const int middle = 12;
  static const int ring = 16;
  static const int pinky = 20;

  static const List<int> nonThumbTips = [index, middle, ring, pinky];
}
