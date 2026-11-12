import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';
import 'package:msupperlimbs/features/fnose/data/fnose_settings_repository.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';

final fnoseSettingsRepositoryProvider = Provider<FnoseSettingsRepository>((
  ref,
) {
  return FnoseSettingsRepository(
    ref.watch(apiClientProvider),
    () => currentUserId(ref),
  );
});

final fnoseSettingsProvider = FutureProvider<FnoseSettings>((ref) async {
  final status = ref.watch(authProvider.select((auth) => auth.status));
  final token = ref.read(authProvider).accessToken;
  if (token == null || status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  return ref.watch(fnoseSettingsRepositoryProvider).getSettings(token);
});

final fnoseAdvSettingsProvider = FutureProvider<FnoseAdvSettings>((ref) async {
  final status = ref.watch(authProvider.select((auth) => auth.status));
  final token = ref.read(authProvider).accessToken;
  if (token == null || status != AuthStatus.authenticated) {
    throw StateError('Not authenticated');
  }
  return ref.watch(fnoseSettingsRepositoryProvider).getAdvSettings(token);
});
