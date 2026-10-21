import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // GET CURRENT USER ROLE
  // ============================================================

  Future<String?> getCurrentUserRole() async {
    final user = currentUser;

    if (user == null) {
      debugPrint('AUTH ROLE: No logged-in user');
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('======================================');
      debugPrint('AUTH ROLE CHECK');
      debugPrint('USER ID: ${user.id}');
      debugPrint('EMAIL: ${user.email}');
      debugPrint('PROFILE: $response');
      debugPrint('======================================');

      if (response == null) {
        debugPrint('AUTH ROLE ERROR: Profile not found');
        return null;
      }

      final rawRole = response['role'];

      if (rawRole == null) {
        debugPrint('AUTH ROLE ERROR: Role is null');
        return null;
      }

      final role = rawRole.toString().trim().toLowerCase();

      debugPrint('AUTH ROLE: $role');

      return role;
    } on PostgrestException catch (e) {
      debugPrint('======================================');
      debugPrint('PROFILE QUERY ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('CODE: ${e.code}');
      debugPrint('DETAILS: ${e.details}');
      debugPrint('HINT: ${e.hint}');
      debugPrint('======================================');

      throw Exception('Could not load your account profile: ${e.message}');
    } catch (e) {
      debugPrint('======================================');
      debugPrint('PROFILE UNKNOWN ERROR');
      debugPrint('$e');
      debugPrint('======================================');

      throw Exception('Could not load your account profile.');
    }
  }

  // ============================================================
  // GET CURRENT USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      return response;
    } on PostgrestException catch (e) {
      debugPrint('PROFILE LOAD ERROR: ${e.message}');

      throw Exception('Could not load your account profile: ${e.message}');
    } catch (e) {
      debugPrint('PROFILE LOAD UNKNOWN ERROR: $e');

      throw Exception('Could not load your account profile.');
    }
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
    try {
      await _client.auth.signOut();
      debugPrint('USER SIGNED OUT');
    } catch (e) {
      debugPrint('SIGN OUT ERROR: $e');
      rethrow;
    }
  }
}
