// lib/business_logic/notification_manager.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../repository/notification_repository.dart';
import '../model/notification_model.dart';

class NotificationManager {
  final NotificationRepository _repository = NotificationRepository();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();

    // Setup Firebase messaging
    _setupFirebaseMessaging();
  }

  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _setupFirebaseMessaging() {
    _firebaseMessaging.getToken().then((token) {
      // Save FCM token to user profile
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
      _saveNotification(message);
    });
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'course_notifications',
      'Course Notifications',
      channelDescription: 'Notifications for course updates and activities',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? '',
      details,
    );
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    final notification = NotificationModel(
      notificationId: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      userId: message.data['userId'] ?? '',
      title: message.notification?.title ?? 'Notification',
      body: message.notification?.body ?? '',
      type: message.data['type'] ?? 'system',
      createdAt: DateTime.now(),
      data: message.data,
    );

    await _repository.createNotification(notification);
  }

  // Send local notification
  Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? userId,
    String type = 'system',
    Map<String, dynamic>? data,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'course_notifications',
      'Course Notifications',
      channelDescription: 'Notifications for course updates',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );

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

