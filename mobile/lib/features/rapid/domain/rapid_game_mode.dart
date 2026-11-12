/// The API accepts only one hand per match (`leftHand` / `rightHand`).
enum RapidGameMode { leftHand, rightHand }

extension RapidGameModeX on RapidGameMode {
  String get apiValue => switch (this) {
    RapidGameMode.leftHand => 'leftHand',
    RapidGameMode.rightHand => 'rightHand',
  };

  String get label => switch (this) {
    RapidGameMode.leftHand => 'Left Hand Only',
    RapidGameMode.rightHand => 'Right Hand Only',
  };

  String get description => switch (this) {
    RapidGameMode.leftHand => 'Play using only your left hand',
    RapidGameMode.rightHand => 'Play using only your right hand',
  };

  static RapidGameMode fromString(String value) {
    return switch (value) {
      'leftHand' => RapidGameMode.leftHand,
      _ => RapidGameMode.rightHand,
    };
  }
}
