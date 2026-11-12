typedef UtcNow = DateTime Function();

/// Relógio único de uma execução (calibração + pré-jogo + partida).
///
/// [startedAt] é o t0 da execução. Todos os samples e eventos persistidos
/// usam [offsetMs] (ms desde t0), nunca epoch. Sem [source], o tempo avança
/// por um [Stopwatch] (monotónico): um ajuste do relógio do sistema durante
/// a execução não faz o offset recuar.
class SessionClock {
  factory SessionClock({UtcNow? source}) {
    if (source != null) return SessionClock._(source, source().toUtc());
    final start = DateTime.now().toUtc();
    final elapsed = Stopwatch()..start();
    return SessionClock._(() => start.add(elapsed.elapsed), start);
  }

  SessionClock._(this._source, this.startedAt);

  final UtcNow _source;
  final DateTime startedAt;

  DateTime now() => _source().toUtc();

  /// Ms desde [startedAt] até [at] (por omissão, agora); nunca negativo.
  int offsetMs([DateTime? at]) {
    final ms = (at ?? now()).difference(startedAt).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }
}
