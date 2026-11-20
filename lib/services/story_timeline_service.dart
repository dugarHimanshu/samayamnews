import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/demo_news.dart';
import '../models/news_article.dart';
import '../models/story_timeline.dart';

/// Central service managing chronological linking of related news articles
/// for both Readers, Editors, and Admins.
class StoryTimelineService extends ChangeNotifier {
  StoryTimelineService._();
  static final StoryTimelineService instance = StoryTimelineService._();

  static const String _kStorageKey = 'samayam_story_timelines_v1';
  final SupabaseClient _supabase = Supabase.instance.client;

  final Map<String, StoryTimeline> _timelinesById = {};
  bool _initialized = false;

  Map<String, StoryTimeline> get allTimelines => Map.unmodifiable(_timelinesById);

  /// Initializes the service and loads all saved story links.
  Future<void> load() async {
    if (_initialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString(_kStorageKey);

      if (rawJson != null && rawJson.isNotEmpty) {
        final decoded = jsonDecode(rawJson) as List<dynamic>;
        for (final item in decoded) {
          final timeline = StoryTimeline.fromMap(Map<String, dynamic>.from(item as Map));
          _timelinesById[timeline.id] = timeline;
        }
      }

      // If no timelines exist yet, seed with demo topic threads
      if (_timelinesById.isEmpty) {
        _seedDefaultDemoTimelines();
        await _saveToLocalPrefs();
      }

      // Try fetching from Supabase table if it exists
      try {
        final response = await _supabase.from('story_timelines').select();
        final rows = List<Map<String, dynamic>>.from(response as List);
        for (final row in rows) {
          final timeline = StoryTimeline.fromMap(row);
          _timelinesById[timeline.id] = timeline;
        }
        await _saveToLocalPrefs();
      } catch (_) {
        // Backend table is optional; local persistence acts as guaranteed storage
      }

      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('StoryTimelineService load error: $e');
    }
  }

