import 'package:firebase_auth/firebase_auth.dart';
// lib/repository/quiz_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/quiz_model.dart';

class QuizRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<void> saveQuizResult({
    required String userId,
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

  Future<dynamic> getQuizResult({
    required String userId,
    required String moduleId,
  }) async {
    // Implement fetching quiz result from backend if needed
    return null;
  }
  Future<dynamic> getUserQuizSubmission({required String userId, required String quizId}) async { return null; }
  Future<void> submitQuiz(dynamic submission) async {}
  Future<dynamic> getAssignmentByLessonId(String lessonId) async { return null; }
  Future<dynamic> getUserAssignmentSubmission({required String userId, required String assignmentId}) async { return null; }
  Future<void> submitAssignment(dynamic submission) async {}
  Future<void> saveQuiz(dynamic quiz) async {}
  Future<dynamic> getQuizByLessonId(String lessonId) async { return null; }
}



