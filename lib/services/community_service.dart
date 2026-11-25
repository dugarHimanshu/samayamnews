import 'api_client.dart';

class NewsComment {
  final String id;
  final String userId;
  final String author;
  final String body;
  final DateTime createdAt;

  const NewsComment({required this.id, required this.userId, required this.author, required this.body, required this.createdAt});

  factory NewsComment.fromApi(Map<String, dynamic> j) => NewsComment(
        id: j['id'].toString(),
        userId: (j['userId'] ?? '').toString(),
        author: (j['author'] ?? 'Reader').toString(),
        body: (j['body'] ?? '').toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

/// A birthday / wedding-anniversary wishes poster.
class Wish {
  final String id;
  final String kind; // birthday | anniversary
  final String? photoUrl;
  final String recipientName;
  final String message;
  final String fromNames;
  final String status;
  final String? rejectionReason;
  final DateTime createdAt;

  const Wish({
    required this.id,
    required this.kind,
    this.photoUrl,
    required this.recipientName,
    required this.message,
    required this.fromNames,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  bool get isBirthday => kind == 'birthday';

  factory Wish.fromApi(Map<String, dynamic> j) => Wish(
        id: j['id'].toString(),
        kind: (j['kind'] ?? 'birthday').toString(),
        photoUrl: j['photoUrl']?.toString(),
        recipientName: (j['recipientName'] ?? '').toString(),
        message: (j['message'] ?? '').toString(),
        fromNames: (j['fromNames'] ?? '').toString(),
        status: (j['status'] ?? 'pending').toString(),
        rejectionReason: j['rejectionReason']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class CommunityService {
  CommunityService._();
  static final CommunityService instance = CommunityService._();

  final ApiClient _api = ApiClient.instance;

  // ---------------------------------------------------------------- comments

  Future<({List<NewsComment> items, String? nextCursor})> comments(String articleId, {String? cursor}) async {
    final res = await _api.get('/articles/$articleId/comments', query: {'cursor': cursor, 'limit': 30}) as Map;
    return (
      items: [for (final c in res['items'] as List) NewsComment.fromApi(Map<String, dynamic>.from(c as Map))],
      nextCursor: res['nextCursor'] as String?,
    );
  }

  Future<NewsComment> addComment(String articleId, String body) async =>
      NewsComment.fromApi(Map<String, dynamic>.from(await _api.post('/articles/$articleId/comments', {'body': body}) as Map));

  Future<void> deleteComment(String id) => _api.delete('/comments/$id');

  // ---------------------------------------------------------------- wishes

  Future<List<Wish>> wishes({String? kind}) async {
    final res = await _api.get('/wishes', query: {'kind': kind, 'limit': 50}) as Map;
    return [for (final w in res['items'] as List) Wish.fromApi(Map<String, dynamic>.from(w as Map))];
  }

  Future<List<Wish>> myWishes() async {
    final res = await _api.get('/me/wishes') as Map;
    return [for (final w in res['items'] as List) Wish.fromApi(Map<String, dynamic>.from(w as Map))];
  }

  Future<Wish> sendWish({
    required String kind,
    String? photoMediaId,
    required String recipientName,
    required String message,
    required String fromNames,
    int? districtId,
  }) async =>
      Wish.fromApi(Map<String, dynamic>.from(await _api.post('/wishes', {
        'kind': kind,
        if (photoMediaId != null) 'photoMediaId': photoMediaId,
        'recipientName': recipientName,
        'message': message,
        'fromNames': fromNames,
        if (districtId != null) 'districtId': districtId,
      }) as Map));

  Future<List<Wish>> wishQueue({String status = 'pending'}) async {
    final res = await _api.get('/editor/wishes', query: {'status': status, 'limit': 50}) as Map;
    return [for (final w in res['items'] as List) Wish.fromApi(Map<String, dynamic>.from(w as Map))];
  }

  Future<void> approveWish(String id) => _api.post('/editor/wishes/$id/review', {'decision': 'approve'});
  Future<void> rejectWish(String id, String reason) =>
      _api.post('/editor/wishes/$id/review', {'decision': 'reject', 'reason': reason});
  Future<void> deleteWish(String id) => _api.delete('/wishes/$id');
}
