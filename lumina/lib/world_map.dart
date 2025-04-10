import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'package:lumina/lib/models/gender_inequality_data.dart';
import 'package:lumina/services/gender_inequality_data_manager.dart';

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
  
  // Tooltip state variables
  bool _tooltipVisible = false;
  String? _hoveredCountryId;
  Offset _tooltipPosition = Offset.zero;
  OverlayEntry? _tooltipOverlay;

  // Map of country names to ISO codes
  late final Map<String, String> _countryToIso;

  // Map of hotspot countries with their severity levels and story counts
  Map<String, Map<String, dynamic>> _hotspotCountries = {};

  // Map severity levels to colors
  final Map<String, Color> _severityColors = {
    'High': const Color.fromARGB(255, 255, 20, 20),
    'Medium': const Color.fromARGB(255, 255, 102, 0),
    'Low': const Color.fromARGB(255, 233, 202, 25), // Changed from Color.fromARGB(255, 200, 200, 0) to yellow
  };

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    // Initialize _countryToIso map
    _initializeCountryToIso();

    // First load hotspot data, then reload regions
    loadHotspotData().then((_) {
      loadRegions().then((data) {
        _regions = data;
        setState(() {});
      });
    });
  }

  void _initializeCountryToIso() {
    _countryToIso = {
      for (var data in GenderInequalityDataManager().data)
        data.country: _countryToIso[data.country] ?? 'UNKNOWN'
    };
  }

  @override
  void dispose() {
    _hideTooltip();
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
      final id = path.getAttribute('id');
      final className = path.getAttribute('class');
      final partPath = path.getAttribute('d') ?? '';

      // Skip empty paths
      if (partPath.isEmpty) {
        print('Skipping empty path at index $pathIndex');
        continue;
      }
      print('Processing path with id: $id, class: $className');
      // Get the ISO code for this country
      String isoCode = id ?? _countryToIso[className] ?? 'UNKNOWN_$pathIndex';
      // If this country is a hotspot, use its assigned severity color; otherwise, use light gray.
      final color = _hotspotCountries.containsKey(isoCode)
          ? _severityColors[_hotspotCountries[isoCode]!['severity']] ??
              Colors.grey[200]!
          : Colors.grey[200]!;

      regions.add(Region(id: isoCode, path: partPath, color: color));
      pathIndex++;
    }

    print('Created ${regions.length} regions');
    return regions;
  }

  Future<void> loadHotspotData() async {
    final stories = await FirebaseService.getAllStories();
    await GenderInequalityDataManager().loadData(); // Ensure data is loaded
    final giiData = GenderInequalityDataManager().data;
    Map<String, int> storyCounts = {};
    Map<String, Map<String, int>> themeCounts = {};

    for (var story in stories) {
      String country = story['country'];
      storyCounts[country] = (storyCounts[country] ?? 0) + 1;
      if (story.containsKey('themes')) {
        List<dynamic> themes = story['themes'];
        for (var theme in themes) {
          themeCounts[country] = themeCounts[country] ?? {};
          themeCounts[country]![theme.toString()] = (themeCounts[country]![theme.toString()] ?? 0) + 1;
        }
      }
    }

    _hotspotCountries.clear();
    storyCounts.forEach((country, count) {
      // Find the GII data for the country
      final gii = giiData.firstWhere((data) => data.country == country, orElse: () => null);
      double giiScore = gii?.genderInequalityIndex ?? 0.0;

      // Determine severity based on thresholds
      String severity;
      if (count >= 20 || giiScore > 0.5) {
        severity = 'High';
      } else if (count >= 5 || giiScore > 0.3) {
        severity = 'Medium';
      } else {
        severity = 'Low';
      }

      // Optionally, pick the most frequent theme
      List<String> prominentThemes = [];
      if (themeCounts.containsKey(country)) {
        var entry = themeCounts[country]!.entries.reduce((a, b) => a.value >= b.value ? a : b);
        prominentThemes.add(entry.key);
      }

      // Look up ISO code from your _countryToIso mapping
      String? iso = _countryToIso[country];
      if (iso != null) {
        _hotspotCountries[iso] = {
          'severity': severity,
          'stories': count,
          'giiScore': giiScore,
          'themes': prominentThemes,
          'countryName': country,
        };
      }
    });

    setState(() {});
  }

  Future<List<GenderInequalityData>> loadGenderInequalityData() async {
    final String csvString = await rootBundle.loadString('assets/gii.csv');
    final List<String> lines = LineSplitter.split(csvString).toList();
    final List<GenderInequalityData> data = [];

    for (int i = 1; i < lines.length; i++) { // Skip header
      final List<String> values = lines[i].split(',');
      if (values.length < 10) continue; // Ensure there are enough columns

      data.add(GenderInequalityData(
        hdiRank: int.tryParse(values[0]) ?? 0,
        country: values[1],
        genderInequalityIndex: double.tryParse(values[2]) ?? 0.0,
        maternalMortality: double.tryParse(values[5]) ?? 0.0,
        adolescentBirthRate: double.tryParse(values[7]) ?? 0.0,
        parliamentSeatsWomen: double.tryParse(values[9]) ?? 0.0,
        educationFemale: double.tryParse(values[11]) ?? 0.0,
        educationMale: double.tryParse(values[12]) ?? 0.0,
        labourForceFemale: double.tryParse(values[14]) ?? 0.0,
        labourForceMale: double.tryParse(values[15]) ?? 0.0,
      ));
    }

    return data;
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
            fontSize: 40,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Container(
          height: 500, // Fixed height to prevent layout constraints issues
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map in white panel - 85%
              Expanded(
                flex: 85,
                child: Container(
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
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16),
                  child: _regions.isEmpty
                      ? Center(child: CircularProgressIndicator())
                      : FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 1000, // Fixed reference size
                            height: 450, // Fixed reference size
                            child: Stack(
                              children: [
                                ..._regions.map((region) {
                                  return _getRegionImage(region);
                                }),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
              SizedBox(width: 12),
              // Hotspots Panel - 15%
              Expanded(
                flex: 15,
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
                  child: SingleChildScrollView(
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
        ),
      ],
    );
  }

  // Show tooltip using Overlay
  void _showTooltip(BuildContext context, Offset position, String countryId) {
    // Hide any existing tooltip first
    _hideTooltip();
    
    // Only show tooltip for hotspot countries
    if (!_hotspotCountries.containsKey(countryId)) {
      return;
    }
    
    // Get country name from ISO code
    final countryName = _countryToIso.entries
        .firstWhere((entry) => entry.value == countryId, 
                  orElse: () => MapEntry(countryId, countryId))
        .key;
        
    // Get severity color
    final severity = _hotspotCountries[countryId]?['severity'] ?? 'Low';
    final severityColor = _severityColors[severity] ?? Colors.grey;
    
    // Create overlay entry
    _tooltipOverlay = OverlayEntry(
      builder: (context) => Positioned(
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
                  'Inequality Hotspot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  countryName,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Stories: ${_hotspotCountries[countryId]?['stories'] ?? 0}',
                  style: TextStyle(color: Colors.black87),
                ),
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

  List<Widget> _getHotspotItems() {
    List<Widget> items = [];
    _hotspotCountries.forEach((iso, data) {
      String countryName = data['countryName'] ?? iso;
      String severity = data['severity'];
      int storyCount = data['stories'];
      Color color = _severityColors[severity] ?? Colors.grey;
      items.add(
        _HotspotItem(
          country: countryName,
          level: severity,
          color: color,
        ),
      );
    });
    return items;
  }

  Widget _getRegionImage(Region region) {
    return ClipPath(
      clipper: RegionClipper(path: region.path),
      child: MouseRegion(
        onEnter: (event) {
          // Show tooltip when mouse enters a region
          _showTooltip(context, event.position, region.id);
        },
        onHover: (event) {
          // Update tooltip when mouse moves within the same region
          if (_hoveredCountryId == region.id) {
            _updateTooltipPosition(event.position);
          } else {
            // Show new tooltip if mouse moved to a different country
            _showTooltip(context, event.position, region.id);
          }
        },
        onExit: (event) {
          // Hide tooltip when mouse exits a region
          _hideTooltip();
        },
        child: Container(
          color: region.color,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                print('Tapped on ${region.id}');
                // Add your tap action here if needed
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.black.withOpacity(0.3),
                    width: 0.5,
                  ),
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