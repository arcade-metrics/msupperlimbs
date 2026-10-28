import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/finger_tap_detector.dart';
import 'package:msupperlimbs/features/rapid/domain/motion/pulse_line_controller.dart';

/// Builds game-motion engines from persisted Rapid settings.
class RapidMotionFactory {
  const RapidMotionFactory._();

  static FingerTapDetector tapDetector(RapidSettings settings) =>
      FingerTapDetector.fromSettings(settings);

  static PulseLineController pulseController(RapidSettings settings) =>
      PulseLineController.fromSettings(settings);
}
