import 'package:cloud_firestore/cloud_firestore.dart';
// lib/model/notification_model.dart

class NotificationModel {
  final String notificationId;
  final String userId; // null for broadcast notifications
  final String title;
  final String body;
  final String type; // course, system, achievement, etc.
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? data; // Additional data

  NotificationModel({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    required this.createdAt,
    this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      notificationId: map['notificationId'] ?? '',
      userId: map['userId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: map['type'] ?? 'system',
      isRead: map['isRead'] ?? false,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      data: map['data'] != null
          ? Map<String, dynamic>.from(map['data'])
          : null,
    );
  }
}



