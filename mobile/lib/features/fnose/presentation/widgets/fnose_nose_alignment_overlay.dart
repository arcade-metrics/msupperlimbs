import 'package:flutter/material.dart';

class FnoseNoseAlignmentOverlay extends StatelessWidget {
  const FnoseNoseAlignmentOverlay({
    super.key,
    required this.center,
    required this.radius,
    required this.inside,
    this.detected,
  });

  final Offset center;
  final double radius;
  final bool inside;

  /// Posição do nariz seguida pela câmara, para o operador ver o tracking.
  final Offset? detected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final centerPx = Offset(
          center.dx * size.width,
          center.dy * size.height,
        );
        final radiusPx = radius * size.shortestSide;
        final point = detected == null
            ? null
            : Offset(detected!.dx * size.width, detected!.dy * size.height);
        final color = inside ? Colors.greenAccent : Colors.redAccent;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                left: centerPx.dx - radiusPx,
                top: centerPx.dy - radiusPx,
                width: radiusPx * 2,
                height: radiusPx * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 4),
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              ),
              if (point != null)
                Positioned(
                  left: point.dx - 10,
                  top: point.dy - 10,
                  width: 20,
                  height: 20,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
