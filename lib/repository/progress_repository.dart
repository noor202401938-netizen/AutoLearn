// lib/repository/progress_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/video_progress_model.dart';

class ProgressRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<VideoProgressModel?> getVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final response = await _apiClient.get('/user/progress/$lessonId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return VideoProgressModel(
          userId: userId,
          courseId: courseId,
          moduleId: moduleId,
          lessonId: lessonId,
          videoURL: data['videoURL'] ?? '',
          currentPosition: data['currentPosition'] ?? 0,
          totalDuration: data['totalDuration'] ?? 0,
          isCompleted: data['isCompleted'] ?? false,
          lastUpdated: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> saveVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String videoURL,
    required int currentPosition,
    required int totalDuration,
    bool isCompleted = false,
  }) async {
    await _apiClient.post('/user/progress', {
      'lessonId': lessonId,
      'currentPosition': currentPosition,
      'totalDuration': totalDuration,
      'isCompleted': isCompleted,
    });
  }

  Future<void> markVideoCompleted({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    await saveVideoProgress(
      userId: userId,
      courseId: courseId,
      moduleId: moduleId,
      lessonId: lessonId,
      videoURL: '',
      currentPosition: 0,
      totalDuration: 0,
      isCompleted: true,
    );
  }

  Future<double> getCourseCompletionPercentage({
    required String userId,
    required String courseId,
    required int totalLessons,
  }) async {
    try {
      final response = await _apiClient.get('/user/courses/$courseId/completion');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['completionPercentage'] ?? 0).toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  Stream<VideoProgressModel?> watchVideoProgress({
    required String userId,
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async* {
    yield await getVideoProgress(
      userId: userId, courseId: courseId, moduleId: moduleId, lessonId: lessonId
    );
  }
}
