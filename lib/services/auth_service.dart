import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'api_client.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _client.auth.currentUser;

  bool get isLoggedIn => currentUser != null;

  // ============================================================
  // CURRENT USER PROFILE / ROLE (from the API, which reads app.profiles)
  // ============================================================

  Map<String, dynamic>? _profile;
  String? _profileUserId;

  Future<Map<String, dynamic>?> getCurrentUserProfile({bool refresh = false}) async {
    final user = currentUser;
    if (user == null) return null;
    if (!refresh && _profile != null && _profileUserId == user.id) return _profile;
    try {
      final res = await ApiClient.instance.get('/me');
      _profile = Map<String, dynamic>.from(res as Map);
      _profileUserId = user.id;
      return _profile;
    } on ApiException catch (e) {
      debugPrint('PROFILE LOAD ERROR: ${e.code} ${e.message}');
      throw Exception('Could not load your account profile: ${e.message}');
    }
  }

  /// reader / freelancer / employee / editor / admin (null when signed out).
  Future<String?> getCurrentUserRole() async {
    final profile = await getCurrentUserProfile(refresh: true);
    return profile?['role']?.toString().trim().toLowerCase();
  }

  // ============================================================
  // EMAIL + PASSWORD LOGIN
  // ============================================================

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      final session = response.session;

      debugPrint('======================================');
      debugPrint('LOGIN SUCCESS');
      debugPrint('USER ID: ${user?.id}');
      debugPrint('EMAIL: ${user?.email}');
      debugPrint('SESSION EXISTS: ${session != null}');
      debugPrint('======================================');

      if (user == null || session == null) {
        throw Exception('Login succeeded but no active session was created.');
      }
    } on AuthException catch (e) {
      debugPrint('======================================');
      debugPrint('SUPABASE AUTH ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS: ${e.statusCode}');
      debugPrint('CODE: ${e.code}');
      debugPrint('======================================');

      throw Exception(e.message);
    } catch (e) {
      debugPrint('======================================');
      debugPrint('UNKNOWN AUTH ERROR');
      debugPrint('$e');
      debugPrint('======================================');

      rethrow;
    }
  }

  // ============================================================
  // EMAIL SIGN UP
  // ============================================================

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
      );

      debugPrint('======================================');
      debugPrint('SIGN UP RESULT');
      debugPrint('USER ID: ${response.user?.id}');
      debugPrint('EMAIL: ${response.user?.email}');
      debugPrint('SESSION EXISTS: ${response.session != null}');
      debugPrint('======================================');

      // With email confirmation enabled, Supabase can create
      // the Auth user without creating an active session.
      if (response.user == null) {
        throw Exception('Unable to create your account.');
      }

      if (response.session == null) {
        throw Exception(
          'Account created successfully. Please check your email and confirm your account before signing in.',
        );
      }
    } on AuthException catch (e) {
      debugPrint('======================================');
      debugPrint('SUPABASE SIGN UP ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS: ${e.statusCode}');
      debugPrint('CODE: ${e.code}');
      debugPrint('======================================');

      throw Exception(e.message);
    } catch (e) {
      debugPrint('SIGN UP ERROR: $e');
      rethrow;
    }
  }

  // ============================================================
  // SIGN OUT
  // ============================================================

  Future<void> signOut() async {
    _profile = null;
    _profileUserId = null;
    try {
      await _client.auth.signOut();
      debugPrint('USER SIGNED OUT');
    } catch (e) {
      debugPrint('SIGN OUT ERROR: $e');
      rethrow;
    }
  }
}
