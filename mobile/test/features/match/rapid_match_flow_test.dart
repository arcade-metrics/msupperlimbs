import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';
import 'package:msupperlimbs/features/rapid/application/rapid_match_flow.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_result.dart';

const _rapid = '/api/v1/msupperlimbs-rapid/matches/m-1';

/// Fake ciatec-core for one Rapid match. [failures] maps a path to the
/// statuses it answers before succeeding.
class _FakeCore {
  final requests = <http.Request>[];
  final failures = <String, List<int>>{};

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final queued = failures[path];
    if (queued != null && queued.isNotEmpty) {
      final status = queued.removeAt(0);
      return _json({'success': false, 'code': 'X', 'message': 'x'}, status);
    }
    return switch (path) {
      '/api/v1/catalog/games' => _json({
        'games': [
          {'id': 'g-other', 'slug': 'msupperlimbs-fnose'},
          {'id': 'g-1', 'slug': 'msupperlimbs-rapid'},
        ],
      }, 200),
      '/api/v1/matches/preset' => _json({
        'game_id': 'g-1',
        'preset': {'id': 'p-1'},
        'current_level_id': 'l-1',
      }, 200),
      '/api/v1/sessions/matches' => _json({
        'id': 'm-1',
        'session_id': 's-1',
      }, 201),
      _ => _json({'created': true}, path.endsWith('/end') ? 200 : 201),
    };
  });

  late final api = MatchApi(ApiClient(client: client));

  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.url.path}',
  ];

  List<http.Request> to(String path) =>
      requests.where((r) => r.url.path == path).toList();

  Map<String, dynamic> body(http.Request r) =>
      jsonDecode(r.body) as Map<String, dynamic>;
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

RapidGameResult _result({int frames = 3}) => RapidGameResult(
  tapCount: 7,
  durationSeconds: 30,
  durationMs: 30000,
  gameMode: 'rightHand',
  visualizationType: 'line',
  phaseEvents: const [
    {'offsetMs': 0, 'eventType': 'phase', 'toPhase': 'waitingHand'},
    {
      'offsetMs': 4000,
      'eventType': 'phase',
      'fromPhase': 'countdown',
      'toPhase': 'playing',
    },
  ],
  tapEvents: const [
    {
      'offsetMs': 4500,
      'eventType': 'tap',
      'handIndex': 0,
      'finger': 'tip',
      'pulseHeightBefore': 0.2,
      'pulseHeightAfter': 0.4,
    },
  ],
  pulseEvents: const [
    {
      'offsetMs': 4300,
      'eventType': 'pulse_tick',
      'pulseHeight': 0.25,
      'pulseState': 'active',
    },
  ],
  poseSamples: [
    for (var i = 0; i < frames; i++)
      {'offsetMs': i * 33, 'phase': 'playing', 'hands': const []},
  ],
  avgPulseHeight: 0.3,
  maxPulseHeight: 0.5,
);

const _context = {'appVersion': '0.1.0', 'screenWidth': 1080};

RapidMatchFlow _flow(_FakeCore core) => RapidMatchFlow(
  core.api,
  () => 'access',
  uploader: () => MatchUploader(sleep: (_) async {}),
);

