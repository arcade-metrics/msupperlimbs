enum RapidGameMode { leftHand, rightHand, bothHands }

extension RapidGameModeX on RapidGameMode {
  String get apiValue => switch (this) {
    RapidGameMode.leftHand => 'leftHand',
    RapidGameMode.rightHand => 'rightHand',
    RapidGameMode.bothHands => 'bothHands',
  };

  String get label => switch (this) {
    RapidGameMode.leftHand => 'Left Hand Only',
    RapidGameMode.rightHand => 'Right Hand Only',
    RapidGameMode.bothHands => 'Both Hands',
  };

  String get description => switch (this) {
    RapidGameMode.leftHand => 'Play using only your left hand',
    RapidGameMode.rightHand => 'Play using only your right hand',
    RapidGameMode.bothHands => 'Play using both hands',
  };

  static RapidGameMode fromString(String value) {
    return switch (value) {
      'leftHand' => RapidGameMode.leftHand,
      'bothHands' => RapidGameMode.bothHands,
      _ => RapidGameMode.rightHand,
    };
  }
}
