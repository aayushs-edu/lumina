import 'package:algolia/algolia.dart';

class AlgoliaService {
  static Algolia? _algoliaInstance;

  // Replace with your Algolia credentials
  static Algolia get algolia {
    if (_algoliaInstance != null) return _algoliaInstance!;
    
    _algoliaInstance = const Algolia.init(
      applicationId: 'WYSUTH4RJZ', // Your App ID
      apiKey: '057685d462a6909bd9f007a2b0c898df', // Your API Key
    );
    return _algoliaInstance!;
  }

  // Basic search stories
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

  // Advanced search with multiple filters
  static Future<List<Map<String, dynamic>>> searchWithMultipleFilters({
    String? query,
    List<String>? themes,
    List<String>? countries,
  }) async {
    AlgoliaQuery algoliaQuery = algolia.instance.index('lumina_stories');
    
    if (query != null && query.isNotEmpty) {
      algoliaQuery = algoliaQuery.query(query);
    }
    
    // Build filters based on selected themes and countries
    List<String> filters = [];
    
    // Add theme filters
    if (themes != null && themes.isNotEmpty) {
      List<String> themeFilters = themes.map((theme) => 'themes:"${theme.replaceAll('"', '').trim()}"').toList();
      String themeFilterString = '(${themeFilters.join(' OR ')})';
      filters.add(themeFilterString);
    }
    
    // Add country filters
    if (countries != null && countries.isNotEmpty) {
      List<String> countryFilters = countries.map((country) => 'country:"${country.replaceAll('"', '').trim()}"').toList();
      String countryFilterString = '(${countryFilters.join(' OR ')})';
      filters.add(countryFilterString);
    }
    
    // If we have filters, apply them
    if (filters.isNotEmpty) {
      String filterString = filters.join(' AND ');
      algoliaQuery = algoliaQuery.filters(filterString);
    }
    
    // Execute the search
    AlgoliaQuerySnapshot querySnapshot = await algoliaQuery.getObjects();
    
    return querySnapshot.hits
        .map((hit) => {
              'id': hit.objectID,
              ...hit.data,
            })
        .toList();
  }
  
  // Legacy methods for backward compatibility
  static Future<List<Map<String, dynamic>>> filterByTheme(String theme) async {
    return searchWithMultipleFilters(themes: [theme]);
  }

  static Future<List<Map<String, dynamic>>> filterByCountry(String country) async {
    return searchWithMultipleFilters(countries: [country]);
  }

  static Future<List<Map<String, dynamic>>> searchWithFilters({
    String? query,
    String? theme,
    String? country,
  }) async {
    return searchWithMultipleFilters(
      query: query,
      themes: theme != null ? [theme] : null,
      countries: country != null ? [country] : null,
    );
  }
}