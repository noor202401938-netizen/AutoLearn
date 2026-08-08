import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/api_client.dart';

class AdminPaymentManagement extends StatefulWidget {
  const AdminPaymentManagement({super.key});

  @override
  State<AdminPaymentManagement> createState() => _AdminPaymentManagementState();
}

class _AdminPaymentManagementState extends State<AdminPaymentManagement> {
  final ApiClient _apiClient = ApiClient.instance;
  List<dynamic> _payments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPayments();
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final response = await _apiClient.get('/payments');
      if (response.statusCode == 200) {
        setState(() {
          _payments = jsonDecode(response.body) as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Failed to load payments. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading payments: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refundPayment(String paymentId) async {
    final colorScheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text('Confirm Refund',
            style: TextStyle(color: colorScheme.onSurface)),
        content: Text('Are you sure you want to refund this payment?',
            style: TextStyle(color: colorScheme.onSurfaceVariant)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Refund', style: TextStyle(color: colorScheme.onError)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiClient.post('/payments/$paymentId/refund', {});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Refund processed successfully'),
              backgroundColor: Theme.of(context).colorScheme.secondary),
        );
        _fetchPayments();
      } else {
        String errorMsg = '${response.statusCode}';
        try {
          final body = jsonDecode(response.body);
          if (body['error'] != null) errorMsg = body['error'];
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to refund: $errorMsg'),
              backgroundColor: Theme.of(context).colorScheme.error),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error),
      );
    }
  }

  Color _getStatusColor(String status) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'succeeded':
        return colorScheme.secondary;
      case 'refunded':
        return colorScheme.error;
      case 'pending':
        return colorScheme.tertiary;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage,
                style: TextStyle(color: colorScheme.error, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchPayments,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_payments.isEmpty) {
      return Center(
          child: Text('No payments found.',
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant, fontSize: 18)));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payment Management',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface),
              ),
              IconButton(
                icon: Icon(Icons.refresh, color: colorScheme.onSurface),
                onPressed: _fetchPayments,
                tooltip: 'Refresh',
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _payments.length,
              itemBuilder: (context, index) {
                final payment = _payments[index];
                final status = payment['status'] ?? 'unknown';
                final amount = payment['amount'] ?? 0.0;
                final currency = payment['currency'] ?? 'USD';
                final date = payment['createdAt'] != null
                    ? DateTime.parse(payment['createdAt'])
                    : null;
                final userEmail = payment['user']?['email'] ?? 'Unknown User';

                return Card(
                  color: isDark
                      ? colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3)
                      : colorScheme.surfaceContainerHigh,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          _getStatusColor(status).withValues(alpha: 0.2),
                      child: Icon(
                        status == 'succeeded'
                            ? Icons.check_circle
                            : status == 'refunded'
                                ? Icons.replay
                                : Icons.hourglass_empty,
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Text(
                      '$amount $currency - $userEmail',
                      style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.bold),
                        ),
                        if (date != null)
                          Text(
                            'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(date.toLocal())}',
                            style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: status.toLowerCase() == 'succeeded'
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  colorScheme.error.withValues(alpha: 0.8),
                              foregroundColor: colorScheme.onError,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('Refund'),
                            onPressed: () => _refundPayment(payment['id']),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
