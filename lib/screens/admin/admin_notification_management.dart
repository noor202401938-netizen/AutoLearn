// lib/screens/admin/admin_notification_management.dart
import 'package:flutter/material.dart';
import '../../repository/notification_repository.dart';

class AdminNotificationManagement extends StatefulWidget {
  const AdminNotificationManagement({super.key});

  @override
  State<AdminNotificationManagement> createState() => _AdminNotificationManagementState();
}

class _AdminNotificationManagementState extends State<AdminNotificationManagement> {
  final NotificationRepository _notificationRepository = NotificationRepository();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _selectedType = 'system';
  bool _isSending = false;
  List<dynamic> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoadingHistory = true);
    try {
      final history = await _notificationRepository.getBroadcastHistory();
      if (mounted) {
        setState(() {
          _history = history;
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
      }
    }
  }

  Future<void> _sendBroadcastNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      await _notificationRepository.broadcastNotification(
        _titleController.text.trim(),
        _messageController.text.trim(),
        _selectedType,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Broadcast notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedType = 'system';
        });
        _fetchHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send broadcast: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Broadcast Notification',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Send a real-time notification to all students.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Notification Title',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Message Body',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a message';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    dropdownColor: Theme.of(context).colorScheme.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Notification Type',
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'system', child: Text('System Update')),
                      DropdownMenuItem(value: 'alert', child: Text('Alert / Urgent')),
                      DropdownMenuItem(value: 'course', child: Text('Course Update')),
                      DropdownMenuItem(value: 'promotional', child: Text('Promotional')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSending ? null : _sendBroadcastNotification,
                      child: _isSending
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Send Broadcast to All Students',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Broadcast History',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_history.isEmpty)
            Text(
              'No broadcast history found.',
              style: TextStyle(color: Colors.white.withOpacity(0.6)),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(item['title'] ?? 'No Title', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item['message'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                        const SizedBox(height: 4),
                        Text('Type: ${item['type']} | Sent: ${item['sentAt']}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
