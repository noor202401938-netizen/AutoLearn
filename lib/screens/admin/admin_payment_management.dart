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
          _payments = response.data as List<dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load payments. Status: ${response.statusCode}';
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        title: const Text('Confirm Refund', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to refund this payment?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Refund', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await _apiClient.post('/payments/$paymentId/refund', {});
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Refund processed successfully'), backgroundColor: Colors.green),
        );
        _fetchPayments();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refund: ${response.data['error'] ?? response.statusCode}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'succeeded': return Colors.green;
      case 'refunded': return Colors.redAccent;
      case 'pending': return Colors.orange;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)),
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
      return const Center(child: Text('No payments found.', style: TextStyle(color: Colors.white70, fontSize: 18)));
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Management',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
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
                final date = payment['createdAt'] != null ? DateTime.parse(payment['createdAt']) : null;
                final userEmail = payment['user']?['email'] ?? 'Unknown User';

                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      child: Icon(
                        status == 'succeeded' ? Icons.check_circle :
                        status == 'refunded' ? Icons.replay :
                        Icons.hourglass_empty,
                        color: _getStatusColor(status),
                      ),
                    ),
                    title: Text(
                      '$amount $currency - $userEmail',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          'Status: ${status.toUpperCase()}',
                          style: TextStyle(color: _getStatusColor(status), fontWeight: FontWeight.bold),
                        ),
                        if (date != null)
                          Text(
                            'Date: ${DateFormat('MMM d, yyyy - h:mm a').format(date.toLocal())}',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                          ),
                      ],
                    ),
                    trailing: status.toLowerCase() == 'succeeded'
                        ? ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.8),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
