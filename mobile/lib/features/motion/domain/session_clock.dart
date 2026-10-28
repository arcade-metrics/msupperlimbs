typedef UtcNow = DateTime Function();

/// Relógio único de uma execução (pré-jogo + partida).
///
/// Todos os samples e eventos persistidos devem usar [nowMs]. A API VIDEO do
/// MediaPipe mantém o seu relógio monotónico apenas internamente no Android.
class SessionClock {
  SessionClock({UtcNow? source})
    : _source = source ?? _systemUtcNow,
      startedAt = (source ?? _systemUtcNow)().toUtc();

  final UtcNow _source;
  final DateTime startedAt;

  DateTime now() => _source().toUtc();
  int nowMs() => now().millisecondsSinceEpoch;

  static DateTime _systemUtcNow() => DateTime.now().toUtc();
}
