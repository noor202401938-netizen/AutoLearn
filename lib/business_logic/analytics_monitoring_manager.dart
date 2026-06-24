// lib/business_logic/analytics_monitoring_manager.dart
import '../repository/progress_repository.dart';
import '../repository/enrollment_repository.dart';
import '../repository/quiz_repository.dart';
import '../backend/api_client.dart';
import 'dart:convert';

class AnalyticsMonitoringManager {
  final ProgressRepository _progressRepository = ProgressRepository();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final QuizRepository _quizRepository = QuizRepository();

  // Log event (no-op stub replacing Firebase Analytics)
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    // Analytics logging disabled — Firebase removed
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    // Analytics logging disabled — Firebase removed
  }

  // Get course completion statistics
  Future<Map<String, dynamic>> getCourseStats(String courseId) async {
    try {
      final response = await ApiClient.instance.get('/courses/$courseId/stats');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'totalEnrollments': 0,
        'completionRate': 0.0,
        'averageScore': 0.0,
        'averageTimeSpent': 0,
      };
    } catch (e) {
      return {};
    }
  }

  // Get user learning statistics
  Future<Map<String, dynamic>> getUserLearningStats(String userId) async {
    try {
      final response = await ApiClient.instance.get('/user/stats');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {
        'enrolledCourses': 0,
        'completedCourses': 0,
        'totalLessonsWatched': 0,
        'totalQuizzesTaken': 0,
      };
    } catch (e) {
      return {};
    }
  }

  // Track course enrollment
  Future<void> trackEnrollment(String courseId) async {
    await logEvent('course_enrolled', {'course_id': courseId});
  }

  // Track course completion
  Future<void> trackCourseCompletion(String courseId) async {
    await logEvent('course_completed', {'course_id': courseId});
  }

  // Track quiz completion
  Future<void> trackQuizCompletion(String quizId, int score) async {
    await logEvent('quiz_completed', {
      'quiz_id': quizId,
      'score': score,
    });
  }

  Future<Map<String, dynamic>> getPlatformAnalytics() async {
    try {
      final response = await ApiClient.instance.get('/admin/analytics');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Failed to get platform analytics: $e');
    }
    return {};
  }
}
