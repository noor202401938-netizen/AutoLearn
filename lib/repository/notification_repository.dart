// lib/repository/notification_repository.dart
import 'dart:async';
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    try {
      final response = await _apiClient.get('/user/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map<NotificationModel>((json) => NotificationModel(
          notificationId: json['id'],
          userId: json['userId'],
          title: json['title'],
          body: json['message'],
          createdAt: DateTime.parse(json['createdAt']),
          isRead: json['isRead'],
          type: json['type'],
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(String id) async {
    await _apiClient.put('/user/notifications/$id/read', {});
  }

  Future<void> markAllAsRead(String uid) async {
    await _apiClient.put('/user/notifications/read-all', {});
  }

  Future<int> getUnreadCount(String userId) async {
    try {
      final response = await _apiClient.get('/user/notifications/unread-count');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Stream<int> watchUnreadCount(String uid) {
    return Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) => getUnreadCount(uid))
        .distinct();
  }
  
  Stream<List<NotificationModel>> watchUserNotifications(String userId) {
    return Stream.periodic(const Duration(seconds: 15))
        .asyncMap((_) => getUserNotifications(userId))
        .distinct();
  }

  Future<void> createNotification(dynamic notification) async {
    try {
      await _apiClient.post('/user/notifications', notification);
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<void> broadcastNotification(String title, String message, String type) async {
    try {
      await _apiClient.post('/user/notifications/broadcast', {
        'title': title,
        'message': message,
        'type': type,
      });
    } catch (e) {
      throw Exception('Failed to broadcast notification: $e');
    }
  }

  Future<List<dynamic>> getBroadcastHistory() async {
    try {
      final response = await _apiClient.get('/user/notifications/broadcast-history');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
