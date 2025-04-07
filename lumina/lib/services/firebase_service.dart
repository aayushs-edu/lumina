import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:csv/csv.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _storiesCollection = _firestore.collection('stories');

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp();
  }

  // Upload CSV data to Firestore
  static Future<void> uploadCSVDataToFirestore(String filePath) async {
    try {
      final File file = File(filePath);
      final String csvData = await file.readAsString();
      final List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      
      // Assuming first row is header
      final List<String> headers = csvTable[0].map((header) => header.toString()).toList();

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

  // Get all stories
  static Future<List<Map<String, dynamic>>> getAllStories() async {
    QuerySnapshot querySnapshot = await _storiesCollection.get();
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // Get stories by theme
  static Future<List<Map<String, dynamic>>> getStoriesByTheme(String theme) async {
    QuerySnapshot querySnapshot =
        await _storiesCollection.where('themes', arrayContains: theme).get();
    return querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
  }

  // Get random stories
  static Future<List<Map<String, dynamic>>> getRandomStories(int limit) async {
    // Firestore doesn't support direct random queries, so we'll get all and shuffle
    QuerySnapshot querySnapshot = await _storiesCollection.get();
    List<Map<String, dynamic>> stories = querySnapshot.docs
        .map((doc) => {
              'id': doc.id,
              ...doc.data() as Map<String, dynamic>,
            })
        .toList();
    
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
}