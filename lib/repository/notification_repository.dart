// lib/repository/notification_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';
import '../model/notification_model.dart';

class NotificationRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<List<NotificationModel>> getUserNotifications(String uid) async {
    try {
      final response = await _apiClient.get('/user/notifications');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotificationModel(
          notificationId: json['id'],
          userId: json['userId'],
          title: json['title'],
          body: json['message'],
          timestamp: DateTime.parse(json['createdAt']),
          isRead: json['isRead'],
          type: json['type'],
        )).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead({required String uid, required String notificationId}) async {
    await _apiClient.put('/user/notifications/$notificationId/read', {});
  }

  Future<void> markAllAsRead(String uid) async {
    // Backend would need an endpoint to mark all as read
  }

  Stream<int> watchUnreadCount(String uid) async* {
    yield 0;
  }
}
