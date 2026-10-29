/// Events of several streams on one timeline, ordered by `offsetMs`; events
/// at the same offset keep their stream and insertion order.
List<Map<String, dynamic>> byOffset(
  Iterable<List<Map<String, dynamic>>> streams,
) {
  final all = [for (final stream in streams) ...stream];
  int offset(int i) => all[i]['offsetMs'] as int;
  final order = List<int>.generate(all.length, (i) => i)
    ..sort((a, b) {
      final byTime = offset(a).compareTo(offset(b));
      return byTime != 0 ? byTime : a.compareTo(b);
    });
  return [for (final i in order) all[i]];
}
