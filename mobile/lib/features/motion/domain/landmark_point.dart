class LandmarkPoint {
  const LandmarkPoint({
    required this.index,
    required this.x,
    required this.y,
    required this.z,
    this.visibility,
    this.presence,
    this.handIndex,
  });

  final int index;
  final double x;
  final double y;
  final double z;
  final double? visibility;
  final double? presence;
  final int? handIndex;

  factory LandmarkPoint.fromMap(Map<dynamic, dynamic> map) {
    return LandmarkPoint(
      index: (map['index'] as num?)?.toInt() ?? 0,
      x: (map['x'] as num?)?.toDouble() ?? 0,
      y: (map['y'] as num?)?.toDouble() ?? 0,
      z: (map['z'] as num?)?.toDouble() ?? 0,
      visibility: (map['visibility'] as num?)?.toDouble(),
      presence: (map['presence'] as num?)?.toDouble(),
      handIndex: (map['handIndex'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toKinematicJson() => {
    'i': index,
    'x': x,
    'y': y,
    'z': z,
    'v': ?visibility,
    'p': ?presence,
    'hand': ?handIndex,
  };
}
