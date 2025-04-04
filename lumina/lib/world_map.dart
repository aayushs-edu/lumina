import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';

class InteractiveWorldMap extends StatefulWidget {
  @override
  _InteractiveWorldMapState createState() => _InteractiveWorldMapState();
}

class Region {
  final String id;
  final String path;
  final Color color;

  Region({required this.id, required this.path, required this.color});
}

class _InteractiveWorldMapState extends State<InteractiveWorldMap>
    with SingleTickerProviderStateMixin {
  List<Region> _regions = [];
  final Random random = Random();
  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    loadRegions().then((data) {
      _regions = data;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  Color _getRandomRedShade() {
    // Generate random red shade between 100-255 for vibrancy
    final red =
        100 + random.nextInt(156); // This ensures red is between 100-255
    // Keep some minimal green and blue for better visibility
    final greenBlue =
        20 + random.nextInt(30); // This keeps green/blue low but not zero
    return Color.fromRGBO(red, greenBlue, greenBlue, 1.0);
  }

  loadRegions() async {
    // Load the SVG file
    final String svgString = await rootBundle.loadString('assets/world.svg');
    final document = XmlDocument.parse(svgString);

    // Find all path elements in the SVG
    final paths = document.findAllElements('path');
    final regions = <Region>[];

    print('Found ${paths.length} paths in SVG');

    // Process each path to extract country data
    int pathIndex = 0;
    for (var path in paths) {
      final id = path.getAttribute('id') ?? '';
      final partPath = path.getAttribute('d') ?? '';

      // Skip empty paths
      if (partPath.isEmpty) {
        print('Skipping empty path at index $pathIndex');
        continue;
      }

      // Use index as ID if no ID exists
      final regionId = id.isNotEmpty ? id : 'region_$pathIndex';
      regions.add(
        Region(id: regionId, path: partPath, color: _getRandomRedShade()),
      );
      pathIndex++;
    }

    print('Created ${regions.length} regions');
    return regions;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          "Inequality Atlas",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map
            Expanded(
              flex: 5,
              child: AspectRatio(
                aspectRatio: 2.2,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ..._regions.map((region) {
                        return _getRegionImage(region);
                      }),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            // Hotspots Panel
            Expanded(
              flex: 1,
              child: SizedBox(
                height: 400,
                width: 200,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(
                        255,
                        255,
                        20,
                        20,
                      ).withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(
                          255,
                          255,
                          20,
                          20,
                        ).withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Inequality Hotspots",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ..._getHotspotItems(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  List<Widget> _getHotspotItems() {
    return [
      _HotspotItem(
        country: "United States",
        level: "High",
        color: const Color.fromARGB(255, 255, 20, 20),
      ),
      _HotspotItem(
        country: "Russia",
        level: "High",
        color: const Color.fromARGB(255, 255, 20, 20),
      ),
      _HotspotItem(
        country: "China",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      _HotspotItem(
        country: "India",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      _HotspotItem(
        country: "Brazil",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
    ];
  }

  Widget _getRegionImage(Region region) {
    return ClipPath(
      clipper: RegionClipper(path: region.path),
      child: GestureDetector(
        onTap: () {
          print('Tapped on ${region.id}');
        },
        child: Container(
          color: region.color,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('Tapped on ${region.id}');
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!, width: 0.5),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class RegionClipper extends CustomClipper<Path> {
  final String path;
  // Original SVG viewBox dimensions
  static const originalWidth = 2000.0;
  static const originalHeight = 1001.0;

  RegionClipper({super.reclip, required this.path});

  @override
  Path getClip(Size size) {
    final pathData = parseSvgPathData(path);

    // Calculate scale to fit container
    final scaleX = size.width / originalWidth;
    final scaleY = size.height / originalHeight;

    // Use uniform scaling to maintain aspect ratio
    final scale = min(scaleX, scaleY);

    // Create transformation matrix
    final matrix = Matrix4.identity()..scale(scale, scale);

    return pathData.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return false;
  }
}

class _HotspotItem extends StatelessWidget {
  final String country;
  final String level;
  final Color color;

  const _HotspotItem({
    required this.country,
    required this.level,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              country,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            level,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
