enum RapidGamePhase {
  /// Waiting for a hand in frame.
  waitingHand,

  /// Hand visible; hold still for validation.
  holdingHand,

  /// 3-2-1-GO overlay.
  countdown,

  /// Match running.
  playing,

  /// Timer ended.
  finished,
}
