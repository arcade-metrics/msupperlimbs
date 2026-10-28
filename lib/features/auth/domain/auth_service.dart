import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/auth/data/auth_repository.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_adv_settings_state.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_settings_state.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_settings_state.dart';
import 'package:msupperlimbs/features/user/application/user_state.dart';

import '../../user/domain/services/user_service.dart';

final authServiceProvider = Provider((ref) {
  final authRepository = ref.read(authRepositoryProvider);
  final userService = ref.read(userServiceProvider);
  return AuthService(authRepository, userService);
});

class AuthService {
  final AuthRepository _authRepository;
  final UserService _userService;

  AuthService(this._authRepository, this._userService);

  Future<User?> signInWithEmail(
      WidgetRef ref, String email, String password) async {
    final firebaseUser = await _authRepository.signInWithEmail(email, password);
    if (firebaseUser != null) {
      await _userService.createOrUpdateUser(
          firebaseUser.uid, firebaseUser.displayName, firebaseUser.email);

      await ref
          .read(fnoseSettingsServiceProvider)
          .createFNoseSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(fnoseAdvSettingsServiceProvider)
          .createFNoseAdvSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(rapidSettingsServiceProvider)
          .createRapidSettingsIfNotExists(firebaseUser.uid);

      final sessionService = ref.read(sessionServiceProvider);
      await sessionService.createOrUpdateSession(ref, firebaseUser.uid);
    }
    return firebaseUser;
  }

  Future<User?> signUpWithEmail(
      WidgetRef ref, String email, String password) async {
    final firebaseUser = await _authRepository.signUpWithEmail(email, password);
    if (firebaseUser != null) {
      await _userService.createOrUpdateUser(
          firebaseUser.uid, firebaseUser.displayName, firebaseUser.email);

      await ref
          .read(fnoseSettingsServiceProvider)
          .createFNoseSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(fnoseAdvSettingsServiceProvider)
          .createFNoseAdvSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(rapidSettingsServiceProvider)
          .createRapidSettingsIfNotExists(firebaseUser.uid);
    }
    return firebaseUser;
  }

  Future<User?> signInWithGoogle(WidgetRef ref) async {
    final firebaseUser = await _authRepository.signInWithGoogle();
    if (firebaseUser != null) {
      await _userService.createOrUpdateUser(
          firebaseUser.uid, firebaseUser.displayName, firebaseUser.email);

      await ref
          .read(fnoseSettingsServiceProvider)
          .createFNoseSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(fnoseAdvSettingsServiceProvider)
          .createFNoseAdvSettingsIfNotExists(firebaseUser.uid);
      await ref
          .read(rapidSettingsServiceProvider)
          .createRapidSettingsIfNotExists(firebaseUser.uid);

      final sessionService = ref.read(sessionServiceProvider);
      await sessionService.createOrUpdateSession(ref, firebaseUser.uid);
    }
    return firebaseUser;
  }

  Future<void> signOut() async {
    return await _authRepository.signOut();
  }

  // Auth State Stream
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();
}
