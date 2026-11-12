import 'package:flutter_test/flutter_test.dart';

const _epochKeys = {
  't',
  'timestamp',
  'started_at_ms',
  'ended_at_ms',
  'startedAtMs',
  'endedAtMs',
};

/// Fails if [payload] has an epoch-style key or an integer large enough to
/// be an epoch (seconds or ms). Offsets stay far below 1e9 ms (~11 days).
void expectNoEpoch(Object? payload, [String path = r'$']) {
  if (payload is Map) {
    for (final entry in payload.entries) {
      final key = entry.key.toString();
      expect(_epochKeys, isNot(contains(key)), reason: '$path.$key');
      expectNoEpoch(entry.value, '$path.$key');
    }
  } else if (payload is Iterable) {
    var i = 0;
    for (final item in payload) {
      expectNoEpoch(item, '$path[${i++}]');
    }
  } else if (payload is int) {
    expect(payload, lessThan(1000000000), reason: path);
  }
}
