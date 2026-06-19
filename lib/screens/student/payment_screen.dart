// lib/screens/student/payment_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/payment_manager.dart';

class PaymentScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final int amountCents; // course fee in cents
  final String currency;

  const PaymentScreen({super.key, required this.courseId, required this.courseTitle, required this.amountCents, this.currency = 'USD'});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentManager _paymentManager = PaymentManager();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _paymentManager.startPendingPayment(
      courseId: widget.courseId,
      amountCents: widget.amountCents,
      currency: widget.currency,
    );
  }

  Future<void> _simulatePayNow() async {
    if (!mounted) return;
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(seconds: 1));
    await _paymentManager.confirmPaidForCourse(widget.courseId);
    if (!mounted) return;
    Navigator.pop(context, true); // return success
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.amountCents / 100).toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Enrollment'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enroll in Course',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Complete payment to enroll in this course and get full access to all lessons.'),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Course', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(widget.courseTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Text('Amount', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text('${widget.currency} $amount', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _simulatePayNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isProcessing
                    ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary, strokeWidth: 2))
                    : const Text('Pay Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


