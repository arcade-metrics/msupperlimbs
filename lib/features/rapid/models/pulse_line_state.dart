import 'package:flutter/material.dart';

/// Represents the visual state of the pulse line
enum PulseLineState {
  /// Line is almost flat, minimal movement
  idle,
  
  /// Line shows regular peaks, normal movement
  active,
  
  /// Line shows erratic patterns, irregular movement
  unstable,
  
  /// Line is completely flat, no movement
  flatline
}

/// Extension to provide visual properties for each state
extension PulseLineStateExtension on PulseLineState {
  /// Returns the color associated with this state
  Color get color {
    switch (this) {
      case PulseLineState.idle:
        return Colors.blue.shade300;
      case PulseLineState.active:
        return Colors.green;
      case PulseLineState.unstable:
        return Colors.amber;
      case PulseLineState.flatline:
        return Colors.red.shade300;
    }
  }
  
  /// Returns the line width for this state
  double get lineWidth {
    switch (this) {
      case PulseLineState.idle:
        return 2.0;
      case PulseLineState.active:
        return 3.0;
      case PulseLineState.unstable:
        return 3.5;
      case PulseLineState.flatline:
        return 1.5;
    }
  }
  
  /// Returns the decay rate for this state
  /// If settings are provided, use those values, otherwise use defaults
  double getDecayRate({
    double? idleRate,
    double? activeRate,
    double? unstableRate,
    double? flatlineRate,
  }) {
    switch (this) {
      case PulseLineState.idle:
        return idleRate ?? 0.05;
      case PulseLineState.active:
        return activeRate ?? 0.03;
      case PulseLineState.unstable:
        return unstableRate ?? 0.07;
      case PulseLineState.flatline:
        return flatlineRate ?? 0.10;
    }
  }
  
  /// Legacy getter for backward compatibility
  double get decayRate => getDecayRate();
}
