class NewsArticle {
  final String id;
  final String title;
  final String description; // short summary shown in cards
  final String category; // display name (English)
  final String author;
  final String source;
  final String publishedAt; // dd/MM/yyyy for display
  final String imageUrl;
  final String location; // "village • mandal • district • state"
  final String content; // full body (empty in feed lists — load with NewsRepository.getArticle)

  // API fields
  final String categorySlug;
  final int? districtId;
  final String districtName;
  final String stateName;
  final String language;
  final bool isBreaking;
  final DateTime? publishedAtTime;
  final String thumbUrl;
  final String categoryTe;
  final String categoryHi;
  final int likeCount;
  final int commentCount;
  // Follow-up link: tapping [relatedAnchor] in the body opens [relatedArticleId].
  final String? relatedArticleId;
  final String? relatedAnchor;

  /// Category name in the reader's language (falls back to English).
  String categoryIn(String language) {
    final l = language.toLowerCase();
    if ((l.startsWith('te') || l == 'telugu') && categoryTe.isNotEmpty) return categoryTe;
    if ((l.startsWith('hi') || l == 'hindi') && categoryHi.isNotEmpty) return categoryHi;
    return category;
  }

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
    this.categorySlug = '',
    this.districtId,
    this.districtName = '',
    this.stateName = '',
    this.language = 'en',
    this.isBreaking = false,
    this.publishedAtTime,
    this.thumbUrl = '',
    this.categoryTe = '',
    this.categoryHi = '',
    this.likeCount = 0,
    this.commentCount = 0,
    this.relatedArticleId,
    this.relatedAnchor,
  });

  /// From the API's article DTO (/v1/feed, /v1/articles, /v1/articles/:id).
  factory NewsArticle.fromApi(Map<String, dynamic> j) {
    final loc = Map<String, dynamic>.from((j['location'] ?? const {}) as Map);
    String name(String key) => (loc[key] is Map) ? (loc[key]['nameEn'] ?? '').toString() : '';
    final parts = [name('village'), name('mandal'), name('district'), name('state')].where((p) => p.isNotEmpty);
    final cat = (j['category'] is Map) ? Map<String, dynamic>.from(j['category'] as Map) : const <String, dynamic>{};
    final image = (j['image'] is Map) ? Map<String, dynamic>.from(j['image'] as Map) : const <String, dynamic>{};
    final published = DateTime.tryParse((j['publishedAt'] ?? '').toString())?.toLocal();
    return NewsArticle(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: (j['summary'] ?? '').toString(),
      category: (cat['nameEn'] ?? '').toString(),
      author: (j['authorName'] ?? '').toString(),
      source: (j['source'] ?? '').toString(),
      publishedAt: published == null ? '' : _fmt(published),
      imageUrl: (image['medium'] ?? image['large'] ?? '').toString(),
      thumbUrl: (image['thumb'] ?? '').toString(),
      location: parts.join(' • '),
      content: (j['body'] ?? '').toString(),
      categorySlug: (cat['slug'] ?? '').toString(),
      districtId: (loc['district'] is Map) ? loc['district']['id'] as int? : null,
      districtName: name('district'),
      stateName: name('state'),
      language: (j['language'] ?? 'en').toString(),
      isBreaking: j['isBreaking'] == true,
      publishedAtTime: published,
      categoryTe: (cat['nameTe'] ?? '').toString(),
      categoryHi: (cat['nameHi'] ?? '').toString(),
      likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (j['commentCount'] as num?)?.toInt() ?? 0,
      relatedArticleId: j['relatedArticleId']?.toString(),
      relatedAnchor: j['relatedAnchor']?.toString(),
    );
  }

  /// Local cache format (saved articles survive offline / for guests).
  Map<String, dynamic> toCacheJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'author': author,
        'source': source,
        'publishedAt': publishedAt,
        'imageUrl': imageUrl,
        'location': location,
        'categorySlug': categorySlug,
        'districtName': districtName,
        'stateName': stateName,
      };

  factory NewsArticle.fromCacheJson(Map<String, dynamic> j) => NewsArticle(
        id: (j['id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        category: (j['category'] ?? '').toString(),
        author: (j['author'] ?? '').toString(),
        source: (j['source'] ?? '').toString(),
        publishedAt: (j['publishedAt'] ?? '').toString(),
        imageUrl: (j['imageUrl'] ?? '').toString(),
        location: (j['location'] ?? '').toString(),
        content: '',
        categorySlug: (j['categorySlug'] ?? '').toString(),
        districtName: (j['districtName'] ?? '').toString(),
        stateName: (j['stateName'] ?? '').toString(),
      );

  NewsArticle withContent(String body) => NewsArticle(
        id: id,
        title: title,
        description: description,
        category: category,
        author: author,
        source: source,
        publishedAt: publishedAt,
        imageUrl: imageUrl,
        location: location,
        content: body,
        categorySlug: categorySlug,
        districtId: districtId,
        districtName: districtName,
        stateName: stateName,
        language: language,
        isBreaking: isBreaking,
        publishedAtTime: publishedAtTime,
        thumbUrl: thumbUrl,
        categoryTe: categoryTe,
        categoryHi: categoryHi,
        likeCount: likeCount,
        commentCount: commentCount,
        relatedArticleId: relatedArticleId,
        relatedAnchor: relatedAnchor,
      );

  static String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
