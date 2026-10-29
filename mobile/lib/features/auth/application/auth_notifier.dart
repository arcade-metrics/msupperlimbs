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

  /// Last login/register failure; shown with `apiErrorMessage`.
  final Object? error;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? accessToken,
    Object? error,
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
    _api.onUnauthorized = _refreshAfterUnauthorized;
    restore();
  }

  final ApiClient _api;
  final FlutterSecureStorage _storage;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  /// The refresh in flight. The server rotates the refresh token, so two
  /// concurrent refreshes would revoke each other: callers share this one.
  Future<String?>? _refreshing;

  /// Cold start: the stored access token may have expired, so the session is
  /// reopened with the refresh token. A rejected refresh ends the session; a
  /// network failure keeps the tokens for the next start.
  Future<void> restore() async {
    final stored = await _storage.read(key: _refreshKey);
    if (stored == null || stored.isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    final token = await _refreshOnce();
    if (token == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }
    try {
      final user = await _api.me(token);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
        accessToken: state.accessToken ?? token,
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<String?> _refreshAfterUnauthorized(String rejectedToken) async {
    final current = state.accessToken;
    if (current != null && current != rejectedToken) return current;
    return _refreshOnce();
  }

  Future<String?> _refreshOnce() {
    return _refreshing ??= _refresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _refresh() async {
    final refreshToken = await _storage.read(key: _refreshKey);
    if (refreshToken == null || refreshToken.isEmpty) {
      await _endSession();
      return null;
    }
    try {
      final tokens = await _api.refresh(refreshToken);
      await _persistTokens(tokens);
      state = state.copyWith(accessToken: tokens.accessToken);
      return tokens.accessToken;
    } on ApiException catch (e) {
      if (e.statusCode == 401) await _endSession();
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _endSession() async {
    await _clearTokens();
    state = const AuthState(status: AuthStatus.unauthenticated);
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
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = state.copyWith(clearError: true);
    try {
      final session = await _api.register(
        email: email,
        password: password,
        name: name,
      );
      await _persist(session);
      state = AuthState(
        status: AuthStatus.authenticated,
        user: session.user,
        accessToken: session.tokens.accessToken,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.unauthenticated, error: e);
    }
  }

  Future<void> logout() async {
    final accessToken = state.accessToken;
    final refreshToken = await _storage.read(key: _refreshKey);
    try {
      if (accessToken != null && refreshToken != null) {
        await _api.logout(accessToken: accessToken, refreshToken: refreshToken);
      }
    } catch (_) {
      // The local session ends even if the server could not be reached.
    } finally {
      await _clearTokens();
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> _persist(AuthSession session) => _persistTokens(session.tokens);

  Future<void> _persistTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessKey, value: tokens.accessToken);
    await _storage.write(key: _refreshKey, value: tokens.refreshToken);
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

/// Id of the logged-in user, for routes scoped to the caller
/// (`/{slug}/players/{user_id}/…`).
String currentUserId(Ref ref) {
  final id = ref.read(authProvider).user?.id;
  if (id == null) throw StateError('Not authenticated');
  return id;
}
