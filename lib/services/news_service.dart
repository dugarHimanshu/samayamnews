import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news_article.dart';

class NewsService {
  NewsService._();

  static final NewsService instance = NewsService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // FETCH ALL PUBLISHED NEWS
  // ============================================================
  //
  // DEMO / MOCKUP MODE:
  // We intentionally do NOT filter by state or district.
  //
  // The user's selected location is still passed around by the
  // app, but for now everyone sees the complete published feed.
  //
  // Later we can add:
  //
  //   .eq('state', state)
  //   .eq('district', district)
  //
  // when location-based filtering is ready.
  //
  // ============================================================

  Future<List<NewsArticle>> fetchNews({String? state, String? district}) async {
    try {
      debugPrint('========================================');
      debugPrint('FETCHING ALL PUBLISHED NEWS');
      debugPrint('Selected state: $state');
      debugPrint('Selected district: $district');
      debugPrint('User: ${_client.auth.currentUser?.id ?? 'guest'}');
      debugPrint('========================================');

      final response = await _client
          .from('news_articles')
          .select()
          .order('published_at', ascending: false);

      final rows = List<Map<String, dynamic>>.from(response as List);

      debugPrint('NEWS ROWS RETURNED: ${rows.length}');

      return rows.map((row) => NewsArticle.fromMap(row)).toList();
    } on PostgrestException catch (e) {
      debugPrint('========================================');
      debugPrint('NEWS FETCH ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('CODE: ${e.code}');
      debugPrint('DETAILS: ${e.details}');
      debugPrint('HINT: ${e.hint}');
      debugPrint('========================================');

      throw Exception('We could not load the latest news.');
    } catch (e) {
      debugPrint('NEWS FETCH UNKNOWN ERROR: $e');

      throw Exception('We could not load the latest news.');
    }
  }
}