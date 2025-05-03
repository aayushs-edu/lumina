import 'dart:convert';
import 'dart:math';// Add this import for file operations
import 'dart:html' as html; // Import the html package
import 'package:flutter/services.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:csv/csv.dart';

enum HotspotLevel {
  extreme, // GII > 0.5
  high, // GII > 0.3
  medium, // GII > 0.2
  low, // GII > 0.1
  none, // No data or GII <= 0.1
}

class GenderInequalityData {
  final int hdiRank;
  final String country;
  final String isoCode;
  final double genderInequalityIndex;
  final double maternalMortality;
  final double adolescentBirthRate;
  final double parliamentSeatsWomen;
  final double educationFemale;
  final double educationMale;
  final double labourForceFemale;
  final double labourForceMale;
  final HotspotLevel hotspotLevel;
  final int storyCount;

  GenderInequalityData({
    required this.hdiRank,
    required this.country,
    required this.isoCode,
    required this.genderInequalityIndex,
    required this.maternalMortality,
    required this.adolescentBirthRate,
    required this.parliamentSeatsWomen,
    required this.educationFemale,
    required this.educationMale,
    required this.labourForceFemale,
    required this.labourForceMale,
    required this.storyCount,
  }) : hotspotLevel = _determineHotspotLevel(genderInequalityIndex, storyCount);

  // Calculate hotspot level using both the GII value and the story count.
  // Here we use a logarithmic factor (base 10) to boost the GII score.
  static HotspotLevel _determineHotspotLevel(double gii, int storyCount) {
    double factor = log(storyCount + 1) / log(10); // calculates base-10 logarithm
    double effectiveScore = gii * (1 + factor * 0.5); // boosts score by up to 50% per log-step
    if (effectiveScore > 0.6) return HotspotLevel.extreme;
    if (effectiveScore > 0.4) return HotspotLevel.high;
    if (effectiveScore > 0.3) return HotspotLevel.medium;
    if (effectiveScore > 0) return HotspotLevel.low;
    return HotspotLevel.none;
  }

  factory GenderInequalityData.fromJson(Map<String, dynamic> json) {
    return GenderInequalityData(
      hdiRank: json['hdiRank'],
      country: json['country'],
      isoCode: json['isoCode'],
      genderInequalityIndex: (json['genderInequalityIndex'] ?? 0).toDouble(),
      maternalMortality: (json['maternalMortality'] ?? 0).toDouble(),
      adolescentBirthRate: (json['adolescentBirthRate'] ?? 0).toDouble(),
      parliamentSeatsWomen: (json['parliamentSeatsWomen'] ?? 0).toDouble(),
      educationFemale: (json['educationFemale'] ?? 0).toDouble(),
      educationMale: (json['educationMale'] ?? 0).toDouble(),
      labourForceFemale: (json['labourForceFemale'] ?? 0).toDouble(),
      labourForceMale: (json['labourForceMale'] ?? 0).toDouble(),
      storyCount: json['storyCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hdiRank': hdiRank,
      'country': country,
      'isoCode': isoCode,
      'genderInequalityIndex': genderInequalityIndex,
      'maternalMortality': maternalMortality,
      'adolescentBirthRate': adolescentBirthRate,
      'parliamentSeatsWomen': parliamentSeatsWomen,
      'educationFemale': educationFemale,
      'educationMale': educationMale,
      'labourForceFemale': labourForceFemale,
      'labourForceMale': labourForceMale,
      'storyCount': storyCount,
    };
  }

  static final Map<String, String> _countryToIso = {
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
    'Viet Nam': 'VN',
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
    'Congo (Democratic Republic of the)': 'CD',
    'Congo': 'CG',
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
    "Côte d'Ivoire": 'CI',
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

  static String getIsoCode(String country) {
    final trimmedCountry = country.trim();
    for (final entry in _countryToIso.entries) {
      if (entry.key.trim() == trimmedCountry) {
        return entry.value;
      }
    }
    return 'UNKNOWN';
  }
}

class GenderInequalityDataManager {
  static final GenderInequalityDataManager _instance =
      GenderInequalityDataManager._internal();
  List<GenderInequalityData> _data = [];

  factory GenderInequalityDataManager() {
    return _instance;
  }

  GenderInequalityDataManager._internal();

  Future<void> loadData() async {
    if (_data.isEmpty) {
      print('Starting to load GII data from JSON...');
      try {
        // Load the JSON file from assets
        final String jsonString = await rootBundle.loadString('assets/data/gii.json');
        final List<dynamic> jsonData = jsonDecode(jsonString);

        // Parse the JSON data into GenderInequalityData objects
        _data = jsonData.map((item) => GenderInequalityData.fromJson(item)).toList();

        print('Successfully loaded ${_data.length} entries from gii.json.');
      } catch (e) {
        print('Error loading GII data from JSON: $e');
      }
    }
  }

  List<GenderInequalityData> get data => _data;

  GenderInequalityData? getDataForCountry(String country) {
    try {
      return _data.firstWhere((data) => data.country == country);
    } catch (e) {
      return null;
    }
  }
}
