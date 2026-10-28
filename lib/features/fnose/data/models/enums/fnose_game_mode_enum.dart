enum FNoseGameMode {
  leftHand,
  rightHand,
  bothHands,
}

extension FNoseGameModeX on FNoseGameMode {
  String get asString => name;

  static FNoseGameMode fromString(String value) {
    return FNoseGameMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => FNoseGameMode.bothHands,
    );
  }
}
