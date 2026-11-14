class Magazine {
  final String id;
  final String title;
  final String subtitle;
  final String issue;
  final String coverImageUrl;
  final String pdfUrl;
  final String date;
  final int pageCount;
  final String category;

  const Magazine({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.issue,
    required this.coverImageUrl,
    required this.pdfUrl,
    required this.date,
    required this.pageCount,
    required this.category,
  });

  factory Magazine.fromMap(Map<String, dynamic> map) {
    return Magazine(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      subtitle: (map['subtitle'] ?? '').toString(),
      issue: (map['issue'] ?? 'Monthly Edition').toString(),
      coverImageUrl: (map['cover_image_url'] ?? map['coverImageUrl'] ?? '').toString(),
      pdfUrl: (map['pdf_url'] ?? map['pdfUrl'] ?? '').toString(),
      date: (map['date'] ?? '').toString(),
      pageCount: (map['page_count'] ?? map['pageCount'] ?? 16) as int,
      category: (map['category'] ?? 'Special Edition').toString(),
    );
  }

  /// From the API's magazine DTO (/v1/magazines).
  factory Magazine.fromApi(Map<String, dynamic> j) {
    final published = DateTime.tryParse((j['publishedAt'] ?? '').toString())?.toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return Magazine(
      id: (j['id'] ?? '').toString(),
      title: (j['title'] ?? '').toString(),
      subtitle: (j['subtitle'] ?? '').toString(),
      issue: (j['issue'] ?? '').toString(),
      coverImageUrl: (j['coverUrl'] ?? '').toString(),
      pdfUrl: (j['pdfUrl'] ?? '').toString(),
      date: published == null ? '' : '${published.day.toString().padLeft(2, '0')} ${months[published.month - 1]} ${published.year}',
      pageCount: (j['pageCount'] as int?) ?? 0,
      category: ((j['category'] ?? 'Special Edition').toString()).replaceFirst(RegExp(r'^Demo:\s*'), ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'issue': issue,
      'cover_image_url': coverImageUrl,
      'pdf_url': pdfUrl,
      'date': date,
      'page_count': pageCount,
      'category': category,
    };
  }
}