void main() {
  test('a finished match goes through every route in order', () async {
    final core = _FakeCore();
    final flow = _flow(core)..start(_context);

    final saved = await flow.complete(_result(frames: 1200), _context);

    expect((saved.matchId, saved.sessionId), ('m-1', 's-1'));
    expect(core.calls, [
      'GET /api/v1/catalog/games',
      'GET /api/v1/matches/preset',
      'POST /api/v1/sessions/matches',
      'POST $_rapid/context',
      'POST $_rapid/telemetry/pose',
      'POST $_rapid/telemetry/pose',
      'POST $_rapid/telemetry/pose',
      'POST $_rapid/events',
      'POST $_rapid/metrics',
      'POST /api/v1/matches/m-1/finish',
      'POST /api/v1/sessions/s-1/end',
    ]);
    expect(core.requests[1].url.queryParameters, {'game_id': 'g-1'});
    expect(core.body(core.requests[2]), {'game_id': 'g-1', 'level_id': 'l-1'});

    final chunks = core.to('$_rapid/telemetry/pose').map(core.body).toList();
    expect(chunks.map((c) => c['chunkIndex']), [0, 1, 2]);
    expect(chunks.map((c) => (c['frames'] as List).length), [500, 500, 200]);

    final batch = core.body(core.to('$_rapid/events').single);
    expect(batch['batchIndex'], 0);
    expect((batch['events'] as List).map((e) => e['offsetMs']), [
      0,
      4000,
      4300,
      4500,
    ]);

    expect(core.body(core.to('$_rapid/metrics').single), {
      'tapCount': 7,
      'avgTapFrequency': 7 / 30,
      'avgPulseHeight': 0.3,
      'maxPulseHeight': 0.5,
      'isValidMatch': true,
    });

    final finish = core.to('/api/v1/matches/m-1/finish').single;
    expect(
      finish.headers['Idempotency-Key'],
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    final finishBody = core.body(finish);
    expect(finishBody, containsPair('score', 7));
    expect(finishBody, containsPair('duration_ms', 30000));
    expect(finishBody, containsPair('completed', true));
    final stats = (finishBody['extra'] as Map)['upload_stats'] as Map;
    expect(stats['chunks'], 4, reason: '3 pose chunks + 1 event batch');
    expect(stats['retries'], 0);
    expect(stats['bytes'], greaterThan(0));
    expect(core.to('/api/v1/sessions/s-1/end').single.url.queryParameters, {
      'cancelled': 'false',
    });
  });

  test('a transient failure resends the same chunk and is counted', () async {
    final core = _FakeCore()..failures['$_rapid/telemetry/pose'] = [503];
    final flow = _flow(core)..start(_context);

    await flow.complete(_result(), _context);

    final chunks = core.to('$_rapid/telemetry/pose').map(core.body).toList();
    expect(chunks.map((c) => c['chunkIndex']), [0, 0]);
    final finish = core.body(core.to('/api/v1/matches/m-1/finish').single);
    expect(((finish['extra'] as Map)['upload_stats'] as Map)['retries'], 1);
  });

  test(
    'a rejected upload is not retried and the match is not finished',
    () async {
      final core = _FakeCore()..failures['$_rapid/events'] = [400];
      final flow = _flow(core)..start(_context);

      await expectLater(
        flow.complete(_result(), _context),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 400)),
      );
      expect(core.to('$_rapid/events'), hasLength(1));
      expect(core.to('/api/v1/matches/m-1/finish'), isEmpty);
    },
  );

  test('a context that failed at the start is sent with the upload', () async {
    final core = _FakeCore()..failures['$_rapid/context'] = [400];
    final flow = _flow(core)..start(_context);

    await flow.complete(_result(), _context);

    expect(core.to('$_rapid/context'), hasLength(2));
  });

  test('leaving mid-match finishes it as not completed', () async {
    final core = _FakeCore();
    final flow = _flow(core)..start(_context);

    await flow.cancel(score: 3, durationMs: 12000);
    await flow.cancel(score: 3, durationMs: 12000);

    final finish = core.to('/api/v1/matches/m-1/finish').single;
    expect(core.body(finish), containsPair('completed', false));
    expect(core.body(finish), containsPair('score', 3));
    expect(core.to('/api/v1/sessions/s-1/end').single.url.queryParameters, {
      'cancelled': 'true',
    });
  });

  test(
    'leaving before play starts or after the finish sends nothing',
    () async {
      final core = _FakeCore();
      await _flow(core).cancel(score: 0, durationMs: 0);
      expect(core.requests, isEmpty);

      final flow = _flow(core)..start(_context);
      await flow.complete(_result(), _context);
      final sent = core.requests.length;
      await flow.cancel(score: 7, durationMs: 30000);
      expect(core.requests, hasLength(sent));
    },
  );

  test('the game and level are resolved once per app run', () async {
    final core = _FakeCore();
    for (var i = 0; i < 2; i++) {
      final flow = RapidMatchFlow(core.api, () => 'access')..start(_context);
      await flow.complete(_result(), _context);
    }
    expect(core.to('/api/v1/catalog/games'), hasLength(1));
    expect(core.to('/api/v1/sessions/matches'), hasLength(2));
  });

  test('chunked splits at the limit and keeps the order', () {
    expect(chunked([1, 2, 3, 4, 5], 2), [
      [1, 2],
      [3, 4],
      [5],
    ]);
    expect(chunked(<int>[], 500), isEmpty);
    expect(newIdempotencyKey(Random(1)), isNot(newIdempotencyKey(Random(2))));
  });
}
