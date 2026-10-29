import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/calibration/application/calibration_job.dart';
import 'package:msupperlimbs/features/calibration/application/calibration_providers.dart';
import 'package:msupperlimbs/features/match/application/match_flow.dart';
import 'package:msupperlimbs/features/match/application/pending_uploads.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/match/data/pending_upload_store.dart';
import 'package:path_provider/path_provider.dart';

/// One per app run, so the resolved game/level is cached across matches.
final matchApiProvider = Provider<MatchApi>(
  (ref) => MatchApi(ref.watch(apiClientProvider)),
);

/// Matches and calibration runs kept on the device until they are sent.
final pendingUploadsProvider = Provider<PendingUploads>((ref) {
  String? token() => ref.read(authProvider).accessToken;
  final matches = ref.watch(matchApiProvider);
  final matchJobs = MatchJobRunner(matches, token);
  final calibrationJobs = CalibrationJobRunner(
    matches,
    ref.watch(calibrationApiProvider),
    token,
  );
  return PendingUploads(
    FilePendingUploadStore(() async {
      final base = await getApplicationSupportDirectory();
      return Directory('${base.path}/pending_uploads');
    }),
    handlers: {
      PendingMatch.kind: matchJobs.replay,
      PendingCalibration.kind: calibrationJobs.replay,
    },
    userId: () => ref.read(authProvider).user?.id,
  );
});

/// Watched by the app root: sends what was kept every time a user is
/// authenticated (app start with a saved session, or login).
final pendingUploadsFlushProvider = Provider<void>((ref) {
  ref.listen<AuthStatus>(authProvider.select((auth) => auth.status), (
    previous,
    next,
  ) {
    if (next == AuthStatus.authenticated) {
      unawaited(ref.read(pendingUploadsProvider).flush());
    }
  }, fireImmediately: true);
});
