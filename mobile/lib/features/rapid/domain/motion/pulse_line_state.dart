/// Visual / physics state of the pulse line.
enum PulseLineState {
  /// Almost flat, minimal movement.
  idle,

  /// Regular peaks, normal movement.
  active,

  /// Erratic patterns.
  unstable,

  /// Completely flat.
  flatline,
}

extension PulseLineStateX on PulseLineState {
  /// Extra fall rate (1/s) layered on top of base gravity.
  double getDecayRate({
    double idleRate = 0.05,
    double activeRate = 0.03,
    double unstableRate = 0.07,
    double flatlineRate = 0.10,
  }) {
    return switch (this) {
      PulseLineState.idle => idleRate,
      PulseLineState.active => activeRate,
      PulseLineState.unstable => unstableRate,
      PulseLineState.flatline => flatlineRate,
    };
  }
}
