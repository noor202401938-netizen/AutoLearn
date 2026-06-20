// lib/business_logic/notification_manager.dart
import '../repository/notification_repository.dart';
import '../model/notification_model.dart';

class NotificationManager {
  final NotificationRepository _repository = NotificationRepository();

  // Initialize notifications (no-op on web — Firebase Messaging removed)
  Future<void> initialize() async {
    // Firebase Messaging and local notifications not supported on web
  }

  // Send local notification (no-op on web)
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? userId,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    if (userId != null) {
      final notification = NotificationModel(
        notificationId: 'notif_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        title: title,
        body: body,
        type: type,
        createdAt: DateTime.now(),
        data: data,
      );
      await _repository.createNotification(notification);
    }
  }

  // Get user notifications
  Future<List<NotificationModel>> getUserNotifications(String userId) async {
    return await _repository.getUserNotifications(userId);
  }

  // Get unread count
  Future<int> getUnreadCount(String userId) async {
    return await _repository.getUnreadCount(userId);
  }

  // Mark as read
  Future<void> markAsRead(String notificationId) async {
    await _repository.markAsRead(notificationId);
  }

  // Mark all as read
  Future<void> markAllAsRead(String userId) async {
    await _repository.markAllAsRead(userId);
  }

  // Watch notifications
  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _repository.watchUserNotifications(userId);
  }
}
