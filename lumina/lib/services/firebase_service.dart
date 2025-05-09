import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _storiesCollection = _firestore.collection(
    'stories',
  );

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Upload CSV data to Firestore
  static Future<void> uploadCSVDataToFirestore(String filePath) async {
    try {
      final File file = File(filePath);
      final String csvData = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(
        csvData,
      );

      // Assuming first row is header
      final List<String> headers =
          csvTable[0].map((header) => header.toString()).toList();

      for (int i = 1; i < csvTable.length; i++) {
        final Map<String, dynamic> storyData = {};

        for (int j = 0; j < headers.length; j++) {
          storyData[headers[j]] = csvTable[i][j];
        }

        // Add timestamp if not present
        if (!storyData.containsKey('timestamp')) {
          storyData['timestamp'] = DateTime.now().toIso8601String();
        }

        // Add userId if not present
        if (!storyData.containsKey('userId')) {
          storyData['userId'] = "anonymous";
        }

        await _storiesCollection.add(storyData);
      }

      print("CSV data uploaded successfully!");
    } catch (e) {
      print("Error uploading CSV data: $e");
    }
  }

  // Private helper to clean theme strings according to new rules.
  static List<String> _cleanThemes(List<dynamic> themes) {
    List<String> cleaned = [];
    if (themes.isNotEmpty) {
      String first = themes[0].toString();
      if (first.length > 3) {
        first = first.substring(2, first.length - 1);
      }
      cleaned.add(first);
      if (themes.length > 1) {
        String second = themes[1].toString();
        if (second.length > 3) {
          second = second.substring(1, second.length - 2);
        }
        cleaned.add(second);
      }
    }
    return cleaned;
  }

  // Modified getAllStories without calling _cleanThemes
  static Future<List<Map<String, dynamic>>> getAllStories() async {
    QuerySnapshot querySnapshot = await _storiesCollection.get();
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      // Removed _cleanThemes call
      return data;
    }).toList();
  }

  // Modified getStoriesByTheme without calling _cleanThemes
  static Future<List<Map<String, dynamic>>> getStoriesByTheme(String theme) async {
    QuerySnapshot querySnapshot = await _storiesCollection.where('themes', arrayContains: theme).get();
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      // Removed _cleanThemes call
      return data;
    }).toList();
  }

  // Modified getTopStoriesByTheme without calling _cleanThemes
  static Future<List<Map<String, dynamic>>> getTopStoriesByTheme(String theme, int limit) async {
    print("Fetching top stories for theme: $theme with limit: $limit");
    QuerySnapshot querySnapshot = await _storiesCollection
        .where('themes', arrayContains: theme)
        .orderBy('likes', descending: true)
        .limit(limit)
        .get();
    return querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      // Removed _cleanThemes call
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getTopStoriesByCountryAndThemes(
      String country, List<String> themes, int limit) async {
    try {
      print("Fetching top stories for country: $country with themes: $themes and limit: $limit");

      // Query Firestore for stories matching the country and themes
      QuerySnapshot querySnapshot = await _storiesCollection
          .where('country', isEqualTo: country)
          .where('themes', arrayContainsAny: themes)
          .orderBy('likes', descending: true)
          .limit(limit)
          .get();

      // Map the results to a list of story objects
      return querySnapshot.docs.map((doc) {
        Map<String, dynamic> data = {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
        return data;
      }).toList();
    } catch (e) {
      print("Error fetching top stories for country and themes: $e");
      return [];
    }
  }

  // Modified getRandomStories without calling _cleanThemes
  static Future<List<Map<String, dynamic>>> getRandomStories(int limit) async {
    QuerySnapshot querySnapshot = await _storiesCollection.get();
    List<Map<String, dynamic>> stories = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
      // Removed _cleanThemes call
      return data;
    }).toList();

    stories.shuffle();
    return stories.take(limit).toList();
  }

  // Add a new story
  static Future<void> addStory({
    required String title,
    required String story,
    required String country,
    required List<String> themes,
    required List<String> keywords,
    String userId = "anonymous",
  }) async {
    await _storiesCollection.add({
      'title': title,
      'story': story,
      'country': country,
      'themes': themes,
      'keywords': keywords,
      'likes': 0,
      'reports': 0,
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Update likes
  static Future<void> updateLikes(String storyId, int likes) async {
    await _storiesCollection.doc(storyId).update({'likes': likes});
  }

  Future<int> getStoryCountForCountry(String country) async {
    try {
      final QuerySnapshot snapshot =
          await _storiesCollection.where('country', isEqualTo: country).get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting story count for $country: $e');
      return 0;
    }
  }

  static Future<List<MapEntry<String, int>>> getPrevalentThemesForCountry(String country) async {
    QuerySnapshot snapshot = await _storiesCollection.where('country', isEqualTo: country).get();
    Map<String, int> themeCounts = {};
    for (var doc in snapshot.docs) {
      List<dynamic> themes = doc['themes'] as List<dynamic>;
      for (var theme in themes) {
        String themeStr = theme.toString();
        themeCounts[themeStr] = (themeCounts[themeStr] ?? 0) + 1;
      }
    }
    var entries = themeCounts.entries.toList();
    // Sort descending by count.
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }
}
