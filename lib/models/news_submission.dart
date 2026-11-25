/// A story submitted by a reporter, as returned by the API
/// (/v1/me/submissions, /v1/editor/queue).
class NewsSubmission {
  final String? id; // null until the API creates it
  final String submitterId;
  final String title;
  final String description; // summary
  final String category; // display name (English)
  final String author;
  final String source;
  final String content; // body
  final String? imageUrl; // processed cover image (medium) for display
  final String? coverMediaId; // uploaded image id sent with a new submission

  // Location by display name (English, LGD)
  final String state;
  final String district;
  final String? region; // mandal
  final String? village;

  final String status; // pending / in_review / published / rejected
  final DateTime? submittedAt;

  // API-only fields
  final int version;
  final String? rejectionReason;
  final bool claimedByMe;
  final String? claimedByName;
  final String? relatedArticleId; // follow-up link chosen by the editor
  final String? relatedAnchor;

  const NewsSubmission({
    this.id,
    required this.submitterId,
    required this.title,
    required this.description,
    required this.category,
    required this.author,
    required this.source,
    required this.content,
    this.imageUrl,
    this.coverMediaId,
    required this.state,
    required this.district,
    this.region,
    this.village,
    this.status = 'pending',
    this.submittedAt,
    this.version = 1,
    this.rejectionReason,
    this.claimedByMe = false,
    this.claimedByName,
    this.relatedArticleId,
    this.relatedAnchor,
  });

  factory NewsSubmission.fromApi(Map<String, dynamic> j) {
    final loc = Map<String, dynamic>.from((j['location'] ?? const {}) as Map);
    String? name(String key) => (loc[key] is Map) ? loc[key]['nameEn']?.toString() : null;
    final cat = (j['category'] is Map) ? Map<String, dynamic>.from(j['category'] as Map) : const <String, dynamic>{};
    final cover = (j['coverImage'] is Map) ? Map<String, dynamic>.from(j['coverImage'] as Map) : const <String, dynamic>{};
    final claim = (j['claim'] is Map) ? Map<String, dynamic>.from(j['claim'] as Map) : null;
    return NewsSubmission(
      id: j['id']?.toString(),
      submitterId: (j['submitterId'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      description: (j['summary'] ?? '').toString(),
      category: (cat['nameEn'] ?? '').toString(),
      author: (j['authorName'] ?? '').toString(),
      source: (j['source'] ?? '').toString(),
      content: (j['body'] ?? '').toString(),
      imageUrl: cover['medium']?.toString(),
      coverMediaId: j['coverMediaId']?.toString(),
      state: name('state') ?? '',
      district: name('district') ?? '',
      region: name('mandal'),
      village: name('village'),
      status: (j['status'] ?? 'pending').toString(),
      submittedAt: DateTime.tryParse((j['createdAt'] ?? '').toString())?.toLocal(),
      version: (j['version'] as int?) ?? 1,
      rejectionReason: j['rejectionReason']?.toString(),
      claimedByMe: claim?['byMe'] == true,
      claimedByName: claim?['editorName']?.toString(),
      relatedArticleId: j['relatedArticleId']?.toString(),
      relatedAnchor: j['relatedAnchor']?.toString(),
    );
  }
}
