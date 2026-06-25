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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Notifications', style: theme.textTheme.titleMedium),
        backgroundColor: colorScheme.surface.withOpacity(0.8),
        elevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
        ],
      ),
      body: Container(
        color: colorScheme.surface,
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
              : _notifications.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildNotificationsList(colorScheme, isDark),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_none_rounded, size: 64, color: colorScheme.onSurfaceVariant.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            'No Notifications',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(ColorScheme colorScheme, bool isDark) {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: notification.isRead 
                ? (isDark ? colorScheme.surfaceContainerHighest.withOpacity(0.3) : Colors.white)
                : colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: notification.isRead 
                  ? colorScheme.outlineVariant.withOpacity(0.3)
                  : colorScheme.primary.withOpacity(0.3),
            ),
            boxShadow: notification.isRead ? null : [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: notification.isRead ? colorScheme.onSurfaceVariant.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getNotificationIcon(notification.type),
                color: notification.isRead ? colorScheme.onSurfaceVariant : colorScheme.primary,
              ),
            ),
            title: Text(
              notification.title,
              style: theme.textTheme.bodyMedium,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(notification.body, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.createdAt),
                  style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            trailing: notification.isRead
                ? null
                : Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
            onTap: () => _markAsRead(notification),
          ),
        );
      },
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'course':
        return Icons.school_rounded;
      case 'achievement':
        return Icons.workspace_premium_rounded;
      case 'quiz':
        return Icons.quiz_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
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
