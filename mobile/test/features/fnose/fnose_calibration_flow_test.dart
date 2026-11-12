import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/calibration/data/calibration_api.dart';
import 'package:msupperlimbs/features/fnose/application/fnose_calibration_flow.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_calibration.dart';
import 'package:msupperlimbs/features/match/application/match_uploader.dart';
import 'package:msupperlimbs/features/match/data/match_api.dart';

const _run = '/api/v1/calibrations/run-1';

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
      '/api/v1/calibrations' => _json({'id': 'run-1'}, 201),
      _ => _json({'created': true}, 202),
    };
  });

  late final api = ApiClient(client: client);

  List<String> get calls => [
    for (final r in requests) '${r.method} ${r.url.path}',
  ];

  Map<String, dynamic> body(http.Request r) =>
      jsonDecode(r.body) as Map<String, dynamic>;

  List<Map<String, dynamic>> bodiesTo(String path) => [
    for (final r in requests)
      if (r.url.path == path) body(r),
  ];
}

http.Response _json(Object body, int status) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

FnoseCalibrationRun _calibrationRun({
  bool completed = true,
  int sensorSamples = 2500,
}) => FnoseCalibrationRun(
  completed: completed,
  startedOffsetMs: 0,
  endedOffsetMs: 7900,
  context: const {'screenWidth': 1000, 'dataContractVersion': 3},
  sensorSamples: [
    for (var i = 0; i < sensorSamples; i++)
      {'offsetMs': i * 20, 'ax': 0.0, 'ay': 9.8, 'az': 0.0},
  ],
  poseFrames: const [
    {'offsetMs': 100, 'pose': <Map<String, dynamic>>[]},
  ],
  events: const [
    {'offsetMs': 0, 'eventType': 'calibration_start'},
    {'offsetMs': 7900, 'eventType': 'game_start'},
  ],
  steps: const [
    {
      'stepType': 'DEVICE_STILL',
      'status': 'PASSED',
      'params': {'requiredStableTimeMs': 2500, 'stabilityGraceMs': 400},
      'result': {'achievedMs': 2510},
    },
  ],
  result: completed
      ? const {
          'fingerOffset': {'dx': 0.01, 'dy': -0.02, 'space': 'screen_norm'},
        }
      : null,
);

FnoseCalibrationFlow _flow(_FakeCore core) => FnoseCalibrationFlow(
  MatchApi(core.api),
  CalibrationApi(core.api),
  () => 'access',
  uploader: () => MatchUploader(sleep: (_) async {}),
);

void main() {
  test('uploads the run in order, finish last', () async {
    final core = _FakeCore();

    final id = await _flow(core).upload(_calibrationRun());

    expect(id, 'run-1');
    expect(core.calls, [
      'GET /api/v1/catalog/games',
      'GET /api/v1/matches/preset',
      'POST /api/v1/calibrations',
      'POST $_run/sensor',
      'POST $_run/sensor',
      'POST $_run/sensor',
      'POST $_run/pose',
      'POST $_run/events',
      'POST $_run/finish',
    ]);

    final open = core.body(core.requests[2]);
    expect(open, containsPair('gameId', 'g-fnose'));
    expect(open, containsPair('protocolCode', 'device-body-setup/v1'));
    expect(open, containsPair('startedOffsetMs', 0));
    expect(open, containsPair('screenWidth', 1000));
    expect(open.keys, containsAll(['appVersion', 'platform']));

    final sensor = core.bodiesTo('$_run/sensor');
    expect(sensor.map((c) => c['chunkIndex']), [0, 1, 2]);
    expect(sensor.map((c) => (c['samples'] as List).length), [1000, 1000, 500]);
    expect(core.bodiesTo('$_run/pose').single['chunkIndex'], 0);
    expect(core.bodiesTo('$_run/events').single['batchIndex'], 0);

    final finish = core.bodiesTo('$_run/finish').single;
    expect(finish['status'], 'COMPLETED');
    expect(finish['endedOffsetMs'], 7900);
    expect(finish['steps'], hasLength(1));
    expect(finish, contains('result'));
  });

  test('an abandoned run finishes as ABANDONED without a result', () async {
    final core = _FakeCore();

    await _flow(core).upload(_calibrationRun(completed: false));

    final finish = core.bodiesTo('$_run/finish').single;
    expect(finish['status'], 'ABANDONED');
    expect(finish, isNot(contains('result')));
  });

  test('a finish retried after it reached the server counts as done', () async {
    final core = _FakeCore()
      ..failures['$_run/finish'] = [
        (503, 'UNAVAILABLE'),
        (409, 'CALIBRATION_ALREADY_FINALIZED'),
      ];

    expect(await _flow(core).upload(_calibrationRun()), 'run-1');
    expect(core.bodiesTo('$_run/finish'), hasLength(2));
  });

  test('other errors fail the upload', () async {
    final core = _FakeCore()
      ..failures['$_run/events'] = [(400, 'VALIDATION_ERROR')];

    await expectLater(
      _flow(core).upload(_calibrationRun()),
      throwsA(
        isA<ApiException>().having((e) => e.code, 'code', 'VALIDATION_ERROR'),
      ),
    );
    expect(core.bodiesTo('$_run/finish'), isEmpty);
  });

  test('no sensor samples means no sensor chunk', () async {
    final core = _FakeCore();

    await _flow(core).upload(_calibrationRun(sensorSamples: 0));

    expect(core.bodiesTo('$_run/sensor'), isEmpty);
  });
}
