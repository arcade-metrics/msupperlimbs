enum FNoseGameState {
  waitingStableDevice, // Waiting for stable position
  waitingUserPositioning, // Device is stable, waiting for correct user positioning
  preGame, // Countdown or success message before starting
  touchNose, // Player should touch nose
  touchTarget, // Player should touch the target
  ended // Game is over
}
