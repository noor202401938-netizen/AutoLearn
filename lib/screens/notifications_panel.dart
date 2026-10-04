import 'package:flutter/material.dart';
import '../model/notification_model.dart';
import '../repository/notification_repository.dart';
import '../widgets/notebook/notebook.dart';

/// Announcements and course updates, newest first. Unread ones are
/// highlighted; tapping marks them read.
class NotificationsPanel extends StatefulWidget {
  const NotificationsPanel({super.key});

  @override
  State<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends State<NotificationsPanel> {
  final _repo = NotificationRepository();
  List<NotificationModel>? _items;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repo.getUserNotifications('');
    if (mounted) setState(() => _items = items);
  }

  Future<void> _read(NotificationModel n) async {
    if (n.isRead) return;
    await _repo.markAsRead(n.notificationId);
    _load();
  }

  Future<void> _readAll() async {
    await _repo.markAllAsRead('');
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nb = NotebookColors.of(context);
    final items = _items;
    final unread = items?.where((n) => !n.isRead).length ?? 0;
    return NotebookPage(
      title: 'Notifications',
      actions: [if (unread > 0) TextButton(onPressed: _readAll, child: const Text('Mark all read'))],
      body: items == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.all(24), children: [
                if (items.isEmpty)
                  const NotebookEmpty(title: "You're all caught up", note: 'announcements will appear here'),
                for (final n in items) ...[
                  NoteCard(
                    onTap: () => _read(n),
                    color: n.isRead ? null : nb.highlighter.withValues(alpha: theme.brightness == Brightness.dark ? 0.12 : 0.35),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Text(n.type.toUpperCase(), style: theme.textTheme.labelSmall),
                        const Spacer(),
                        Text(timeAgo(n.createdAt), style: theme.textTheme.bodySmall),
                      ]),
                      const SizedBox(height: 6),
                      Text(n.title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(n.body, style: theme.textTheme.bodyMedium),
                    ]),
                  ),
                  const SizedBox(height: 12),
                ],
              ]),
            ),
    );
  }
}
