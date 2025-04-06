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
  
  // Tooltip state variables
  bool _tooltipVisible = false;
  String? _hoveredCountryId;
  Offset _tooltipPosition = Offset.zero;
  OverlayEntry? _tooltipOverlay;

  // Map of country names to ISO codes
  final Map<String, String> _countryToIso = {
    'United States': 'US',
    'Russian Federation': 'RU',
    'China': 'CN',
    'India': 'IN',
    'Brazil': 'BR',
    'Canada': 'CA',
    'Mexico': 'MX',
    'Argentina': 'AR',
    'United Kingdom': 'GB',
    'France': 'FR',
    'Germany': 'DE',
    'Italy': 'IT',
    'Spain': 'ES',
    'Japan': 'JP',
    'South Korea': 'KR',
    'Australia': 'AU',
    'South Africa': 'ZA',
    'Nigeria': 'NG',
    'Egypt': 'EG',
    'Saudi Arabia': 'SA',
    'Turkey': 'TR',
    'Indonesia': 'ID',
    'Pakistan': 'PK',
    'Bangladesh': 'BD',
    'Vietnam': 'VN',
    'Thailand': 'TH',
    'Philippines': 'PH',
    'Malaysia': 'MY',
    'Singapore': 'SG',
    'New Zealand': 'NZ',
    'Sweden': 'SE',
    'Norway': 'NO',
    'Finland': 'FI',
    'Denmark': 'DK',
    'Netherlands': 'NL',
    'Belgium': 'BE',
    'Switzerland': 'CH',
    'Austria': 'AT',
    'Poland': 'PL',
    'Ukraine': 'UA',
    'Romania': 'RO',
    'Hungary': 'HU',
    'Czech Republic': 'CZ',
    'Greece': 'GR',
    'Portugal': 'PT',
    'Ireland': 'IE',
    'Israel': 'IL',
    'Iran': 'IR',
    'Iraq': 'IQ',
    'Afghanistan': 'AF',
    'Kazakhstan': 'KZ',
    'Uzbekistan': 'UZ',
    'Turkmenistan': 'TM',
    'Azerbaijan': 'AZ',
    'Georgia': 'GE',
    'Armenia': 'AM',
    'Mongolia': 'MN',
    'North Korea': 'KP',
    'Myanmar': 'MM',
    'Laos': 'LA',
    'Cambodia': 'KH',
    'Sri Lanka': 'LK',
    'Nepal': 'NP',
    'Bhutan': 'BT',
    'Maldives': 'MV',
    'Oman': 'OM',
    'Yemen': 'YE',
    'Qatar': 'QA',
    'United Arab Emirates': 'AE',
    'Kuwait': 'KW',
    'Jordan': 'JO',
    'Lebanon': 'LB',
    'Syria': 'SY',
    'Iceland': 'IS',
    'Greenland': 'GL',
    'Cuba': 'CU',
    'Jamaica': 'JM',
    'Haiti': 'HT',
    'Dominican Republic': 'DO',
    'Puerto Rico': 'PR',
    'Colombia': 'CO',
    'Venezuela': 'VE',
    'Peru': 'PE',
    'Ecuador': 'EC',
    'Chile': 'CL',
    'Bolivia': 'BO',
    'Paraguay': 'PY',
    'Uruguay': 'UY',
    'Guyana': 'GY',
    'Suriname': 'SR',
    'Costa Rica': 'CR',
    'Panama': 'PA',
    'Nicaragua': 'NI',
    'Honduras': 'HN',
    'El Salvador': 'SV',
    'Guatemala': 'GT',
    'Belize': 'BZ',
    'Morocco': 'MA',
    'Algeria': 'DZ',
    'Tunisia': 'TN',
    'Libya': 'LY',
    'Sudan': 'SD',
    'South Sudan': 'SS',
    'Ethiopia': 'ET',
    'Somalia': 'SO',
    'Kenya': 'KE',
    'Tanzania': 'TZ',
    'Uganda': 'UG',
    'Rwanda': 'RW',
    'Burundi': 'BI',
    'Democratic Republic of the Congo': 'CD',
    'Republic of the Congo': 'CG',
    'Gabon': 'GA',
    'Equatorial Guinea': 'GQ',
    'Cameroon': 'CM',
    'Central African Republic': 'CF',
    'Chad': 'TD',
    'Niger': 'NE',
    'Mali': 'ML',
    'Mauritania': 'MR',
    'Senegal': 'SN',
    'Gambia': 'GM',
    'Guinea-Bissau': 'GW',
    'Guinea': 'GN',
    'Sierra Leone': 'SL',
    'Liberia': 'LR',
    'Côte d\'Ivoire': 'CI',
    'Ghana': 'GH',
    'Togo': 'TG',
    'Benin': 'BJ',
    'Burkina Faso': 'BF',
    'Zambia': 'ZM',
    'Zimbabwe': 'ZW',
    'Malawi': 'MW',
    'Mozambique': 'MZ',
    'Madagascar': 'MG',
    'Namibia': 'NA',
    'Botswana': 'BW',
    'Angola': 'AO',
    'Eswatini': 'SZ',
    'Lesotho': 'LS',
    'Mauritius': 'MU',
    'Comoros': 'KM',
    'Seychelles': 'SC',
    'Papua New Guinea': 'PG',
    'Fiji': 'FJ',
    'Solomon Islands': 'SB',
    'Vanuatu': 'VU',
    'Samoa': 'WS',
    'Tonga': 'TO',
    'Kiribati': 'KI',
    'Tuvalu': 'TV',
    'Nauru': 'NR',
    'Marshall Islands': 'MH',
    'Palau': 'PW',
    'Micronesia': 'FM',
    'Timor-Leste': 'TL',
    'Brunei': 'BN',
    'Taiwan': 'TW',
    'Hong Kong': 'HK',
    'Macau': 'MO',
    'Cyprus': 'CY',
    'Malta': 'MT',
    'Luxembourg': 'LU',
    'Liechtenstein': 'LI',
    'Monaco': 'MC',
    'San Marino': 'SM',
    'Vatican City': 'VA',
    'Andorra': 'AD',
    'Albania': 'AL',
    'North Macedonia': 'MK',
    'Montenegro': 'ME',
    'Bosnia and Herzegovina': 'BA',
    'Serbia': 'RS',
    'Croatia': 'HR',
    'Slovenia': 'SI',
    'Slovakia': 'SK',
    'Lithuania': 'LT',
    'Latvia': 'LV',
    'Estonia': 'EE',
    'Belarus': 'BY',
    'Moldova': 'MD',
    'Kyrgyzstan': 'KG',
    'Tajikistan': 'TJ',
    'East Timor': 'TL',
    'Guam': 'GU',
    'Northern Mariana Islands': 'MP',
    'American Samoa': 'AS',
    'Cook Islands': 'CK',
    'Niue': 'NU',
    'Tokelau': 'TK',
    'Wallis and Futuna': 'WF',
    'French Polynesia': 'PF',
    'New Caledonia': 'NC',
    'Pitcairn Islands': 'PN',
    'Easter Island': 'CL',
    'Galápagos Islands': 'EC',
    'Falkland Islands': 'FK',
    'South Georgia and the South Sandwich Islands': 'GS',
    'Bouvet Island': 'BV',
    'Heard Island and McDonald Islands': 'HM',
    'French Southern and Antarctic Lands': 'TF',
    'Antarctica': 'AQ',
    'Svalbard and Jan Mayen': 'SJ',
  };

  // Map of hotspot countries with their severity levels and story counts
  final Map<String, Map<String, dynamic>> _hotspotCountries = {
    'US': {'severity': 'High', 'stories': 42},
    'RU': {'severity': 'High', 'stories': 38},
    'CN': {'severity': 'Medium', 'stories': 25},
    'IN': {'severity': 'Medium', 'stories': 31},
    'BR': {'severity': 'Medium', 'stories': 19},
    'ZA': {'severity': 'Medium', 'stories': 15}, // South Africa
    'NG': {'severity': 'High', 'stories': 20}, // Nigeria
    'FR': {'severity': 'Medium', 'stories': 10}, // France
    'DE': {'severity': 'Medium', 'stories': 12}, // Germany
    'JP': {'severity': 'Low', 'stories': 5}, // Japan
    'MX': {'severity': 'Medium', 'stories': 8}, // Mexico
    // Add more countries as needed
  };

  // Map severity levels to colors
  final Map<String, Color> _severityColors = {
    'High': const Color.fromARGB(255, 255, 20, 20),
    'Medium': const Color.fromARGB(255, 255, 102, 0),
    'Low': const Color.fromARGB(255, 200, 200, 0),
  };

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

      // Color hotspot countries with severity colors, others light gray
      final color =
          _hotspotCountries.containsKey(isoCode)
              ? _severityColors[_hotspotCountries[isoCode]!['severity']] ??
                  Colors.grey[200]!
              : Colors.grey[200]!;

      regions.add(Region(id: isoCode, path: partPath, color: color));
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
            fontSize: 40,
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
                height: 500,
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
      _HotspotItem(
        country: "South Africa",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      _HotspotItem(
        country: "Nigeria",
        level: "High",
        color: const Color.fromARGB(255, 255, 20, 20),
      ),
      _HotspotItem(
        country: "France",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      _HotspotItem(
        country: "Germany",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      _HotspotItem(
        country: "Japan",
        level: "Low",
        color: const Color.fromARGB(255, 200, 200, 0),
      ),
      _HotspotItem(
        country: "Mexico",
        level: "Medium",
        color: const Color.fromARGB(255, 255, 102, 0),
      ),
      // Add more countries as needed
    ];
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