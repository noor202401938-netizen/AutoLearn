// lib/business_logic/video_manager.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../repository/progress_repository.dart';
import '../backend/youtube_service.dart';
import '../model/video_progress_model.dart';
import '../backend/api_client.dart';

class VideoManager {
  final ProgressRepository _progressRepository = ProgressRepository();
  final YouTubeService _youtubeService = YouTubeService();
  final ApiClient _apiClient = ApiClient.instance;

  // Get video progress for a lesson
  Future<VideoProgressModel?> getVideoProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) return null;

      return await _progressRepository.getVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      throw Exception('Failed to get video progress: $e');
    }
  }

  // Save video progress
  Future<void> saveProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
    required String videoURL,
    required int currentPosition,
    required int totalDuration,
    bool isCompleted = false,
  }) async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) throw Exception('User not authenticated');

      await _progressRepository.saveVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        videoURL: videoURL,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isCompleted: isCompleted,
      );
    } catch (e) {
      throw Exception('Failed to save progress: $e');
    }
  }

  // Mark video as completed
  Future<void> markVideoCompleted({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) throw Exception('User not authenticated');

      await _progressRepository.markVideoCompleted(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      throw Exception('Failed to mark video as completed: $e');
    }
  }

  // Get video captions
  Future<VideoCaptionModel?> getVideoCaptions(String videoURL,
      {String language = 'en'}) async {
    try {
      final videoId = YouTubeService.extractVideoId(videoURL);
      if (videoId == null) return null;

      return await _youtubeService.getVideoCaptions(videoId,
          language: language);
    } catch (e) {
      // Return null if captions can't be fetched (graceful degradation)
      return null;
    }
  }

  // Generate AI summary for video using OpenAI
  Future<VideoSummaryModel?> generateAISummary(
      String videoURL, String videoTitle) async {
    try {
      final videoId = YouTubeService.extractVideoId(videoURL) ?? '';

      // Make API call to our custom backend
      final response = await _apiClient.post('/ai/summary', {
        'videoTitle': videoTitle,
      });

      if (response.statusCode == 200) {
        final summaryData = json.decode(response.body);

        return VideoSummaryModel(
          videoId: videoId,
          summary: summaryData['summary'] ?? '',
          keyPoints: List<String>.from(summaryData['keyPoints'] ?? []),
          generatedAt: DateTime.now(),
        );
      } else {
        // If API call fails, return a basic summary
        return VideoSummaryModel(
          videoId: videoId,
          summary:
              'Unable to generate AI summary at this time. Please try again later.',
          keyPoints: [
            'Review the video content carefully',
            'Take notes on important concepts',
            'Practice applying what you learned',
          ],
          generatedAt: DateTime.now(),
        );
      }
    } catch (e) {
      // Return null on error (graceful degradation)
      return null;
    }
  }

  // Get course completion percentage
  Future<double> getCourseCompletion({
    required String courseId,
    required int totalLessons,
  }) async {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) return 0.0;

      return await _progressRepository.getCourseCompletionPercentage(
        userId: user.uid,
        courseId: courseId,
        totalLessons: totalLessons,
      );
    } catch (e) {
      return 0.0;
    }
  }

  // Watch video progress in real-time
  Stream<VideoProgressModel?> watchVideoProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) {
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user == null) return Stream.value(null);

      return _progressRepository.watchVideoProgress(
        userId: user.uid,
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
      );
    } catch (e) {
      return Stream.value(null);
    }
  }

  // Extract YouTube video ID from URL
  String? extractVideoId(String url) {
    return YouTubeService.extractVideoId(url);
  }
}
