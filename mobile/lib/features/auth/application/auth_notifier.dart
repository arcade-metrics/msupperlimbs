import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/auth/data/models/auth_models.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.error,
  });

  final AuthStatus status;
  final AuthUser? user;
  final String? accessToken;
  final String? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? accessToken,
    String? error,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api, this._storage)
    : super(const AuthState(status: AuthStatus.unknown)) {
    restore();
  }

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  Future<void> restore() async {
    final token = await _storage.read(key: _accessKey);
    if (token == null || token.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _api.me(token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: token,
      );
    } catch (_) {
      await _clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _api.login(email: email, password: password);
      await _persist(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        accessToken: session.tokens.accessToken,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required bool consent,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _api.register(
        email: email,
        password: password,
        name: name,
        consent: consent,
      );
      await _persist(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        accessToken: session.tokens.accessToken,
      );
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        error: e.toString(),
      );
    }
  }

  Future<void> logout() async {
    await _clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> _persist(AuthSession session) async {
    await _storage.write(key: _accessKey, value: session.tokens.accessToken);
    await _storage.write(key: _refreshKey, value: session.tokens.refreshToken);
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    ref.watch(apiClientProvider),
    ref.watch(secureStorageProvider),
  );
});
