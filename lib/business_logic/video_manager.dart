// lib/business_logic/video_manager.dart
import 'dart:convert';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../backend/api_client.dart';
import '../model/video_progress_model.dart';
import '../repository/progress_repository.dart';

/// Video lesson helpers. The server identifies the student from their token,
/// so nothing here needs a user id.
class VideoManager {
  final ProgressRepository _progress = ProgressRepository();
  final ApiClient _api = ApiClient.instance;

  Future<VideoProgressModel?> getVideoProgress({
    required String courseId,
    required String moduleId,
    required String lessonId,
  }) async {
    try {
      return await _progress.getVideoProgress(userId: '', courseId: courseId, moduleId: moduleId, lessonId: lessonId);
    } on Exception {
      return null; // start from the beginning
    }
  }

  /// Saves the watch position; never throws (it runs on a timer).
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
      await _progress.saveVideoProgress(
        userId: '',
        courseId: courseId,
        moduleId: moduleId,
        lessonId: lessonId,
        videoURL: videoURL,
        currentPosition: currentPosition,
        totalDuration: totalDuration,
        isCompleted: isCompleted,
      );
    } on Exception {
      // Next tick retries.
    }
  }

  /// AI study notes for a lesson, or null when the AI isn't available.
  Future<VideoSummaryModel?> generateAISummary(String videoURL, String videoTitle) async {
    try {
      final response = await _api.post('/ai/summary', {'videoTitle': videoTitle});
      if (response.statusCode != 200) return null;
      final data = json.decode(response.body);
      return VideoSummaryModel(
        videoId: extractVideoId(videoURL) ?? '',
        summary: data['summary'] ?? '',
        keyPoints: List<String>.from(data['keyPoints'] ?? []),
        generatedAt: DateTime.now(),
      );
    } on Exception {
      return null;
    }
  }

  String? extractVideoId(String url) => YoutubePlayer.convertUrlToId(url);
}
