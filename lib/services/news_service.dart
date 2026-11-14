import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/advertisement.dart';
import '../models/magazine.dart';
import '../models/news_article.dart';
import 'api_client.dart';
import 'location_repository.dart';

/// One page of the home feed: NewsArticle / AdvertisementItem / Magazine items, in display order.
class FeedPage {
  final List<Object> items;
  final String? nextCursor;
  const FeedPage(this.items, this.nextCursor);

  List<NewsArticle> get articles => items.whereType<NewsArticle>().toList();
}

class NewsService {
  NewsService._();
  static final NewsService instance = NewsService._();

  final ApiClient _api = ApiClient.instance;

  int? districtIdFor(String? state, String? district) {
    final repo = LocationRepository.instance;
    return (repo.district(state, district) ?? repo.districtAnywhere(district))?.id;
  }

  /// Home feed: the selected district's last-48h news first, then everything else newest-first.
  Future<FeedPage> fetchFeed({String? state, String? district, String? cursor, int limit = 20}) async {
    try {
      final res = await _api.get('/feed', query: {
        'district': districtIdFor(state, district),
        'cursor': cursor,
        'limit': limit,
      }) as Map;
      final items = <Object>[];
      for (final raw in res['items'] as List) {
        final item = Map<String, dynamic>.from(raw as Map);
        switch (item['type']) {
          case 'article':
            final a = NewsArticle.fromApi(Map<String, dynamic>.from(item['article'] as Map));
            items.add(a);
            NewsRepository.instance._remember([a]);
          case 'ad':
            items.add(AdvertisementItem.fromApi(Map<String, dynamic>.from(item['ad'] as Map)));
          case 'magazine':
            items.add(Magazine.fromApi(Map<String, dynamic>.from(item['magazine'] as Map)));
        }
      }
      return FeedPage(items, res['nextCursor'] as String?);
    } on ApiException catch (e) {
      debugPrint('Feed load failed: $e');
      throw Exception('We could not load the latest news.');
    }
  }

  /// Latest article id for "new stories" checks (cheap, CDN-cached).
  Future<String?> latestId({String? state, String? district}) async {
    final res = await _api.get('/feed/head', query: {'district': districtIdFor(state, district)}) as Map;
    return res['latestId'] as String?;
  }

  /// Back-compat: articles only, first page.
  Future<List<NewsArticle>> fetchNews({String? state, String? district}) async =>
      (await fetchFeed(state: state, district: district, limit: 50)).articles;
}

/// App-wide cache of articles fetched from the API. Screens that used to filter
/// the bundled demo list now filter this, and listen for updates.
class NewsRepository extends ChangeNotifier {
  NewsRepository._();
  static final NewsRepository instance = NewsRepository._();

  final ApiClient _api = ApiClient.instance;
  final Map<String, NewsArticle> _byId = {};
  final Map<String, NewsArticle> _details = {};
  List<Magazine> _magazines = const [];
  bool loading = false;

  /// Everything fetched so far, newest first.
  List<NewsArticle> get articles {
    final list = _byId.values.toList();
    list.sort((a, b) => (b.publishedAtTime ?? DateTime(0)).compareTo(a.publishedAtTime ?? DateTime(0)));
    return list;
  }

  List<Magazine> get magazines => _magazines;

  void _remember(Iterable<NewsArticle> list) {
    for (final a in list) {
      if (a.id.isNotEmpty) _byId[a.id] = a;
    }
  }

  Future<List<NewsArticle>> _list(String path, Map<String, dynamic> query) async {
    final res = await _api.get(path, query: query) as Map;
    final items = (res['items'] as List).map((e) => NewsArticle.fromApi(Map<String, dynamic>.from(e as Map))).toList();
    _remember(items);
    notifyListeners();
    return items;
  }

  Future<void> refreshLatest() async {
    loading = true;
    try {
      await _list('/articles', {'limit': 50});
    } catch (e) {
      debugPrint('refreshLatest failed: $e');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<List<NewsArticle>> loadCategory(String slug) => _guard(() => _list('/articles', {'category': slug, 'limit': 50}));

  Future<List<NewsArticle>> loadDistrict(int districtId) =>
      _guard(() => _list('/articles', {'district': districtId, 'limit': 50}));

  Future<List<NewsArticle>> search(String q) async {
    if (q.trim().length < 2) return const [];
    return _guard(() => _list('/search', {'q': q.trim(), 'limit': 30}));
  }

  Future<List<NewsArticle>> _guard(Future<List<NewsArticle>> Function() f) async {
    try {
      return await f();
    } catch (e) {
      debugPrint('News load failed: $e');
      return const [];
    }
  }

  /// Full article including body (cached).
  Future<NewsArticle?> getArticle(String id) async {
    if (_details.containsKey(id)) return _details[id];
    try {
      final res = await _api.get('/articles/$id') as Map;
      final a = NewsArticle.fromApi(Map<String, dynamic>.from(res));
      _details[id] = a;
      _remember([a]);
      return a;
    } catch (e) {
      debugPrint('Article $id load failed: $e');
      return null;
    }
  }

  Future<List<Magazine>> loadMagazines() async {
    try {
      final res = await _api.get('/magazines') as Map;
      _magazines = (res['items'] as List).map((e) => Magazine.fromApi(Map<String, dynamic>.from(e as Map))).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Magazines load failed: $e');
    }
    return _magazines;
  }
}

/// Batches view / share / ad events and sends them to /v1/events every 20 seconds
/// (or every 20 events), so analytics never cost one request per screen.
class Analytics {
  Analytics._();
  static final Analytics instance = Analytics._();

  final List<Map<String, String>> _queue = [];
  Timer? _timer;

  void track(String type, String id) {
    if (id.isEmpty) return;
    _queue.add({'type': type, 'id': id});
    if (_queue.length >= 20) {
      flush();
    } else {
      _timer ??= Timer(const Duration(seconds: 20), flush);
    }
  }

  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    if (_queue.isEmpty) return;
    final batch = List<Map<String, String>>.from(_queue);
    _queue.clear();
    try {
      await ApiClient.instance.post('/events', {'events': batch});
    } catch (_) {
      // analytics are best-effort
    }
  }
}
