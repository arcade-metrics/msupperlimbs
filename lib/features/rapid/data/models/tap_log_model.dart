class TapLogModel {
  final int timestamp;
  final String tappedFinger;
  final double distance;
  final double intensity;
  final double pulseHeightBefore;
  final double pulseHeightAfter;
  final String handType;
  final double tapSensitivity;

  TapLogModel({
    required this.timestamp,
    required this.tappedFinger,
    required this.distance,
    required this.intensity,
    required this.pulseHeightBefore,
    required this.pulseHeightAfter,
    required this.handType,
    required this.tapSensitivity,
  });

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp,
      'tappedFinger': tappedFinger,
      'distance': distance,
      'intensity': intensity,
      'pulseHeightBefore': pulseHeightBefore,
      'pulseHeightAfter': pulseHeightAfter,
      'handType': handType,
      'tapSensitivity': tapSensitivity,
    };
  }

  factory TapLogModel.fromMap(Map<String, dynamic> map) {
    return TapLogModel(
      timestamp: map['timestamp'] as int,
      tappedFinger: map['tappedFinger'] as String,
      distance: (map['distance'] as num).toDouble(),
      intensity: (map['intensity'] as num).toDouble(),
      pulseHeightBefore: (map['pulseHeightBefore'] as num).toDouble(),
      pulseHeightAfter: (map['pulseHeightAfter'] as num).toDouble(),
      handType: map['handType'] as String,
      tapSensitivity: (map['tapSensitivity'] as num).toDouble(),
    );
  }

  @override
  String toString() {
    return 'TapLogModel(timestamp: $timestamp, finger: $tappedFinger, distance: $distance, intensity: $intensity, handType: $handType)';
  }
}
