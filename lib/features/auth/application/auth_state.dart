import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/data/auth_repository.dart';
import 'package:msupperlimbs/features/auth/domain/auth_service.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';
import 'package:msupperlimbs/features/user/domain/entities/user.dart';

// Provides the authentication repository (e.g. FirebaseAuth wrapper)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

// Composes authentication logic using AuthRepository and UserService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.read(authRepositoryProvider),
    ref.read(userServiceProvider),
  );
});

// Exposes authentication state stream (auto-disposed on unmount)
final authStateProvider = StreamProvider.autoDispose((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Listens to auth state and loads/clears user accordingly
final authStateListenerProvider = Provider<void>((ref) {
  ref.listen<UserModel?>(userProvider, (previous, next) {});

  ref.listen(authStateProvider, (previous, next) {
    final user = next.value;
    if (user != null) {
      ref.read(userProvider.notifier).loadUser(user.uid);
    } else {
      ref.read(userProvider.notifier).clearUser();
    }
  });
});
