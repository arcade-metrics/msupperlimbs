import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_spark_controller.dart';
import 'package:msupperlimbs/features/fnose/data/models/enums/spark_state_enum.dart';

final leftSparkControllerProvider =
    StateNotifierProvider<SparkController, SparkState>((ref) {
  return SparkController();
});

final rightSparkControllerProvider =
    StateNotifierProvider<SparkController, SparkState>((ref) {
  return SparkController();
});