  void _seedDefaultDemoTimelines() {
    // 1. ISRO Propulsion developments thread
    final isroTimeline = StoryTimeline(
      id: 'timeline_isro_propulsion',
      title: 'ISRO Next-Gen Engine & Deep Space Missions',
      mainArticleId: 'news_001_video',
      articleIds: ['news_001_video', 'news_isro_followup'],
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    );

    // 2. Hyderabad Mega Infrastructure Developments
    final hydTimeline = StoryTimeline(
      id: 'timeline_hyd_infrastructure',
      title: 'Hyderabad ₹9,400 Cr Infrastructure & Industrial Corridor',
      mainArticleId: 'news_001',
      articleIds: ['news_001', 'news_001_followup'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    _timelinesById[isroTimeline.id] = isroTimeline;
    _timelinesById[hydTimeline.id] = hydTimeline;
  }

  Future<void> _saveToLocalPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _timelinesById.values.map((t) => t.toMap()).toList();
      await prefs.setString(_kStorageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('StoryTimelineService save error: $e');
    }
  }

  /// Checks if an article belongs to any story timeline.
  bool hasLinkedStories(String articleId) {
    if (articleId.isEmpty) return false;
    return _timelinesById.values.any((timeline) => timeline.articleIds.contains(articleId));
  }

  /// Returns the timeline associated with an article, or null if none.
  StoryTimeline? getTimelineForArticle(String articleId) {
    if (articleId.isEmpty) return null;
    for (final timeline in _timelinesById.values) {
      if (timeline.articleIds.contains(articleId)) {
        return timeline;
      }
    }
    return null;
  }

  /// Resolves all articles linked in the same story topic, arranged in chronological order
  /// from the initial report to the latest follow-up developments.
  List<TimelineArticleItem> getChronologicalArticles(
    String articleId,
    List<NewsArticle> availableArticles,
  ) {
    final timeline = getTimelineForArticle(articleId);
    if (timeline == null || timeline.articleIds.isEmpty) return [];

    // Map all available articles by their ID with demoNews as universal fallback
    final articleMap = <String, NewsArticle>{};
    for (final a in demoNews) {
      articleMap[a.id] = a;
    }
    for (final a in availableArticles) {
      articleMap[a.id] = a;
    }

    final linkedArticles = <NewsArticle>[];
    for (final id in timeline.articleIds) {
      final found = articleMap[id];
      if (found != null) {
        linkedArticles.add(found);
      }
    }

    if (linkedArticles.isEmpty) return [];

    // Sort chronologically:
    // If article IDs match timeline.articleIds order, keep that order (or order by publication).
    // The mainArticleId is guaranteed to be the original report.
    final items = <TimelineArticleItem>[];
    for (int i = 0; i < linkedArticles.length; i++) {
      final art = linkedArticles[i];
      final isOriginal = (i == 0) || (art.id == timeline.mainArticleId);
      final isLatest = (i == linkedArticles.length - 1) && linkedArticles.length > 1;

      String phase;
      if (isOriginal) {
        phase = 'Original Story';
      } else if (isLatest) {
        phase = 'Latest Development';
      } else {
        phase = 'Follow-up #${i}';
      }

      items.add(
        TimelineArticleItem(
          article: art,
          chronologicalIndex: i + 1,
          isOriginalReport: isOriginal,
          isLatestDevelopment: isLatest,
          phaseLabel: phase,
        ),
      );
    }

    return items;
  }

  /// Links multiple articles together into a single chronological story timeline.
  Future<void> linkArticlesToMain({
    required String mainArticleId,
    required List<String> relatedArticleIds,
    required String topicTitle,
  }) async {
    // Collect all article IDs with mainArticleId as the anchor
    final orderedIds = <String>[mainArticleId];
    for (final id in relatedArticleIds) {
      if (!orderedIds.contains(id) && id.isNotEmpty) {
        orderedIds.add(id);
      }
    }

    // Check if a timeline already exists for this mainArticleId
    String timelineId = 'timeline_${mainArticleId}_${DateTime.now().millisecondsSinceEpoch}';
    final existing = getTimelineForArticle(mainArticleId);
    if (existing != null) {
      timelineId = existing.id;
    }

    final newTimeline = StoryTimeline(
      id: timelineId,
      title: topicTitle.trim().isNotEmpty ? topicTitle.trim() : 'Story Developments & Follow-ups',
      mainArticleId: mainArticleId,
      articleIds: orderedIds,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    _timelinesById[timelineId] = newTimeline;
    await _saveToLocalPrefs();

    // Sync to Supabase in background
    try {
      await _supabase.from('story_timelines').upsert(newTimeline.toMap());
    } catch (_) {}

    notifyListeners();
  }

  /// Removes a single article from its timeline.
  Future<void> unlinkArticleFromTimeline(String articleId) async {
    final timeline = getTimelineForArticle(articleId);
    if (timeline == null) return;

    final updatedList = List<String>.from(timeline.articleIds)..remove(articleId);

    if (updatedList.length <= 1) {
      // If only one or zero articles left, remove the timeline
      _timelinesById.remove(timeline.id);
      try {
        await _supabase.from('story_timelines').delete().eq('id', timeline.id);
      } catch (_) {}
    } else {
      final newMain = updatedList.contains(timeline.mainArticleId) ? timeline.mainArticleId : updatedList.first;
      final updatedTimeline = timeline.copyWith(
        articleIds: updatedList,
        mainArticleId: newMain,
      );
      _timelinesById[timeline.id] = updatedTimeline;
      try {
        await _supabase.from('story_timelines').upsert(updatedTimeline.toMap());
      } catch (_) {}
    }

    await _saveToLocalPrefs();
    notifyListeners();
  }

  /// Deletes an entire timeline.
  Future<void> deleteTimeline(String timelineId) async {
    _timelinesById.remove(timelineId);
    await _saveToLocalPrefs();
    try {
      await _supabase.from('story_timelines').delete().eq('id', timelineId);
    } catch (_) {}
    notifyListeners();
  }
}
