import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/spark_state_enum.dart';

class SparkController extends StateNotifier<SparkState> {
  SparkController() : super(SparkState.idle);

  void setState(SparkState newState) => state = newState;

  void goArmed() {
    if (state == SparkState.idle) {
      state = SparkState.armed;
    }
  }

  void goAiming() {
    if (state == SparkState.armed) {
      state = SparkState.aiming;
    }
  }

  void goFire() {
    if (state == SparkState.aiming) {
      state = SparkState.fired;
    }
  }

  void reset() {
    state = SparkState.idle;
  }
}
