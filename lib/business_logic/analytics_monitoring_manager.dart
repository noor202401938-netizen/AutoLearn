// lib/business_logic/analytics_monitoring_manager.dart
import '../repository/progress_repository.dart';
import '../repository/enrollment_repository.dart';
import '../repository/quiz_repository.dart';

class AnalyticsMonitoringManager {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final ProgressRepository _progressRepository = ProgressRepository();
  final EnrollmentRepository _enrollmentRepository = EnrollmentRepository();
  final QuizRepository _quizRepository = QuizRepository();

  // Log event
  Future<void> logEvent(String eventName, Map<String, dynamic>? parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters != null 
          ? parameters.map((key, value) => MapEntry(key, value as Object))
          : null,
    );
  }

  // Log screen view
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // Get course completion statistics
  Future<Map<String, dynamic>> getCourseStats(String courseId) async {
    try {
      // This would typically query Firestore for aggregated stats
      // For now, return placeholder structure
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
      final enrolledCourses = await _enrollmentRepository.getUserCourseIds(
        uid: userId,
      );

      int totalLessons = 0;
      int completedLessons = 0;

      for (final courseId in enrolledCourses) {
        // Get course completion
        final completion = await _progressRepository.getCourseCompletionPercentage(
          userId: userId,
          courseId: courseId,
          totalLessons: 10, // This should be calculated properly
        );
        if (completion >= 80) completedLessons++;
        totalLessons++;
      }

      return {
        'enrolledCourses': enrolledCourses.length,
        'completedCourses': completedLessons,
        'totalLessonsWatched': 0, // Would need to calculate from progress
        'totalQuizzesTaken': 0, // Would need to query quiz submissions
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
}

