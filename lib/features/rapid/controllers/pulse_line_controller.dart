import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:msupperlimbs/features/rapid/models/pulse_line_state.dart';

class PulseLineController extends ChangeNotifier {
  // ===== Parâmetros ajustáveis (vêm do Settings no futuro) =====
  final int maxPoints;                 // tamanho da janela deslizante
  final double minY;                   // limite inferior normalizado (0..1)
  final double maxY;                   // limite superior normalizado (0..1)
  final double baseline;               // linha de base (para inicialização/ressonância)
  final double gravityPerSecond;       // quanto a linha cai por segundo (0..1 / s)
  final double impulseStrength;        // quanto a linha sobe por tap (0..1)
  final double floorRestitution;       // "amortecimento" ao tocar o piso (0..1 -> 0 sem bounce)
  
  // ===== Modulação de decaimento por estado =====
  final double _decayRateIdle;         // taxa de decaimento adicional no estado idle
  final double _decayRateActive;       // taxa de decaimento adicional no estado active
  final double _decayRateUnstable;     // taxa de decaimento adicional no estado unstable
  final double _decayRateFlatline;     // taxa de decaimento adicional no estado flatline

  // ===== Estado dinâmico =====
  final Queue<double> _points;
  double _currentY;
  PulseLineState _state;

  // ===== Callbacks para logging =====
  Function(double height, PulseLineState state, String eventType)? onStateChange;
  Function(double heightBefore, double heightAfter, double impulseStrength)? onImpulse;

  PulseLineController({
    this.maxPoints = 420,
    this.minY = 0.0,
    this.maxY = 1.0,
    this.baseline = 0.25,
    this.gravityPerSecond = 0.35,
    this.impulseStrength = 0.12,
    this.floorRestitution = 0.0,
    double decayRateIdle = 0.05,
    double decayRateActive = 0.03,
    double decayRateUnstable = 0.07,
    double decayRateFlatline = 0.10,
    PulseLineState initialState = PulseLineState.idle,
  })  : _decayRateIdle = decayRateIdle,
        _decayRateActive = decayRateActive,
        _decayRateUnstable = decayRateUnstable,
        _decayRateFlatline = decayRateFlatline,
        _points = Queue<double>(),
        _currentY = baseline,
        _state = initialState {
    // pré-carrega a janela com baseline para desenhar algo estável no início
    for (int i = 0; i < maxPoints; i++) {
      _points.add(baseline);
    }
  }

  // ===== Exposição pública =====
  List<double> get points => _points.toList(growable: false);
  PulseLineState get state => _state;

  set state(PulseLineState newState) {
    if (_state == newState) return;
    final oldState = _state;
    _state = newState;
    
    // Trigger callback for state change
    onStateChange?.call(_currentY, newState, 'state_change');
    
    notifyListeners();
  }

  double get currentY => _currentY;

  /// Avança a simulação em `dtSeconds` (chame isso a cada frame/tick).
  void tick(double dtSeconds) {
    if (dtSeconds <= 0) {
      _pushPoint(_currentY);
      return;
    }

    final double heightBefore = _currentY;

    // 1) Gravidade base + modulação por estado (decayRate atua como "peso extra")
    //    Ex.: idle cai um pouco mais rápido que active, etc.
    final double stateExtraDecayPerSecond = _state.getDecayRate(
      idleRate: _decayRateIdle,
      activeRate: _decayRateActive,
      unstableRate: _decayRateUnstable,
      flatlineRate: _decayRateFlatline,
    );
    final double totalFall = (gravityPerSecond + stateExtraDecayPerSecond) * dtSeconds;

    _currentY -= totalFall;

    // 2) Piso/teto + opcional "amortecimento" quando bate no piso
    if (_currentY < minY) {
      _currentY = minY + (baseline - minY) * floorRestitution;
    } else if (_currentY > maxY) {
      _currentY = maxY;
    }

    // 3) Empurra para a janela deslizante
    _pushPoint(_currentY);

    // 4) Trigger callback for tick event (only if height changed significantly)
    if ((heightBefore - _currentY).abs() > 0.001) {
      onStateChange?.call(_currentY, _state, 'tick');
    }

    // 5) Notifica
    notifyListeners();
  }

  /// Dá um impulso para cima (chame quando detectar um tap).
  void impulse([double? strength]) {
    final double heightBefore = _currentY;
    final double up = strength ?? impulseStrength;
    _currentY = (_currentY + up).clamp(minY, maxY);
    _pushPoint(_currentY);
    
    // Trigger callback for impulse event
    onImpulse?.call(heightBefore, _currentY, up);
    onStateChange?.call(_currentY, _state, 'impulse');
    
    notifyListeners();
  }
  
  /// Atualiza o valor atual da linha (compatibilidade com código existente)
  void update(double value) {
    _currentY = value.clamp(minY, maxY);
    _pushPoint(_currentY);
    notifyListeners();
  }

  // ===== Utilitários =====
  void _pushPoint(double y) {
    _points.add(y);
    if (_points.length > maxPoints) {
      _points.removeFirst();
    }
  }

  /// Reinicia a linha em baseline (útil em troca de fase ou calibração).
  void reset({double? to}) {
    _currentY = to ?? baseline;
    _points.clear();
    for (int i = 0; i < maxPoints; i++) {
      _points.add(_currentY);
    }
    notifyListeners();
  }
}
