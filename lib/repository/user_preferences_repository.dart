// lib/repository/user_preferences_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';

class UserPreferencesRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<bool> getAccessibilityMode(String uid) async {
    return false; // Implement getting from backend
  }

  Future<void> setAccessibilityMode({required String uid, required bool enabled}) async {
    // Implement saving to backend
  }
}
