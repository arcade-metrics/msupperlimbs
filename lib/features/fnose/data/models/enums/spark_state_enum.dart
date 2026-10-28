enum SparkState {
  idle, // Init state (without aura)
  armed, // nose touched (aura active)
  aiming, // while arm is going to touch the target
  fired // register touch
}
