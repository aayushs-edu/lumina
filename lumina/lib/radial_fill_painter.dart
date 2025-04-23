import 'package:flutter/material.dart';

class RadialFillPainter extends CustomPainter {
  final double progress;
  final Color color;

  RadialFillPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(progress)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    final radius = size.longestSide * progress;
    canvas.drawCircle(size.center(Offset.zero), radius, paint);
  }

  @override
  bool shouldRepaint(covariant RadialFillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
