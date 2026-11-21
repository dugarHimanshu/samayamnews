import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';
import 'auth_service.dart';
import 'location_repository.dart';

/// Admin dashboard calls through the API.
class AdminService {
  final ApiClient _api = ApiClient.instance;

  String get _adminId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('You must be logged in.');
    return user.id;
  }

  Future<bool> isCurrentUserAdmin() async => (await AuthService.instance.getCurrentUserRole()) == 'admin';

  Future<Map<String, int>> fetchStats() async {
    final res = Map<String, dynamic>.from(await _api.get('/admin/stats') as Map);
    final roles = Map<String, dynamic>.from((res['users_by_role'] ?? const {}) as Map);
    final subs = Map<String, dynamic>.from((res['submissions_by_status'] ?? const {}) as Map);
    int n(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
    return {
      'total_users': n(res, 'total_users'),
      'readers': n(roles, 'reader'),
      'freelancers': n(roles, 'freelancer'),
      'employees': n(roles, 'employee'),
      'editors': n(roles, 'editor'),
      'admins': n(roles, 'admin'),
      'pending': n(subs, 'pending'),
      'in_review': n(subs, 'in_review'),
      'published': n(subs, 'published'),
      'rejected': n(subs, 'rejected'),
      'live_articles': n(res, 'live_articles'),
      'pending_applications': n(res, 'pending_applications'),
    };
  }

  /// Users in the shape the dashboard expects (id, email, full_name, role, language, state, district).
  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final out = <Map<String, dynamic>>[];
    String? cursor;
    final loc = LocationRepository.instance;
    do {
      final res = await _api.get('/admin/users', query: {'limit': 50, 'cursor': cursor}) as Map;
      for (final raw in res['items'] as List) {
        final u = Map<String, dynamic>.from(raw as Map);
        final district = loc.byId(u['homeDistrictId'] as int?);
        final state = loc.byId(district?.parentId);
        out.add({
          'id': u['id'],
          'email': u['email'],
          'full_name': u['fullName'],
          'role': u['role'],
          'language': u['language'],
          'state': state?.nameEn,
          'district': district?.nameEn,
        });
      }
      cursor = res['nextCursor'] as String?;
    } while (cursor != null && out.length < 1000);
    out.sort((a, b) => (a['full_name'] ?? '').toString().compareTo((b['full_name'] ?? '').toString()));
    return out;
  }

  Future<void> updateUserRole({required String userId, required String role}) async {
    const allowedRoles = {'reader', 'freelancer', 'employee', 'editor', 'admin'};
    final normalizedRole = role.trim().toLowerCase();
    if (!allowedRoles.contains(normalizedRole)) throw Exception('Invalid user role.');
    if (userId == _adminId) throw Exception('You cannot change your own administrator role.');
    try {
      await _api.patch('/admin/users/$userId', {'role': normalizedRole});
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? language,
    String? state,
    String? district,
  }) async {
    if (userId == _adminId) throw Exception('Your administrator profile cannot be edited here.');
    final body = <String, dynamic>{
      if (fullName != null) 'fullName': fullName.trim(),
      if (language != null) 'language': language.trim(),
    };
    if (district != null) {
      final d = LocationRepository.instance.district(state, district) ?? LocationRepository.instance.districtAnywhere(district);
      if (d != null) body['homeDistrictId'] = d.id;
    }
    if (body.isEmpty) return;
    try {
      await _api.patch('/admin/users/$userId', body);
    } on ApiException catch (e) {
      throw Exception(e.message);
    }
  }

  Future<void> signOut() => AuthService.instance.signOut();
}
