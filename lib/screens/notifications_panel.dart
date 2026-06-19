// lib/screens/notifications_panel.dart
import 'package:flutter/material.dart';
import '../business_logic/notification_manager.dart';
import '../model/notification_model.dart';

class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final NotificationManager _notificationManager = NotificationManager();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final user = null /* was FirebaseAuth.instance.currentUser */;
      if (user != null) {
        _notifications = await _notificationManager.getUserNotifications(user.uid);
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await _notificationManager.markAsRead(notification.notificationId);
      setState(() {
        final index = _notifications.indexWhere(
          (n) => n.notificationId == notification.notificationId,
        );
        if (index != -1) {
          _notifications[index] = NotificationModel(
            notificationId: notification.notificationId,
            userId: notification.userId,
            title: notification.title,
            body: notification.body,
            type: notification.type,
            isRead: true,
            createdAt: notification.createdAt,
            data: notification.data,
          );
        }
      });
    }
  }

  Future<void> _markAllAsRead() async {
    final user = null /* was FirebaseAuth.instance.currentUser */;
    if (user != null) {
      await _notificationManager.markAllAsRead(user.uid);
      _loadNotifications();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF4169E1),
        foregroundColor: Colors.white,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllAsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : _buildNotificationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No Notifications',
            style: TextStyle(fontSize: 20, color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: notification.isRead ? Colors.white : Colors.blue[50],
          child: ListTile(
            leading: Icon(
              _getNotificationIcon(notification.type),
              color: const Color(0xFF4169E1),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead
                    ? FontWeight.normal
                    : FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(notification.body),
                const SizedBox(height: 4),
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : const Icon(Icons.circle, size: 8, color: Colors.blue),
            onTap: () => _markAsRead(notification),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'course':
        return Icons.school;
      case 'achievement':
        return Icons.workspace_premium;
      case 'quiz':
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

