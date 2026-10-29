import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

/// One per app run, so the resolved game/level is cached across matches.
final matchApiProvider = Provider<MatchApi>(
  (ref) => MatchApi(ref.watch(apiClientProvider)),
);
