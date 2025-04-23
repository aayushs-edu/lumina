import 'dart:ui';
import 'package:flutter/material.dart';

class BezierLine {
  final Offset from;
  final Offset to;
  final DateTime startTime;

  BezierLine({required this.from, required this.to, required this.startTime});
}

class BezierCurvePainter extends CustomPainter {
  final BezierLine line;

  BezierCurvePainter({required this.line});

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = DateTime.now().difference(line.startTime).inMilliseconds / 1000.0;
    final progress = elapsed.clamp(0.0, 1.0);

    final paint = Paint()
      ..color = Colors.amberAccent.withOpacity(1.0 - (1.0 - progress).abs())
      ..strokeWidth = 3
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke;

    final cp1 = Offset(line.from.dx + 100, line.from.dy);
    final cp2 = Offset(line.to.dx - 100, line.to.dy);

    final path = Path()
      ..moveTo(line.from.dx, line.from.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, line.to.dx, line.to.dy);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
