import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/core/network/api_error_messages.dart';
import 'package:msupperlimbs/features/auth/domain/password_policy.dart';
import 'package:msupperlimbs/l10n/generated/app_localizations.dart';

const _user = {
  'id': 'u-1',
  'email': 'player@example.com',
  'name': 'Player',
  'role': 'PLAYER',
  'createdAt': '2026-01-15T12:00:00+00:00',
  'emailVerified': true,
  'isFirstAccess': false,
  'totpEnabled': false,
  'participantProfileId': null,
  'hasActiveEnrollment': false,
};

const _session = {
  'user': _user,
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
};

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  group('ApiClient auth', () {
    test('login parses the camelCase session', () async {
      late http.Request sent;
      final api = ApiClient(
        client: MockClient((request) async {
          sent = request;
          return _json(_session, 200);
        }),
      );

      final session = await api.login(
        email: 'player@example.com',
        password: 'SenhaForte1',
      );

      expect(sent.url.path, '/api/v1/auth/login');
      expect(jsonDecode(sent.body), {
        'email': 'player@example.com',
        'password': 'SenhaForte1',
      });
      expect(session.tokens.accessToken, 'access-1');
      expect(session.tokens.refreshToken, 'refresh-1');
      expect(session.user.role, 'PLAYER');
      expect(session.user.participantProfileId, isNull);
      expect(session.user.hasActiveEnrollment, isFalse);
    });

    test('register accepts 201 and sends no consent', () async {
      late http.Request sent;
      final api = ApiClient(
        client: MockClient((request) async {
          sent = request;
          return _json(_session, 201);
        }),
      );

      final session = await api.register(
        email: 'player@example.com',
        password: 'SenhaForte1',
        name: 'Player',
      );

      expect(sent.url.path, '/api/v1/auth/register');
      expect(jsonDecode(sent.body), {
        'email': 'player@example.com',
        'password': 'SenhaForte1',
        'name': 'Player',
      });
      expect(session.user.id, 'u-1');
    });

    test('me reads the enrolment fields', () async {
      final api = ApiClient(
        client: MockClient((request) async {
          expect(request.headers['Authorization'], 'Bearer access-1');
          return _json({
            ..._user,
            'role': 'PARTICIPANT',
            'participantProfileId': 'pp-1',
            'hasActiveEnrollment': true,
          }, 200);
        }),
      );

      final user = await api.me('access-1');

      expect(user.role, 'PARTICIPANT');
      expect(user.participantProfileId, 'pp-1');
      expect(user.hasActiveEnrollment, isTrue);
    });

    test('logout sends the refresh token and accepts 204', () async {
      late http.Request sent;
      final api = ApiClient(
        client: MockClient((request) async {
          sent = request;
          return http.Response('', 204);
        }),
      );

      await api.logout(accessToken: 'access-1', refreshToken: 'refresh-1');

      expect(sent.url.path, '/api/v1/auth/logout');
      expect(sent.headers['Authorization'], 'Bearer access-1');
      expect(jsonDecode(sent.body), {'refreshToken': 'refresh-1'});
    });

    test('postJson accepts 202', () async {
      final api = ApiClient(
        client: MockClient((_) async => _json({'created': true}, 202)),
      );

      final body = await api.postJson('/x', accessToken: 'access-1');

      expect(body, {'created': true});
    });

    test('errors carry the ciatec-core code', () async {
      final api = ApiClient(
        client: MockClient(
          (_) async => _json({
            'success': false,
            'code': 'INVALID_CREDENTIALS',
            'message': 'Invalid email or password',
          }, 401),
        ),
      );

      await expectLater(
        api.login(email: 'player@example.com', password: 'wrong'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 401)
              .having((e) => e.code, 'code', 'INVALID_CREDENTIALS')
              .having((e) => e.message, 'message', 'Invalid email or password'),
        ),
      );
    });

    test('a non-JSON error has no code', () async {
      final api = ApiClient(
        client: MockClient((_) async => http.Response('<html>', 502)),
      );

      await expectLater(
        api.me('access-1'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 502)
              .having((e) => e.code, 'code', isNull),
        ),
      );
    });
  });

  group('password policy', () {
    test('matches the ciatec-core rule', () {
      expect(meetsPasswordPolicy('SenhaForte1'), isTrue);
      expect(meetsPasswordPolicy('Senha1'), isFalse);
      expect(meetsPasswordPolicy('senhaforte1'), isFalse);
      expect(meetsPasswordPolicy('SenhaForte'), isFalse);
    });
  });

  group('apiErrorMessage', () {
    final l10n = lookupAppLocalizations(const Locale('pt'));

    ApiException error(int status, [String? code]) =>
        ApiException(statusCode: status, code: code, message: '');

    test('maps known codes', () {
      expect(
        apiErrorMessage(l10n, error(401, 'INVALID_CREDENTIALS')),
        l10n.auth_invalidCredentials,
      );
      expect(
        apiErrorMessage(l10n, error(409, 'EMAIL_IN_USE')),
        l10n.auth_emailInUse,
      );
      expect(
        apiErrorMessage(l10n, error(400, 'VALIDATION_ERROR')),
        l10n.error_validation,
      );
    });

    test('falls back by status and error type', () {
      expect(apiErrorMessage(l10n, error(503)), l10n.error_server);
      expect(apiErrorMessage(l10n, error(404, 'OTHER')), l10n.error_generic);
      expect(
        apiErrorMessage(l10n, const SocketException('offline')),
        l10n.error_network,
      );
    });
  });
}
