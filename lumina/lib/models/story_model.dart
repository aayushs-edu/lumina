class Story {
  final String id;
  final String title;
  final String story;
  final String country;
  final List<String> themes;
  final List<String> keywords;
  final int likes;
  final int reports;
  final String userId;
  final String timestamp;

  Story({
    required this.id,
    required this.title,
    required this.story,
    required this.country,
    required this.themes,
    required this.keywords,
    required this.likes,
    required this.reports,
    required this.userId,
    required this.timestamp,
  });

  factory Story.fromMap(Map<String, dynamic> map) {
    return Story(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      story: map['story'] ?? '',
      country: map['country'] ?? '',
      themes: List<String>.from(map['themes'] ?? []),
      keywords: List<String>.from(map['keywords'] ?? []),
      likes: map['likes'] ?? 0,
      reports: map['reports'] ?? 0,
      userId: map['userId'] ?? 'anonymous',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'story': story,
      'country': country,
      'themes': themes,
      'keywords': keywords,
      'likes': likes,
      'reports': reports,
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}