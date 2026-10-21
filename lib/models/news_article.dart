class NewsArticle {
  final String id;
  final String title;
  final String description;
  final String category;
  final String author;
  final String source;
  final String publishedAt;
  final String imageUrl;
  final String location;
  final String content;

  const NewsArticle({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.source,
    required this.publishedAt,
    required this.imageUrl,
    required this.location,
    required this.content,
  });

  // ============================================================
  // SUPABASE -> MODEL
  // ============================================================

  factory NewsArticle.fromMap(Map<String, dynamic> map) {
    final state = (map['state'] ?? '').toString().trim();

    final district = (map['district'] ?? '').toString().trim();

    final city = (map['city'] ?? '').toString().trim();

    final region = (map['region'] ?? '').toString().trim();

    final village = (map['village'] ?? '').toString().trim();

    // Build a readable location string without requiring
    // a dedicated location column in news_articles.
    final locationParts = <String>[];

    if (village.isNotEmpty) {
      locationParts.add(village);
    }

    if (region.isNotEmpty) {
      locationParts.add(region);
    }

    if (city.isNotEmpty) {
      locationParts.add(city);
    }

    if (district.isNotEmpty) {
      locationParts.add(district);
    }

    if (state.isNotEmpty) {
      locationParts.add(state);
    }

    return NewsArticle(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      category: (map['category'] ?? '').toString(),
      author: (map['author'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      publishedAt: _formatPublishedAt(map['published_at']),
      imageUrl: (map['image_url'] ?? '').toString(),
      location: locationParts.join(' • '),
      content: (map['content'] ?? '').toString(),
    );
  }

  // ============================================================
  // DATE FORMATTING
  // ============================================================

  static String _formatPublishedAt(dynamic value) {
    if (value == null) {
      return '';
    }

    final raw = value.toString().trim();

    if (raw.isEmpty) {
      return '';
    }

    try {
      final date = DateTime.parse(raw).toLocal();

      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return raw;
    }
  }
}