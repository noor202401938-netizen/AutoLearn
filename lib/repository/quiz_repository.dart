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
    try {
      await _apiClient.post('/user/quiz', {
        'moduleId': moduleId,
        'score': score,
        'totalQuestions': totalQuestions,
        'passed': passed,
      });
    } catch (e) {
      throw Exception('Failed to save quiz result: $e');
    }
  }

  Future<dynamic> getQuizResult({
    required String userId,
    required String moduleId,
  }) async {
    try {
      final response = await _apiClient.get('/user/quiz/$moduleId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getUserQuizSubmission({required String userId, required String quizId}) async {
    try {
      final response = await _apiClient.get('/user/quizzes/$quizId/submission');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> submitQuiz(dynamic submission) async {
    try {
      final quizId = submission['quizId'];
      await _apiClient.post('/user/quizzes/$quizId/submit', submission);
    } catch (e) {
      throw Exception('Failed to submit quiz: $e');
    }
  }

  Future<dynamic> getAssignmentByLessonId(String lessonId) async {
    try {
      final response = await _apiClient.get('/assignments/lesson/$lessonId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<dynamic> getUserAssignmentSubmission({required String userId, required String assignmentId}) async {
    try {
      final response = await _apiClient.get('/user/assignments/$assignmentId/submission');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> submitAssignment(dynamic submission) async {
    try {
      final assignmentId = submission['assignmentId'];
      await _apiClient.post('/user/assignments/$assignmentId/submit', submission);
    } catch (e) {
      throw Exception('Failed to submit assignment: $e');
    }
  }

  Future<void> saveQuiz(dynamic quiz) async {
    try {
      await _apiClient.post('/quizzes', quiz);
    } catch (e) {
      throw Exception('Failed to save quiz: $e');
    }
  }

  Future<dynamic> getQuizByLessonId(String lessonId) async {
    try {
      final response = await _apiClient.get('/quizzes/lesson/$lessonId');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
