import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/data/fnose_match_repository.dart';
import 'package:msupperlimbs/features/fnose/data/fnose_pregame_repository.dart';
import 'package:msupperlimbs/features/fnose/data/fnose_settings_repository.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';

final fnoseSettingsRepositoryProvider = Provider<FnoseSettingsRepository>((
  ref,
) {
  return FnoseSettingsRepository(ref.watch(apiClientProvider));
});

final fnosePregameRepositoryProvider = Provider<FnosePregameRepository>((ref) {
  return FnosePregameRepository(ref.watch(apiClientProvider));
});

final fnoseSettingsProvider = FutureProvider<FnoseSettings>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (token == null || auth.status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  return ref.watch(fnoseSettingsRepositoryProvider).getSettings(token);
});

final fnoseAdvSettingsProvider = FutureProvider<FnoseAdvSettings>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (token == null || auth.status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  return ref.watch(fnoseSettingsRepositoryProvider).getAdvSettings(token);
});

final fnoseMatchRepositoryProvider = Provider<FnoseMatchRepository>((ref) {
  return FnoseMatchRepository(ref.watch(apiClientProvider));
});
