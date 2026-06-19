
// lib/model/video_progress_model.dart

class VideoProgressModel {
  final String progressId;
  final String userId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final String videoURL;
  final int currentPosition; // in seconds
  final int totalDuration; // in seconds
  final bool isCompleted;
  final DateTime? lastWatchedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VideoProgressModel({
    required this.progressId,
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    required this.videoURL,
    this.currentPosition = 0,
    this.totalDuration = 0,
    this.isCompleted = false,
    this.lastWatchedAt,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'progressId': progressId,
      'userId': userId,
      'courseId': courseId,
      'moduleId': moduleId,
      'lessonId': lessonId,
      'videoURL': videoURL,
      'currentPosition': currentPosition,
      'totalDuration': totalDuration,
      'isCompleted': isCompleted,
      'lastWatchedAt': lastWatchedAt != null ? lastWatchedAt!.toIso8601String() : null,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
    };
  }

  // Create from Firestore document
  factory VideoProgressModel.fromMap(Map<String, dynamic> map) {
    return VideoProgressModel(
      progressId: map['id'] ?? map['progressId'] ?? '',
      userId: map['userId'] ?? '',
      courseId: map['courseId'] ?? '',
      moduleId: map['moduleId'] ?? '',
      lessonId: map['lessonId'] ?? '',
      videoURL: map['videoURL'] ?? '',
      currentPosition: map['currentPosition'] ?? 0,
      totalDuration: map['totalDuration'] ?? 0,
      isCompleted: map['isCompleted'] ?? false,
      lastWatchedAt: map['lastWatchedAt'] != null
          ? (DateTime.tryParse(map['lastWatchedAt']?.toString() ?? '') ?? DateTime.now())
          : null,
      createdAt: (DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? (DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now())
          : null,
    );
  }

  // Copy with method for updates
  VideoProgressModel copyWith({
    String? progressId,
    String? userId,
    String? courseId,
    String? moduleId,
    String? lessonId,
    String? videoURL,
    int? currentPosition,
    int? totalDuration,
    bool? isCompleted,
    DateTime? lastWatchedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoProgressModel(
      progressId: progressId ?? this.progressId,
      userId: userId ?? this.userId,
      courseId: courseId ?? this.courseId,
      moduleId: moduleId ?? this.moduleId,
      lessonId: lessonId ?? this.lessonId,
      videoURL: videoURL ?? this.videoURL,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isCompleted: isCompleted ?? this.isCompleted,
      lastWatchedAt: lastWatchedAt ?? this.lastWatchedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Calculate completion percentage
  double get completionPercentage {
    if (totalDuration == 0) return 0.0;
    return (currentPosition / totalDuration * 100).clamp(0.0, 100.0);
  }
}

// Model for AI-generated video summary
class VideoSummaryModel {
  final String videoId;
  final String summary;
  final List<String> keyPoints;
  final DateTime generatedAt;

  VideoSummaryModel({
    required this.videoId,
    required this.summary,
    this.keyPoints = const [],
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'summary': summary,
      'keyPoints': keyPoints,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory VideoSummaryModel.fromMap(Map<String, dynamic> map) {
    return VideoSummaryModel(
      videoId: map['videoId'] ?? '',
      summary: map['summary'] ?? '',
      keyPoints: List<String>.from(map['keyPoints'] ?? []),
      generatedAt: (DateTime.tryParse(map['generatedAt']?.toString() ?? '') ?? DateTime.now()),
    );
  }
}

// Model for video captions
class VideoCaptionModel {
  final String videoId;
  final String language;
  final List<CaptionItem> captions;
  final DateTime? lastUpdated;

  VideoCaptionModel({
    required this.videoId,
    this.language = 'en',
    this.captions = const [],
    this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'language': language,
      'captions': captions.map((item) => item.toMap()).toList(),
      'lastUpdated': lastUpdated != null ? lastUpdated!.toIso8601String() : null,
    };
  }

  factory VideoCaptionModel.fromMap(Map<String, dynamic> map) {
    return VideoCaptionModel(
      videoId: map['videoId'] ?? '',
      language: map['language'] ?? 'en',
      captions: map['captions'] != null
          ? (map['captions'] as List).map((item) => CaptionItem.fromMap(item)).toList()
          : [],
      lastUpdated: map['lastUpdated'] != null
          ? (DateTime.tryParse(map['lastUpdated']?.toString() ?? '') ?? DateTime.now())
          : null,
    );
  }
}

class CaptionItem {
  final double startTime;
  final double endTime;
  final String text;

  CaptionItem({
    required this.startTime,
    required this.endTime,
    required this.text,
  });

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'text': text,
    };
  }

  factory CaptionItem.fromMap(Map<String, dynamic> map) {
    return CaptionItem(
      startTime: (map['startTime'] ?? 0).toDouble(),
      endTime: (map['endTime'] ?? 0).toDouble(),
      text: map['text'] ?? '',
    );
  }
}



