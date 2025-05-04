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
        // Stored JSON data object
        final List<Map<String, dynamic>> jsonData = [{"hdiRank":3,"country":"Switzerland","isoCode":"CH","genderInequalityIndex":0.018,"maternalMortality":7,"adolescentBirthRate":2.2,"parliamentSeatsWomen":39,"educationFemale":96.9,"educationMale":97.5,"labourForceFemale":61.5,"labourForceMale":71.9,"storyCount":0},{"hdiRank":2,"country":"Norway","isoCode":"NO","genderInequalityIndex":0.012,"maternalMortality":2,"adolescentBirthRate":2.2,"parliamentSeatsWomen":45,"educationFemale":99.1,"educationMale":99.3,"labourForceFemale":62.5,"labourForceMale":69.6,"storyCount":0},{"hdiRank":9,"country":"Iceland","isoCode":"IS","genderInequalityIndex":0.039,"maternalMortality":3,"adolescentBirthRate":5.1,"parliamentSeatsWomen":47.6,"educationFemale":99.8,"educationMale":99.7,"labourForceFemale":70.7,"labourForceMale":78.3,"storyCount":5},{"hdiRank":0,"country":"Hong Kong, China (SAR)","isoCode":"UNKNOWN","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":1.6,"parliamentSeatsWomen":0,"educationFemale":77.9,"educationMale":84.1,"labourForceFemale":52.9,"labourForceMale":64.7,"storyCount":0},{"hdiRank":1,"country":"Denmark","isoCode":"DK","genderInequalityIndex":0.009,"maternalMortality":5,"adolescentBirthRate":1.8,"parliamentSeatsWomen":43.6,"educationFemale":95.1,"educationMale":95.2,"labourForceFemale":59.4,"labourForceMale":67.4,"storyCount":2},{"hdiRank":4,"country":"Sweden","isoCode":"SE","genderInequalityIndex":0.023,"maternalMortality":5,"adolescentBirthRate":3.3,"parliamentSeatsWomen":46.4,"educationFemale":92.4,"educationMale":92.7,"labourForceFemale":63.7,"labourForceMale":70.4,"storyCount":4},{"hdiRank":19,"country":"Germany","isoCode":"DE","genderInequalityIndex":0.071,"maternalMortality":4,"adolescentBirthRate":7.2,"parliamentSeatsWomen":34.8,"educationFemale":95.4,"educationMale":95.9,"labourForceFemale":56.1,"labourForceMale":66.6,"storyCount":3},{"hdiRank":20,"country":"Ireland","isoCode":"IE","genderInequalityIndex":0.072,"maternalMortality":5,"adolescentBirthRate":5.9,"parliamentSeatsWomen":27.4,"educationFemale":88.6,"educationMale":86.4,"labourForceFemale":59.4,"labourForceMale":70.5,"storyCount":4},{"hdiRank":8,"country":"Singapore","isoCode":"SG","genderInequalityIndex":0.036,"maternalMortality":7,"adolescentBirthRate":2.5,"parliamentSeatsWomen":29.1,"educationFemale":80.5,"educationMale":85.9,"labourForceFemale":63.4,"labourForceMale":77,"storyCount":0},{"hdiRank":17,"country":"Australia","isoCode":"AU","genderInequalityIndex":0.063,"maternalMortality":3,"adolescentBirthRate":7.7,"parliamentSeatsWomen":44.5,"educationFemale":94.6,"educationMale":94.4,"labourForceFemale":62.3,"labourForceMale":71.1,"storyCount":0},{"hdiRank":5,"country":"Netherlands","isoCode":"NL","genderInequalityIndex":0.025,"maternalMortality":4,"adolescentBirthRate":2.7,"parliamentSeatsWomen":37.8,"educationFemale":89.8,"educationMale":92.7,"labourForceFemale":63.6,"labourForceMale":72.4,"storyCount":0},{"hdiRank":11,"country":"Belgium","isoCode":"BE","genderInequalityIndex":0.044,"maternalMortality":5,"adolescentBirthRate":5.1,"parliamentSeatsWomen":44.3,"educationFemale":88.7,"educationMale":90.7,"labourForceFemale":50.8,"labourForceMale":59.5,"storyCount":9},{"hdiRank":6,"country":"Finland","isoCode":"FI","genderInequalityIndex":0.032,"maternalMortality":8,"adolescentBirthRate":4.1,"parliamentSeatsWomen":45.5,"educationFemale":99.2,"educationMale":98.9,"labourForceFemale":58.2,"labourForceMale":64.2,"storyCount":1},{"hdiRank":28,"country":"United Kingdom","isoCode":"GB","genderInequalityIndex":0.094,"maternalMortality":10,"adolescentBirthRate":10,"parliamentSeatsWomen":31.3,"educationFemale":99.8,"educationMale":99.8,"labourForceFemale":59.1,"labourForceMale":68,"storyCount":8},{"hdiRank":23,"country":"New Zealand","isoCode":"NZ","genderInequalityIndex":0.082,"maternalMortality":7,"adolescentBirthRate":11.8,"parliamentSeatsWomen":50.4,"educationFemale":82,"educationMale":81.8,"labourForceFemale":66.9,"labourForceMale":75.9,"storyCount":0},{"hdiRank":7,"country":"United Arab Emirates","isoCode":"AE","genderInequalityIndex":0.035,"maternalMortality":9,"adolescentBirthRate":2.8,"parliamentSeatsWomen":50,"educationFemale":82,"educationMale":86.1,"labourForceFemale":55.3,"labourForceMale":89.5,"storyCount":0},{"hdiRank":18,"country":"Canada","isoCode":"CA","genderInequalityIndex":0.069,"maternalMortality":11,"adolescentBirthRate":6.6,"parliamentSeatsWomen":35,"educationFemale":97.8,"educationMale":97.6,"labourForceFemale":61.5,"labourForceMale":69.5,"storyCount":1},{"hdiRank":16,"country":"South Korea","isoCode":"KR","genderInequalityIndex":0.062,"maternalMortality":8,"adolescentBirthRate":2.1,"parliamentSeatsWomen":18.6,"educationFemale":83.8,"educationMale":93.5,"labourForceFemale":55,"labourForceMale":73.7,"storyCount":1},{"hdiRank":10,"country":"Luxembourg","isoCode":"LU","genderInequalityIndex":0.043,"maternalMortality":6,"adolescentBirthRate":4.2,"parliamentSeatsWomen":33.3,"educationFemale":96.6,"educationMale":89.3,"labourForceFemale":58,"labourForceMale":65.1,"storyCount":1},{"hdiRank":44,"country":"United States","isoCode":"US","genderInequalityIndex":0.18,"maternalMortality":21,"adolescentBirthRate":15.1,"parliamentSeatsWomen":28.1,"educationFemale":95.4,"educationMale":95.1,"labourForceFemale":56.8,"labourForceMale":68,"storyCount":213},{"hdiRank":12,"country":"Austria","isoCode":"AT","genderInequalityIndex":0.048,"maternalMortality":5,"adolescentBirthRate":5.2,"parliamentSeatsWomen":41,"educationFemale":100,"educationMale":100,"labourForceFemale":56.6,"labourForceMale":66.7,"storyCount":1},{"hdiRank":13,"country":"Slovenia","isoCode":"SI","genderInequalityIndex":0.049,"maternalMortality":5,"adolescentBirthRate":4.4,"parliamentSeatsWomen":33.1,"educationFemale":97.8,"educationMale":98.8,"labourForceFemale":54.3,"labourForceMale":63.6,"storyCount":0},{"hdiRank":22,"country":"Japan","isoCode":"JP","genderInequalityIndex":0.078,"maternalMortality":4,"adolescentBirthRate":2.8,"parliamentSeatsWomen":15.4,"educationFemale":98.2,"educationMale":99.1,"labourForceFemale":54.2,"labourForceMale":71.4,"storyCount":2},{"hdiRank":26,"country":"Israel","isoCode":"IL","genderInequalityIndex":0.092,"maternalMortality":3,"adolescentBirthRate":7.4,"parliamentSeatsWomen":23.3,"educationFemale":92.5,"educationMale":94.5,"labourForceFemale":61.2,"labourForceMale":68.5,"storyCount":0},{"hdiRank":35,"country":"Malta","isoCode":"MT","genderInequalityIndex":0.117,"maternalMortality":3,"adolescentBirthRate":11.5,"parliamentSeatsWomen":27.8,"educationFemale":82.2,"educationMale":88.1,"labourForceFemale":56.1,"labourForceMale":71.2,"storyCount":0},{"hdiRank":15,"country":"Spain","isoCode":"ES","genderInequalityIndex":0.059,"maternalMortality":3,"adolescentBirthRate":6.3,"parliamentSeatsWomen":41.4,"educationFemale":78.5,"educationMale":83.2,"labourForceFemale":53.2,"labourForceMale":62.9,"storyCount":2},{"hdiRank":24,"country":"France","isoCode":"FR","genderInequalityIndex":0.084,"maternalMortality":8,"adolescentBirthRate":9.4,"parliamentSeatsWomen":36.4,"educationFemale":84.3,"educationMale":88.3,"labourForceFemale":52.5,"labourForceMale":60.2,"storyCount":0},{"hdiRank":62,"country":"Cyprus","isoCode":"CY","genderInequalityIndex":0.253,"maternalMortality":68,"adolescentBirthRate":6.8,"parliamentSeatsWomen":14.3,"educationFemale":81.1,"educationMale":84.8,"labourForceFemale":59.6,"labourForceMale":71.1,"storyCount":3},{"hdiRank":14,"country":"Italy","isoCode":"IT","genderInequalityIndex":0.057,"maternalMortality":5,"adolescentBirthRate":3.9,"parliamentSeatsWomen":33,"educationFemale":78.6,"educationMale":86.1,"labourForceFemale":40.7,"labourForceMale":58.1,"storyCount":2},{"hdiRank":27,"country":"Estonia","isoCode":"EE","genderInequalityIndex":0.093,"maternalMortality":5,"adolescentBirthRate":8.1,"parliamentSeatsWomen":25.7,"educationFemale":97.6,"educationMale":98.1,"labourForceFemale":60.6,"labourForceMale":71.4,"storyCount":0},{"hdiRank":32,"country":"Czechia","isoCode":"UNKNOWN","genderInequalityIndex":0.113,"maternalMortality":3,"adolescentBirthRate":9.4,"parliamentSeatsWomen":23.5,"educationFemale":99.8,"educationMale":99.8,"labourForceFemale":52.2,"labourForceMale":67.9,"storyCount":0},{"hdiRank":37,"country":"Greece","isoCode":"GR","genderInequalityIndex":0.12,"maternalMortality":8,"adolescentBirthRate":8.3,"parliamentSeatsWomen":21,"educationFemale":69.9,"educationMale":77.8,"labourForceFemale":44.7,"labourForceMale":60.4,"storyCount":2},{"hdiRank":45,"country":"Bahrain","isoCode":"UNKNOWN","genderInequalityIndex":0.181,"maternalMortality":16,"adolescentBirthRate":8.7,"parliamentSeatsWomen":22.5,"educationFemale":79.9,"educationMale":83.1,"labourForceFemale":42.4,"labourForceMale":85.8,"storyCount":0},{"hdiRank":0,"country":"Andorra","isoCode":"AD","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":5.9,"parliamentSeatsWomen":46.4,"educationFemale":81.7,"educationMale":84.6,"labourForceFemale":0,"labourForceMale":0,"storyCount":0},{"hdiRank":31,"country":"Poland","isoCode":"PL","genderInequalityIndex":0.105,"maternalMortality":2,"adolescentBirthRate":9.2,"parliamentSeatsWomen":27.5,"educationFemale":86.5,"educationMale":90.7,"labourForceFemale":50.1,"labourForceMale":65.5,"storyCount":2},{"hdiRank":39,"country":"Latvia","isoCode":"LV","genderInequalityIndex":0.142,"maternalMortality":18,"adolescentBirthRate":10.5,"parliamentSeatsWomen":30,"educationFemale":99.8,"educationMale":99.3,"labourForceFemale":55.6,"labourForceMale":67.9,"storyCount":4},{"hdiRank":30,"country":"Lithuania","isoCode":"LT","genderInequalityIndex":0.098,"maternalMortality":9,"adolescentBirthRate":9.7,"parliamentSeatsWomen":28.4,"educationFemale":95.5,"educationMale":97.9,"labourForceFemale":58.8,"labourForceMale":67.7,"storyCount":0},{"hdiRank":25,"country":"Croatia","isoCode":"HR","genderInequalityIndex":0.087,"maternalMortality":5,"adolescentBirthRate":8.2,"parliamentSeatsWomen":31.8,"educationFemale":95.5,"educationMale":97.4,"labourForceFemale":46.9,"labourForceMale":58.2,"storyCount":0},{"hdiRank":54,"country":"Qatar","isoCode":"QA","genderInequalityIndex":0.212,"maternalMortality":8,"adolescentBirthRate":6.9,"parliamentSeatsWomen":4.4,"educationFemale":81.8,"educationMale":71.4,"labourForceFemale":61.7,"labourForceMale":95.3,"storyCount":0},{"hdiRank":55,"country":"Saudi Arabia","isoCode":"SA","genderInequalityIndex":0.229,"maternalMortality":16,"adolescentBirthRate":11.6,"parliamentSeatsWomen":19.9,"educationFemale":71.3,"educationMale":80.9,"labourForceFemale":34.5,"labourForceMale":79.6,"storyCount":2},{"hdiRank":21,"country":"Portugal","isoCode":"PT","genderInequalityIndex":0.076,"maternalMortality":12,"adolescentBirthRate":7.1,"parliamentSeatsWomen":37,"educationFemale":59.7,"educationMale":61.9,"labourForceFemale":54.7,"labourForceMale":63.1,"storyCount":0},{"hdiRank":0,"country":"San Marino","isoCode":"SM","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":3.7,"parliamentSeatsWomen":33.3,"educationFemale":81.8,"educationMale":84.3,"labourForceFemale":70.4,"labourForceMale":70.6,"storyCount":0},{"hdiRank":49,"country":"Chile","isoCode":"CL","genderInequalityIndex":0.19,"maternalMortality":15,"adolescentBirthRate":22.8,"parliamentSeatsWomen":32.7,"educationFemale":82.2,"educationMale":84.4,"labourForceFemale":50.1,"labourForceMale":70.6,"storyCount":0},{"hdiRank":46,"country":"Slovakia","isoCode":"SK","genderInequalityIndex":0.184,"maternalMortality":5,"adolescentBirthRate":26.6,"parliamentSeatsWomen":21.3,"educationFemale":98.8,"educationMale":99.1,"labourForceFemale":56.2,"labourForceMale":67.3,"storyCount":0},{"hdiRank":63,"country":"Turkey","isoCode":"TR","genderInequalityIndex":0.259,"maternalMortality":17,"adolescentBirthRate":15.7,"parliamentSeatsWomen":17.4,"educationFemale":59.1,"educationMale":78.1,"labourForceFemale":35.1,"labourForceMale":71.4,"storyCount":1},{"hdiRank":56,"country":"Hungary","isoCode":"HU","genderInequalityIndex":0.23,"maternalMortality":15,"adolescentBirthRate":21.9,"parliamentSeatsWomen":14.1,"educationFemale":97.6,"educationMale":98.8,"labourForceFemale":53.7,"labourForceMale":67.8,"storyCount":1},{"hdiRank":71,"country":"Argentina","isoCode":"AR","genderInequalityIndex":0.292,"maternalMortality":45,"adolescentBirthRate":37.9,"parliamentSeatsWomen":44.4,"educationFemale":73.6,"educationMale":71.6,"labourForceFemale":52.1,"labourForceMale":71.7,"storyCount":0},{"hdiRank":51,"country":"Kuwait","isoCode":"KW","genderInequalityIndex":0.199,"maternalMortality":7,"adolescentBirthRate":5.3,"parliamentSeatsWomen":6.3,"educationFemale":61.8,"educationMale":56.5,"labourForceFemale":44.4,"labourForceMale":88.5,"storyCount":0},{"hdiRank":33,"country":"Montenegro","isoCode":"ME","genderInequalityIndex":0.114,"maternalMortality":6,"adolescentBirthRate":9.7,"parliamentSeatsWomen":27.2,"educationFemale":70.8,"educationMale":83.7,"labourForceFemale":44.4,"labourForceMale":57.8,"storyCount":0},{"hdiRank":0,"country":"Saint Kitts and Nevis","isoCode":"UNKNOWN","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":36.8,"parliamentSeatsWomen":31.3,"educationFemale":0,"educationMale":0,"labourForceFemale":0,"labourForceMale":0,"storyCount":0},{"hdiRank":60,"country":"Uruguay","isoCode":"UY","genderInequalityIndex":0.24,"maternalMortality":19,"adolescentBirthRate":35.2,"parliamentSeatsWomen":26.9,"educationFemale":62.5,"educationMale":59.3,"labourForceFemale":55.7,"labourForceMale":71.4,"storyCount":0},{"hdiRank":56,"country":"Romania","isoCode":"RO","genderInequalityIndex":0.23,"maternalMortality":10,"adolescentBirthRate":35.4,"parliamentSeatsWomen":18.9,"educationFemale":89.4,"educationMale":94,"labourForceFemale":42.3,"labourForceMale":62,"storyCount":0},{"hdiRank":68,"country":"Brunei Darussalam","isoCode":"UNKNOWN","genderInequalityIndex":0.279,"maternalMortality":44,"adolescentBirthRate":9.5,"parliamentSeatsWomen":9.1,"educationFemale":70.9,"educationMale":71.5,"labourForceFemale":54.9,"labourForceMale":71.7,"storyCount":0},{"hdiRank":43,"country":"Russian Federation","isoCode":"RU","genderInequalityIndex":0.178,"maternalMortality":14,"adolescentBirthRate":14.5,"parliamentSeatsWomen":17.8,"educationFemale":98.3,"educationMale":98.9,"labourForceFemale":55.5,"labourForceMale":70.3,"storyCount":0},{"hdiRank":79,"country":"Bahamas","isoCode":"UNKNOWN","genderInequalityIndex":0.333,"maternalMortality":77,"adolescentBirthRate":25.1,"parliamentSeatsWomen":20,"educationFemale":86.8,"educationMale":90,"labourForceFemale":69,"labourForceMale":73.9,"storyCount":0},{"hdiRank":95,"country":"Panama","isoCode":"PA","genderInequalityIndex":0.392,"maternalMortality":50,"adolescentBirthRate":68.5,"parliamentSeatsWomen":22.5,"educationFemale":67.6,"educationMale":65.6,"labourForceFemale":49.7,"labourForceMale":77,"storyCount":0},{"hdiRank":66,"country":"Oman","isoCode":"OM","genderInequalityIndex":0.267,"maternalMortality":17,"adolescentBirthRate":9.7,"parliamentSeatsWomen":9.9,"educationFemale":93.3,"educationMale":98.7,"labourForceFemale":35,"labourForceMale":83.8,"storyCount":0},{"hdiRank":69,"country":"Georgia","isoCode":"GE","genderInequalityIndex":0.283,"maternalMortality":28,"adolescentBirthRate":29.7,"parliamentSeatsWomen":19,"educationFemale":98.2,"educationMale":98.7,"labourForceFemale":55.5,"labourForceMale":73.5,"storyCount":1},{"hdiRank":64,"country":"Trinidad and Tobago","isoCode":"UNKNOWN","genderInequalityIndex":0.264,"maternalMortality":27,"adolescentBirthRate":37.7,"parliamentSeatsWomen":32.4,"educationFemale":86,"educationMale":81.9,"labourForceFemale":47.3,"labourForceMale":62.4,"storyCount":0},{"hdiRank":70,"country":"Barbados","isoCode":"UNKNOWN","genderInequalityIndex":0.289,"maternalMortality":39,"adolescentBirthRate":41.9,"parliamentSeatsWomen":32.7,"educationFemale":95.7,"educationMale":86.3,"labourForceFemale":58.2,"labourForceMale":65.1,"storyCount":0},{"hdiRank":52,"country":"Malaysia","isoCode":"MY","genderInequalityIndex":0.202,"maternalMortality":21,"adolescentBirthRate":9.1,"parliamentSeatsWomen":14.5,"educationFemale":76.1,"educationMale":79.2,"labourForceFemale":55.1,"labourForceMale":80.5,"storyCount":0},{"hdiRank":58,"country":"Costa Rica","isoCode":"CR","genderInequalityIndex":0.232,"maternalMortality":22,"adolescentBirthRate":35.7,"parliamentSeatsWomen":47.4,"educationFemale":50.2,"educationMale":48.1,"labourForceFemale":50.1,"labourForceMale":72.9,"storyCount":0},{"hdiRank":36,"country":"Serbia","isoCode":"RS","genderInequalityIndex":0.119,"maternalMortality":10,"adolescentBirthRate":14.4,"parliamentSeatsWomen":36.6,"educationFemale":89.9,"educationMale":96.1,"labourForceFemale":51,"labourForceMale":66.1,"storyCount":1},{"hdiRank":74,"country":"Thailand","isoCode":"TH","genderInequalityIndex":0.31,"maternalMortality":29,"adolescentBirthRate":31.6,"parliamentSeatsWomen":14,"educationFemale":49.3,"educationMale":53,"labourForceFemale":59.9,"labourForceMale":76,"storyCount":0},{"hdiRank":42,"country":"Kazakhstan","isoCode":"KZ","genderInequalityIndex":0.177,"maternalMortality":13,"adolescentBirthRate":20.9,"parliamentSeatsWomen":24.7,"educationFemale":100,"educationMale":100,"labourForceFemale":63.3,"labourForceMale":74.6,"storyCount":0},{"hdiRank":29,"country":"Belarus","isoCode":"BY","genderInequalityIndex":0.096,"maternalMortality":1,"adolescentBirthRate":11.2,"parliamentSeatsWomen":34.7,"educationFemale":98.4,"educationMale":99.5,"labourForceFemale":65.8,"labourForceMale":75.3,"storyCount":0},{"hdiRank":53,"country":"Bulgaria","isoCode":"UNKNOWN","genderInequalityIndex":0.206,"maternalMortality":7,"adolescentBirthRate":38.2,"parliamentSeatsWomen":24.2,"educationFemale":94.9,"educationMale":96.5,"labourForceFemale":50.6,"labourForceMale":63.1,"storyCount":3},{"hdiRank":0,"country":"Palau","isoCode":"PW","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":42.1,"parliamentSeatsWomen":6.9,"educationFemale":96.9,"educationMale":97.3,"labourForceFemale":59.8,"labourForceMale":73.6,"storyCount":0},{"hdiRank":87,"country":"Mauritius","isoCode":"MU","genderInequalityIndex":0.369,"maternalMortality":84,"adolescentBirthRate":24,"parliamentSeatsWomen":20,"educationFemale":66.5,"educationMale":72.4,"labourForceFemale":42.2,"labourForceMale":68.4,"storyCount":0},{"hdiRank":34,"country":"Albania","isoCode":"AL","genderInequalityIndex":0.116,"maternalMortality":8,"adolescentBirthRate":14.5,"parliamentSeatsWomen":35.7,"educationFemale":82.2,"educationMale":86.5,"labourForceFemale":56.1,"labourForceMale":69.9,"storyCount":0},{"hdiRank":47,"country":"China","isoCode":"CN","genderInequalityIndex":0.186,"maternalMortality":23,"adolescentBirthRate":11.1,"parliamentSeatsWomen":24.9,"educationFemale":79.7,"educationMale":86.4,"labourForceFemale":53.8,"labourForceMale":74.5,"storyCount":1},{"hdiRank":50,"country":"Armenia","isoCode":"AM","genderInequalityIndex":0.198,"maternalMortality":27,"adolescentBirthRate":18.3,"parliamentSeatsWomen":35.5,"educationFemale":96,"educationMale":97.1,"labourForceFemale":62.8,"labourForceMale":71.8,"storyCount":0},{"hdiRank":84,"country":"Mexico","isoCode":"MX","genderInequalityIndex":0.352,"maternalMortality":59,"adolescentBirthRate":53.7,"parliamentSeatsWomen":49.8,"educationFemale":63.7,"educationMale":65.4,"labourForceFemale":45,"labourForceMale":76.3,"storyCount":0},{"hdiRank":121,"country":"Iran","isoCode":"IR","genderInequalityIndex":0.484,"maternalMortality":22,"adolescentBirthRate":29.7,"parliamentSeatsWomen":5.6,"educationFemale":73.1,"educationMale":77.3,"labourForceFemale":13.6,"labourForceMale":67.5,"storyCount":0},{"hdiRank":90,"country":"Sri Lanka","isoCode":"LK","genderInequalityIndex":0.376,"maternalMortality":29,"adolescentBirthRate":15.4,"parliamentSeatsWomen":5.3,"educationFemale":80.6,"educationMale":83.3,"labourForceFemale":29.7,"labourForceMale":70.7,"storyCount":1},{"hdiRank":40,"country":"Bosnia and Herzegovina","isoCode":"BA","genderInequalityIndex":0.148,"maternalMortality":6,"adolescentBirthRate":9.4,"parliamentSeatsWomen":17.5,"educationFemale":82.7,"educationMale":94,"labourForceFemale":41.1,"labourForceMale":61.8,"storyCount":0},{"hdiRank":107,"country":"Dominican Republic","isoCode":"DO","genderInequalityIndex":0.433,"maternalMortality":107,"adolescentBirthRate":63.2,"parliamentSeatsWomen":25.7,"educationFemale":67.5,"educationMale":64.2,"labourForceFemale":50.9,"labourForceMale":76.9,"storyCount":0},{"hdiRank":89,"country":"Ecuador","isoCode":"EC","genderInequalityIndex":0.371,"maternalMortality":66,"adolescentBirthRate":62.1,"parliamentSeatsWomen":38.7,"educationFemale":54.1,"educationMale":54.2,"labourForceFemale":53.6,"labourForceMale":76.9,"storyCount":0},{"hdiRank":38,"country":"North Macedonia","isoCode":"MK","genderInequalityIndex":0.134,"maternalMortality":3,"adolescentBirthRate":16.1,"parliamentSeatsWomen":41.7,"educationFemale":61.9,"educationMale":75.1,"labourForceFemale":42.2,"labourForceMale":64.1,"storyCount":0},{"hdiRank":73,"country":"Cuba","isoCode":"CU","genderInequalityIndex":0.3,"maternalMortality":39,"adolescentBirthRate":48.9,"parliamentSeatsWomen":53.4,"educationFemale":78.6,"educationMale":81.8,"labourForceFemale":55.5,"labourForceMale":84,"storyCount":0},{"hdiRank":41,"country":"Moldova (Republic of)","isoCode":"UNKNOWN","genderInequalityIndex":0.156,"maternalMortality":12,"adolescentBirthRate":27.2,"parliamentSeatsWomen":40.6,"educationFemale":96.3,"educationMale":98.1,"labourForceFemale":71.5,"labourForceMale":73.7,"storyCount":0},{"hdiRank":76,"country":"Maldives","isoCode":"MV","genderInequalityIndex":0.328,"maternalMortality":57,"adolescentBirthRate":6.8,"parliamentSeatsWomen":4.6,"educationFemale":46.9,"educationMale":46.3,"labourForceFemale":53.3,"labourForceMale":78.2,"storyCount":0},{"hdiRank":85,"country":"Peru","isoCode":"PE","genderInequalityIndex":0.36,"maternalMortality":69,"adolescentBirthRate":56.1,"parliamentSeatsWomen":40,"educationFemale":55.6,"educationMale":66.7,"labourForceFemale":66.7,"labourForceMale":82.4,"storyCount":0},{"hdiRank":77,"country":"Azerbaijan","isoCode":"AZ","genderInequalityIndex":0.329,"maternalMortality":41,"adolescentBirthRate":40.1,"parliamentSeatsWomen":18.3,"educationFemale":93.6,"educationMale":97.6,"labourForceFemale":61.9,"labourForceMale":69.6,"storyCount":0},{"hdiRank":94,"country":"Brazil","isoCode":"BR","genderInequalityIndex":0.391,"maternalMortality":72,"adolescentBirthRate":43.6,"parliamentSeatsWomen":17.5,"educationFemale":67.4,"educationMale":65,"labourForceFemale":53.8,"labourForceMale":73.6,"storyCount":2},{"hdiRank":95,"country":"Colombia","isoCode":"CO","genderInequalityIndex":0.392,"maternalMortality":75,"adolescentBirthRate":57.6,"parliamentSeatsWomen":29.2,"educationFemale":59.7,"educationMale":57.1,"labourForceFemale":51.1,"labourForceMale":76.2,"storyCount":0},{"hdiRank":65,"country":"Libya","isoCode":"LY","genderInequalityIndex":0.266,"maternalMortality":72,"adolescentBirthRate":7,"parliamentSeatsWomen":16.5,"educationFemale":62.2,"educationMale":45.3,"labourForceFemale":32.8,"labourForceMale":59.9,"storyCount":0},{"hdiRank":114,"country":"Algeria","isoCode":"DZ","genderInequalityIndex":0.46,"maternalMortality":78,"adolescentBirthRate":11.6,"parliamentSeatsWomen":7,"educationFemale":42.9,"educationMale":46.8,"labourForceFemale":17.6,"labourForceMale":65.5,"storyCount":0},{"hdiRank":104,"country":"Guyana","isoCode":"GY","genderInequalityIndex":0.416,"maternalMortality":112,"adolescentBirthRate":64.6,"parliamentSeatsWomen":35.4,"educationFemale":58.7,"educationMale":56.4,"labourForceFemale":37.8,"labourForceMale":53.4,"storyCount":0},{"hdiRank":72,"country":"Mongolia","isoCode":"MN","genderInequalityIndex":0.297,"maternalMortality":39,"adolescentBirthRate":25,"parliamentSeatsWomen":17.1,"educationFemale":79.3,"educationMale":73,"labourForceFemale":53.5,"labourForceMale":68.4,"storyCount":0},{"hdiRank":0,"country":"Dominica","isoCode":"UNKNOWN","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":37.9,"parliamentSeatsWomen":34.4,"educationFemale":0,"educationMale":0,"labourForceFemale":0,"labourForceMale":0,"storyCount":0},{"hdiRank":115,"country":"Tonga","isoCode":"TO","genderInequalityIndex":0.462,"maternalMortality":126,"adolescentBirthRate":19.2,"parliamentSeatsWomen":3.7,"educationFemale":93.7,"educationMale":93.4,"labourForceFemale":43,"labourForceMale":54.9,"storyCount":0},{"hdiRank":111,"country":"Jordan","isoCode":"JO","genderInequalityIndex":0.449,"maternalMortality":41,"adolescentBirthRate":24.9,"parliamentSeatsWomen":13.3,"educationFemale":77.4,"educationMale":84.2,"labourForceFemale":13.8,"labourForceMale":60.7,"storyCount":0},{"hdiRank":48,"country":"Ukraine","isoCode":"UA","genderInequalityIndex":0.188,"maternalMortality":17,"adolescentBirthRate":15.2,"parliamentSeatsWomen":20.3,"educationFemale":95.7,"educationMale":93.5,"labourForceFemale":47.8,"labourForceMale":62.9,"storyCount":0},{"hdiRank":59,"country":"Tunisia","isoCode":"TN","genderInequalityIndex":0.237,"maternalMortality":37,"adolescentBirthRate":6.6,"parliamentSeatsWomen":26.3,"educationFemale":40,"educationMale":47.2,"labourForceFemale":29.3,"labourForceMale":71.8,"storyCount":0},{"hdiRank":0,"country":"Marshall Islands","isoCode":"MH","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":57.5,"parliamentSeatsWomen":6.1,"educationFemale":91.6,"educationMale":92.5,"labourForceFemale":37.3,"labourForceMale":61.2,"storyCount":0},{"hdiRank":106,"country":"Paraguay","isoCode":"PY","genderInequalityIndex":0.429,"maternalMortality":71,"adolescentBirthRate":69.9,"parliamentSeatsWomen":16.8,"educationFemale":54.3,"educationMale":53.3,"labourForceFemale":59.1,"labourForceMale":82.4,"storyCount":0},{"hdiRank":78,"country":"Fiji","isoCode":"FJ","genderInequalityIndex":0.332,"maternalMortality":38,"adolescentBirthRate":26.1,"parliamentSeatsWomen":19.6,"educationFemale":66.1,"educationMale":61.3,"labourForceFemale":37.3,"labourForceMale":77.7,"storyCount":0},{"hdiRank":93,"country":"Egypt","isoCode":"EG","genderInequalityIndex":0.389,"maternalMortality":17,"adolescentBirthRate":43.6,"parliamentSeatsWomen":22.8,"educationFemale":85.9,"educationMale":78.7,"labourForceFemale":15.3,"labourForceMale":69.1,"storyCount":0},{"hdiRank":61,"country":"Uzbekistan","isoCode":"UZ","genderInequalityIndex":0.242,"maternalMortality":30,"adolescentBirthRate":15.7,"parliamentSeatsWomen":29.1,"educationFemale":100,"educationMale":100,"labourForceFemale":39.9,"labourForceMale":73.1,"storyCount":0},{"hdiRank":91,"country":"Viet Nam","isoCode":"VN","genderInequalityIndex":0.378,"maternalMortality":124,"adolescentBirthRate":35,"parliamentSeatsWomen":30.3,"educationFemale":61.5,"educationMale":69.5,"labourForceFemale":68.5,"labourForceMale":77.8,"storyCount":0},{"hdiRank":82,"country":"Saint Lucia","isoCode":"UNKNOWN","genderInequalityIndex":0.347,"maternalMortality":73,"adolescentBirthRate":36.3,"parliamentSeatsWomen":24.1,"educationFemale":50,"educationMale":44,"labourForceFemale":62.7,"labourForceMale":75.8,"storyCount":0},{"hdiRank":86,"country":"Lebanon","isoCode":"LB","genderInequalityIndex":0.365,"maternalMortality":21,"adolescentBirthRate":20,"parliamentSeatsWomen":6.3,"educationFemale":54.7,"educationMale":61.1,"labourForceFemale":29.8,"labourForceMale":70.2,"storyCount":0},{"hdiRank":99,"country":"South Africa","isoCode":"ZA","genderInequalityIndex":0.401,"maternalMortality":127,"adolescentBirthRate":60.9,"parliamentSeatsWomen":45.4,"educationFemale":83,"educationMale":84.9,"labourForceFemale":50.8,"labourForceMale":63.5,"storyCount":0},{"hdiRank":109,"country":"Indonesia","isoCode":"ID","genderInequalityIndex":0.439,"maternalMortality":173,"adolescentBirthRate":32.9,"parliamentSeatsWomen":21.9,"educationFemale":51,"educationMale":58.2,"labourForceFemale":52.5,"labourForceMale":81.5,"storyCount":1},{"hdiRank":92,"country":"Philippines","isoCode":"PH","genderInequalityIndex":0.388,"maternalMortality":78,"adolescentBirthRate":48.1,"parliamentSeatsWomen":27.5,"educationFemale":74.4,"educationMale":69.9,"labourForceFemale":44.1,"labourForceMale":68.8,"storyCount":1},{"hdiRank":120,"country":"Botswana","isoCode":"BW","genderInequalityIndex":0.483,"maternalMortality":186,"adolescentBirthRate":48.3,"parliamentSeatsWomen":11.1,"educationFemale":92.1,"educationMale":92.5,"labourForceFemale":60.1,"labourForceMale":69.7,"storyCount":0},{"hdiRank":83,"country":"Jamaica","isoCode":"JM","genderInequalityIndex":0.35,"maternalMortality":99,"adolescentBirthRate":32,"parliamentSeatsWomen":31,"educationFemale":74.8,"educationMale":67,"labourForceFemale":56,"labourForceMale":69.9,"storyCount":0},{"hdiRank":101,"country":"Samoa","isoCode":"WS","genderInequalityIndex":0.406,"maternalMortality":59,"adolescentBirthRate":43.8,"parliamentSeatsWomen":13,"educationFemale":92.4,"educationMale":87,"labourForceFemale":49.8,"labourForceMale":80.6,"storyCount":0},{"hdiRank":81,"country":"Kyrgyzstan","isoCode":"KG","genderInequalityIndex":0.345,"maternalMortality":50,"adolescentBirthRate":33.8,"parliamentSeatsWomen":20.5,"educationFemale":92.4,"educationMale":94.4,"labourForceFemale":52.5,"labourForceMale":78,"storyCount":0},{"hdiRank":113,"country":"Belize","isoCode":"BZ","genderInequalityIndex":0.454,"maternalMortality":130,"adolescentBirthRate":56.6,"parliamentSeatsWomen":19.6,"educationFemale":54.5,"educationMale":49.8,"labourForceFemale":48.6,"labourForceMale":75.6,"storyCount":0},{"hdiRank":134,"country":"Venezuela","isoCode":"VE","genderInequalityIndex":0.521,"maternalMortality":259,"adolescentBirthRate":82,"parliamentSeatsWomen":22.2,"educationFemale":81,"educationMale":76.4,"labourForceFemale":45.2,"labourForceMale":70.6,"storyCount":0},{"hdiRank":105,"country":"Bolivia","isoCode":"BO","genderInequalityIndex":0.418,"maternalMortality":161,"adolescentBirthRate":63.1,"parliamentSeatsWomen":48.2,"educationFemale":58.4,"educationMale":69.5,"labourForceFemale":71.8,"labourForceMale":85,"storyCount":0},{"hdiRank":110,"country":"Morocco","isoCode":"MA","genderInequalityIndex":0.44,"maternalMortality":72,"adolescentBirthRate":25.5,"parliamentSeatsWomen":21.4,"educationFemale":31.9,"educationMale":37.9,"labourForceFemale":19.8,"labourForceMale":69.6,"storyCount":1},{"hdiRank":136,"country":"Gabon","isoCode":"GA","genderInequalityIndex":0.524,"maternalMortality":227,"adolescentBirthRate":89.8,"parliamentSeatsWomen":18.1,"educationFemale":70.4,"educationMale":55.3,"labourForceFemale":34.7,"labourForceMale":56.2,"storyCount":0},{"hdiRank":100,"country":"Suriname","isoCode":"SR","genderInequalityIndex":0.405,"maternalMortality":96,"adolescentBirthRate":55.2,"parliamentSeatsWomen":29.4,"educationFemale":45.5,"educationMale":42.3,"labourForceFemale":42.3,"labourForceMale":61.7,"storyCount":0},{"hdiRank":80,"country":"Bhutan","isoCode":"BT","genderInequalityIndex":0.334,"maternalMortality":60,"adolescentBirthRate":18.5,"parliamentSeatsWomen":15.7,"educationFemale":26.7,"educationMale":34.3,"labourForceFemale":53.5,"labourForceMale":73.5,"storyCount":0},{"hdiRank":67,"country":"Tajikistan","isoCode":"TJ","genderInequalityIndex":0.269,"maternalMortality":17,"adolescentBirthRate":44.9,"parliamentSeatsWomen":26.6,"educationFemale":93.6,"educationMale":94,"labourForceFemale":33.3,"labourForceMale":52.1,"storyCount":0},{"hdiRank":87,"country":"El Salvador","isoCode":"SV","genderInequalityIndex":0.369,"maternalMortality":43,"adolescentBirthRate":54.5,"parliamentSeatsWomen":27.4,"educationFemale":42.7,"educationMale":51.4,"labourForceFemale":46.4,"labourForceMale":77.7,"storyCount":0},{"hdiRank":143,"country":"Iraq","isoCode":"IQ","genderInequalityIndex":0.562,"maternalMortality":76,"adolescentBirthRate":61.2,"parliamentSeatsWomen":28.9,"educationFemale":25.3,"educationMale":40.4,"labourForceFemale":10.8,"labourForceMale":68.2,"storyCount":0},{"hdiRank":127,"country":"Bangladesh","isoCode":"BD","genderInequalityIndex":0.498,"maternalMortality":123,"adolescentBirthRate":73.3,"parliamentSeatsWomen":20.9,"educationFemale":43.7,"educationMale":50.5,"labourForceFemale":39.2,"labourForceMale":81.4,"storyCount":1},{"hdiRank":97,"country":"Nicaragua","isoCode":"NI","genderInequalityIndex":0.397,"maternalMortality":78,"adolescentBirthRate":84,"parliamentSeatsWomen":51.6,"educationFemale":49.4,"educationMale":40.3,"labourForceFemale":48.6,"labourForceMale":81.1,"storyCount":0},{"hdiRank":75,"country":"Cabo Verde","isoCode":"UNKNOWN","genderInequalityIndex":0.325,"maternalMortality":42,"adolescentBirthRate":54,"parliamentSeatsWomen":38.9,"educationFemale":28.8,"educationMale":31.7,"labourForceFemale":46.7,"labourForceMale":62.8,"storyCount":0},{"hdiRank":0,"country":"Tuvalu","isoCode":"TV","genderInequalityIndex":0,"maternalMortality":0,"adolescentBirthRate":31.7,"parliamentSeatsWomen":6.3,"educationFemale":58.1,"educationMale":58.5,"labourForceFemale":20,"labourForceMale":29.6,"storyCount":0},{"hdiRank":108,"country":"India","isoCode":"IN","genderInequalityIndex":0.437,"maternalMortality":103,"adolescentBirthRate":16.3,"parliamentSeatsWomen":14.6,"educationFemale":41,"educationMale":58.7,"labourForceFemale":28.3,"labourForceMale":76.1,"storyCount":14},{"hdiRank":117,"country":"Guatemala","isoCode":"GT","genderInequalityIndex":0.474,"maternalMortality":96,"adolescentBirthRate":63.2,"parliamentSeatsWomen":19.4,"educationFemale":31.1,"educationMale":37.8,"labourForceFemale":41.5,"labourForceMale":82.8,"storyCount":0},{"hdiRank":102,"country":"Honduras","isoCode":"HN","genderInequalityIndex":0.413,"maternalMortality":72,"adolescentBirthRate":71.3,"parliamentSeatsWomen":27.3,"educationFemale":34.8,"educationMale":31.4,"labourForceFemale":49.6,"labourForceMale":81.1,"storyCount":0},{"hdiRank":116,"country":"Lao People's Democratic Republic","isoCode":"UNKNOWN","genderInequalityIndex":0.467,"maternalMortality":126,"adolescentBirthRate":71.8,"parliamentSeatsWomen":22,"educationFemale":18.7,"educationMale":30.4,"labourForceFemale":61.5,"labourForceMale":70.8,"storyCount":0},{"hdiRank":124,"country":"Eswatini (Kingdom of)","isoCode":"UNKNOWN","genderInequalityIndex":0.491,"maternalMortality":240,"adolescentBirthRate":68.4,"parliamentSeatsWomen":21.2,"educationFemale":35.3,"educationMale":37.3,"labourForceFemale":44.9,"labourForceMale":51.5,"storyCount":0},{"hdiRank":112,"country":"Namibia","isoCode":"NA","genderInequalityIndex":0.45,"maternalMortality":215,"adolescentBirthRate":63.1,"parliamentSeatsWomen":35.6,"educationFemale":42.1,"educationMale":45,"labourForceFemale":54.1,"labourForceMale":61.2,"storyCount":0},{"hdiRank":119,"country":"Myanmar","isoCode":"MM","genderInequalityIndex":0.479,"maternalMortality":179,"adolescentBirthRate":32.8,"parliamentSeatsWomen":15,"educationFemale":39.2,"educationMale":49.9,"labourForceFemale":44.2,"labourForceMale":78.6,"storyCount":0},{"hdiRank":130,"country":"Ghana","isoCode":"GH","genderInequalityIndex":0.512,"maternalMortality":263,"adolescentBirthRate":63.4,"parliamentSeatsWomen":14.5,"educationFemale":59.1,"educationMale":74,"labourForceFemale":72.1,"labourForceMale":73.1,"storyCount":0},{"hdiRank":139,"country":"Kenya","isoCode":"KE","genderInequalityIndex":0.533,"maternalMortality":530,"adolescentBirthRate":62.6,"parliamentSeatsWomen":24.8,"educationFemale":54.6,"educationMale":63.5,"labourForceFemale":62.9,"labourForceMale":72.6,"storyCount":1},{"hdiRank":126,"country":"Nepal","isoCode":"NP","genderInequalityIndex":0.495,"maternalMortality":174,"adolescentBirthRate":63.4,"parliamentSeatsWomen":33.8,"educationFemale":26,"educationMale":42.8,"labourForceFemale":27.9,"labourForceMale":55,"storyCount":3},{"hdiRank":122,"country":"Cambodia","isoCode":"KH","genderInequalityIndex":0.486,"maternalMortality":218,"adolescentBirthRate":45.7,"parliamentSeatsWomen":19.3,"educationFemale":16.4,"educationMale":29,"labourForceFemale":73.7,"labourForceMale":85.8,"storyCount":0},{"hdiRank":144,"country":"Congo","isoCode":"CG","genderInequalityIndex":0.572,"maternalMortality":282,"adolescentBirthRate":101.2,"parliamentSeatsWomen":15.9,"educationFemale":32.1,"educationMale":50,"labourForceFemale":44.1,"labourForceMale":63.9,"storyCount":0},{"hdiRank":133,"country":"Angola","isoCode":"AO","genderInequalityIndex":0.52,"maternalMortality":222,"adolescentBirthRate":135.8,"parliamentSeatsWomen":33.6,"educationFemale":21.3,"educationMale":37.4,"labourForceFemale":74.7,"labourForceMale":78.2,"storyCount":0},{"hdiRank":142,"country":"Cameroon","isoCode":"CM","genderInequalityIndex":0.555,"maternalMortality":438,"adolescentBirthRate":108.6,"parliamentSeatsWomen":31.1,"educationFemale":24.5,"educationMale":39.3,"labourForceFemale":66.8,"labourForceMale":76.8,"storyCount":0},{"hdiRank":137,"country":"Zambia","isoCode":"ZM","genderInequalityIndex":0.526,"maternalMortality":135,"adolescentBirthRate":116.1,"parliamentSeatsWomen":15.1,"educationFemale":33.7,"educationMale":51.4,"labourForceFemale":54.2,"labourForceMale":66.4,"storyCount":0},{"hdiRank":151,"country":"Papua New Guinea","isoCode":"PG","genderInequalityIndex":0.604,"maternalMortality":192,"adolescentBirthRate":54.3,"parliamentSeatsWomen":1.7,"educationFemale":26.3,"educationMale":37.5,"labourForceFemale":46,"labourForceMale":48,"storyCount":0},{"hdiRank":103,"country":"Timor-Leste","isoCode":"TL","genderInequalityIndex":0.415,"maternalMortality":204,"adolescentBirthRate":33.3,"parliamentSeatsWomen":40,"educationFemale":33.5,"educationMale":39.8,"labourForceFemale":27.9,"labourForceMale":41.4,"storyCount":0},{"hdiRank":123,"country":"Syria","isoCode":"SY","genderInequalityIndex":0.487,"maternalMortality":30,"adolescentBirthRate":38.1,"parliamentSeatsWomen":11.2,"educationFemale":24.1,"educationMale":32,"labourForceFemale":14.4,"labourForceMale":68.9,"storyCount":0},{"hdiRank":158,"country":"Haiti","isoCode":"HT","genderInequalityIndex":0.621,"maternalMortality":350,"adolescentBirthRate":51.8,"parliamentSeatsWomen":2.7,"educationFemale":28,"educationMale":36.9,"labourForceFemale":48.8,"labourForceMale":66,"storyCount":0},{"hdiRank":138,"country":"Uganda","isoCode":"UG","genderInequalityIndex":0.527,"maternalMortality":284,"adolescentBirthRate":105.7,"parliamentSeatsWomen":33.8,"educationFemale":10.8,"educationMale":20.4,"labourForceFemale":74.5,"labourForceMale":84.2,"storyCount":0},{"hdiRank":132,"country":"Zimbabwe","isoCode":"ZW","genderInequalityIndex":0.519,"maternalMortality":357,"adolescentBirthRate":92.6,"parliamentSeatsWomen":33.6,"educationFemale":63.4,"educationMale":73.6,"labourForceFemale":60,"labourForceMale":71.6,"storyCount":0},{"hdiRank":165,"country":"Nigeria","isoCode":"NG","genderInequalityIndex":0.677,"maternalMortality":1047,"adolescentBirthRate":99.6,"parliamentSeatsWomen":4.5,"educationFemale":42.4,"educationMale":57.8,"labourForceFemale":77,"labourForceMale":85.7,"storyCount":1},{"hdiRank":98,"country":"Rwanda","isoCode":"RW","genderInequalityIndex":0.4,"maternalMortality":259,"adolescentBirthRate":32.2,"parliamentSeatsWomen":54.7,"educationFemale":14.6,"educationMale":18.7,"labourForceFemale":54.8,"labourForceMale":66.2,"storyCount":0},{"hdiRank":147,"country":"Togo","isoCode":"TG","genderInequalityIndex":0.578,"maternalMortality":399,"adolescentBirthRate":77,"parliamentSeatsWomen":18.7,"educationFemale":13.5,"educationMale":33.1,"labourForceFemale":79.8,"labourForceMale":98.6,"storyCount":0},{"hdiRank":150,"country":"Mauritania","isoCode":"MR","genderInequalityIndex":0.603,"maternalMortality":464,"adolescentBirthRate":76.8,"parliamentSeatsWomen":20.3,"educationFemale":16.1,"educationMale":27.6,"labourForceFemale":31,"labourForceMale":65.7,"storyCount":0},{"hdiRank":135,"country":"Pakistan","isoCode":"PK","genderInequalityIndex":0.522,"maternalMortality":154,"adolescentBirthRate":41.2,"parliamentSeatsWomen":20.1,"educationFemale":22,"educationMale":26.9,"labourForceFemale":24.5,"labourForceMale":80.7,"storyCount":1},{"hdiRank":156,"country":"Côte d'Ivoire","isoCode":"CI","genderInequalityIndex":0.612,"maternalMortality":480,"adolescentBirthRate":103.3,"parliamentSeatsWomen":15.6,"educationFemale":13.5,"educationMale":29.3,"labourForceFemale":54.5,"labourForceMale":71.2,"storyCount":0},{"hdiRank":131,"country":"Tanzania","isoCode":"TZ","genderInequalityIndex":0.513,"maternalMortality":238,"adolescentBirthRate":123.4,"parliamentSeatsWomen":36.9,"educationFemale":9.3,"educationMale":14.3,"labourForceFemale":75.5,"labourForceMale":84.5,"storyCount":0},{"hdiRank":141,"country":"Lesotho","isoCode":"LS","genderInequalityIndex":0.552,"maternalMortality":566,"adolescentBirthRate":89.1,"parliamentSeatsWomen":26,"educationFemale":34.1,"educationMale":29.7,"labourForceFemale":51.6,"labourForceMale":65,"storyCount":0},{"hdiRank":129,"country":"Senegal","isoCode":"SN","genderInequalityIndex":0.505,"maternalMortality":261,"adolescentBirthRate":64.6,"parliamentSeatsWomen":44.2,"educationFemale":9.2,"educationMale":19,"labourForceFemale":39.3,"labourForceMale":68.4,"storyCount":0},{"hdiRank":140,"country":"Sudan","isoCode":"SD","genderInequalityIndex":0.548,"maternalMortality":270,"adolescentBirthRate":77.6,"parliamentSeatsWomen":31,"educationFemale":17,"educationMale":20.4,"labourForceFemale":28,"labourForceMale":69.1,"storyCount":0},{"hdiRank":148,"country":"Malawi","isoCode":"MW","genderInequalityIndex":0.579,"maternalMortality":381,"adolescentBirthRate":117.2,"parliamentSeatsWomen":22.9,"educationFemale":12.7,"educationMale":26.2,"labourForceFemale":63.1,"labourForceMale":74.6,"storyCount":0},{"hdiRank":160,"country":"Benin","isoCode":"BJ","genderInequalityIndex":0.649,"maternalMortality":523,"adolescentBirthRate":90.8,"parliamentSeatsWomen":7.4,"educationFemale":9.2,"educationMale":21.5,"labourForceFemale":51.6,"labourForceMale":67.8,"storyCount":0},{"hdiRank":149,"country":"Gambia","isoCode":"GM","genderInequalityIndex":0.585,"maternalMortality":458,"adolescentBirthRate":60.7,"parliamentSeatsWomen":8.6,"educationFemale":26,"educationMale":40.7,"labourForceFemale":59,"labourForceMale":64.5,"storyCount":0},{"hdiRank":125,"country":"Ethiopia","isoCode":"ET","genderInequalityIndex":0.494,"maternalMortality":267,"adolescentBirthRate":66.5,"parliamentSeatsWomen":38.9,"educationFemale":7.5,"educationMale":13.1,"labourForceFemale":57.6,"labourForceMale":79.2,"storyCount":0},{"hdiRank":161,"country":"Liberia","isoCode":"LR","genderInequalityIndex":0.656,"maternalMortality":652,"adolescentBirthRate":122,"parliamentSeatsWomen":9.7,"educationFemale":19.7,"educationMale":45.8,"labourForceFemale":43.5,"labourForceMale":50.1,"storyCount":0},{"hdiRank":145,"country":"Madagascar","isoCode":"MG","genderInequalityIndex":0.574,"maternalMortality":392,"adolescentBirthRate":118.1,"parliamentSeatsWomen":17.8,"educationFemale":15.9,"educationMale":21.2,"labourForceFemale":78.8,"labourForceMale":88.9,"storyCount":0},{"hdiRank":159,"country":"Guinea-Bissau","isoCode":"GW","genderInequalityIndex":0.631,"maternalMortality":725,"adolescentBirthRate":85.8,"parliamentSeatsWomen":13.7,"educationFemale":10.9,"educationMale":24.6,"labourForceFemale":52.1,"labourForceMale":66.1,"storyCount":0},{"hdiRank":152,"country":"Congo (Democratic Republic of the)","isoCode":"CD","genderInequalityIndex":0.605,"maternalMortality":547,"adolescentBirthRate":107.5,"parliamentSeatsWomen":14.8,"educationFemale":38.8,"educationMale":65.7,"labourForceFemale":60,"labourForceMale":66.4,"storyCount":0},{"hdiRank":154,"country":"Guinea","isoCode":"GN","genderInequalityIndex":0.609,"maternalMortality":553,"adolescentBirthRate":112.2,"parliamentSeatsWomen":29.6,"educationFemale":7.5,"educationMale":20,"labourForceFemale":44.6,"labourForceMale":67,"storyCount":0},{"hdiRank":162,"country":"Afghanistan","isoCode":"AF","genderInequalityIndex":0.665,"maternalMortality":620,"adolescentBirthRate":79.7,"parliamentSeatsWomen":27.2,"educationFemale":7,"educationMale":24.1,"labourForceFemale":23.3,"labourForceMale":77.1,"storyCount":1},{"hdiRank":118,"country":"Mozambique","isoCode":"MZ","genderInequalityIndex":0.477,"maternalMortality":127,"adolescentBirthRate":165.1,"parliamentSeatsWomen":42.4,"educationFemale":17.9,"educationMale":25.1,"labourForceFemale":73.9,"labourForceMale":80.1,"storyCount":0},{"hdiRank":157,"country":"Sierra Leone","isoCode":"SL","genderInequalityIndex":0.613,"maternalMortality":443,"adolescentBirthRate":97.9,"parliamentSeatsWomen":12.3,"educationFemale":14.5,"educationMale":33.9,"labourForceFemale":48.3,"labourForceMale":55.9,"storyCount":0},{"hdiRank":146,"country":"Burkina Faso","isoCode":"BF","genderInequalityIndex":0.577,"maternalMortality":264,"adolescentBirthRate":108.7,"parliamentSeatsWomen":16.9,"educationFemale":11.2,"educationMale":20.3,"labourForceFemale":27.5,"labourForceMale":41,"storyCount":0},{"hdiRank":166,"country":"Yemen","isoCode":"YE","genderInequalityIndex":0.82,"maternalMortality":183,"adolescentBirthRate":52.5,"parliamentSeatsWomen":0.3,"educationFemale":23.7,"educationMale":38.2,"labourForceFemale":5.8,"labourForceMale":64.7,"storyCount":0},{"hdiRank":128,"country":"Burundi","isoCode":"BI","genderInequalityIndex":0.499,"maternalMortality":494,"adolescentBirthRate":52.6,"parliamentSeatsWomen":38.9,"educationFemale":8.2,"educationMale":13.8,"labourForceFemale":78,"labourForceMale":79.1,"storyCount":0},{"hdiRank":153,"country":"Mali","isoCode":"ML","genderInequalityIndex":0.607,"maternalMortality":440,"adolescentBirthRate":147.7,"parliamentSeatsWomen":28.6,"educationFemale":8,"educationMale":15.5,"labourForceFemale":51.5,"labourForceMale":85,"storyCount":1},{"hdiRank":163,"country":"Chad","isoCode":"TD","genderInequalityIndex":0.671,"maternalMortality":1063,"adolescentBirthRate":135.7,"parliamentSeatsWomen":25.9,"educationFemale":3.7,"educationMale":15,"labourForceFemale":51.1,"labourForceMale":75,"storyCount":0},{"hdiRank":154,"country":"Niger","isoCode":"NE","genderInequalityIndex":0.609,"maternalMortality":441,"adolescentBirthRate":168,"parliamentSeatsWomen":25.9,"educationFemale":2.6,"educationMale":4.5,"labourForceFemale":64.6,"labourForceMale":96.5,"storyCount":0},{"hdiRank":0,"country":"South Sudan","isoCode":"SS","genderInequalityIndex":0,"maternalMortality":1223,"adolescentBirthRate":97.4,"parliamentSeatsWomen":32.3,"educationFemale":26.5,"educationMale":36.4,"labourForceFemale":0,"labourForceMale":0,"storyCount":0},{"hdiRank":164,"country":"Somalia","isoCode":"SO","genderInequalityIndex":0.674,"maternalMortality":621,"adolescentBirthRate":116.1,"parliamentSeatsWomen":20.7,"educationFemale":4.4,"educationMale":17.8,"labourForceFemale":22.3,"labourForceMale":49.3,"storyCount":1}];
        
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
