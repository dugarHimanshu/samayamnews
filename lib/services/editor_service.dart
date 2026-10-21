// services/editor_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news_article.dart';
import '../models/news_submission.dart';

class EditorService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // CURRENT USER SESSION
  // ============================================================

  String get _editorId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('Authentication required. Please sign in again.');
    }

    return user.id;
  }

  // ============================================================
  // ROLE VERIFICATION
  // ============================================================

  Future<String?> getCurrentRole() async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) {
        return null;
      }

      final role = response['role'];

      return role?.toString().trim().toLowerCase();
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // SUBMISSION QUEUE
  // ============================================================

  Future<List<NewsSubmission>> fetchQueue() async {
    try {
      final response = await _client
          .from('news_submissions')
          .select()
          .inFilter('status', ['pending', 'in_review'])
          .order('submitted_at', ascending: true);

      return (response as List)
          .map((row) => NewsSubmission.fromMap(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error loading queue: ${e.message}');
    } catch (_) {
      throw Exception('Unable to load the submission queue.');
    }
  }

  // ============================================================
  // REVIEWS & LIVE AUDITS
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchReviewsFor(
    List<String> submissionIds,
  ) async {
    if (submissionIds.isEmpty) {
      return [];
    }

    try {
      final response = await _client
          .from('submission_reviews')
          .select('submission_id, editor_id, status, profiles(full_name)')
          .inFilter('submission_id', submissionIds);

      return List<Map<String, dynamic>>.from(response as List);
    } on PostgrestException catch (e) {
      throw Exception('Database error fetching reviews: ${e.message}');
    } catch (_) {
      throw Exception('Unable to load review information.');
    }
  }

  // ============================================================
  // DASHBOARD ANALYTICS & STATS
  // ============================================================

  Future<Map<String, int>> fetchStats() async {
    try {
      final today = DateTime.now().toIso8601String().substring(0, 10);

      final newCount = await _client
          .from('news_submissions')
          .select('id')
          .eq('status', 'pending')
          .count(CountOption.exact);

      final inReviewCount = await _client
          .from('news_submissions')
          .select('id')
          .eq('status', 'in_review')
          .count(CountOption.exact);

      final approvedToday = await _client
          .from('news_submissions')
          .select('id')
          .eq('status', 'published')
          .gte('updated_at', today)
          .count(CountOption.exact);

      final rejectedToday = await _client
          .from('news_submissions')
          .select('id')
          .eq('status', 'rejected')
          .gte('updated_at', today)
          .count(CountOption.exact);

      return {
        'new': newCount.count,
        'in_review': inReviewCount.count,
        'approved_today': approvedToday.count,
        'rejected_today': rejectedToday.count,
      };
    } on PostgrestException catch (e) {
      throw Exception('Database error loading stats: ${e.message}');
    } catch (_) {
      throw Exception('Unable to load editor statistics.');
    }
  }

  // ============================================================
  // CLAIM SUBMISSION LOCK
  // ============================================================

  Future<void> claimSubmission(String submissionId) async {
    try {
      final existing = await _client
          .from('submission_reviews')
          .select('id')
          .eq('submission_id', submissionId)
          .eq('editor_id', _editorId)
          .eq('status', 'active')
          .maybeSingle();

      if (existing == null) {
        await _client.from('submission_reviews').insert({
          'submission_id': submissionId,
          'editor_id': _editorId,
          'status': 'active',
        });
      }

      await _client
          .from('news_submissions')
          .update({'status': 'in_review'})
          .eq('id', submissionId);
    } on PostgrestException catch (e) {
      throw Exception(
        'Permission or database error claiming story: ${e.message}',
      );
    } catch (_) {
      throw Exception('Unable to open this story for review.');
    }
  }

  // ============================================================
  // TOUCH REVIEW ACTIVITY HEARTBEAT
  // ============================================================

  Future<void> touchActivity(String submissionId) async {
    try {
      await _client
          .from('submission_reviews')
          .update({'last_activity_at': DateTime.now().toIso8601String()})
          .eq('submission_id', submissionId)
          .eq('editor_id', _editorId)
          .eq('status', 'active');
    } catch (_) {
      // Non-blocking heartbeat failure
    }
  }

  // ============================================================
  // SAVE SUBMISSION DRAFT (LIVE UPDATE)
  // ============================================================

  Future<void> saveDraft(
    String submissionId,
    Map<String, dynamic> edits,
  ) async {
    try {
      final response = await _client
          .from('news_submissions')
          .update(edits)
          .eq('id', submissionId)
          .select('id')
          .maybeSingle();

      if (response == null) {
        throw Exception('Draft record could not be found or updated.');
      }

      await touchActivity(submissionId);
    } on PostgrestException catch (e) {
      throw Exception('Database error saving draft: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('We could not save the draft.');
    }
  }

  // ============================================================
  // PUBLISH SUBMISSION (MOVE TO LIVE FEED)
  // ============================================================

  Future<void> publishSubmission(
    String submissionId,
    Map<String, dynamic> finalFields,
  ) async {
    try {
      final submissionResponse = await _client
          .from('news_submissions')
          .update({...finalFields, 'status': 'published'})
          .eq('id', submissionId)
          .select('id')
          .maybeSingle();

      if (submissionResponse == null) {
        throw Exception('Submission target not found for publication.');
      }

      await _client.from('news_articles').insert({
        'submission_id': submissionId,
        'title': finalFields['title'],
        'description': finalFields['description'],
        'category': finalFields['category'],
        'author': finalFields['author'],
        'source': finalFields['source'],
        'content': finalFields['content'],
        'image_url': finalFields['image_url'],
        'state': finalFields['state'],
        'district': finalFields['district'],
        'region': finalFields['region'],
        'village': finalFields['village'],
      });

      await _client
          .from('submission_reviews')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('submission_id', submissionId)
          .eq('editor_id', _editorId)
          .eq('status', 'active');
    } on PostgrestException catch (e) {
      throw Exception(
        'Database restriction prevented publishing: ${e.message}',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('We could not publish this story.');
    }
  }

  // ============================================================
  // REJECT SUBMISSION WITH FEEDBACK
  // ============================================================

  Future<void> rejectSubmission(String submissionId, String reason) async {
    try {
      final submissionResponse = await _client
          .from('news_submissions')
          .update({'status': 'rejected'})
          .eq('id', submissionId)
          .select('id')
          .maybeSingle();

      if (submissionResponse == null) {
        throw Exception('Submission target not found for rejection.');
      }

      await _client.from('submission_feedback').insert({
        'submission_id': submissionId,
        'editor_id': _editorId,
        'reason': reason,
      });

      await _client
          .from('submission_reviews')
          .update({
            'status': 'completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('submission_id', submissionId)
          .eq('editor_id', _editorId)
          .eq('status', 'active');
    } on PostgrestException catch (e) {
      throw Exception('Database restriction prevented rejection: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('We could not reject this story.');
    }
  }

  // ============================================================
  // FETCH PUBLISHED NEWS FEED
  // ============================================================

  Future<List<NewsArticle>> fetchPublishedNews() async {
    try {
      final response = await _client
          .from('news_articles')
          .select()
          .order('published_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response as List);

      return rows.map((row) => NewsArticle.fromMap(row)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Database error fetching live news: ${e.message}');
    } catch (_) {
      throw Exception('Unable to load published news.');
    }
  }

  // ============================================================
  // UPDATE PUBLISHED NEWS ARTICLE
  // ============================================================

  Future<void> updatePublishedNews(
    String articleId,
    Map<String, dynamic> updates,
  ) async {
    _editorId; // Authenticate user presence

    try {
      final response = await _client
          .from('news_articles')
          .update(updates)
          .eq('id', articleId)
          .select('id')
          .maybeSingle();

      if (response == null) {
        throw Exception('Published article not found or update blocked.');
      }
    } on PostgrestException catch (e) {
      throw Exception('RLS Policy or database restriction error: ${e.message}');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to update published news.');
    }
  }

  // ============================================================
  // DELETE PUBLISHED NEWS ARTICLE
  // ============================================================

  Future<void> deletePublishedNews(String articleId) async {
    _editorId; // Authenticate user presence

    try {
      final response = await _client
          .from('news_articles')
          .delete()
          .eq('id', articleId)
          .select('id')
          .maybeSingle();

      if (response == null) {
        throw Exception('Published article not found or delete blocked.');
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'RLS Policy or foreign key constraint error: ${e.message}',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Unable to delete published news.');
    }
  }
}
