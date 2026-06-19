// lib/model/chat_message_model.dart

class ChatMessageModel {
  final String messageId;
  final String userId;
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;
  final String? courseId; // Optional: if related to a specific course
  final String? lessonId; // Optional: if related to a specific lesson

  ChatMessageModel({
    required this.messageId,
    required this.userId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.courseId,
    this.lessonId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': messageId,
      'userId': userId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'courseId': courseId,
      'lessonId': lessonId,
    };
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      messageId: json['id'] ?? json['messageId'] ?? '',
      userId: json['userId'] ?? '',
      role: json['role'] ?? 'user',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      courseId: json['courseId'],
      lessonId: json['lessonId'],
    );
  }

  ChatMessageModel copyWith({
    String? messageId,
    String? userId,
    String? role,
    String? content,
    DateTime? timestamp,
    String? courseId,
    String? lessonId,
  }) {
    return ChatMessageModel(
      messageId: messageId ?? this.messageId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      courseId: courseId ?? this.courseId,
      lessonId: lessonId ?? this.lessonId,
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

class ChatSessionModel {
  final String sessionId;
  final String userId;
  final String? title;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<ChatMessageModel> messages;

  ChatSessionModel({
    required this.sessionId,
    required this.userId,
    this.title,
    required this.createdAt,
    this.updatedAt,
    this.messages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': sessionId,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    return ChatSessionModel(
      sessionId: json['id'] ?? json['sessionId'] ?? '',
      userId: json['userId'] ?? '',
      title: json['title'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      messages: (json['messages'] as List<dynamic>?)
              ?.map((m) => ChatMessageModel.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
