import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_match_flow.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_engine.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

const _fnose = '/api/v1/msupperlimbs-fnose/matches/m-1';
const _create = '/api/v1/sessions/matches';

class _FakeCore {
  final requests = <http.Request>[];
  final failures = <String, List<(int, String)>>{};

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path;
    final queued = failures[path];
    if (queued != null && queued.isNotEmpty) {
      final (status, code) = queued.removeAt(0);
      return _json({'success': false, 'code': code, 'message': code}, status);
    }
    return switch (path) {
      '/api/v1/catalog/games' => _json({
        'games': [
          {'id': 'g-fnose', 'slug': 'msupperlimbs-fnose'},
        ],
      }, 200),
      '/api/v1/matches/preset' => _json({
        'preset': {'id': 'p-1'},
        'current_level_id': 'l-1',
      }, 200),
      _create => _json({'id': 'm-1', 'session_id': 's-1'}, 201),
      _ => _json({'created': true}, path.endsWith('/end') ? 200 : 201),
    };
  });

  late final api = MatchApi(ApiClient(client: client));

  List<Map<String, dynamic>> bodiesTo(String path) => [
    for (final r in requests)
      if (r.url.path == path) jsonDecode(r.body) as Map<String, dynamic>,
  ];

  List<String> get paths => [for (final r in requests) r.url.path];
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

FnoseGameResult _result() => const FnoseGameResult(
  totalTime: 60,
  durationMs: 60000,
  gameMode: 'leftHand',
  totalLeftSparks: 5,
  totalRightSparks: 0,
  totalSparks: 5,
  avgDistance: 0.12,
  avgAngle: 95,
  phaseEvents: [
    {
      'offsetMs': 9000,
      'eventType': 'phase',
      'fromPhase': 'countdown',
      'toPhase': 'playing',
    },
  ],
  sparkEvents: [
    {
      'offsetMs': 9500,
      'eventType': 'spark',
      'side': 'left',
      'fromState': 'idle',
      'toState': 'armed',
    },
  ],
  poseSamples: [
    {'offsetMs': 9033, 'phase': 'playing', 'pose': <Map<String, dynamic>>[]},
  ],
);

const _context = {'appVersion': '0.1.0'};

FnoseMatchFlow _flow(_FakeCore core) => FnoseMatchFlow(
  core.api,
  () => 'access',
  uploader: () => MatchUploader(sleep: (_) async {}),
);

void main() {
  test('the match waits for the calibration upload and links it', () async {
    final core = _FakeCore();
    final calibration = Completer<String?>();
    final flow = _flow(core)
      ..start(_context, calibrationRunId: calibration.future);

    await pumpEventQueue();
    expect(core.paths, isNot(contains(_create)));

    calibration.complete('run-1');
    final saved = await flow.complete(_result(), _context);

    expect((saved.matchId, saved.sessionId), ('m-1', 's-1'));
    expect(core.bodiesTo(_create).single, {
      'game_id': 'g-fnose',
      'level_id': 'l-1',
      'calibration_run_id': 'run-1',
    });
    expect(
      core.paths,
      containsAllInOrder([
        _create,
        '$_fnose/context',
        '$_fnose/telemetry/pose',
        '$_fnose/events',
        '$_fnose/metrics',
        '/api/v1/matches/m-1/finish',
        '/api/v1/sessions/s-1/end',
      ]),
    );
    expect(core.bodiesTo('$_fnose/metrics').single, {
      'totalLeftSparks': 5,
      'totalRightSparks': 0,
      'totalSparks': 5,
      'avgDistance': 0.12,
      'avgAngle': 95.0,
      'isValidMatch': true,
    });
    final events = core.bodiesTo('$_fnose/events').single['events'] as List;
    expect(events.map((e) => e['eventType']), ['phase', 'spark']);
    final finish = core.bodiesTo('/api/v1/matches/m-1/finish').single;
    expect(finish['score'], 5);
    expect(finish['duration_ms'], 60000);
  });

  test('without a calibration run the match is created unlinked', () async {
    final core = _FakeCore();
    final flow = _flow(core)
      ..start(_context, calibrationRunId: Future.value(null));

    await flow.complete(_result(), _context);

    expect(
      core.bodiesTo(_create).single,
      isNot(contains('calibration_run_id')),
    );
  });

  test('a link the server refuses does not cost the match', () async {
    final core = _FakeCore()
      ..failures[_create] = [(409, 'CALIBRATION_ALREADY_LINKED')];
    final flow = _flow(core)
      ..start(_context, calibrationRunId: Future.value('run-1'));

    final saved = await flow.complete(_result(), _context);

    expect(saved.matchId, 'm-1');
    final creates = core.bodiesTo(_create);
    expect(creates.first, containsPair('calibration_run_id', 'run-1'));
    expect(creates.last, isNot(contains('calibration_run_id')));
  });

  test('other errors creating the match are not hidden', () async {
    final core = _FakeCore()..failures[_create] = [(403, 'LEVEL_LOCKED')];
    final flow = _flow(core)
      ..start(_context, calibrationRunId: Future.value('run-1'));

    await expectLater(
      flow.complete(_result(), _context),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'LEVEL_LOCKED'),
      ),
    );
    expect(core.bodiesTo(_create), hasLength(1));
  });
}
