import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Base URL of the Samayam API. Override with --dart-define=API_BASE_URL=...
/// Defaults: Android emulator reaches the host machine at 10.0.2.2.
String _defaultBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4000';
  }
  return 'http://localhost:4000';
}

/// Error returned by the API: { error: { code, message, requestId } }.
class ApiException implements Exception {
  final int status;
  final String code;
  final String message;
  final String? requestId;

  ApiException(this.status, this.code, this.message, [this.requestId]);

  @override
  String toString() => message;
}

/// Thin JSON client for /v1. Attaches the Supabase access token when signed in.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  final String baseUrl = _defaultBaseUrl();
  final http.Client _http = http.Client();
  static const _timeout = Duration(seconds: 20);

  Map<String, String> _headers({bool json = false}) {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    return {
      'accept': 'application/json',
      if (json) 'content-type': 'application/json',
      if (token != null) 'authorization': 'Bearer $token',
    };
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final q = <String, String>{};
    query?.forEach((k, v) {
      if (v != null && v.toString().isNotEmpty) q[k] = v.toString();
    });
    return Uri.parse('$baseUrl/v1$path').replace(queryParameters: q.isEmpty ? null : q);
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers()));

  Future<dynamic> post(String path, [Object? body]) => _send(
        () => _http.post(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})),
      );

  Future<dynamic> patch(String path, Object body) =>
      _send(() => _http.patch(_uri(path), headers: _headers(json: true), body: jsonEncode(body)));

  Future<dynamic> put(String path, [Object? body]) => _send(
        () => _http.put(_uri(path), headers: _headers(json: true), body: jsonEncode(body ?? {})),
      );

  Future<dynamic> delete(String path) => _send(() => _http.delete(_uri(path), headers: _headers()));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(_timeout);
    } catch (e) {
      throw ApiException(0, 'network', 'Could not reach the server. Check your internet connection.');
    }
    final body = res.body.isEmpty ? null : _tryDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;
    final err = (body is Map && body['error'] is Map) ? body['error'] as Map : const {};
    final message = (err['message'] ?? 'Request failed (${res.statusCode})').toString();
    debugPrint('API ${res.statusCode} ${err['code']} ${err['requestId'] ?? ''}: $message');
    throw ApiException(res.statusCode, (err['code'] ?? 'error').toString(), message, err['requestId']?.toString());
  }

  dynamic _tryDecode(String s) {
    try {
      return jsonDecode(s);
    } catch (_) {
      return s;
    }
  }
}
