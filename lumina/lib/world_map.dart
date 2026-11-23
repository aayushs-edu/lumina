import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/waving_leaf.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:xml/xml.dart';
import 'package:lumina/models/gender_inequality_data.dart';
import 'package:lumina/widgets/theme_tag.dart';

class InteractiveWorldMap extends StatefulWidget {
  const InteractiveWorldMap({super.key, this.header});

  /// Optional heading shown beside the legend, above the map.
  final Widget? header;

  @override
  _InteractiveWorldMapState createState() => _InteractiveWorldMapState();
}

class Region {
  final String id;
  final String path;
  final Color color;

  /// The SVG path parsed once, in the SVG's own coordinate space.
  final Path parsedPath;

  /// Bounds of [parsedPath], used as a cheap prefilter for hit-testing.
  final Rect bounds;

  Region._(this.id, this.path, this.color, this.parsedPath)
    : bounds = parsedPath.getBounds();

  factory Region({
    required String id,
    required String path,
    required Color color,
  }) => Region._(id, path, color, parseSvgPathData(path));

  /// Union of every region's bounds: the map's actual extent, so it can be
  /// scaled to fill its frame rather than the SVG's padded canvas.
  /// Tiny outlying islands are left out so they don't letterbox the land;
  /// the frame clips anything that lands past its edge.
  static Rect contentBounds(List<Region> regions) {
    if (regions.isEmpty) return Rect.zero;
    var full = regions.first.bounds;
    for (final region in regions.skip(1)) {
      full = full.expandToInclude(region.bounds);
    }
    final minArea = full.width * full.height * 0.0003;
    Rect? land;
    for (final region in regions) {
      final b = region.bounds;
      if (b.width * b.height < minArea) continue;
      land = land == null ? b : land.expandToInclude(b);
    }
    return land ?? full;
  }
}

class _InteractiveWorldMapState extends State<InteractiveWorldMap> {
  List<Region> _regions = [];
  final Random random = Random();

  // Tooltip state
  OverlayEntry? _tooltipOverlay;

  // Region currently under the mouse (null when over sea / outside the map).
  // Drives the hover highlight and cursor without rebuilding the map.
  final ValueNotifier<String?> _hoveredRegionId = ValueNotifier<String?>(null);

