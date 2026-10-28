import 'package:msupperlimbs/features/rapid/models/pulse_line_state.dart';

class PulseStateLogModel {
  final int timestamp;
  final double pulseHeight;
  final PulseLineState pulseState;
  final String eventType; // 'tick', 'impulse', 'reset', 'state_change'
  final Map<String, dynamic>? additionalData;

  PulseStateLogModel({
    required this.timestamp,
    required this.pulseHeight,
    required this.pulseState,
    required this.eventType,
    this.additionalData,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'pulseHeight': pulseHeight,
      'pulseState': pulseState.name,
      'eventType': eventType,
      'additionalData': additionalData,
    };
  }

  factory PulseStateLogModel.fromMap(Map<String, dynamic> map) {
    return PulseStateLogModel(
      timestamp: map['timestamp'] as int,
      pulseHeight: (map['pulseHeight'] as num).toDouble(),
      pulseState: PulseLineState.values.firstWhere(
        (state) => state.name == map['pulseState'],
        orElse: () => PulseLineState.idle,
      ),
      eventType: map['eventType'] as String,
      additionalData: map['additionalData'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() {
    return 'PulseStateLogModel(timestamp: $timestamp, height: $pulseHeight, state: $pulseState, event: $eventType)';
  }
}
