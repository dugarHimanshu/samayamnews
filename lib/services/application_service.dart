import 'api_client.dart';
import 'auth_service.dart';

/// A reporter / freelancer registration request.
class ContributorApplication {
  final String id;
  final String role; // 'employee' (reporter) or 'freelancer'
  final String fullName;
  final String mobile;
  final String email;
  final String? address;
  final String? state;
  final String? district;
  final String? mandal;
  final String status; // pending / approved / rejected
  final String? rejectionReason;
  final DateTime createdAt;

  const ContributorApplication({
    required this.id,
    required this.role,
    required this.fullName,
    required this.mobile,
    required this.email,
    this.address,
    this.state,
    this.district,
    this.mandal,
    required this.status,
    this.rejectionReason,
    required this.createdAt,
  });

  String get roleLabel => role == 'freelancer' ? 'Freelancer' : 'Reporter';
  bool get isPending => status == 'pending';

  static String? _name(dynamic place) => place is Map ? place['nameEn']?.toString() : null;

  factory ContributorApplication.fromApi(Map<String, dynamic> j) => ContributorApplication(
        id: j['id'].toString(),
        role: (j['role'] ?? 'employee').toString(),
        fullName: (j['fullName'] ?? '').toString(),
        mobile: (j['mobile'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        address: j['address']?.toString(),
        state: _name(j['state']),
        district: _name(j['district']),
        mandal: _name(j['mandal']),
        status: (j['status'] ?? 'pending').toString(),
        rejectionReason: j['rejectionReason']?.toString(),
        createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '')?.toLocal() ?? DateTime.now(),
      );
}

class ApplicationService {
  ApplicationService._();
  static final ApplicationService instance = ApplicationService._();

  final ApiClient _api = ApiClient.instance;

  /// Sends the registration form. When nobody is signed in, [password] creates the login;
  /// when a reader is signed in, the application is attached to their account.
  Future<ContributorApplication> register({
    required String role,
    required String fullName,
    required String mobile,
    required String email,
    String? password,
    String? address,
    required int districtId,
    int? mandalId,
  }) async {
    final res = await _api.post('/applications', {
      'role': role,
      'fullName': fullName,
      'mobile': mobile,
      'email': email,
      if (password != null && !AuthService.instance.isLoggedIn) 'password': password,
      if (address != null && address.isNotEmpty) 'address': address,
      'districtId': districtId,
      if (mandalId != null) 'mandalId': mandalId,
    });
    return ContributorApplication.fromApi(Map<String, dynamic>.from(res as Map));
  }

  /// The signed-in user's latest application, or null.
  Future<ContributorApplication?> myApplication() async {
    final res = await _api.get('/me/application') as Map;
    final a = res['application'];
    return a == null ? null : ContributorApplication.fromApi(Map<String, dynamic>.from(a as Map));
  }

  // ---------------------------------------------------------------- admin

  Future<({List<ContributorApplication> items, Map<String, int> counts})> list({String? status}) async {
    final res = await _api.get('/admin/applications', query: {'status': status, 'limit': 50}) as Map;
    final counts = Map<String, dynamic>.from((res['counts'] ?? const {}) as Map);
    return (
      items: [for (final a in res['items'] as List) ContributorApplication.fromApi(Map<String, dynamic>.from(a as Map))],
      counts: {for (final e in counts.entries) e.key: (e.value as num?)?.toInt() ?? 0},
    );
  }

  Future<void> approve(String id, {String? role}) =>
      _api.post('/admin/applications/$id/review', {'decision': 'approve', if (role != null) 'role': role});

  Future<void> reject(String id, String reason) =>
      _api.post('/admin/applications/$id/review', {'decision': 'reject', 'reason': reason});
}
