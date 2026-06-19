// lib/repository/user_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';

class UserRepository {
  final ApiClient _apiClient = ApiClient.instance;

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
    } catch (e) {
      throw Exception('Error saving user data: $e');
    }
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
}
