import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:msupperlimbs/core/config/api_config.dart';
import 'package:msupperlimbs/features/auth/data/models/auth_models.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) =>
      Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}$path');

  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
    required bool consent,
  }) async {
    final response = await _client.post(
      _uri('/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'name': name,
        'consent': consent,
      }),
    );
    return _parseAuthSession(response);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      _uri('/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseAuthSession(response);
  }

  Future<AuthUser> me(String accessToken) async {
    final response = await _client.get(
      _uri('/auth/me'),
      headers: _authHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return AuthUser.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri(path),
      headers: _authHeaders(accessToken),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> putJson(
    String path, {
    required String accessToken,
    required Map<String, dynamic> body,
  }) async {
    final response = await _client.put(
      _uri(path),
      headers: {
        ..._authHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    required String accessToken,
    Map<String, dynamic>? body,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: {
        ..._authHeaders(accessToken),
        'Content-Type': 'application/json',
      },
      body: body == null ? null : jsonEncode(body),
    );
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Map<String, String> _authHeaders(String accessToken) => {
    'Authorization': 'Bearer $accessToken',
  };

  AuthSession _parseAuthSession(http.Response response) {
    if (response.statusCode != 200) {
      throw ApiException(_errorMessage(response));
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession.fromJson(body);
  }

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {}
    return 'Request failed (${response.statusCode})';
  }
}

class ApiException implements Exception {
  ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}
