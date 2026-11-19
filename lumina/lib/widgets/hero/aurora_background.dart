import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'hero_common.dart';

/// Slow, silky ribbons and pools of warm light on a cream ground, with a fine
/// film grain. The light leans gently toward the pointer.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.pointer});

  final ValueListenable<Offset?> pointer;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _Blob {
  const _Blob(
    this.color,
    this.bx,
    this.by,
    this.ax,
    this.ay,
    this.fx,
    this.fy,
    this.phase,
    this.radius,
  );
  final Color color;
  final double bx, by, ax, ay, fx, fy, phase, radius;
}

class _Ribbon {
  const _Ribbon(
    this.base,
    this.amp,
    this.k,
    this.speed,
    this.thickness,
    this.colors,
    this.phase,
  );
  final double base, amp, k, speed, thickness, phase;
  final List<Color> colors;
}

class _AuroraBackgroundState extends HeroTickerState<AuroraBackground> {
  final DriftingLight _light = DriftingLight(followRate: 3.5);
  Size _size = Size.zero;
  ui.Image? _grain;

  static const blobs = [
    _Blob(Color(0xFFFFB38A), 0.22, 0.30, 0.10, 0.08, 0.050, 0.070, 0.0, 0.55),
    _Blob(Color(0xFFFF8A65), 0.78, 0.26, 0.09, 0.10, 0.060, 0.045, 1.7, 0.50),
    _Blob(Color(0xFFFFC857), 0.55, 0.62, 0.14, 0.07, 0.040, 0.065, 3.1, 0.48),
    _Blob(Color(0xFFFF9DB0), 0.12, 0.70, 0.08, 0.09, 0.070, 0.050, 4.4, 0.42),
    _Blob(Color(0xFFFFD6A5), 0.90, 0.68, 0.07, 0.08, 0.055, 0.060, 5.2, 0.45),
  ];

  static const ribbons = [
    _Ribbon(0.30, 0.07, 1.6, 0.22, 0.11, [
      Color(0xFFFF7A59),
      Color(0xFFFFB347),
      Color(0xFFFF8FA3),
    ], 0.0),
    _Ribbon(0.55, 0.06, 2.3, -0.17, 0.08, [
      Color(0xFFFFC46B),
      Color(0xFFFF6F61),
      Color(0xFFFFB38A),
    ], 2.1),
    _Ribbon(0.72, 0.05, 1.2, 0.12, 0.07, [
      Color(0xFFFF9DB0),
      Color(0xFFFFC857),
      Color(0xFFFF8A65),
    ], 4.0),
  ];

  @override
  void initState() {
    super.initState();
    _makeGrain();
  }

  Future<void> _makeGrain() async {
    const n = 160;
    final rnd = math.Random(3);
    final pixels = Uint8List(n * n * 4);
    for (int i = 0; i < n * n; i++) {
      final v = rnd.nextInt(256);
      pixels[i * 4] = v;
      pixels[i * 4 + 1] = v;
      pixels[i * 4 + 2] = v;
      pixels[i * 4 + 3] = 255;
    }
    ui.decodeImageFromPixels(pixels, n, n, ui.PixelFormat.rgba8888, (img) {
      if (mounted) {
        _grain = img;
      } else {
        img.dispose();
      }
    });
  }

  @override
  void onTick(double dt) {
    if (_size.isEmpty) return;
    _light.update(_size, dt, widget.pointer.value, motion: motion);
  }

  @override
  void dispose() {
    _grain?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return CustomPaint(size: Size.infinite, painter: _AuroraPainter(this));
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  _AuroraPainter(this.state) : super(repaint: state.repaint);
  final _AuroraBackgroundState state;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final t = state.elapsed;
    final light = state._light.position ?? size.center(Offset.zero);
    // Parallax: everything leans a little toward the light.
    final lean = Offset(
      (light.dx / size.width - 0.5) * size.width * 0.04,
      (light.dy / size.height - 0.5) * size.height * 0.04,
    );

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF1E6), Color(0xFFFFF7F1), Color(0xFFFFFFFF)],
          stops: [0.0, 0.6, 1.0],
        ).createShader(rect),
    );

    // Pools of colour.
    final span = math.max(size.width, size.height);
    for (final b in _AuroraBackgroundState.blobs) {
      final c =
          Offset(
            size.width *
                (b.bx + b.ax * math.sin(t * b.fx * 2 * math.pi + b.phase)),
            size.height *
                (b.by + b.ay * math.cos(t * b.fy * 2 * math.pi + b.phase)),
          ) +
          lean;
      final r = span * b.radius;
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [b.color.withAlpha(150), b.color.withAlpha(0)],
          ).createShader(Rect.fromCircle(center: c, radius: r)),
      );
    }

    // Silk ribbons: each is a stack of soft strokes with a gaussian falloff.
    const strands = 20;
    const segments = 56;
    for (final rb in _AuroraBackgroundState.ribbons) {
      final shader = LinearGradient(colors: rb.colors).createShader(rect);
      final thick = size.height * rb.thickness;
      for (int s = 0; s < strands; s++) {
        final u = s / (strands - 1) * 2 - 1; // -1..1 across the ribbon
        final alpha = math.exp(-u * u * 3.2) * 0.17;
        final path = Path();
        for (int i = 0; i <= segments; i++) {
          final x = -60 + (size.width + 120) * i / segments;
          final nx = x / size.width;
          final y =
              size.height * rb.base +
              size.height *
                  rb.amp *
                  math.sin(nx * rb.k * math.pi + t * rb.speed * 2 + rb.phase) +
              size.height *
                  rb.amp *
                  0.4 *
                  math.sin(nx * rb.k * 2.3 * math.pi - t * rb.speed * 1.3) +
              u *
                  thick *
                  (0.65 + 0.35 * math.sin(nx * 3.0 + t * 0.4 + rb.phase));
          final p = Offset(x, y) + lean * 0.6;
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = thick / strands * 4.2
            ..shader = shader
            ..color = Color.fromRGBO(0, 0, 0, alpha),
        );
      }
    }

    // A soft white highlight where the light is.
    canvas.drawCircle(
      light,
      320,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
        ).createShader(Rect.fromCircle(center: light, radius: 320)),
    );

    // Fine grain for a printed, tactile finish.
    final grain = state._grain;
    if (grain != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ImageShader(
            grain,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
          )
          ..color = const Color.fromRGBO(0, 0, 0, 0.05)
          ..blendMode = BlendMode.multiply,
      );
    }

    // Ease the bottom 40% into the page's white so the hero has no edge.
    final fadeRect = Rect.fromLTWH(
      0,
      size.height * 0.6,
      size.width,
      size.height * 0.4 + 1,
    );
    canvas.drawRect(
      fadeRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x00FFFFFF),
            Color(0x1FFFFFFF),
            Color(0x73FFFFFF),
            Color(0xD9FFFFFF),
            Color(0xFFFFFFFF),
          ],
          stops: [0.0, 0.25, 0.55, 0.82, 1.0],
        ).createShader(fadeRect),
    );
  }

  @override
  bool shouldRepaint(covariant _AuroraPainter old) => old.state != state;
}
