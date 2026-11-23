import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/waving_leaf.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'package:lumina/models/gender_inequality_data.dart';
import 'package:lumina/widgets/theme_tag.dart';
import 'package:lumina/widgets/navbar.dart';

extension OffsetExtension on Offset {
  Offset normalized() {
    final len = distance;
    if (len == 0) return this;
    return this / len;
  }
}

class LuminaLensWorldMap extends StatefulWidget {
  @override
  _LuminaLensWorldMapState createState() => _LuminaLensWorldMapState();
}

class Region {
  final String id;
  final String path;
  final Color color;

  Region({required this.id, required this.path, required this.color});
}

class RadialFillPainter extends CustomPainter {
  final Path countryPath;
  final double progress;
  final Color fillColor;
  
  RadialFillPainter({
    required this.countryPath, 
    required this.progress,
    required this.fillColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final rect = countryPath.getBounds();
    final center = rect.center;
    final radius = max(rect.width, rect.height) * progress * 2;
    
    // Create radial gradient for fill
    final gradient = RadialGradient(
      colors: [
        fillColor,
        fillColor.withOpacity(0.0),
      ],
      stops: [progress, 1.0],
      radius: 1.0,
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;
    
    // Create path and clip to country shape
    canvas.clipPath(countryPath);
    canvas.drawCircle(center, radius, paint);
    
    // Add glow effect
    if (progress > 0.3) {
      final glowPaint = Paint()
        ..color = fillColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 * progress);
      
      canvas.drawPath(countryPath, glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant RadialFillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CurvesPainter extends CustomPainter {
  final Offset sourcePoint;
  final List<Offset> targetPoints;
  final double progress;
  final Color curveColor;
  
  CurvesPainter({
    required this.sourcePoint,
    required this.targetPoints,
    required this.progress,
    required this.curveColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Get the size of the canvas to properly scale coordinates
    final scaleX = size.width / 1000.0;  // Match the SizedBox width in build
    final scaleY = size.height / 450.0;  // Match the SizedBox height in build
    
    // Transform source point to canvas coordinates
    final scaledSourcePoint = Offset(
      sourcePoint.dx * scaleX,
      sourcePoint.dy * scaleY,
    );
    
    // Draw curves to each target
    for (var targetPoint in targetPoints) {
      // Transform target point to canvas coordinates
      final scaledTargetPoint = Offset(
        targetPoint.dx * scaleX,
        targetPoint.dy * scaleY,
      );
      
      _drawCurve(canvas, scaledSourcePoint, scaledTargetPoint, progress);
      
      // Add particle effects along the curve
      if (progress > 0.1) {
        _drawParticles(canvas, scaledSourcePoint, scaledTargetPoint, progress);
      }
    }
  }
  
  void _drawCurve(Canvas canvas, Offset source, Offset target, double progress) {
    // Calculate control points for bezier
    final distance = (target - source).distance;
    final midpoint = Offset(
      source.dx + (target.dx - source.dx) * 0.5,
      source.dy + (target.dy - source.dy) * 0.5,
    );
    
    // Raise control point perpendicular to line
    final perpendicular = Offset(
      -(target.dy - source.dy),
      target.dx - source.dx,
    ).normalized();
    
    final controlPoint = Offset(
      midpoint.dx + perpendicular.dx * distance * 0.2,
      midpoint.dy + perpendicular.dy * distance * 0.2,
    );
    
    // Create path for the curve
    final path = Path()
      ..moveTo(source.dx, source.dy);
    
    // Only draw as far as the progress allows
    final endPoint = Offset(
      source.dx + (target.dx - source.dx) * progress,
      source.dy + (target.dy - source.dy) * progress,
    );
    
    path.quadraticBezierTo(
      controlPoint.dx, 
      controlPoint.dy, 
      endPoint.dx, 
      endPoint.dy
    );
    
    // Draw the curve with glow effect
    final paint = Paint()
      ..color = curveColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawPath(path, paint);
    
    // Add glow effect
    final glowPaint = Paint()
      ..color = curveColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0);
    
    canvas.drawPath(path, glowPaint);
  }
  
  void _drawParticles(Canvas canvas, Offset source, Offset target, double progress) {
    final random = Random();
    final particleCount = 6;
    
    // Calculate control points
    final distance = (target - source).distance;
    final midpoint = Offset(
      source.dx + (target.dx - source.dx) * 0.5,
      source.dy + (target.dy - source.dy) * 0.5,
    );
    
    final perpendicular = Offset(
      -(target.dy - source.dy),
      target.dx - source.dx,
    ).normalized();
    
    final controlPoint = Offset(
      midpoint.dx + perpendicular.dx * distance * 0.2,
      midpoint.dy + perpendicular.dy * distance * 0.2,
    );
    
    // Draw particles along the curve
    for (int i = 0; i < particleCount; i++) {
      final t = min(1.0, (progress * 1.2) - (i * 0.08));
      if (t <= 0) continue;
      
      // Calculate position along the curve using quadratic bezier formula
      final particlePosition = _getPointOnQuadraticCurve(
        source, controlPoint, target, t
      );
      
      // Add some randomness to particle positions
      final jitter = Offset(
        (random.nextDouble() - 0.5) * 4,
        (random.nextDouble() - 0.5) * 4,
      );
      
      // Draw particle
      final particlePaint = Paint()
        ..color = curveColor.withOpacity(0.6 + random.nextDouble() * 0.4)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        particlePosition + jitter, 
        2.0 + random.nextDouble() * 3.0, 
        particlePaint
      );
      
      // Draw glow around particle
      final glowPaint = Paint()
        ..color = curveColor.withOpacity(0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3.0);
      
      canvas.drawCircle(
        particlePosition + jitter, 
        4.0 + random.nextDouble() * 2.0, 
        glowPaint
      );
    }
  }
  
  Offset _getPointOnQuadraticCurve(
    Offset p0, Offset p1, Offset p2, double t
  ) {
    final mt = 1 - t;
    return Offset(
      mt * mt * p0.dx + 2 * mt * t * p1.dx + t * t * p2.dx,
      mt * mt * p0.dy + 2 * mt * t * p1.dy + t * t * p2.dy,
    );
  }
  
  @override
  bool shouldRepaint(covariant CurvesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class TargetFillPainter extends CustomPainter {
  final Path countryPath;
  final double progress;
  final Color fillColor;
  
  TargetFillPainter({
    required this.countryPath, 
    required this.progress,
    required this.fillColor,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Create impact effect
    if (progress < 0.3) {
      final impactProgress = progress / 0.3;
      final shockwavePaint = Paint()
        ..color = fillColor.withOpacity(0.5 * (1 - impactProgress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10.0 * (1 - impactProgress);
      
      canvas.drawPath(countryPath, shockwavePaint);
    }
    
    // Draw fill
    final fillPaint = Paint()
      ..color = fillColor.withOpacity(progress)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(countryPath, fillPaint);
    
    // Add highlight glow
    if (progress > 0.5) {
      final glowPaint = Paint()
        ..color = Colors.white.withOpacity(0.7 * (progress - 0.5) * 2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2.0);
      
      canvas.drawPath(countryPath, glowPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant TargetFillPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// Add this CustomPainter class, ideally near the top of the file or in a separate file.
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;
    final double spacing = 50; // Adjust this value for grid spacing

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LuminaLensWorldMapState extends State<LuminaLensWorldMap>
    with TickerProviderStateMixin {
  List<Region> _regions = [];
  final Random random = Random();
  late AnimationController _gradientController;

  // Tooltip state
  bool _tooltipVisible = false;
  String? _hoveredCountryId;
  Offset _tooltipPosition = Offset.zero;
  OverlayEntry? _tooltipOverlay;

  // New animation controllers
  late AnimationController _radialFillController;
  late AnimationController _curveAnimationController;
  late AnimationController _targetFillController;

  // Animation state variables
  String? _animatingCountryId;
  List<String> _targetCountryIds = [];
  Map<String, double> _targetFillValues = {};
  Map<String, Path?> _countryPaths = {};

  // Add these variables to your _InteractiveWorldMapState class
  late AnimationController _fillAnimationController;
  String? _selectedCountryId;
  List<String> _connectedCountryIds = [];
  Map<String, Offset> _countryPositions = {};

  // Panel state
  String? _selectedCountry;
  GenderInequalityData? _selectedCountryData;

  // Map of country names to ISO codes
  late final Map<String, String> _countryToIso;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // New animation controllers
    _radialFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _curveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _targetFillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // New animation controller
    _fillAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addStatusListener(_onFillComplete);

    // Add listeners
    _radialFillController.addStatusListener(_onRadialFillComplete);
    _curveAnimationController.addStatusListener(_onCurveAnimationComplete);

    // Load GII data and then initialize _countryToIso and regions.
    GenderInequalityDataManager().loadData().then((_) {
      // Initialize _countryToIso after data is loaded
      setState(() {
        _initializeCountryToIso();
      });

      loadRegions().then((regionsData) {
        setState(() {
          _regions = regionsData;
          // Ensure the overlay is initialized if regions are present
          if (_regions.isNotEmpty) {
            // Trigger rebuild if necessary
          }
        });
      });
    });
  }

  void _onFillComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Select random countries and start connecting animations
      setState(() {
        _connectedCountryIds = _selectRandomCountries(_selectedCountryId!, 3);
      });
    }
  }

  void _initializeCountryToIso() {
    _countryToIso = {
      for (var data in GenderInequalityDataManager().data)
        data.country: data.isoCode,
    };
  }

  // Helper to get country name from ISO code
  String? _getCountryNameFromIso(String id) {
    // By our new approach, the region id is the country name.
    return id;
  }

  void _showTooltip(BuildContext context, Offset position, String countryId) {
    // Hide any existing tooltip first
    _hideTooltip();

    final countryName = _getCountryNameFromIso(countryId);
    if (countryName == null) return;

    final giiData = GenderInequalityDataManager().getDataForCountry(
      countryName,
    );
    if (giiData == null) return;

    // Create overlay entry
    _tooltipOverlay = OverlayEntry(
      builder:
          (context) => Positioned(
            left: position.dx + 10, // Offset to prevent cursor overlap
            top: position.dy + 10,
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.all(12),
                constraints: BoxConstraints(maxWidth: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      countryName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_tooltipOverlay!);
    _tooltipVisible = true;
    _hoveredCountryId = countryId;
    _tooltipPosition = position;
  }

  // Hide tooltip
  void _hideTooltip() {
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
      _tooltipVisible = false;
      _hoveredCountryId = null;
    }
  }

  // Update tooltip position on mouse move
  void _updateTooltipPosition(Offset position) {
    if (_tooltipVisible && _tooltipPosition != position) {
      _tooltipPosition = position;
      // Only recreate tooltip if it's significantly moved
      if ((position - _tooltipPosition).distance > 5) {
        _hideTooltip();
        _showTooltip(context, position, _hoveredCountryId!);
      }
    }
  }

  void _updateSelectedCountry(String countryName) async {
    final giiData = GenderInequalityDataManager().getDataForCountry(
      countryName,
    );
    setState(() {
      _selectedCountry = countryName;
      _selectedCountryData = giiData;
    });
  }

  void _onRadialFillComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // When radial fill completes, start curve animations
      _startCurveAnimations();
    }
  }

  void _onCurveAnimationComplete(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // When curves complete, start filling target countries
      _targetFillController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _hideTooltip();
    _gradientController.dispose();
    _fillAnimationController.dispose();
    super.dispose();
  }

  Future<List<Region>> loadRegions() async {
    print('Starting to load regions...'); // Progress print
    // Load the SVG file
    final String svgString = await rootBundle.loadString('assets/world.svg');
    final document = XmlDocument.parse(svgString);

    // Find all path elements in the SVG
    final paths = document.findAllElements('path');
    final regions = <Region>[];
    
    // Set a consistent gray color for all countries
    final Color defaultGray = Colors.grey[300]!;

    for (var path in paths) {
      final id = path.getAttribute('id');
      final className = path.getAttribute('class');
      final partPath = path.getAttribute('d') ?? '';

      // Skip empty paths
      if (partPath.isEmpty) continue;

      String isoCode = id ?? className ?? 'UNKNOWN';
      String? countryName;
      
      // Try to find matching country data (for name purposes only)
      for (var data in GenderInequalityDataManager().data) {
        if (data.isoCode.toLowerCase() == (isoCode).toLowerCase() ||
            data.country.toLowerCase() == isoCode.toLowerCase()) {
          countryName = data.country;
          break;
        }
      }
      
      final regionId = countryName ?? isoCode; // use actual country name if available
      regions.add(Region(id: regionId, path: partPath, color: defaultGray));
      
      // Calculate and store the country center point for bezier curves
      try {
        final pathObj = parseSvgPathData(partPath);
        final bounds = pathObj.getBounds();
        _countryPositions[regionId] = bounds.center;
      } catch (e) {
        print('Error calculating center for $regionId: $e');
      }
    }

    print('Finished loading regions. Total: ${regions.length}'); // Progress print
    return regions;
  }

  void _onCountryClick(String countryId) {
    setState(() {
      _selectedCountryId = countryId;
      _connectedCountryIds = [];
    });
    
    _fillAnimationController.forward(from: 0.0);
  }

  List<String> _selectRandomCountries(String excludeCountry, int count) {
    final availableCountries = _regions
        .map((r) => r.id)
        .where((id) => id != excludeCountry && _countryPositions.containsKey(id))
        .toList();
    
    availableCountries.shuffle();
    return availableCountries.take(count).toList();
  }

  void _startCurveAnimations() {
    // Reset target fill values
    _targetFillValues = {
      for (var id in _connectedCountryIds) id: 0.0,
    };

    // Get the source and target positions
    final sourcePosition = _getCountryCenter(_selectedCountryId!);
    final targetPositions = _connectedCountryIds
        .map((id) => _getCountryCenter(id))
        .toList();

    // Start curve animations
    setState(() {
      _curveAnimationController.forward(from: 0.0);
    });

    // Pass the positions to the painter
    Overlay.of(context)!.insert(
      OverlayEntry(
        builder: (context) => CustomPaint(
          size: Size.infinite,
          painter: ConnectionPainter(
            sourcePosition: sourcePosition,
            targetPositions: targetPositions,
            progress: _curveAnimationController.value,
            color: Colors.blue, // Adjust color as needed
          ),
        ),
      ),
    );
  }

  // Helper to get center point of a country path
  Offset _getCountryCenter(String countryId) {
    final path = _countryPaths[countryId];
    if (path == null) return Offset.zero;

    // Get the raw center from the path
    final rect = path.getBounds();

    // Scale the center to match the canvas size
    final scaleX = 1000.0 / RegionClipper.originalWidth; // Match the map width
    final scaleY = 450.0 / RegionClipper.originalHeight; // Match the map height
    return Offset(rect.center.dx * scaleX, rect.center.dy * scaleY);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: LuminaNavbar(currentPage: 'luminaLens'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: constraints.maxWidth * 0.8, // Dynamically size to 80% of the width
              height: constraints.maxHeight * 0.8, // Dynamically size to 80% of the height
              color: Colors.grey,
              child: const Center(
                child: Text(
                  'Map Placeholder',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
class RegionClipper extends CustomClipper<Path> {
  final String path;
  static const originalWidth = 2000.0;
  static const originalHeight = 1001.0;

  RegionClipper({required this.path});

  @override
  Path getClip(Size size) {
    final pathData = parseSvgPathData(path);
    final scaleX = size.width / originalWidth;
    final scaleY = size.height / originalHeight;
    final scale = min(scaleX, scaleY);
    final matrix = Matrix4.identity()..scale(scale, scale);
    return pathData.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class ConnectionPainter extends CustomPainter {
  final Offset sourcePosition;
  final List<Offset> targetPositions;
  final double progress;
  final Color color;

  ConnectionPainter({
    required this.sourcePosition,
    required this.targetPositions,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var targetPosition in targetPositions) {
      // Calculate control point for bezier curve
      final dx = targetPosition.dx - sourcePosition.dx;
      final dy = targetPosition.dy - sourcePosition.dy;
      final distance = sqrt(dx * dx + dy * dy);

      // Midpoint with some randomized offset for natural curves
      final midX = sourcePosition.dx + dx / 2;
      final midY = sourcePosition.dy + dy / 2;
      final controlPoint = Offset(midX, midY - distance * 0.2);

      // Determine how far along the curve to draw based on progress
      final curveProgress = progress.clamp(0.0, 1.0);

      // Create path for the curve
      final path = Path();
      path.moveTo(sourcePosition.dx, sourcePosition.dy);

      // Calculate the point along the bezier curve at the current progress
      final t = curveProgress;
      final mt = 1 - t;
      final endX = mt * mt * sourcePosition.dx +
          2 * mt * t * controlPoint.dx +
          t * t * targetPosition.dx;
      final endY = mt * mt * sourcePosition.dy +
          2 * mt * t * controlPoint.dy +
          t * t * targetPosition.dy;

      // Draw only up to the current progress point
      path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, endX, endY);

      // Draw curve with glow effect
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(path, paint);

      // Add glow effect
      final glowPaint = Paint()
        ..color = color.withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4.0);

      canvas.drawPath(path, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}