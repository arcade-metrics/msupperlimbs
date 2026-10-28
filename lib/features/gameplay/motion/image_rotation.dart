/// Rotation of an image or camera frame in degrees
enum ImageRotation {
  rotation0deg,
  rotation90deg,
  rotation180deg,
  rotation270deg;

  int get degrees {
    switch (this) {
      case ImageRotation.rotation0deg:
        return 0;
      case ImageRotation.rotation90deg:
        return 90;
      case ImageRotation.rotation180deg:
        return 180;
      case ImageRotation.rotation270deg:
        return 270;
    }
  }
}

