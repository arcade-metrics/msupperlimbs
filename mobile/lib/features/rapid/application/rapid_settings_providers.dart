import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/rapid/data/models/rapid_settings.dart';
import 'package:msupperlimbs/features/rapid/data/rapid_match_repository.dart';
import 'package:msupperlimbs/features/rapid/data/rapid_settings_repository.dart';

final rapidSettingsRepositoryProvider = Provider<RapidSettingsRepository>((
  ref,
) {
  return RapidSettingsRepository(
    ref.watch(apiClientProvider),
    () => currentUserId(ref),
  );
});

final rapidSettingsProvider = FutureProvider<RapidSettings>((ref) async {
  final status = ref.watch(authProvider.select((auth) => auth.status));
  final token = ref.read(authProvider).accessToken;
  if (token == null || status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  return ref.watch(rapidSettingsRepositoryProvider).getSettings(token);
});

final rapidSettingsDraftProvider = StateProvider<RapidSettings?>((ref) => null);

final rapidMatchRepositoryProvider = Provider<RapidMatchRepository>((ref) {
  return RapidMatchRepository(ref.watch(apiClientProvider));
});
