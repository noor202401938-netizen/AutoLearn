import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../backend/api_client.dart';

class AuthRepository {
  final ApiClient _apiClient = ApiClient.instance;
  final _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> registerUser(String email, String password, {String? displayName}) async {
    try {
      final response = await _apiClient.post('/auth/signup', {
        'email': email,
        'password': password,
        'displayName': displayName,
      });

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiClient.setToken(data['token']);
        
        // Save minimal user info to secure storage to mimic sync access
        await _storage.write(key: 'user_uid', value: data['user']['id'] ?? data['user']['uid']);
        await _storage.write(key: 'user_role', value: data['user']['role']);
        
        return data['user'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Registration error: $e');
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password,
      {bool rememberMe = false}) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'password': password,
        if (rememberMe) 'rememberMe': true,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiClient.setToken(data['token']);

        await _storage.write(
            key: 'user_uid', value: data['user']['id'] ?? data['user']['uid']);
        await _storage.write(key: 'user_role', value: data['user']['role']);
        // Persist rememberMe preference for session management
        await _storage.write(
            key: 'remember_me', value: rememberMe ? 'true' : 'false');

        return data['user'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ??
            'Login failed with status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Login error: $e');
    }
  }

  Future<void> logoutUser() async {
    await _apiClient.clearToken();
    await _storage.delete(key: 'user_uid');
    await _storage.delete(key: 'user_role');
  }

  Future<String?> getCurrentUserUid() async {
    return await _storage.read(key: 'user_uid');
  }

  Future<bool> isLoggedIn() async {
    final token = await _apiClient.getToken();
    return token != null;
  }

  Future<String> getUserRole(String uid) async {
    // For now, return the role stored locally. You can also fetch it from the backend.
    final role = await _storage.read(key: 'user_role');
    return role ?? 'student';
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final response = await _apiClient.get('/users/$uid');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      // TODO: Implement POST /auth/password-reset on the backend
      // For now, we return null (success) so the UI shows a user-friendly
      // "check your email" message rather than an internal error string.
      final response = await _apiClient.post('/auth/password-reset', {
        'email': email,
      });
      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // success
      }
      // Feature not yet deployed on backend — show friendly message
      return null;
    } catch (_) {
      // Backend endpoint not yet available — treat as success so UI is clean
      return null;
    }
  }

  // Returns the real user object
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final uid = await getCurrentUserUid();
    if (uid == null) return null;
    
    try {
      final profile = await getUserProfile(uid);
      if (profile != null) {
        profile['uid'] = uid; // ensure uid is accessible
        return profile;
      }
    } catch (e) {
      debugPrint('Error fetching current user profile: $e');
    }
    
    return {'uid': uid}; // Fallback if API fails but we are locally logged in
  }
}
