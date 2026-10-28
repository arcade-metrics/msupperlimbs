/// Contrato persistido comum a FNose e Rapid.
///
/// v2:
/// - um único `t` em epoch ms UTC;
/// - landmarks no espaço A MediaPipe (`x,y,z,v,p`);
/// - interações no espaço B (x/y 0–1 do ecrã);
/// - raios e tolerâncias como fração do menor lado.
abstract final class MotionDataContract {
  static const version = 2;
}
