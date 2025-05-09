import 'dart:math';
import 'package:flutter/material.dart';

class Particle {
  Offset position;
  Offset velocity;
  double life;
  double radius;
  Color color;

  Particle({required this.position, required this.velocity, required this.life, required this.radius, required this.color});
}

class ParticleBurst extends StatefulWidget {
  final Offset origin;

  ParticleBurst({required this.origin});

  @override
  _ParticleBurstState createState() => _ParticleBurstState();
}

class _ParticleBurstState extends State<ParticleBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _generateParticles();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 700),
    )..addListener(() => setState(() {}))
     ..forward();
  }

  void _generateParticles() {
    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = _random.nextDouble() * 0.2 + 0.1; // Even slower random speed (0.5 to 1.5)
      final initialX = _random.nextDouble() * MediaQuery.of(context).size.width; // Random X position
      final initialY = _random.nextDouble() * MediaQuery.of(context).size.height; // Random Y position

      _particles.add(
        Particle(
          position: Offset(initialX, initialY), // Start at a random position
          velocity: Offset(cos(angle), sin(angle)) * speed,
          life: 1.0,
          radius: _random.nextDouble() * 3 + 2,
          color: Colors.amberAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = _controller.value;

    for (var p in _particles) {
      p.position += p.velocity * 0.5; // Slow down movement
      p.life -= 0.01; // Decrease life slower
    }

    _particles.removeWhere((p) => p.life <= 0);

    return Positioned.fill(
      child: CustomPaint(
        painter: _ParticlePainter(particles: _particles, time: time),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double time;

  _ParticlePainter({required this.particles, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (var p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(p.life)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(p.position, p.radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
