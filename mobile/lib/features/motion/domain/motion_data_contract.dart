/// Contrato persistido comum a FNose e Rapid.
///
/// v3:
/// - tempo só em `offsetMs`: ms desde `SessionClock.startedAt` (t0 da
///   execução, antes da calibração e do pré-jogo); nenhum epoch;
/// - cada mudança de fase é um evento `phase` (`fromPhase` → `toPhase`);
/// - landmarks no espaço A MediaPipe (`x,y,z,v,p`);
/// - interações no espaço B (x/y 0–1 do ecrã);
/// - raios e tolerâncias como fração do menor lado.
abstract final class MotionDataContract {
  static const version = 3;
}

/// Evento `phase`; sem [from] marca a fase inicial da execução.
Map<String, dynamic> phaseEvent({
  required int offsetMs,
  String? from,
  required String to,
}) => {
  'offsetMs': offsetMs,
  'eventType': 'phase',
  'fromPhase': ?from,
  'toPhase': to,
};
