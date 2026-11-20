import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/news_submission.dart';

// Handles everything related to submitting news: checking the
// user's role, checking today's usage, uploading the image,
// inserting the submission, and fetching a user's own submissions.
class SubmissionService {
  final SupabaseClient _client = Supabase.instance.client;

  // Returns the current logged-in user's role from `profiles`.
  // Returns null if nobody is logged in (guest).
  Future<String?> getCurrentUserRole() async {
    final user = _client.auth.currentUser;
    if (user == null) return null; // guest, not logged in

    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    return response['role'] as String?;
  }

  // Returns how many submissions the current freelancer has made
  // today, out of 10. Employees/editors/admins don't have a limit,
  // so this only matters for the "7/10" progress UI for freelancers.
  Future<int> getTodaySubmissionCount() async {
    final user = _client.auth.currentUser;
    if (user == null) return 0;

    final today = DateTime.now().toIso8601String().substring(
      0,
      10,
    ); // YYYY-MM-DD

    final response = await _client
        .from('submission_daily_usage')
        .select('submission_count')
        .eq('user_id', user.id)
        .eq('usage_date', today)
        .maybeSingle(); // no row yet today = 0 submissions so far

    if (response == null) return 0;
    return response['submission_count'] as int;
  }

  // Uploads an image or video to the Supabase storage bucket and
  // returns its public URL, ready to store as image_url.
  Future<String> uploadMedia(File mediaFile, {bool isVideo = false}) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to upload media.');
    }

    final ext = mediaFile.path.split('.').last.toLowerCase();
    final fileName = '${user.id}_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final bucket = isVideo ? 'news-videos' : 'news-images';

    try {
      await _client.storage.from(bucket).upload(fileName, mediaFile);
      return _client.storage.from(bucket).getPublicUrl(fileName);
    } catch (_) {
      if (isVideo) {
        // If news-videos bucket is not configured, fall back to news-images
        await _client.storage.from('news-images').upload(fileName, mediaFile);
        return _client.storage.from('news-images').getPublicUrl(fileName);
      }
      rethrow;
    }
  }

  // Uploads an image to the "news-images" storage bucket and
  // returns its public URL, ready to store as image_url.
  Future<String> uploadImage(File imageFile) => uploadMedia(imageFile, isVideo: false);

  // Submits a news story. We always stamp submitter_id with the
  // CURRENT logged-in user here — never trust whatever the caller
  // set on the NewsSubmission object — so the form doesn't need to
  // fetch/track the user id itself.
  //
  // Supabase enforces the 10/day limit for freelancers via a
  // database trigger; if that fires, we turn it into a friendly
  // message instead of a raw Postgres error.
  Future<void> submitNews(NewsSubmission submission) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('You must be logged in to submit a story.');
    }

    final insertMap = submission.toInsertMap();
    insertMap['submitter_id'] =
        user.id; // always overwrite with the real user id

    try {
      await _client.from('news_submissions').insert(insertMap);
    } on PostgrestException catch (e) {
      if (e.message.contains('Daily submission limit reached')) {
        throw Exception(
          'Daily submission limit reached. You can submit again tomorrow.',
        );
      }
      rethrow; // any other database error, let it surface as-is
    }
  }

  // Fetches the current user's own past submissions, newest first.
  // Used for a "My Submissions" screen so freelancers/employees can
  // track status and see rejection feedback.
  Future<List<NewsSubmission>> fetchMySubmissions() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('news_submissions')
        .select()
        .eq('submitter_id', user.id)
        .order('submitted_at', ascending: false);

    return (response as List)
        .map((row) => NewsSubmission.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  // Fetches feedback for a rejected submission, using the public
  // view so the editor's identity is never exposed to the submitter.
  Future<String?> fetchRejectionFeedback(String submissionId) async {
    final response = await _client
        .from('submission_feedback_public')
        .select('reason')
        .eq('submission_id', submissionId)
        .maybeSingle();

    return response?['reason'] as String?;
  }
}