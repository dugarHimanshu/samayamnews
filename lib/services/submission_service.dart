import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/news_submission.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'category_repository.dart';
import 'location_repository.dart';

/// Reporter-side API calls: role/quota, image upload, submitting, and "my submissions".
class SubmissionService {
  final ApiClient _api = ApiClient.instance;
  final Map<String, String?> _reasons = {};

  Future<String?> getCurrentUserRole() => AuthService.instance.getCurrentUserRole();

  /// Today's submissions (IST) for freelancers; 0 for roles without a limit.
  Future<int> getTodaySubmissionCount() async {
    final res = await _api.get('/me/submission-quota') as Map;
    return (res['used'] as int?) ?? 0;
  }

  /// Uploads an image straight to storage through a signed URL issued by the API,
  /// then asks the API to process it (resize to WebP, strip GPS/EXIF).
  /// Returns the media id to send as `coverMediaId`.
  Future<String> uploadImage(Uint8List bytes, {required String fileName}) async {
    final lower = fileName.toLowerCase();
    final contentType = lower.endsWith('.png')
        ? 'image/png'
        : lower.endsWith('.webp')
            ? 'image/webp'
            : lower.endsWith('.heic')
                ? 'image/heic'
                : 'image/jpeg';
    final ticket = await _api.post('/uploads', {
      'kind': 'image',
      'contentType': contentType,
      'sizeBytes': bytes.length,
    }) as Map;
    final res = await http.put(
      Uri.parse(ticket['uploadUrl'].toString()),
      headers: {'content-type': contentType},
      body: bytes,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Image upload failed (${res.statusCode}). Please try again.');
    }
    final mediaId = ticket['mediaId'].toString();
    await _api.post('/uploads/$mediaId/complete');
    return mediaId;
  }

  /// Submits a story. Location/category names are converted to the API's ids.
  Future<void> submitNews(NewsSubmission s) async {
    await CategoryRepository.instance.init();
    final loc = LocationRepository.instance;
    final state = loc.state(s.state);
    final district = loc.district(s.state, s.district);
    if (state == null || district == null) throw Exception('Please choose a valid state and district.');
    await loc.loadChildren(district.id);
    final mandal = loc.mandal(s.state, s.district, s.region);
    if (mandal != null && s.village != null) await loc.loadChildren(mandal.id);
    final village = loc.village(s.state, s.district, s.region, s.village);
    final category = CategoryRepository.instance.byName(s.category) ?? CategoryRepository.instance.byName('other');

    try {
      await _api.post('/submissions', {
        'title': s.title,
        'summary': s.description,
        'body': s.content,
        'language': detectLanguage('${s.title} ${s.content}'),
        'categoryId': category?.id,
        'stateId': state.id,
        'districtId': district.id,
        'mandalId': mandal?.id,
        'villageId': village?.id,
        'coverMediaId': s.coverMediaId,
        'authorName': s.author,
        'source': s.source.isEmpty ? null : s.source,
      });
    } on ApiException catch (e) {
      if (e.code == 'daily_limit_reached') {
        throw Exception('Daily submission limit reached. You can submit again tomorrow.');
      }
      throw Exception(e.message);
    }
  }

  Future<List<NewsSubmission>> fetchMySubmissions() async {
    final res = await _api.get('/me/submissions', query: {'limit': 50}) as Map;
    final list = (res['items'] as List).map((e) => NewsSubmission.fromApi(Map<String, dynamic>.from(e as Map))).toList();
    for (final s in list) {
      if (s.id != null) _reasons[s.id!] = s.rejectionReason;
    }
    return list;
  }

  /// Editor feedback for a rejected story (the editor's identity is never exposed).
  Future<String?> fetchRejectionFeedback(String submissionId) async {
    if (_reasons[submissionId] != null) return _reasons[submissionId];
    final res = await _api.get('/me/submissions/$submissionId') as Map;
    return res['rejectionReason']?.toString();
  }

  /// Telugu / Hindi script → te / hi; otherwise English.
  static String detectLanguage(String text) {
    if (RegExp(r'[ఀ-౿]').hasMatch(text)) return 'te';
    if (RegExp(r'[ऀ-ॿ]').hasMatch(text)) return 'hi';
    return 'en';
  }
}
