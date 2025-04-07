import 'package:algolia/algolia.dart';

class AlgoliaService {
  static Algolia? _algoliaInstance;

  // Replace with your Algolia credentials
  static Algolia get algolia {
    if (_algoliaInstance != null) return _algoliaInstance!;
    
    _algoliaInstance = const Algolia.init(
      applicationId: 'WYSUTH4RJZ', // Replace with your App ID
      apiKey: '057685d462a6909bd9f007a2b0c898df',       // Replace with your API Key
    );
    return _algoliaInstance!;
  }

  // Search stories
  static Future<List<Map<String, dynamic>>> searchStories(String query) async {
    AlgoliaQuery algoliaQuery = algolia.instance.index('lumina_stories').query(query);
    AlgoliaQuerySnapshot querySnapshot = await algoliaQuery.getObjects();
    
    return querySnapshot.hits
        .map((hit) => {
              'id': hit.objectID,
              ...hit.data,
            })
        .toList();
  }

  // Filter stories by theme
  static Future<List<Map<String, dynamic>>> filterByTheme(String theme) async {
    AlgoliaQuery algoliaQuery = algolia.instance.index('lumina_stories').filters('themes:$theme');
    AlgoliaQuerySnapshot querySnapshot = await algoliaQuery.getObjects();
    
    return querySnapshot.hits
        .map((hit) => {
              'id': hit.objectID,
              ...hit.data,
            })
        .toList();
  }

  // Filter stories by country
  static Future<List<Map<String, dynamic>>> filterByCountry(String country) async {
    AlgoliaQuery algoliaQuery = algolia.instance.index('lumina_stories').filters('country:$country');
    AlgoliaQuerySnapshot querySnapshot = await algoliaQuery.getObjects();
    
    return querySnapshot.hits
        .map((hit) => {
              'id': hit.objectID,
              ...hit.data,
            })
        .toList();
  }

  // Combined search with filters
  static Future<List<Map<String, dynamic>>> searchWithFilters({
    String? query,
    String? theme,
    String? country,
  }) async {
    AlgoliaQuery algoliaQuery = algolia.instance.index('lumina_stories');
    
    if (query != null && query.isNotEmpty) {
      algoliaQuery = algoliaQuery.query(query);
    }
    
    List<String> filters = [];
    if (theme != null && theme.isNotEmpty) {
      filters.add('themes:$theme');
    }
    if (country != null && country.isNotEmpty) {
      filters.add('country:$country');
    }
    
    if (filters.isNotEmpty) {
      algoliaQuery = algoliaQuery.filters(filters.join(' AND '));
    }
    
    AlgoliaQuerySnapshot querySnapshot = await algoliaQuery.getObjects();
    
    return querySnapshot.hits
        .map((hit) => {
              'id': hit.objectID,
              ...hit.data,
            })
        .toList();
  }
}