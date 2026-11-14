import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/news_article.dart';
import 'api_client.dart';

/// Saved (bookmarked) articles, keyed by article id.
/// Always kept on the device (works for guests and offline); when signed in it
/// is also synced to the account through /v1/me/bookmarks.
class SavedNewsStore extends ChangeNotifier {
  SavedNewsStore._();

  static final SavedNewsStore instance = SavedNewsStore._();

  static const String _storageKey = 'saved_articles_v2';

  final Map<String, NewsArticle> _saved = {}; // id → article snapshot
  bool _loaded = false;

  bool get loaded => _loaded;
  Set<String> get savedIds => Set.unmodifiable(_saved.keys);
  List<NewsArticle> get savedArticles => _saved.values.toList().reversed.toList();

  bool isSaved(String articleId) => _saved.containsKey(articleId);

  bool get _signedIn => Supabase.instance.client.auth.currentSession != null;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    for (final raw in prefs.getStringList(_storageKey) ?? const []) {
      try {
        final a = NewsArticle.fromCacheJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
        if (a.id.isNotEmpty) _saved[a.id] = a;
      } catch (_) {}
    }
    _loaded = true;
    notifyListeners();
    if (_signedIn) await syncFromServer();
  }

  /// Pulls the account's bookmarks (signed-in users) and merges them in.
  Future<void> syncFromServer() async {
    try {
      final res = await ApiClient.instance.get('/me/bookmarks', query: {'limit': 50}) as Map;
      for (final item in res['items'] as List) {
        final a = NewsArticle.fromApi(Map<String, dynamic>.from((item as Map)['article'] as Map));
        _saved[a.id] = a;
      }
      await _persist();
      notifyListeners();
    } catch (e) {
      debugPrint('Bookmark sync failed: $e');
    }
  }

  Future<void> toggle(NewsArticle article) async {
    if (article.id.isEmpty) return;
    final nowSaved = !_saved.containsKey(article.id);
    if (nowSaved) {
      _saved[article.id] = article;
    } else {
      _saved.remove(article.id);
    }
    notifyListeners();
    await _persist();
    if (_signedIn) {
      try {
        if (nowSaved) {
          await ApiClient.instance.put('/me/bookmarks/${article.id}');
        } else {
          await ApiClient.instance.delete('/me/bookmarks/${article.id}');
        }
      } catch (e) {
        debugPrint('Bookmark sync failed: $e');
      }
    }
  }

  Future<void> remove(String articleId) async {
    final a = _saved[articleId];
    if (a != null) await toggle(a);
  }

  Future<void> clear() async {
    _saved.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _saved.values.map((a) => jsonEncode(a.toCacheJson())).toList());
  }
}
