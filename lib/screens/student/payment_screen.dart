// lib/screens/student/payment_screen.dart
import 'package:flutter/material.dart';
import '../../business_logic/payment_manager.dart';
import '../../backend/payment_gateway_service.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;

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
    
    try {
      final intent = await PaymentGatewayService().createPaymentIntent(
        amountCents: widget.amountCents,
        currency: widget.currency,
      );

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: intent['client_secret'],
          merchantDisplayName: 'AI Tutor App',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _paymentManager.confirmPaidForCourse(widget.courseId);
      if (!mounted) return;
      Navigator.pop(context, true); // return success
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amount = (widget.amountCents / 100).toStringAsFixed(2);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Complete Enrollment', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
              Theme.of(context).colorScheme.background,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enroll in Course',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete payment to enroll in this course and get full access to all lessons.',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Course', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        Text(widget.courseTitle, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 12),
                        Text('Amount', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                        Text('${widget.currency} $amount', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _simulatePayNow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isProcessing
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Pay Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