  // Extent of all country paths, and the size the map was last laid out at;
  // together they map pointer positions back into SVG coordinates.
  Rect _mapBounds = Rect.zero;
  Size _mapLayoutSize = Size.zero;

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
    HotspotLevel.low: const Color.fromARGB(255, 250, 225, 5), // Yellow
    HotspotLevel.none: Colors.grey[200]!, // Light gray
  };

  @override
  void initState() {
    super.initState();
    // Load GII data and then initialize _countryToIso and regions.
    GenderInequalityDataManager().loadData().then((_) {
      // Initialize _countryToIso after data is loaded
      setState(() {
        _initializeCountryToIso();
      });

      loadRegions().then((regionsData) {
        setState(() {
          _regions = regionsData;
          _mapBounds = Region.contentBounds(regionsData);
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
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                constraints: const BoxConstraints(maxWidth: 240),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _rule),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2A1A16),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.baloo2(fontSize: 13, color: _soft),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: GoogleFonts.baloo2(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'GII Score: ${giiData.genderInequalityIndex.toStringAsFixed(3)}',
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _swatch(giiData.hotspotLevel, 9),
                          const SizedBox(width: 6),
                          Text(
                            'Level: ${_getLevelName(giiData.hotspotLevel)}',
                            style: GoogleFonts.baloo2(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<List<MapEntry<String, int>>>(
                        future: _themesFor(countryName),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text("Loading themes...");
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("No themes available.");
                          }
                          final themes = snapshot.data!;
                          return Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children:
                                themes.take(2).map((entry) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ThemeTag(theme: entry.key, square: true),
                                      const SizedBox(width: 4),
                                      Text("(${entry.value})"),
                                    ],
                                  );
                                }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );

    // Insert the overlay
    Overlay.of(context).insert(_tooltipOverlay!);
  }

  // Hide tooltip
  void _hideTooltip() {
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
    }
  }

  // One Firestore query per country per session, shared by the hover tooltip
  // and the details dialog, instead of a new query on every hover.
  static final Map<String, Future<List<MapEntry<String, int>>>> _themesCache =
      {};

  Future<List<MapEntry<String, int>>> _themesFor(String country) {
    return _themesCache.putIfAbsent(country, () {
      final future = FirebaseService.getPrevalentThemesForCountry(country);
      // Let a failed lookup be retried on the next hover.
      future.catchError((Object _) {
        _themesCache.remove(country);
        return <MapEntry<String, int>>[];
      });
      return future;
    });
  }

  /// Topmost region containing [localPosition] (in the map's layout box).
  /// Later regions paint on top, so search back to front.
  Region? _regionAt(Offset localPosition) {
    if (_mapBounds.isEmpty || _mapLayoutSize.isEmpty) return null;
    final scale = _mapLayoutSize.width / _mapBounds.width;
    final svgPoint = localPosition / scale + _mapBounds.topLeft;
    for (var i = _regions.length - 1; i >= 0; i--) {
      final region = _regions[i];
      if (region.bounds.contains(svgPoint) &&
          region.parsedPath.contains(svgPoint)) {
        return region;
      }
    }
    return null;
  }

  void _handleHover(PointerEvent event) {
    final regionId = _regionAt(event.localPosition)?.id;
    if (regionId == _hoveredRegionId.value) return;
    _hoveredRegionId.value = regionId;
    if (regionId == null) {
      _hideTooltip();
    } else {
      _showTooltip(context, event.position, regionId);
    }
  }

  void _handleExit(PointerExitEvent event) {
    _hoveredRegionId.value = null;
    _hideTooltip();
  }

  Widget _buildMap() {
    final map = AspectRatio(
      aspectRatio: _mapBounds.width / _mapBounds.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _mapLayoutSize = constraints.biggest;
          return Stack(
            fit: StackFit.expand,
            children: [
              // All country fills in one picture; only repaints if regions
              // change.
              RepaintBoundary(
                child: CustomPaint(
                  painter: _WorldMapPainter(_regions, _mapBounds),
                  isComplex: true,
                ),
              ),
              // Hover highlight in its own layer so hovering never repaints
              // the map.
              RepaintBoundary(
                child: CustomPaint(
                  painter: _HoveredRegionPainter(
                    regions: _regions,
                    bounds: _mapBounds,
                    hoveredId: _hoveredRegionId,
                    color: const Color(0x142A1A16),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return ValueListenableBuilder<String?>(
      valueListenable: _hoveredRegionId,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) {
          final region = _regionAt(details.localPosition);
          if (region != null) _showCountryDetails(region.id);
        },
        child: map,
      ),
      builder:
          (context, hoveredId, child) => MouseRegion(
            cursor:
                hoveredId != null
                    ? SystemMouseCursors.click
                    : MouseCursor.defer,
            onEnter: _handleHover,
            onHover: _handleHover,
            onExit: _handleExit,
            child: child,
          ),
    );
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

  @override
  void dispose() {
    _hideTooltip();
    _hoveredRegionId.dispose();
    super.dispose();
  }

  Future<List<Region>> loadRegions() async {
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

      // If still no match, try matching by country name directly.
      if (giiData == null) {
        for (var data in giiCountryMap.values) {
          if (data.country.toLowerCase() == isoCode.toLowerCase()) {
            giiData = data;
            break;
          }
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

    return regions;
  }

  static const _ink = Color(0xFF2A1A16);
  static const _soft = Color(0xFF5B4740);
  static const _rule = Color(0xFFEADBD2);

  Widget _swatch(HotspotLevel level, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _hotspotColors[level],
        border:
            level == HotspotLevel.none ? Border.all(color: _rule) : null,
      ),
    );
  }

  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Hotspots',
          style: GoogleFonts.baloo2(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _ink,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 20,
          runSpacing: 6,
          children: [
            for (final level in HotspotLevel.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _swatch(level, 12),
                  const SizedBox(width: 8),
                  Text(
                    _getLevelName(level),
                    style: GoogleFonts.baloo2(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _soft,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 900;
        final header = widget.header;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (header != null) Expanded(child: header) else const Spacer(),
                  const SizedBox(width: 32),
                  _buildLegend(),
                ],
              )
            else ...[
              if (header != null) header,
              const SizedBox(height: 20),
              _buildLegend(),
            ],
            const SizedBox(height: 28),
            Container(
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCFA),
                border: Border.all(color: _rule),
              ),
              padding: EdgeInsets.all(wide ? 32 : 8),
              child:
                  _regions.isEmpty
                      ? SizedBox(
                        height: wide ? 480 : 180,
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF6600),
                            ),
                          ),
                        ),
                      )
                      : _buildMap(),
            ),
            const SizedBox(height: 12),
            Text(
              "Click on a country to see valuable data!",
              style: GoogleFonts.baloo2(fontSize: 15, color: _soft),
            ),
          ],
        );
      },
    );
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

  void _showCountryDetails(String countryId) {
    final countryName = _getCountryNameFromIso(countryId);
    if (countryName == null) return;

    final giiData = GenderInequalityDataManager().getDataForCountry(countryName);
    if (giiData == null) return;

    // Get the hotspot color for this country
    final Color hotspotColor = _hotspotColors[giiData.hotspotLevel] ?? Colors.grey[200]!;

    try {
      showDialog(
        context: context,
        builder: (context) => DefaultTextStyle.merge(
          style: GoogleFonts.baloo2(),
          child: Dialog(
          shape: const RoundedRectangleBorder(),
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          child: Container(
            width: 500,
            padding: EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                          color: _ink,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: _soft),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Hotspot level indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: _rule),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _swatch(giiData.hotspotLevel, 10),
                        const SizedBox(width: 8),
                        Text(
                          _getLevelName(giiData.hotspotLevel),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Main metrics in a row
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildMetricBox(
                        "GII Score",
                        giiData.genderInequalityIndex.toStringAsFixed(3),
                        hotspotColor,
                      ),
                      _buildMetricBox(
                        "Rank",
                        "${giiData.hdiRank}/${GenderInequalityDataManager().data.length}",
                        hotspotColor,
                      ),
                      _buildMetricBox(
                        "Stories",
                        "${giiData.storyCount}",
                        hotspotColor,
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Divider(color: _rule, thickness: 1),
                  SizedBox(height: 24),
                  // Gender Inequality Metrics section
                  Text(
                    "Gender Inequality Metrics",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 16),
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
                              "${giiData.maternalMortality/1000}%",
                              hotspotColor,
                            ),
                            SizedBox(height: 16),
                            _buildDetailedMetric(
                              "Adolescent Birth Rate",
                                "${(giiData.adolescentBirthRate/10).toStringAsFixed(2)}%",
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
                            _buildComparisonMetric(
                              "Secondary Education",
                              "Female: ${giiData.educationFemale}%",
                              "Male: ${giiData.educationMale}%",
                              hotspotColor,
                            ),
                            SizedBox(height: 16),
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
                  // New section: Most Prevalent Themes
                  Text(
                    "Most Prevalent Themes",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _ink,
                    ),
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<List<MapEntry<String, int>>>(
                    future: _themesFor(countryName),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Text(
                          "No themes available.",
                          style: TextStyle(fontSize: 14, color: _soft),
                        );
                      }
                      final themes = snapshot.data!;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: themes.take(3).map((entry) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ThemeTag(theme: entry.key, square: true),
                              SizedBox(width: 4),
                              Text(
                                "(${entry.value})",
                                style: TextStyle(fontSize: 12, color: _soft),
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        ),
      );
    } catch (e) {
    }
  }

  // Helper method to build the metric boxes at the top
  Widget _buildMetricBox(String label, String value, Color accentColor) {
    return Container(
      width: 140,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _rule, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _soft,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _ink,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Helper method to build detailed metrics with icons
  Widget _buildDetailedMetric(String label, String value, Color accentColor) {
    // Define tooltip messages for each metric type.
    String tooltipMessage;
    switch (label) {
      case "Maternal Mortality":
        tooltipMessage = "Percentage of maternal deaths per 100,000 live births.";
        break;
      case "Adolescent Birth Rate":
        tooltipMessage = "Percentage of births from women ages 15-19.";
        break;
      case "Parliament Seats (Women)":
        tooltipMessage = "Percentage of seats held by women in parliament.";
        break;
      default:
        tooltipMessage = "";
    }
    return Row(
      children: [
        Tooltip(
          message: tooltipMessage,
          child: Icon(
            Icons.info_outline,
            size: 20,
            color: _soft,
          ),
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
                  color: _soft,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _ink,
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
        color: const Color(0xFFFFFCFA),
        border: Border.all(color: _rule, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _soft,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.woman,
                size: 20,
                color: _soft,
              ),
              SizedBox(width: 8),
              Text(
                value1,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _ink,
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
                color: _soft,
              ),
              SizedBox(width: 8),
              Text(
                value2,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _ink,
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

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter(this.regions, this.bounds);

  final List<Region> regions;
  final Rect bounds;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / bounds.width;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(-bounds.left, -bounds.top);
    final paint = Paint()..style = PaintingStyle.fill;
    for (final region in regions) {
      paint.color = region.color;
      canvas.drawPath(region.parsedPath, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_WorldMapPainter oldDelegate) =>
      !identical(oldDelegate.regions, regions) || oldDelegate.bounds != bounds;
}

/// Tints every path of the hovered country, like the old per-country InkWell
/// hover highlight. Repaints itself when [hoveredId] changes.
class _HoveredRegionPainter extends CustomPainter {
  _HoveredRegionPainter({
    required this.regions,
    required this.bounds,
    required this.hoveredId,
    required this.color,
  }) : super(repaint: hoveredId);

  final List<Region> regions;
  final Rect bounds;
  final ValueListenable<String?> hoveredId;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final id = hoveredId.value;
    if (id == null) return;
    final scale = size.width / bounds.width;
    canvas.save();
    canvas.scale(scale, scale);
    canvas.translate(-bounds.left, -bounds.top);
    final paint = Paint()..color = color;
    for (final region in regions) {
      if (region.id == id) canvas.drawPath(region.parsedPath, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HoveredRegionPainter oldDelegate) =>
      !identical(oldDelegate.regions, regions) ||
      oldDelegate.bounds != bounds ||
      oldDelegate.hoveredId != hoveredId ||
      oldDelegate.color != color;
}
