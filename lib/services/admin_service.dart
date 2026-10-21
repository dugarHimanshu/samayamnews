import 'package:supabase_flutter/supabase_flutter.dart';

class AdminService {
  AdminService() : _client = Supabase.instance.client;

  final SupabaseClient _client;

  String get _adminId {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('You must be logged in.');
    }

    return user.id;
  }

  // ============================================================
  // ADMIN ROLE CHECK
  // ============================================================

  Future<bool> isCurrentUserAdmin() async {
    final response = await _client
        .from('profiles')
        .select('role')
        .eq('id', _adminId)
        .maybeSingle();

    final role = response?['role']?.toString().trim().toLowerCase();

    return role == 'admin';
  }

  // ============================================================
  // DASHBOARD STATS
  // ============================================================

  Future<Map<String, int>> fetchStats() async {
    final totalUsers = await _client
        .from('profiles')
        .select('id')
        .count(CountOption.exact);

    final freelancers = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'freelancer')
        .count(CountOption.exact);

    final employees = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'employee')
        .count(CountOption.exact);

    final editors = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'editor')
        .count(CountOption.exact);

    final admins = await _client
        .from('profiles')
        .select('id')
        .eq('role', 'admin')
        .count(CountOption.exact);

    final pendingSubmissions = await _client
        .from('news_submissions')
        .select('id')
        .eq('status', 'pending')
        .count(CountOption.exact);

    final inReviewSubmissions = await _client
        .from('news_submissions')
        .select('id')
        .eq('status', 'in_review')
        .count(CountOption.exact);

    final publishedSubmissions = await _client
        .from('news_submissions')
        .select('id')
        .eq('status', 'published')
        .count(CountOption.exact);

    final rejectedSubmissions = await _client
        .from('news_submissions')
        .select('id')
        .eq('status', 'rejected')
        .count(CountOption.exact);

    return {
      'total_users': totalUsers.count,
      'freelancers': freelancers.count,
      'employees': employees.count,
      'editors': editors.count,
      'admins': admins.count,
      'pending': pendingSubmissions.count,
      'in_review': inReviewSubmissions.count,
      'published': publishedSubmissions.count,
      'rejected': rejectedSubmissions.count,
    };
  }

  // ============================================================
  // USER LIST
  // ============================================================

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    final response = await _client
        .from('profiles')
        .select('id, email, full_name, role, language, state, district')
        .order('full_name', ascending: true);

    return List<Map<String, dynamic>>.from(response as List);
  }

  // ============================================================
  // UPDATE USER ROLE
  // ============================================================

  Future<void> updateUserRole({
    required String userId,
    required String role,
  }) async {
    const allowedRoles = {'freelancer', 'employee', 'editor', 'admin'};

    final normalizedRole = role.trim().toLowerCase();

    if (!allowedRoles.contains(normalizedRole)) {
      throw Exception('Invalid user role.');
    }

    if (userId == _adminId) {
      throw Exception('You cannot change your own administrator role.');
    }

    await _client
        .from('profiles')
        .update({'role': normalizedRole})
        .eq('id', userId);
  }

  // ============================================================
  // UPDATE PROFILE DETAILS
  // ============================================================

  Future<void> updateUserProfile({
    required String userId,
    String? fullName,
    String? language,
    String? state,
    String? district,
  }) async {
    if (userId == _adminId) {
      throw Exception('Your administrator profile cannot be edited here.');
    }

    final updateMap = <String, dynamic>{};

    if (fullName != null) {
      updateMap['full_name'] = fullName.trim();
    }

    if (language != null) {
      updateMap['language'] = language.trim();
    }

    if (state != null) {
      updateMap['state'] = state.trim();
    }

    if (district != null) {
      updateMap['district'] = district.trim();
    }

    if (updateMap.isEmpty) {
      return;
    }

    await _client.from('profiles').update(updateMap).eq('id', userId);
  }

  // ============================================================
  // DELETE PROFILE
  // ============================================================
  //
  // IMPORTANT:
  // This only removes the public profile row.
  // Supabase Auth users should NOT be deleted directly from
  // the client application.
  //
  // Actual Auth-user deletion should later be done through a
  // secure server-side/Edge Function if you need that feature.
  //
  // This method is intentionally not exposed in the dashboard
  // for now.
  // ============================================================

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}