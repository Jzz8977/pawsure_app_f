import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 环形进度组件，对应小程序 circle-progress。
/// [value] 0~100
class CircleProgress extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;
  final bool showText;

  const CircleProgress({
    super.key,
    required this.value,
    this.size = 36,
    this.strokeWidth = 4,
    this.activeColor = const Color(0xFFF59E0B),
    this.trackColor = const Color(0xFFECECEC),
    this.showText = true,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 100.0);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CirclePainter(
          value: v,
          strokeWidth: strokeWidth,
          activeColor: activeColor,
          trackColor: trackColor,
        ),
        child: showText
            ? Center(
                child: Text(
                  '${v.round()}%',
                  style: TextStyle(
                    fontSize: size * 0.22,
                    color: activeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color activeColor;
  final Color trackColor;

  const _CirclePainter({
    required this.value,
    required this.strokeWidth,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = (size.width - strokeWidth) / 2;

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (value > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * value / 100,
        false,
        Paint()
          ..color = activeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.value != value ||
      old.activeColor != activeColor ||
      old.trackColor != trackColor;
}
