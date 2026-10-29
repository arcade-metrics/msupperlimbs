import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:msupperlimbs/core/config/api_config.dart';
import 'package:msupperlimbs/features/auth/data/models/auth_models.dart';

/// Called when an authenticated request gets 401 with [rejectedToken].
/// Returns the access token to retry with, or null when the session is gone.
typedef UnauthorizedHandler = Future<String?> Function(String rejectedToken);

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Set by the auth layer; without it a 401 is returned as is.
  UnauthorizedHandler? onUnauthorized;

  static const _json = {'Content-Type': 'application/json'};

  Uri _uri(String path) =>
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}$path');

  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _client.post(
      _uri('/auth/register'),
      headers: _json,
      body: jsonEncode({'email': email, 'password': password, 'name': name}),
    );
    return AuthSession.fromJson(_decode(response));
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/auth/login'),
      headers: _json,
      body: jsonEncode({'email': email, 'password': password}),
    );
    return AuthSession.fromJson(_decode(response));
  }

  /// Rotates the pair: the old refresh token stops working.
  Future<AuthTokens> refresh(String refreshToken) async {
    final response = await _client.post(
      _uri('/auth/refresh'),
      headers: _json,
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    return AuthTokens.fromJson(_decode(response));
  }

  Future<AuthUser> me(String accessToken) async {
    final response = await _authed(
      accessToken,
      (auth) => _client.get(_uri('/auth/me'), headers: auth),
    );
    return AuthUser.fromJson(_decode(response));
  }

  /// Revokes [refreshToken] on the server (204). Not retried on 401: a
  /// refresh would rotate the pair and revoke [refreshToken] anyway.
  Future<void> logout({
    required String accessToken,
    required String refreshToken,
  }) async {
    final response = await _client.post(
      _uri('/auth/logout'),
      headers: {..._authHeaders(accessToken), ..._json},
      body: jsonEncode({'refreshToken': refreshToken}),
    );
    _decode(response);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String accessToken,
  }) async {
    final response = await _authed(
      accessToken,
      (auth) => _client.get(_uri(path), headers: auth),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _authed(
      accessToken,
      (auth) => _client.put(
        _uri(path),
        headers: {...auth, ..._json},
        body: jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _authed(
      accessToken,
      (auth) => _client.post(
        _uri(path),
        headers: {...auth, ..._json},
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  /// Sends with [accessToken]; on 401 asks [onUnauthorized] for a new token
  /// and retries once. A second 401 is returned to the caller.
  Future<http.Response> _authed(
    String accessToken,
    Future<http.Response> Function(Map<String, String> auth) send,
  ) async {
    final response = await send(_authHeaders(accessToken));
    final handler = onUnauthorized;
    if (response.statusCode != 401 || handler == null) return response;
    final fresh = await handler(accessToken);
    if (fresh == null) return response;
    return send(_authHeaders(fresh));
  }

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  /// Any 2xx is a success; 204 and other empty bodies decode to `{}`.
  Map<String, dynamic> _decode(http.Response response) {
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw ApiException.fromResponse(response);
    }
    if (response.body.isEmpty) return const {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

/// Error returned by ciatec-core: `{success: false, code, message}`.
///
/// [code] is null when the body is not in that format (proxy errors, 5xx
/// HTML pages); the UI then falls back to a generic message.
class ApiException implements Exception {
  ApiException({required this.statusCode, this.code, required this.message});

  factory ApiException.fromResponse(http.Response response) {
    String? code;
    String? message;
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        code = body['code'] as String?;
        message = (body['message'] ?? body['detail'])?.toString();
      }
    } catch (_) {}
    return ApiException(
      statusCode: response.statusCode,
      code: code,
      message: message ?? 'Request failed (${response.statusCode})',
    );
  }

  final int statusCode;
  final String? code;
  final String message;

  @override
  String toString() => code == null ? message : '$code: $message';
}
