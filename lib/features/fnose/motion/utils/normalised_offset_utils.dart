import 'dart:ui';

class NormalisedOffset {
  final double x;
  final double y;

  const NormalisedOffset(this.x, this.y);

  factory NormalisedOffset.fromOffset(Offset offset, Size screenSize) {
    return NormalisedOffset(
      offset.dx / screenSize.width,
      offset.dy / screenSize.height,
    );
  }

  Offset toOffset(Size screenSize) {
    return Offset(
      x * screenSize.width,
      y * screenSize.height,
    );
  }

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };

  factory NormalisedOffset.fromJson(Map<String, dynamic> json) {
    return NormalisedOffset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  String toString() => 'NormalisedOffset(x: $x, y: $y)';
}
