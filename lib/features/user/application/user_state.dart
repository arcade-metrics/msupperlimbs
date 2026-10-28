import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/user/data/repositories/user_repository.dart';
import 'package:msupperlimbs/features/gameplay/data/repositories/session_repository.dart';
import 'package:msupperlimbs/features/gameplay/domain/session_service.dart';
import 'package:msupperlimbs/features/user/domain/entities/user.dart';
import 'package:msupperlimbs/features/user/domain/services/user_service.dart';
import 'package:msupperlimbs/features/user/application/user_notifier.dart';

// Repositories
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository();
});

// Services
final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.read(sessionRepositoryProvider));
});

final userServiceProvider = Provider<UserService>((ref) {
  return UserServiceImpl(
    ref.read(userRepositoryProvider),
    ref.read(sessionServiceProvider),
    ref.read(fnoseSettingsServiceProvider),
    ref.read(rapidSettingsServiceProvider),
  );
});

// User state with StateNotifier
final userProvider = StateNotifierProvider<UserNotifier, UserModel?>((ref) {
  return UserNotifier(ref.read(userServiceProvider));
});
