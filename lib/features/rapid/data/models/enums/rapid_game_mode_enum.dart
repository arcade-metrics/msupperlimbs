enum RapidGameMode {
  leftHand,
  rightHand,
  bothHands,
}

extension RapidGameModeX on RapidGameMode {
  String get name {
    switch (this) {
      case RapidGameMode.leftHand:
        return 'leftHand';
      case RapidGameMode.rightHand:
        return 'rightHand';
      case RapidGameMode.bothHands:
        return 'bothHands';
    }
  }

  static RapidGameMode fromString(String value) {
    switch (value) {
      case 'leftHand':
        return RapidGameMode.leftHand;
      case 'rightHand':
        return RapidGameMode.rightHand;
      case 'bothHands':
        return RapidGameMode.bothHands;
      default:
        return RapidGameMode.rightHand; // Default value
    }
  }
}
