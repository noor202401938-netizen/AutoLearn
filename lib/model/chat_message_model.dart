import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'messageId': messageId,
      'userId': userId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'courseId': courseId,
      'lessonId': lessonId,
    };
  }

  // Create from Firestore document
  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      messageId: map['messageId'] ?? '',
      userId: map['userId'] ?? '',
      role: map['role'] ?? 'user',
      content: map['content'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      courseId: map['courseId'],
      lessonId: map['lessonId'],
    );
  }

  // Copy with method for updates
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

  // Check if message is from user
  bool get isUser => role == 'user';

  // Check if message is from assistant
  bool get isAssistant => role == 'assistant';
}

// Model for chat conversation/session
class ChatSessionModel {
  final String sessionId;
  final String userId;
  final String? title; // First user message or custom title
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
      'sessionId': sessionId,
      'userId': userId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt != null ? updatedAt!.toIso8601String() : null,
    };
  }

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      messages: [],
    );
  }
}



