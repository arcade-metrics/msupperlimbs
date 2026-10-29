import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:msupperlimbs/core/config/api_config.dart';
import 'package:msupperlimbs/features/auth/data/models/auth_models.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

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

  Future<AuthUser> me(String accessToken) async {
    final response = await _client.get(
      _uri('/auth/me'),
      headers: _authHeaders(accessToken),
    );
    return AuthUser.fromJson(_decode(response));
  }

  /// Revokes [refreshToken] on the server (204).
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
    final response = await _client.get(
      _uri(path),
      headers: _authHeaders(accessToken),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: {..._authHeaders(accessToken), ..._json},
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: {..._authHeaders(accessToken), ..._json},
      body: body == null ? null : jsonEncode(body),
    );
    return _decode(response);
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
