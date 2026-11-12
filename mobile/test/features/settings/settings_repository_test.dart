import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:msupperlimbs/core/network/api_client.dart';
import 'package:msupperlimbs/features/fnose/data/fnose_settings_repository.dart';
import 'package:msupperlimbs/features/fnose/data/models/fnose_settings.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_adv_catalog.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_game_mode.dart';
import 'package:msupperlimbs/features/rapid/data/rapid_settings_repository.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_game_mode.dart';

const _rapidSettings = {
  'showInfoVideo': true,
  'totalTime': 30,
  'gameMode': 'rightHand',
  'visualizationType': 'bar',
  'tapSensitivity': 0.04,
  'tapCooldownMs': 110,
  'maxPoints': 420,
  'minY': 0.0,
  'maxY': 1.0,
  'baseline': 0.25,
  'gravityPerSecond': 0.35,
  'impulseStrength': 0.06,
  'floorRestitution': 0.0,
  'decayRateIdle': 0.05,
  'decayRateActive': 0.03,
  'decayRateUnstable': 0.07,
  'decayRateFlatline': 0.1,
  'lineColor': null,
  'lineWidth': 3.0,
  'glowEnabled': true,
  'glowBlurSigma': 8.0,
  'useFixedDt': true,
  'fixedDtSeconds': 0.0333,
  'pulseMaxIntensity': 0.6,
  'pulseGravity': 0.003,
  'pulseImpulse': 0.16,
};

const _fnoseSettings = {
  'gameMode': 'rightHand',
  'showInfoVideo': false,
  'totalTime': 45,
  'targetSize': 1.2,
  'advanced': {
    'requiredStableTimeMs': 2500,
    'xTargetPosition': 0.1,
    'minAngleChangeForElbowDetection': 4.0,
    'pitchMinDeg': -12.0,
  },
};

Map<String, dynamic> _envelope(Map<String, dynamic> settings) => {
  'presetId': 'preset-1',
  'updatedAt': '2026-10-29T12:00:00Z',
  'settings': settings,
};

/// Records requests and answers every one with [settings] in the envelope.
class _Recorder {
  _Recorder(this.settings);

  final Map<String, dynamic> settings;
  final requests = <http.Request>[];

  late final api = ApiClient(
    client: MockClient((request) async {
      requests.add(request);
      return http.Response(
        jsonEncode(_envelope(settings)),
        200,
        headers: {'content-type': 'application/json'},
      );
    }),
  );

  http.Request get last => requests.last;
  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

void main() {
  group('RapidSettingsRepository', () {
    late _Recorder core;
    late RapidSettingsRepository repo;
    setUp(() {
      core = _Recorder(_rapidSettings);
      repo = RapidSettingsRepository(core.api, () => 'u-1');
    });

    test('reads the caller settings from the envelope', () async {
      final settings = await repo.getSettings('access');

      expect(core.last.method, 'GET');
      expect(
        core.last.url.path,
        '/api/v1/msupperlimbs-rapid/players/u-1/settings',
      );
      expect(settings.presetId, 'preset-1');
      expect(settings.updatedAt, DateTime.utc(2026, 10, 29, 12));
      expect(settings.visualizationType, 'bar');
      expect(settings.lineColor, isNull);
    });

    test('saving patches every field in camelCase', () async {
      final settings = await repo.getSettings('access');

      await repo.updateSettings('access', settings.copyWith(totalTime: 40));

      expect(core.last.method, 'PATCH');
      expect(core.lastBody.keys, unorderedEquals(_rapidSettings.keys));
      expect(core.lastBody['totalTime'], 40);
    });

    test('restore posts to the restore route', () async {
      await repo.restoreDefaults('access');

      expect(core.last.method, 'POST');
      expect(
        core.last.url.path,
        '/api/v1/msupperlimbs-rapid/players/u-1/settings/restore',
      );
    });
  });

  group('FnoseSettingsRepository', () {
    late _Recorder core;
    late FnoseSettingsRepository repo;
    setUp(() {
      core = _Recorder(_fnoseSettings);
      repo = FnoseSettingsRepository(core.api, () => 'u-1');
    });

    test('basic fields come from the top level', () async {
      final settings = await repo.getSettings('access');

      expect(
        core.last.url.path,
        '/api/v1/msupperlimbs-fnose/players/u-1/settings',
      );
      expect(settings.gameMode, 'rightHand');
      expect(settings.showInfoVideo, isFalse);
      expect(settings.totalTime, 45);
      expect(settings.targetSize, 1.2);
    });

    test('advanced keys are snake_case inside the app', () async {
      final adv = await repo.getAdvSettings('access');

      expect(adv.data, {
        'required_stable_time_ms': 2500,
        'x_target_position': 0.1,
        'min_angle_change_for_elbow_detection': 4.0,
        'pitch_min_deg': -12.0,
      });
      expect(adv.i('required_stable_time_ms', 0), 2500);
    });

    test('saving basic settings does not touch advanced', () async {
      final settings = await repo.getSettings('access');

      await repo.updateSettings('access', settings.copyWith(totalTime: 50));

      expect(core.last.method, 'PATCH');
      expect(core.lastBody, {
        'gameMode': 'rightHand',
        'showInfoVideo': false,
        'totalTime': 50,
        'targetSize': 1.2,
      });
    });

    test('saving advanced patches only advanced, in camelCase', () async {
      await repo.updateAdvSettings('access', {
        'required_stable_time_ms': 3000,
        'x_target_position': 0.2,
      });

      expect(core.last.method, 'PATCH');
      expect(core.lastBody, {
        'advanced': {'requiredStableTimeMs': 3000, 'xTargetPosition': 0.2},
      });
    });

    test('restore from either screen posts to the restore route', () async {
      await repo.restoreDefaults('access');
      await repo.restoreAdvDefaults('access');

      expect(core.requests.map((r) => (r.method, r.url.path)), [
        ('POST', '/api/v1/msupperlimbs-fnose/players/u-1/settings/restore'),
        ('POST', '/api/v1/msupperlimbs-fnose/players/u-1/settings/restore'),
      ]);
    });
  });

  test('every advanced catalog key round-trips through camelCase', () {
    for (final field in fnoseAdvCatalog) {
      final camel = snakeToCamel(field.key);
      expect(camel, isNot(contains('_')), reason: field.key);
      expect(camelToSnake(camel), field.key);
    }
    expect(
      snakeToCamel('nose_alignment_target_radius'),
      'noseAlignmentTargetRadius',
    );
  });

  test('only one hand per match can be chosen', () {
    expect(RapidGameMode.values.map((m) => m.apiValue), [
      'leftHand',
      'rightHand',
    ]);
    expect(FnoseGameModeX.selectableModes.map((m) => m.apiValue), [
      'leftHand',
      'rightHand',
    ]);
  });
}
