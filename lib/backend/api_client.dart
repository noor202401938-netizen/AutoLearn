// lib/backend/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  // The API base URL — set via Vercel's API_BASE_URL environment variable
  // On web, environment variables from Vercel are NOT accessible at runtime
  // unless baked in at build time. We use const String.fromEnvironment instead.
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    assert(_defaultBaseUrl.isNotEmpty, 'API_BASE_URL is not set');
    // If not local development and URL is HTTP, warn or upgrade to HTTPS
    if (!_defaultBaseUrl.contains('localhost') && 
        !_defaultBaseUrl.contains('127.0.0.1') && 
        _defaultBaseUrl.startsWith('http://')) {
      // Security enforcement: upgrading to https
      return _defaultBaseUrl.replaceFirst('http://', 'https://');
    }
    return _defaultBaseUrl;
  }

  static const _storage = FlutterSecureStorage();
  static const Duration _timeout = Duration(seconds: 15);

  static final ApiClient instance = ApiClient._internal();

  ApiClient._internal();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> setToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await getToken();
    if (token != null) {
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
    }
    return {
      'Content-Type': 'application/json',
    };
  }

  Future<http.Response> get(String endpoint) async {
    final headers = await _getHeaders();
    return await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(_timeout);
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(_timeout);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(_timeout);
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    return await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    ).timeout(_timeout);
  }

  Future<http.Response> delete(String endpoint) async {
    final headers = await _getHeaders();
    return await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    ).timeout(_timeout);
  }
}
