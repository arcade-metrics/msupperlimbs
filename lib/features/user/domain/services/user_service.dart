import 'package:msupperlimbs/features/fnose/domain/fnose_settings_service.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_settings_service.dart';
import 'package:msupperlimbs/features/user/data/repositories/user_repository.dart';
import 'package:msupperlimbs/features/gameplay/domain/session_service.dart';
import 'package:msupperlimbs/features/user/domain/entities/user.dart';

abstract class UserService {
  Future<void> createOrUpdateUser(
      String uid, String? displayName, String? email);
  Future<UserModel?> getUserByUid(String uid);
  Future<void> updateUserConsent(UserModel user);
}

class UserServiceImpl implements UserService {
  final UserRepository _userRepository;
  final SessionService _sessionService;
  final FNoseSettingsService _fnoseSettingsService;
  final RapidSettingsService _rapidSettingsService;

  UserServiceImpl(
      this._userRepository, this._sessionService, this._fnoseSettingsService, this._rapidSettingsService);

  @override
  Future<void> createOrUpdateUser(
      String uid, String? displayName, String? email) async {
    final userExists = await _userRepository.userExists(uid);

    UserModel user;
    if (!userExists) {
      user = UserModel(
        uid: uid,
        displayName: displayName ?? email ?? "User-${uid.substring(0, 6)}",
        email: email ?? '',
        createdAt: DateTime.now().toUtc().toIso8601String(),
        lastAccess: DateTime.now().toUtc().toIso8601String(),
        hasConsent: false, // Novo usuário sem consentimento
      );

      await _userRepository.createUser(user);
      await _fnoseSettingsService.createFNoseSettingsStandard(uid);
      await _rapidSettingsService.createRapidSettingsStandard(uid);
    } else {
      user = (await _userRepository.getUser(uid))!;
      await _userRepository.updateLastAccess(user.uid);
    }
  }

  @override
  Future<void> updateUserConsent(UserModel user) async {
    await _userRepository.updateUser(user);
  }

  @override
  Future<UserModel?> getUserByUid(String uid) async {
    return await _userRepository.getUser(uid);
  }
}
