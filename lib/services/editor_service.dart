// services/editor_service.dart
//
// Editor workflow through the API. Method names and the field maps the screens
// pass in are unchanged; they're translated to the API's shape here.

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news_article.dart';
import '../models/news_submission.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'category_repository.dart';
import 'location_repository.dart';
import 'news_service.dart';
import 'submission_service.dart';

class EditorService {
  final ApiClient _api = ApiClient.instance;

  // Latest version per submission (optimistic locking) and the claim info from the last queue load.
  static final Map<String, int> _versions = {};
  static final Map<String, NewsSubmission> _lastQueue = {};

  String get _editorId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('Authentication required. Please sign in again.');
    return user.id;
  }

  Future<String?> getCurrentRole() async {
    try {
      return await AuthService.instance.getCurrentUserRole();
    } catch (_) {
      return null;
    }
  }

  Exception _wrap(ApiException e) => Exception(e.message);

  // ============================================================
  // SUBMISSION QUEUE
  // ============================================================

  Future<List<NewsSubmission>> fetchQueue() async {
    try {
      final out = <NewsSubmission>[];
      String? cursor;
      do {
        final res = await _api.get('/editor/queue', query: {'limit': 50, 'cursor': cursor}) as Map;
        out.addAll((res['items'] as List).map((e) => NewsSubmission.fromApi(Map<String, dynamic>.from(e as Map))));
        cursor = res['nextCursor'] as String?;
      } while (cursor != null && out.length < 500);
      _lastQueue
        ..clear()
        ..addEntries(out.where((s) => s.id != null).map((s) => MapEntry(s.id!, s)));
      for (final s in out) {
        if (s.id != null) _versions[s.id!] = s.version;
      }
      return out;
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  /// Active review locks in the shape the dashboard expects. Built from the claim info
  /// returned with the queue (no extra request).
  Future<List<Map<String, dynamic>>> fetchReviewsFor(List<String> submissionIds) async {
    final me = _editorId;
    return [
      for (final id in submissionIds)
        if (_lastQueue[id]?.claimedByName != null || _lastQueue[id]?.claimedByMe == true)
          {
            'submission_id': id,
            'editor_id': _lastQueue[id]!.claimedByMe ? me : 'other',
            'status': 'active',
            'profiles': {'full_name': _lastQueue[id]!.claimedByName},
          },
    ];
  }

  Future<Map<String, int>> fetchStats() async {
    try {
      final res = await _api.get('/editor/stats') as Map;
      return {
        'new': (res['pending'] as int?) ?? 0,
        'in_review': (res['in_review'] as int?) ?? 0,
        'approved_today': (res['published_today'] as int?) ?? 0,
        'rejected_today': (res['rejected_today'] as int?) ?? 0,
      };
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  // ============================================================
  // CLAIM / HEARTBEAT
  // ============================================================

  Future<void> claimSubmission(String submissionId) async {
    try {
      final res = await _api.post('/editor/submissions/$submissionId/claim') as Map;
      _versions[submissionId] = (res['version'] as int?) ?? 1;
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> touchActivity(String submissionId) async {
    try {
      await _api.post('/editor/submissions/$submissionId/heartbeat');
    } catch (_) {
      // Non-blocking heartbeat failure
    }
  }

  Future<void> releaseSubmission(String submissionId) async {
    try {
      await _api.post('/editor/submissions/$submissionId/release');
    } catch (_) {}
  }

  // ============================================================
  // DRAFT / PUBLISH / REJECT
  // ============================================================

  Future<void> saveDraft(String submissionId, Map<String, dynamic> edits) async {
    try {
      final res = await _api.patch('/editor/submissions/$submissionId', {
        'version': _versions[submissionId] ?? 1,
        'edits': await storyEditsFromFields(edits),
      }) as Map;
      _versions[submissionId] = (res['version'] as int?) ?? (_versions[submissionId] ?? 1) + 1;
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> publishSubmission(String submissionId, Map<String, dynamic> finalFields) async {
    try {
      await _api.post('/editor/submissions/$submissionId/publish', {
        'version': _versions[submissionId] ?? 1,
        'isBreaking': finalFields['is_breaking'] == true,
        'edits': await storyEditsFromFields(finalFields),
      });
      _versions.remove(submissionId);
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> rejectSubmission(String submissionId, String reason) async {
    try {
      await _api.post('/editor/submissions/$submissionId/reject', {'reason': reason});
      _versions.remove(submissionId);
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  // ============================================================
  // PUBLISHED ARTICLES
  // ============================================================

  Future<List<NewsArticle>> fetchPublishedNews() async {
    try {
      final res = await _api.get('/articles', query: {'limit': 50}) as Map;
      return (res['items'] as List).map((e) => NewsArticle.fromApi(Map<String, dynamic>.from(e as Map))).toList();
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  /// Full article (with body) for the edit screen.
  Future<NewsArticle?> fetchArticle(String articleId) async {
    try {
      final res = await _api.get('/editor/articles/$articleId') as Map;
      return NewsArticle.fromApi(Map<String, dynamic>.from(res));
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  Future<void> updatePublishedNews(String articleId, Map<String, dynamic> updates) async {
    try {
      await _api.patch('/editor/articles/$articleId', await storyEditsFromFields(updates));
      NewsRepository.instance.refreshLatest();
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  /// "Delete" unpublishes (soft delete) so it can be restored and the audit trail is kept.
  Future<void> deletePublishedNews(String articleId) async {
    try {
      await _api.post('/editor/articles/$articleId/unpublish');
    } on ApiException catch (e) {
      throw _wrap(e);
    }
  }

  /// Converts the screens' field map (title/description/content/category/state/district/region/village…)
  /// into the API's story fields with ids. Only keys present in [fields] are sent.
  static Future<Map<String, dynamic>> storyEditsFromFields(Map<String, dynamic> fields) async {
    final out = <String, dynamic>{};
    String? str(String k) {
      final v = fields[k]?.toString().trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    if (str('title') != null) out['title'] = str('title');
    if (str('description') != null) out['summary'] = str('description');
    if (str('content') != null) {
      out['body'] = str('content');
      out['language'] = SubmissionService.detectLanguage('${str('title') ?? ''} ${str('content')}');
    }
    if (str('author') != null) out['authorName'] = str('author');
    if (fields.containsKey('source')) out['source'] = str('source');
    if (str('category') != null) {
      await CategoryRepository.instance.init();
      final c = CategoryRepository.instance.byName(str('category'));
      if (c != null) out['categoryId'] = c.id;
    }
    if (str('state') != null && str('district') != null) {
      final loc = LocationRepository.instance;
      final state = loc.state(str('state'));
      final district = loc.district(str('state'), str('district'));
      if (state != null && district != null) {
        await loc.loadChildren(district.id);
        final mandal = loc.mandal(str('state'), str('district'), str('region'));
        if (mandal != null) await loc.loadChildren(mandal.id);
        final village = loc.village(str('state'), str('district'), str('region'), str('village'));
        out['stateId'] = state.id;
        out['districtId'] = district.id;
        out['mandalId'] = mandal?.id;
        out['villageId'] = village?.id;
      }
    }
    return out;
  }
}
