// lib/repository/quiz_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/quiz_model.dart';

class QuizRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<void> saveQuizResult({
    required String uid,
    required String moduleId,
    required int score,
    required int totalQuestions,
    required bool passed,
  }) async {
    await _apiClient.post('/user/quiz', {
      'moduleId': moduleId,
      'score': score,
      'totalQuestions': totalQuestions,
      'passed': passed,
    });
  }

  Future<QuizResultModel?> getQuizResult({
    required String uid,
    required String moduleId,
  }) async {
    // Implement fetching quiz result from backend if needed
    return null;
  }
}
