import 'news_article.dart';

/// Represents a chronological thread of related news articles covering
/// an evolving news story over days or weeks.
class StoryTimeline {
  final String id;
  final String title;
  final String mainArticleId;
  final List<String> articleIds;
  final DateTime createdAt;

  const StoryTimeline({
    required this.id,
    required this.title,
    required this.mainArticleId,
    required this.articleIds,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'main_article_id': mainArticleId,
      'article_ids': articleIds,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StoryTimeline.fromMap(Map<String, dynamic> map) {
    return StoryTimeline(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? 'Related Developments',
      mainArticleId: map['main_article_id']?.toString() ?? '',
      articleIds: (map['article_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  StoryTimeline copyWith({
    String? id,
    String? title,
    String? mainArticleId,
    List<String>? articleIds,
    DateTime? createdAt,
  }) {
    return StoryTimeline(
      id: id ?? this.id,
      title: title ?? this.title,
      mainArticleId: mainArticleId ?? this.mainArticleId,
      articleIds: articleIds ?? this.articleIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// A helper class representing an article with its position and role in the chronological timeline.
class TimelineArticleItem {
  final NewsArticle article;
  final int chronologicalIndex;
  final bool isOriginalReport;
  final bool isLatestDevelopment;
  final String phaseLabel;

  const TimelineArticleItem({
    required this.article,
    required this.chronologicalIndex,
    required this.isOriginalReport,
    required this.isLatestDevelopment,
    required this.phaseLabel,
  });
}
