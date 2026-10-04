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
    defaultValue: 'http://localhost:3001/api',
  );

  static String get baseUrl {
    String url = _defaultBaseUrl.isNotEmpty ? _defaultBaseUrl : 'http://localhost:3001/api';

    // Automatically append /api prefix if missing
    if (!url.endsWith('/api') && !url.endsWith('/api/')) {
      url = url.endsWith('/') ? '${url}api' : '$url/api';
    }

    // If not local development and URL is HTTP, warn or upgrade to HTTPS
    if (!url.contains('localhost') && 
        !url.contains('127.0.0.1') && 
        url.startsWith('http://')) {
      // Security enforcement: upgrading to https
      return url.replaceFirst('http://', 'https://');
    }
    return url;
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

  /// Uploads a file; returns its server URL (e.g. `/uploads/123-456.pdf`).
  Future<String> upload(List<int> bytes, String filename) async {
    final token = await getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload'))
      ..headers.addAll({if (token != null) 'Authorization': 'Bearer $token'})
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final http.Response res;
    try {
      res = await http.Response.fromStream(await request.send().timeout(const Duration(seconds: 60)));
    } on Exception {
      throw const ApiException(0, "Can't reach the server. Check your connection.");
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode == 200 && decoded is Map && decoded['url'] is String) return decoded['url'] as String;
    throw ApiException(res.statusCode,
        decoded is Map && decoded['error'] is String ? decoded['error'] as String : 'Upload failed (${res.statusCode}).');
  }

  /// JSON request that returns the decoded body, or throws [ApiException]
  /// with the server's own error message. AI-backed calls pass a longer
  /// [timeout] because the model can take a while to answer.
  Future<dynamic> json(String method, String endpoint,
      {Map<String, dynamic>? body, Duration? timeout}) async {
    final request = http.Request(method, Uri.parse('$baseUrl$endpoint'))
      ..headers.addAll(await _getHeaders());
    if (body != null) request.body = jsonEncode(body);
    final client = http.Client();
    final http.Response res;
    try {
      res = await http.Response.fromStream(
          await client.send(request).timeout(timeout ?? _timeout));
    } on Exception {
      throw const ApiException(0, "Can't reach the server. Check your connection.");
    } finally {
      client.close();
    }
    final decoded = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return decoded;
    final message = decoded is Map && decoded['error'] is String
        ? decoded['error'] as String
        : 'Something went wrong (${res.statusCode}).';
    throw ApiException(res.statusCode, message);
  }
}

class ApiException implements Exception {
  final int status;
  final String message;
  const ApiException(this.status, this.message);

  @override
  String toString() => message;
}
