// lib/repository/auth_repository.dart
import 'dart:convert';
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

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final response = await _apiClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _apiClient.setToken(data['token']);
        
        await _storage.write(key: 'user_uid', value: data['user']['id'] ?? data['user']['uid']);
        await _storage.write(key: 'user_role', value: data['user']['role']);
        
        return data['user'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Login failed with status code ${response.statusCode}');
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
    // Implement in backend
    return "Not implemented in backend yet";
  }

  // Returns a mock user object with a uid
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final uid = await getCurrentUserUid();
    if (uid == null) return null;
    return {'uid': uid};
  }
}