import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import 'todays_topic_page.dart';
import 'post_story_page.dart';
import 'create_lumina_post_page.dart';
import 'data_center_page.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

void main() {
  runApp(LuminaApp());
}

class LuminaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color.fromARGB(255, 255, 102, 0),
          secondary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.baloo2(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          headlineSmall: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          bodyMedium: GoogleFonts.baloo2(fontSize: 16, color: Colors.black),
        ),
      ),
      home: HomePage(),
      routes: {
        '/todaysTopic': (context) => TodaysTopicPage(),
        '/postStory': (context) => PostStoryPage(),
        '/createLuminaPost': (context) => CreateLuminaPostPage(),
        '/dataCenter': (context) => DataCenterPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  final GlobalKey luminaTextKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/icon
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Your navigation items with COSMOS styling
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/todaysTopic');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      "Today's Topic",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/postStory');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      "Post a Story",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/createLuminaPost');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      "Create a Lumina Post",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/dataCenter');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                    ),
                    child: Text(
                      "Data Center",
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Sign In button
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ParticleBackground(luminaTextKey: luminaTextKey),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Initial space to center the text vertically
                      SizedBox(
                        height: MediaQuery.of(context).size.height / 2 - 100,
                      ),
                      // Lumina text
                      Center(
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  const Color.fromARGB(238, 255, 136, 0),
                                  const Color.fromARGB(255, 255, 20, 20),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ).createShader(bounds),
                          child: Text(
                            "lumina",
                            key: luminaTextKey,
                            style: Theme.of(
                              context,
                            ).textTheme.headlineLarge?.copyWith(
                              shadows: [
                                Shadow(
                                  color: const Color.fromARGB(
                                    238,
                                    255,
                                    136,
                                    0,
                                  ).withOpacity(0.4),
                                  blurRadius: 60,
                                  offset: Offset(0, 0),
                                ),
                                Shadow(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    20,
                                    20,
                                  ).withOpacity(0.3),
                                  blurRadius: 120,
                                  offset: Offset(0, 0),
                                ),
                                Shadow(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    20,
                                    20,
                                  ).withOpacity(0.15),
                                  blurRadius: 180,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Subtitle
                      Center(
                        child: Text(
                          "illuminating hidden inequalities",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                      // Theme panel
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                          backgroundBlendMode: BlendMode.overlay,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Today's Theme",
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Gender Inequality",
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // World Map Panel
                      Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        padding: EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey[100]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 20,
                              spreadRadius: 0,
                            ),
                          ],
                          backgroundBlendMode: BlendMode.overlay,
                        ),
                        child: Column(
                          children: [
                            Text(
                              "Global Impact Map",
                              style: TextStyle(
                                color: Colors.black87.withOpacity(0.8),
                                fontSize: 24,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 24),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: WorldMap(),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 40),

                      // Bottom navigation now part of scroll
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            // Dark/Light mode toggle
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[900],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.grey[800],
                                    ),
                                    child: Text(
                                      "Dark",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      "Light",
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Spacer(),
                            // Scroll to explore button
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: Colors.grey[900],
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    "Scroll to explore",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Add some padding at the bottom for better scrolling
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WorldMap extends StatefulWidget {
  @override
  _WorldMapState createState() => _WorldMapState();
}

class _WorldMapState extends State<WorldMap> {
  late MapShapeSource _mapSource;

  @override
  void initState() {
    _mapSource = MapShapeSource.asset(
      'assets/world_map.json',
      shapeDataField: 'name',
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: SfMaps(layers: [MapShapeLayer(source: _mapSource)]),
    );
  }
}

class MapData {
  MapData(this.name, this.color);

  String name;
  Color color;
}

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

    // Add size fluctuation
    final sizeFluctuation = math.sin(time * 2 + sizePhase) * 0.3 + 1.0;
    final currentSize = size * sizeFluctuation;

    // Add opacity fluctuation
    final opacityFluctuation = math.sin(time * 1.5 + opacityPhase) * 0.2 + 0.8;
    final currentOpacity = opacity * opacityFluctuation;

    // Add some wobble to the movement
    angle += (random.nextDouble() - 0.5) * 0.2;
    final wobbleX = math.sin(angle) * 0.5;
    final wobbleY = math.cos(angle) * 0.5;

    // Calculate speed decay after 15 seconds
    if (time > 15) {
      speedMultiplier = math.max(0.3, 1.0 - (time - 15) / 15);
    }

    // Apply movement with speed multiplier
    position += Offset(
      (speed.dx + wobbleX) * speedMultiplier * 0.3,
      (speed.dy + wobbleY) * speedMultiplier * 0.3,
    );

    // Bounce off screen edges with original bounce physics
    if (position.dx < 0) {
      position = Offset(0, position.dy);
      speed = Offset(-speed.dx * 0.9, speed.dy + (random.nextDouble() - 0.5));
    } else if (position.dx > screenSize.width) {
      position = Offset(screenSize.width, position.dy);
      speed = Offset(-speed.dx * 0.9, speed.dy + (random.nextDouble() - 0.5));
    }
    if (position.dy < 0) {
      position = Offset(position.dx, 0);
      speed = Offset(speed.dx + (random.nextDouble() - 0.5), -speed.dy * 0.9);
    } else if (position.dy > screenSize.height) {
      position = Offset(position.dx, screenSize.height);
      speed = Offset(speed.dx + (random.nextDouble() - 0.5), -speed.dy * 0.9);
    }

    // Update the particle's current size and opacity for rendering
    this.currentSize = currentSize;
    this.currentOpacity = currentOpacity;
  }

  double currentSize = 0.0;
  double currentOpacity = 0.0;
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
      final particleCount =
          (screenSize.width * screenSize.height / 8000)
              .round(); // More particles
      particles = List.generate(
        particleCount,
        (index) => _createParticle(screenSize),
      );
    }
  }

  Particle _createParticle(Size screenSize) {
    final colors = [
      const Color.fromRGBO(255, 82, 182, 0.7),
      const Color.fromRGBO(147, 51, 234, 0.7),
      const Color.fromRGBO(255, 64, 129, 0.7),
      const Color.fromRGBO(124, 77, 255, 0.7),
      const Color.fromRGBO(255, 145, 0, 0.7),
    ];

    // Start all particles from the center of the text
    final startX = textBounds!.left + textBounds!.width / 2;
    final startY = textBounds!.top + textBounds!.height / 2;

    // Calculate random angle for radial movement
    final randomAngle = random.nextDouble() * 2 * math.pi;

    // Much faster initial speed
    final speed = 2.0 + random.nextDouble() * 3.0;
    final velocityX = math.cos(randomAngle) * speed;
    final velocityY = math.sin(randomAngle) * speed;

    return Particle(
      position: Offset(startX, startY),
      speed: Offset(velocityX, velocityY),
      color: colors[random.nextInt(colors.length)],
      size: random.nextDouble() * 15 + 1,
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
    // Try to initialize particles if not done yet
    if (particles.isEmpty) {
      _getTextPosition();
    }

    return Stack(
      children: [
        // Radial gradient background
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.white,
                const Color.fromRGBO(255, 236, 225, 1),
                const Color.fromRGBO(255, 218, 198, 1),
                const Color.fromRGBO(255, 204, 178, 0.7),
              ],
              stops: [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Particles
        if (particles.isNotEmpty)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              for (var particle in particles) {
                particle.update(
                  MediaQuery.of(context).size,
                  _controller.value * 30,
                );
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
