// lib/models/course_model.dart

class CourseModel {
  final String courseId;
  final String title;
  final String description;
  final String instructor;
  final String category;
  final String level; // beginner, intermediate, advanced
  final int duration; // in hours
  final String thumbnailURL;
  final double price;
  final String currency;
  final int enrollmentCount;
  final double rating;
  final int ratingCount;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy; // Admin UID
  final List<ModuleModel> syllabus;
  final List<String> prerequisites;
  final List<String> tags;

  CourseModel({
    required this.courseId,
    required this.title,
    required this.description,
    required this.instructor,
    required this.category,
    required this.level,
    required this.duration,
    required this.thumbnailURL,
    required this.price,
    this.currency = 'USD',
    this.enrollmentCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.isPublished = false,
    required this.createdAt,
    this.updatedAt,
    required this.createdBy,
    this.syllabus = const [],
    this.prerequisites = const [],
    this.tags = const [],
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'title': title,
      'description': description,
      'instructor': instructor,
      'category': category,
      'level': level,
      'duration': duration,
      'thumbnailURL': thumbnailURL,
      'price': price,
      'currency': currency,
      'enrollmentCount': enrollmentCount,
      'rating': rating,
      'ratingCount': ratingCount,
      'isPublished': isPublished,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
      'createdBy': createdBy,
      'syllabus': syllabus.map((module) => module.toMap()).toList(),
      'prerequisites': prerequisites,
      'tags': tags,
    };
  }

  // Create from Firestore document
  factory CourseModel.fromMap(Map<String, dynamic> map) {
    // Robust parsing for timestamps and optional fields
    DateTime parseDate(dynamic value) {
      try {
        if (value == null) return DateTime.now();
                if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
        if (value is String) {
          final parsed = DateTime.tryParse(value);
          return parsed ?? DateTime.now();
        }
      } catch (_) {}
      return DateTime.now();
    }

    final createdAt = parseDate(map['createdAt']);
    final updatedAt =
        map['updatedAt'] != null ? parseDate(map['updatedAt']) : null;

    return CourseModel(
      courseId: map['id'] ?? map['courseId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      instructor: map['instructor'] ?? '',
      category: map['category'] ?? '',
      level: map['level'] ?? 'beginner',
      duration: map['duration'] ?? 0,
      thumbnailURL: map['thumbnailURL'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      currency: map['currency'] ?? 'USD',
      enrollmentCount: map['enrollmentCount'] ?? 0,
      rating: (map['rating'] ?? 0).toDouble(),
      ratingCount: map['ratingCount'] ?? 0,
      isPublished: map['isPublished'] ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: map['createdBy'] ?? '',
      syllabus: map['syllabus'] != null
          ? (map['syllabus'] as List)
              .map((item) => ModuleModel.fromMap(item))
              .toList()
          : [],
      prerequisites: List<String>.from(map['prerequisites'] ?? []),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Copy with method for updates
  CourseModel copyWith({
    String? courseId,
    String? title,
    String? description,
    String? instructor,
    String? category,
    String? level,
    int? duration,
    String? thumbnailURL,
    double? price,
    String? currency,
    int? enrollmentCount,
    double? rating,
    int? ratingCount,
    bool? isPublished,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    List<ModuleModel>? syllabus,
    List<String>? prerequisites,
    List<String>? tags,
  }) {
    return CourseModel(
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      instructor: instructor ?? this.instructor,
      category: category ?? this.category,
      level: level ?? this.level,
      duration: duration ?? this.duration,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      enrollmentCount: enrollmentCount ?? this.enrollmentCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isPublished: isPublished ?? this.isPublished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syllabus: syllabus ?? this.syllabus,
      prerequisites: prerequisites ?? this.prerequisites,
      tags: tags ?? this.tags,
    );
  }
}

// Module Model (for course syllabus)
class ModuleModel {
  final String moduleId;
  final String title;
  final List<LessonModel> lessons;

  ModuleModel({
    required this.moduleId,
    required this.title,
    this.lessons = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'moduleId': moduleId,
      'title': title,
      'lessons': lessons.map((lesson) => lesson.toMap()).toList(),
    };
  }

  factory ModuleModel.fromMap(Map<String, dynamic> map) {
    return ModuleModel(
      moduleId: map['id'] ?? map['moduleId'] ?? '',
      title: map['title'] ?? '',
      lessons: map['lessons'] != null
          ? (map['lessons'] as List)
              .map((item) => LessonModel.fromMap(item))
              .toList()
          : [],
    );
  }
}

// Lesson Model
class LessonModel {
  final String lessonId;
  final String title;
  final int duration; // in minutes
  final String type; // video, quiz, assignment, reading
  final String? videoURL; // YouTube URL
  final String? content; // For reading materials

  LessonModel({
    required this.lessonId,
    required this.title,
    required this.duration,
    required this.type,
    this.videoURL,
    this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'lessonId': lessonId,
      'title': title,
      'duration': duration,
      'type': type,
      'videoURL': videoURL,
      'content': content,
    };
  }

  factory LessonModel.fromMap(Map<String, dynamic> map) {
    return LessonModel(
      lessonId: map['id'] ?? map['lessonId'] ?? '',
      title: map['title'] ?? '',
      duration: map['duration'] ?? 0,
      type: map['type'] ?? 'video',
      videoURL: map['videoURL'],
      content: map['content'],
    );
  }
}
