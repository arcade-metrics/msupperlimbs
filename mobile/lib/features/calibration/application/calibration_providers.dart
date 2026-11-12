import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';

final calibrationApiProvider = Provider<CalibrationApi>(
  (ref) => CalibrationApi(ref.watch(apiClientProvider)),
);
