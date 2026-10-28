import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/user/domain/entities/user.dart';
import 'package:msupperlimbs/features/user/domain/services/user_service.dart';

class UserNotifier extends StateNotifier<UserModel?> {
  final UserService _userService;

  UserNotifier(this._userService) : super(null);

  // Load user and update state
  Future<void> loadUser(String userId) async {
    debugPrint('[UserNotifier] Loading user with uid: $userId');
    final user = await _userService.getUserByUid(userId);
    state = user;
  }

  // Clean user state (logout)
  void clearUser() {
    state = null;
  }

  // Revoga o consentimento do usuário
  Future<void> revokeConsent() async {
    if (state == null) return;
    final updatedUser = UserModel(
      uid: state!.uid,
      displayName: state!.displayName,
      email: state!.email,
      createdAt: state!.createdAt,
      lastAccess: state!.lastAccess,
      hasConsent: false,
      consentTimestamp: state!.consentTimestamp,
      consentUpdatedAt: state!.consentUpdatedAt,
      consentRevokedAt: DateTime.now().toIso8601String(),
      consentVersion: state!.consentVersion,
    );
    await _userService.createOrUpdateUser(
      updatedUser.uid,
      updatedUser.displayName,
      updatedUser.email,
      // Adicione outros campos se necessário
    );
    state = updatedUser;
  }

  // Atualiza o usuário no repositório e no estado local
  Future<void> updateUser(UserModel updatedUser) async {
    await _userService.updateUserConsent(updatedUser);
    state = updatedUser;
  }
}
