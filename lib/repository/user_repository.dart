// lib/repository/user_repository.dart
import 'dart:convert';
import 'dart:async';
import '../backend/api_client.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient.instance;

  // Cache for reactive streams
  final Map<String, StreamController<Map<String, dynamic>?>> _userStreams = {};
  final Map<String, Map<String, dynamic>> _userCache = {};

  Future<void> saveOnboardingData({
    required String uid,
    String? displayName,
    String? phone,
    String? grade,
    String? interest,
  }) async {
    try {
      final response = await _apiClient.put('/users/$uid', {
        'displayName': displayName,
        'phone': phone,
        'grade': grade,
        'interest': interest,
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to save onboarding data');
      }
      
      // Update local cache and notify stream
      final profile = await getUserProfile(uid, forceRefresh: true);
      if (profile != null) {
        _notifyProfileUpdated(uid, profile);
      }
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
  }

  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? phone,
    String? grade,
    String? interest,
  }) async {
    await saveOnboardingData(
      uid: uid,
      displayName: displayName,
      phone: phone,
      grade: grade,
      interest: interest,
    );
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid, {bool forceRefresh = false}) async {
    try {
      // Return cached version if available and not forcing refresh
      if (!forceRefresh && _userCache.containsKey(uid)) {
        return _userCache[uid];
      }
      
      final response = await _apiClient.get('/users/$uid');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _userCache[uid] = data;
        _notifyProfileUpdated(uid, data);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<Map<String, dynamic>?> streamUserProfile(String uid) {
    if (!_userStreams.containsKey(uid)) {
      _userStreams[uid] = StreamController<Map<String, dynamic>?>.broadcast();
    }
    
    // Fetch immediately to populate the stream
    getUserProfile(uid);

    return _userStreams[uid]!.stream;
  }

  void _notifyProfileUpdated(String uid, Map<String, dynamic> profile) {
    if (_userStreams.containsKey(uid)) {
      _userStreams[uid]!.add(profile);
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final response = await _apiClient.get('/users');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> updateUserRole(String uid, String role) async {
    try {
      await _apiClient.put('/users/$uid/role', {'role': role});
      // Force refresh user profile so stream updates if it's the current user
      await getUserProfile(uid, forceRefresh: true);
    } catch (e) {
      print('Error updating user role: $e');
    }
  }

  Future<void> deleteUserProfile(String uid) async {
    try {
      await _apiClient.delete('/users/$uid');
      _userCache.remove(uid);
      _userStreams[uid]?.add(null);
    } catch (e) {
      print('Error deleting user profile: $e');
    }
  }
}
