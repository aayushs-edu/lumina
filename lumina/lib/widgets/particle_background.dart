import 'package:flutter/material.dart';
import 'dart:math' as math;

class Particle {
  Particle({
    required this.position,
    required this.speed,
    required this.color,
    required this.size,
    required this.initialDelay,
  }) {
    // Initialize random phase for size and opacity fluctuations
    sizePhase = random.nextDouble() * 2 * math.pi;
    opacityPhase = random.nextDouble() * 2 * math.pi;
  }

  Offset position;
  Offset speed;
  Color color;
  double size;
  double initialDelay;
  double opacity = 0.0;
  bool hasStarted = false;
  double angle = 0.0;
  double speedMultiplier = 1.0;
  late double sizePhase; // Phase for size fluctuation
  late double opacityPhase; // Phase for opacity fluctuation
  final random = math.Random();

  void update(Size screenSize, double time) {
    if (time < initialDelay) return;

    if (!hasStarted) {
      hasStarted = true;
      opacity = 0.0;
    }

    // Base fade in
    if (opacity < 1.0) {
      opacity = (opacity + 0.15).clamp(0.0, 1.0);
    }

    // Simplify calculations for better performance
    // Use less frequent fluctuation updates
    final sizeFluctuation = math.sin(time * 1.5 + sizePhase) * 0.2 + 1.0;
    final currentSize = size * sizeFluctuation;

    // Simplified opacity fluctuation
    final opacityFluctuation = 0.8 + (time % 2 > 1 ? 0.2 : 0);
    final currentOpacity = opacity * opacityFluctuation;

    // Simplify wobble movement
    if (time % 0.5 < 0.1) {
      angle += (random.nextDouble() - 0.5) * 0.1;
    }
    final wobbleX = math.sin(angle) * 0.3;
    final wobbleY = math.cos(angle) * 0.3;

    // Speed decay starts much sooner and happens more rapidly
    speedMultiplier = math.max(0.2, 1.0 - time / 15);

    // Apply movement with increased speed
    position += Offset(
      (speed.dx + wobbleX) * speedMultiplier * 0.8,
      (speed.dy + wobbleY) * speedMultiplier * 0.8,
    );

    // Simplified bounce detection
    if (position.dx < 0 || position.dx > screenSize.width) {
      speed = Offset(-speed.dx * 0.9, speed.dy);
      position = Offset(
        position.dx < 0 ? 0 : screenSize.width,
        position.dy
      );
    }
    if (position.dy < 0 || position.dy > screenSize.height) {
      speed = Offset(speed.dx, -speed.dy * 0.9);
      position = Offset(
        position.dx,
        position.dy < 0 ? 0 : screenSize.height
      );
    }

    // Update the particle's current size and opacity for rendering
    this.currentSize = currentSize;
    this.currentOpacity = currentOpacity;
  }

  double currentSize = 0.0;
  double currentOpacity = 0.0;
}

class Ray {
  final Offset start;
  final double angle;
  double length;
  double opacity;
  final Color color;
  final double speed;
  final double maxLength;

  Ray({
    required this.start,
    required this.angle,
    required this.color,
    this.length = 0,
    this.opacity = 1.0,
    required this.speed,
    required this.maxLength,
  });

  void update(double deltaTime) {
    if (length < maxLength) {
      length += speed * deltaTime;
    } else {
      opacity = (opacity - 0.02).clamp(0.0, 1.0);
    }
  }
}

class ParticleBackground extends StatefulWidget {
  final GlobalKey luminaTextKey;

  const ParticleBackground({Key? key, required this.luminaTextKey})
    : super(key: key);

  @override
  _ParticleBackgroundState createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late List<Particle> particles;
  late AnimationController _controller;
  final math.Random random = math.Random();
  Rect? textBounds;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();
    particles = [];

    // Initialize particles with shorter delay
    Future.delayed(Duration(milliseconds: 100), () {
      _getTextPosition();
    });
  }

  void _getTextPosition() {
    final RenderBox? box =
        widget.luminaTextKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      final position = box.localToGlobal(Offset.zero);
      textBounds = Rect.fromLTWH(
        position.dx,
        position.dy,
        box.size.width,
        box.size.height,
      );
      _initializeParticles(MediaQuery.of(context).size);
      setState(() {});
    } else {
      // If text position is not available yet, try again after a short delay
      Future.delayed(Duration(milliseconds: 100), _getTextPosition);
    }
  }

  void _initializeParticles(Size screenSize) {
    if (textBounds == null) return;
    if (particles.isEmpty) {
      // Further reduce the particle count for better performance
      final particleCount = (screenSize.width * screenSize.height / 30000).round();
      particles = List.generate(
        particleCount,
        (index) => _createParticle(screenSize),
      );
    }
  }

  Particle _createParticle(Size screenSize) {
    final colors = [
      // Keep existing feminine colors
      const Color.fromRGBO(255, 105, 180, 0.8),  // Hot Pink
      const Color.fromRGBO(255, 182, 193, 0.8),  // Light Pink
      const Color.fromRGBO(219, 112, 147, 0.8),  // Pale Violet Red
      const Color.fromRGBO(255, 20, 147, 0.8),   // Deep Pink
      
      // Add red and orange colors
      const Color.fromRGBO(255, 69, 0, 0.8),     // Red-Orange
      const Color.fromRGBO(255, 140, 0, 0.8),    // Dark Orange
    ];

    final startX = textBounds!.left + textBounds!.width / 2;
    final startY = textBounds!.top + textBounds!.height / 2;
    final randomAngle = random.nextDouble() * 2 * math.pi;
    
    // Increase initial speed for faster movement
    final speed = 15.0 + random.nextDouble() * 20.0;
    final velocityX = math.cos(randomAngle) * speed;
    final velocityY = math.sin(randomAngle) * speed;

    return Particle(
      position: Offset(startX, startY),
      speed: Offset(velocityX, velocityY),
      color: colors[random.nextInt(colors.length)],
      size: random.nextDouble() * 12 + 4,
      initialDelay: random.nextDouble() * 0.2,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (particles.isEmpty) {
      _getTextPosition();
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [
                const Color.fromRGBO(255, 204, 178, 0.7),
                const Color.fromRGBO(255, 218, 198, 1),
                const Color.fromRGBO(255, 236, 225, 1),
                Colors.white,
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        if (particles.isNotEmpty && textBounds != null)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              for (var particle in particles) {
                particle.update(
                  MediaQuery.of(context).size,
                  _controller.value * 30,
                );

                // Calculate fade based on vertical position
                double fadeThreshold = MediaQuery.of(context).size.height * 0.6;
                if (particle.position.dy < fadeThreshold) {
                  double distance = (fadeThreshold - particle.position.dy) / fadeThreshold;
                  particle.currentOpacity = (distance * 0.8).clamp(0.0, 1.0);
                } else {
                  particle.currentOpacity = 0.0;
                }
              }

              return CustomPaint(
                painter: ParticlePainter(particles: particles),
                size: Size.infinite,
              );
            },
          ),
      ],
    );
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.currentOpacity <= 0) continue;

      final paint =
          Paint()
            ..color = particle.color.withOpacity(particle.currentOpacity * 0.7)
            ..style = PaintingStyle.fill
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              particle.currentSize / 3,
            );

      canvas.drawCircle(particle.position, particle.currentSize, paint);
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}