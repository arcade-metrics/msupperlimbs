import 'package:flutter/material.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_types.dart';

class FnoseTargetOverlay extends StatelessWidget {
  const FnoseTargetOverlay({
    super.key,
    required this.xTargetPosition,
    required this.yTargetPosition,
    required this.targetScale,
    required this.showLeft,
    required this.showRight,
    required this.leftSpark,
    required this.rightSpark,
    this.tracked,
  });

  final double xTargetPosition;
  final double yTargetPosition;
  final double targetScale;
  final bool showLeft;
  final bool showRight;
  final FnoseSparkState leftSpark;
  final FnoseSparkState rightSpark;

  /// Ponta do dedo seguida pelo motor, em coordenadas 0–1 do ecrã.
  final Offset? tracked;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final shortest = w < h ? w : h;
        final size = shortest * targetScale;
        final children = <Widget>[];

        if (showLeft) {
          children.add(
            _target(
              left: w * xTargetPosition,
              top: h * yTargetPosition - size / 2,
              size: size,
              spark: leftSpark,
              label: 'L',
            ),
          );
        }
        if (showRight) {
          children.add(
            _target(
              left: w * (1 - xTargetPosition) - size,
              top: h * yTargetPosition - size / 2,
              size: size,
              spark: rightSpark,
              label: 'R',
            ),
          );
        }

        final point = tracked;
        if (point != null) {
          children.add(
            Positioned(
              left: point.dx * w - 9,
              top: point.dy * h - 9,
              width: 18,
              height: 18,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orangeAccent,
                  border: Border.fromBorderSide(
                    BorderSide(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),
          );
        }

        return Stack(children: children);
      },
    );
  }

  Widget _target({
    required double left,
    required double top,
    required double size,
    required FnoseSparkState spark,
    required String label,
  }) {
    final isFire = spark == FnoseSparkState.fire;
    final color = switch (spark) {
      FnoseSparkState.idle => Colors.white54,
      FnoseSparkState.armed => Colors.amberAccent,
      FnoseSparkState.aiming => Colors.lightBlueAccent,
      FnoseSparkState.fire => Colors.greenAccent,
    };
    final scale = isFire ? 1.14 : (spark == FnoseSparkState.armed ? 1.04 : 1.0);
    final borderWidth = isFire ? 7.0 : (spark == FnoseSparkState.armed ? 5.0 : 3.0);
    final fillAlpha = isFire ? 0.55 : (spark == FnoseSparkState.armed ? 0.28 : 0.18);

    return Positioned(
      left: left,
      top: top,
      width: size,
      height: size,
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color, width: borderWidth),
            color: color.withValues(alpha: fillAlpha),
            boxShadow: isFire
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.85),
                      blurRadius: size * 0.28,
                      spreadRadius: size * 0.06,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.28,
                ),
              ),
              SizedBox(
                width: size * (isFire ? 0.2 : 0.14),
                height: size * (isFire ? 0.2 : 0.14),
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
        ),
      ),
    );
  }
}
