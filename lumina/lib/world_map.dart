import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'package:lumina/models/gender_inequality_data.dart';

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

  // Tooltip state
  bool _tooltipVisible = false;
  String? _hoveredCountryId;
  Offset _tooltipPosition = Offset.zero;
  OverlayEntry? _tooltipOverlay;

  // Panel state
  String? _selectedCountry;
  GenderInequalityData? _selectedCountryData;

  // Map of country names to ISO codes
  late final Map<String, String> _countryToIso;

  // Map severity levels to colors
  final Map<HotspotLevel, Color> _hotspotColors = {
    HotspotLevel.extreme: const Color.fromARGB(255, 128, 0, 128), // Purple
    HotspotLevel.high: const Color.fromARGB(255, 255, 0, 0), // Red
    HotspotLevel.medium: const Color.fromARGB(255, 255, 165, 0), // Orange
    HotspotLevel.low: const Color.fromARGB(255, 255, 230, 4), // Yellow
    HotspotLevel.none: Colors.grey[200]!, // Light gray
  };

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

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
                    Text(
                      'GII Score: ${giiData.genderInequalityIndex.toStringAsFixed(3)}',
                      style: TextStyle(color: Colors.black87),
                    ),
                    Text(
                      'Level: ${_getLevelName(giiData.hotspotLevel)}',
                      style: TextStyle(
                        color: _hotspotColors[giiData.hotspotLevel],
                        fontWeight: FontWeight.w500,
                      ),
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

  void _updateSelectedCountry(String countryName) async {
    final giiData = GenderInequalityDataManager().getDataForCountry(
      countryName,
    );
    setState(() {
      _selectedCountry = countryName;
      _selectedCountryData = giiData;
    });
  }

  Widget _buildCountryInfoPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotspots',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: 12),
        ..._getLegendItems(),
      ],
    );
  }

  @override
  void dispose() {
    _hideTooltip();
    _gradientController.dispose();
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
    int initializedCount = 0;
    int unknownCount = 0;

    // Get all GII data for quick lookup
    final giiData = GenderInequalityDataManager().data;
    final giiCountryMap = {
      for (var data in giiData) data.country: data,
    };

    // Create a map of alternative names
    final alternativeNames = {
      'united states': 'United States',
      'united kingdom': 'United Kingdom',
      'russian federation': 'Russian Federation',
      'congo, democratic republic of the': 'Democratic Republic of the Congo',
      'congo, republic of the': 'Republic of the Congo',
      'côte d\'ivoire': 'Côte d\'Ivoire',
      'korea, republic of': 'South Korea',
      'korea, democratic people\'s republic of': 'North Korea',
      'tanzania, united republic of': 'Tanzania',
      'venezuela, bolivarian republic of': 'Venezuela',
      'syrian arab republic': 'Syria',
      'lao people\'s democratic republic': 'Laos',
      'myanmar': 'Myanmar',
      'czech republic': 'Czechia',
      'macedonia, the former yugoslav republic of': 'North Macedonia',
      'palestine, state of': 'Palestine',
      'türkiye': 'Turkey',
      'viet nam': 'Vietnam',
    };

    for (var path in paths) {
      final id = path.getAttribute('id');
      final className = path.getAttribute('class');
      final partPath = path.getAttribute('d') ?? '';

      // Skip empty paths
      if (partPath.isEmpty) continue;

      // Try to find matching country data
      GenderInequalityData? giiData;
      String? countryName;
      String isoCode = id ?? className ?? 'UNKNOWN';

      // Try matching by ISO code directly.
      for (var data in giiCountryMap.values) {
        if (data.isoCode.toLowerCase() == (isoCode).toLowerCase()) {
          giiData = data;
          break;
        }
      }

      // If no match, check for alternative names.
      if (giiData == null) {
        final lowerIso = isoCode.toLowerCase();
        if (alternativeNames.containsKey(lowerIso)) {
          final properName = alternativeNames[lowerIso]!;
          giiData = giiCountryMap[properName];
        }
      }

      if (giiData != null) {
        countryName = giiData.country;
      }
      
      final hotspotLevel = giiData?.hotspotLevel ?? HotspotLevel.none;
      final color = _hotspotColors[hotspotLevel] ?? Colors.grey[200]!;

      final regionId = countryName ?? isoCode; // use actual country name if available
      regions.add(Region(id: regionId, path: partPath, color: color));

      if (giiData != null) {
        initializedCount++;
      } else {
        unknownCount++;
      }
    }

    print(
      'Finished loading regions. Total regions: ${regions.length}',
    ); // Progress print
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
            fontSize: 40,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24),
        Container(
          height: 500,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Map in white panel - now takes up 90%
              Expanded(
                flex: 9,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(255, 128, 0, 128)
                          .withOpacity(0.3),
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
                            width: 1000,
                            height: 450,
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
              SizedBox(width: 8),
              // Country Info Panel - now takes up 10%
              Expanded(
                flex: 1,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromARGB(255, 128, 0, 128)
                          .withOpacity(0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 128, 0, 128)
                            .withOpacity(0.1),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                  child: _buildCountryInfoPanel(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _getLegendItems() {
    return HotspotLevel.values.map((level) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _hotspotColors[level],
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                _getLevelName(level),
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  String _getLevelName(HotspotLevel level) {
    switch (level) {
      case HotspotLevel.extreme:
        return "Extreme";
      case HotspotLevel.high:
        return "High";
      case HotspotLevel.medium:
        return "Medium";
      case HotspotLevel.low:
        return "Low";
      case HotspotLevel.none:
        return "No Data";
    }
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
                _showCountryDetails(region.id);
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

  void _showCountryDetails(String countryId) {
    print('Attempting to show country details for: $countryId'); // Debug print
    final countryName = _getCountryNameFromIso(countryId);
    print('Country name from ISO: $countryName'); // Debug print
    if (countryName == null) return;

    final giiData = GenderInequalityDataManager().getDataForCountry(countryName);
    print('GII data found: ${giiData != null}'); // Debug print
    if (giiData == null) return;

    // Get the hotspot color for this country
    final Color hotspotColor = _hotspotColors[giiData.hotspotLevel] ?? Colors.grey[200]!;

    try {
      print('Showing dialog'); // Debug print
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with country name and close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      countryName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                
                // Hotspot level indicator
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: hotspotColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hotspotColor,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getLevelName(giiData.hotspotLevel),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: hotspotColor,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                
                // Main metrics in a row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // GII Score
                    _buildMetricBox(
                      "GII Score",
                      giiData.genderInequalityIndex.toStringAsFixed(3),
                      hotspotColor,
                    ),
                    
                    // Rank
                    _buildMetricBox(
                      "Rank",
                      "${giiData.hdiRank}/${GenderInequalityDataManager().data.length}",
                      hotspotColor,
                    ),
                    
                    // Stories
                    _buildMetricBox(
                      "Stories",
                      "${giiData.storyCount}",
                      hotspotColor,
                    ),
                  ],
                ),
                SizedBox(height: 32),
                
                // Divider
                Divider(color: Colors.grey[300], thickness: 1),
                SizedBox(height: 24),
                
                // Section title
                Text(
                  "Gender Inequality Metrics",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 16),
                
                // Detailed metrics
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailedMetric(
                            "Maternal Mortality",
                            "${giiData.maternalMortality}%",
                            hotspotColor,
                          ),
                          SizedBox(height: 16),
                          _buildDetailedMetric(
                            "Adolescent Birth Rate",
                            "${giiData.adolescentBirthRate}%",
                            hotspotColor,
                          ),
                          SizedBox(height: 16),
                          _buildDetailedMetric(
                            "Parliament Seats (Women)",
                            "${giiData.parliamentSeatsWomen}%",
                            hotspotColor,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 24),
                    // Right column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Education comparison
                          _buildComparisonMetric(
                            "Secondary Education",
                            "Female: ${giiData.educationFemale}%",
                            "Male: ${giiData.educationMale}%",
                            hotspotColor,
                          ),
                          SizedBox(height: 16),
                          // Labour force comparison
                          _buildComparisonMetric(
                            "Labour Force",
                            "Female: ${giiData.labourForceFemale}%",
                            "Male: ${giiData.labourForceMale}%",
                            hotspotColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
      print('Dialog shown successfully'); // Debug print
    } catch (e) {
      print('Error showing dialog: $e'); // Debug print
    }
  }

  // Helper method to build the metric boxes at the top
  Widget _buildMetricBox(String label, String value, Color accentColor) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build detailed metrics with icons
  Widget _buildDetailedMetric(String label, String value, Color accentColor) {
    return Row(
      children: [
        Icon(
          Icons.info_outline,
          size: 20,
          color: accentColor,
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method to build comparison metrics (male vs female)
  Widget _buildComparisonMetric(String label, String value1, String value2, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.woman,
                size: 20,
                color: accentColor,
              ),
              SizedBox(width: 8),
              Text(
                value1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.man,
                size: 20,
                color: Colors.blue[700],
              ),
              SizedBox(width: 8),
              Text(
                value2,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, TextStyle labelStyle, TextStyle valueStyle) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: labelStyle,
          ),
          Text(
            value,
            style: valueStyle,
          ),
        ],
      ),
    );
  }
}

class RegionClipper extends CustomClipper<Path> {
  final String path;
  static const originalWidth = 2000.0;
  static const originalHeight = 1001.0;

  RegionClipper({super.reclip, required this.path});

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
