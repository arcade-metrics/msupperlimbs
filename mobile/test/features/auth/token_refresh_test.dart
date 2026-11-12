import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/auth/application/auth_notifier.dart';

const _user = {
  'id': 'u-1',
  'email': 'player@example.com',
  'name': 'Player',
  'role': 'PLAYER',
};

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

http.Response _unauthorized(String code) =>
    _json({'success': false, 'code': code, 'message': code}, 401);

String? _bearer(http.Request request) =>
    request.headers['Authorization']?.replaceFirst('Bearer ', '');

/// Fake ciatec-core: each refresh hands out access-N / refresh-N and revokes
/// the previous refresh token; `/x` only accepts [validAccess].
class _FakeCore {
  _FakeCore({required this.validRefresh});

  String? validRefresh;
  String? validAccess;
  int refreshCalls = 0;
  bool offline = false;

  late final client = MockClient((request) async {
    if (offline) throw http.ClientException('offline');
    switch (request.url.path) {
      case '/api/v1/auth/refresh':
        refreshCalls++;
        final sent = (jsonDecode(request.body) as Map)['refreshToken'];
        if (sent != validRefresh) return _unauthorized('INVALID_REFRESH_TOKEN');
        validRefresh = 'refresh-$refreshCalls';
        validAccess = 'access-$refreshCalls';
        return _json({
          'accessToken': validAccess,
          'refreshToken': validRefresh,
        }, 200);
      case '/api/v1/auth/me':
      case '/api/v1/x':
        if (_bearer(request) != validAccess) {
          return _unauthorized('UNAUTHORIZED');
        }
        return _json(request.url.path.endsWith('/me') ? _user : {'ok': 1}, 200);
    }
    return http.Response('', 404);
  });
}

Future<AuthNotifier> _started(ApiClient api) async {
  final notifier = AuthNotifier(api, const FlutterSecureStorage());
  for (var i = 0; i < 100 && notifier.state.status == AuthStatus.unknown; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiClient 401 retry', () {
    test('retries once with the token from onUnauthorized', () async {
      final tokens = <String?>[];
      final api = ApiClient(
        client: MockClient((request) async {
          tokens.add(_bearer(request));
          return _bearer(request) == 'new'
              ? _json({'ok': 1}, 200)
              : _unauthorized('UNAUTHORIZED');
        }),
      );
      String? rejected;
      api.onUnauthorized = (token) async {
        rejected = token;
        return 'new';
      };

      final body = await api.getJson('/x', accessToken: 'old');

      expect(body, {'ok': 1});
      expect(rejected, 'old');
      expect(tokens, ['old', 'new']);
    });

    test('a second 401 is not retried again', () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return _unauthorized('UNAUTHORIZED');
        }),
      );
      var refreshes = 0;
      api.onUnauthorized = (_) async {
        refreshes++;
        return 'new';
      };

      await expectLater(
        api.postJson('/x', accessToken: 'old'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect((calls, refreshes), (2, 1));
    });

    test('no retry when the session is gone', () async {
      var calls = 0;
      final api = ApiClient(
        client: MockClient((_) async {
          calls++;
          return _unauthorized('UNAUTHORIZED');
        }),
      );
      api.onUnauthorized = (_) async => null;

      await expectLater(
        api.getJson('/x', accessToken: 'old'),
        throwsA(isA<ApiException>()),
      );
      expect(calls, 1);
    });
  });

  group('AuthNotifier refresh', () {
    test('restore reopens the session with the refresh token', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'expired',
        'refresh_token': 'refresh-0',
      });
      final core = _FakeCore(validRefresh: 'refresh-0');

      final auth = await _started(ApiClient(client: core.client));

      expect(auth.state.status, AuthStatus.authenticated);
      expect(auth.state.user?.email, 'player@example.com');
      expect(auth.state.accessToken, 'access-1');
      const storage = FlutterSecureStorage();
      expect(await storage.read(key: 'access_token'), 'access-1');
      expect(await storage.read(key: 'refresh_token'), 'refresh-1');
    });

    test('a rejected refresh clears the session', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'expired',
        'refresh_token': 'revoked',
      });
      final core = _FakeCore(validRefresh: 'refresh-0');

      final auth = await _started(ApiClient(client: core.client));

      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('no stored refresh token goes straight to login', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final core = _FakeCore(validRefresh: 'refresh-0');

      final auth = await _started(ApiClient(client: core.client));

      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(core.refreshCalls, 0);
    });

    test('offline at start keeps the tokens for the next start', () async {
      FlutterSecureStorage.setMockInitialValues({
        'access_token': 'expired',
        'refresh_token': 'refresh-0',
      });
      final core = _FakeCore(validRefresh: 'refresh-0')..offline = true;

      final auth = await _started(ApiClient(client: core.client));

      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(
        await const FlutterSecureStorage().read(key: 'refresh_token'),
        'refresh-0',
      );
    });

    test('concurrent 401s share one refresh', () async {
      FlutterSecureStorage.setMockInitialValues({'refresh_token': 'refresh-0'});
      final core = _FakeCore(validRefresh: 'refresh-0');
      final api = ApiClient(client: core.client);
      final auth = await _started(api);
      expect(auth.state.accessToken, 'access-1');

      core.validAccess = 'expired-on-server';
      final results = await Future.wait([
        api.getJson('/x', accessToken: 'access-1'),
        api.getJson('/x', accessToken: 'access-1'),
        api.postJson('/x', accessToken: 'access-1'),
      ]);

      expect(results, everyElement({'ok': 1}));
      expect(core.refreshCalls, 2, reason: 'one at start, one shared');
      expect(auth.state.accessToken, 'access-2');
      expect(auth.state.status, AuthStatus.authenticated);
    });

    test(
      'a request with an already replaced token reuses the new one',
      () async {
        FlutterSecureStorage.setMockInitialValues({
          'refresh_token': 'refresh-0',
        });
        final core = _FakeCore(validRefresh: 'refresh-0');
        final api = ApiClient(client: core.client);
        await _started(api);

        final body = await api.getJson('/x', accessToken: 'stale-from-before');

        expect(body, {'ok': 1});
        expect(core.refreshCalls, 1);
      },
    );

    test('a refresh rejected mid-session logs out', () async {
      FlutterSecureStorage.setMockInitialValues({'refresh_token': 'refresh-0'});
      final core = _FakeCore(validRefresh: 'refresh-0');
      final api = ApiClient(client: core.client);
      final auth = await _started(api);

      core
        ..validAccess = 'expired-on-server'
        ..validRefresh = 'revoked-elsewhere';
      await expectLater(
        api.getJson('/x', accessToken: 'access-1'),
        throwsA(isA<ApiException>()),
      );

      expect(auth.state.status, AuthStatus.unauthenticated);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });
  });
}
