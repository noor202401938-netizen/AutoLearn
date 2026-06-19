// lib/backend/payment_gateway_service.dart
import 'package:flutter_stripe/flutter_stripe.dart';
import 'dart:convert';
import 'api_client.dart';

class PaymentGatewayService {
  final ApiClient _apiClient = ApiClient.instance;
  // Stripe Configuration
  static const String _stripePublishableKey = 'YOUR_STRIPE_PUBLISHABLE_KEY';
  static const String _stripeSecretKey = 'YOUR_STRIPE_SECRET_KEY';
  static const String _stripeApiUrl = 'https://api.stripe.com/v1';

  // Initialize Stripe
  Future<void> initialize() async {
    Stripe.publishableKey = _stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  // Create payment intent from backend
  Future<Map<String, dynamic>> createPaymentIntent({
    required int amountCents,
    String currency = 'USD',
  }) async {
    try {
      final response = await _apiClient.post('/payments/create-intent', {
        'amount': amountCents,
        'currency': currency,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'id': data['id'],
          'client_secret': data['clientSecret'],
          'status': data['status'],
        };
      }
      
      throw Exception('Failed to create payment intent');
    } catch (e) {
      throw Exception('Payment initialization failed: $e');
    }
  }

  // Process payment with Stripe using payment method ID
  Future<bool> processPayment({
    required String paymentIntentClientSecret,
    required String paymentMethodId,
  }) async {
    try {
      // Confirm payment using existing payment method
      // Note: The payment method must be attached to the payment intent server-side
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(),
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Payment error: $e');
      return false;
    }
  }

  // Process payment with card details
  // NOTE: In flutter_stripe 11.x, card details should be collected using CardFormEditController widget
  // This method is a placeholder - for production, implement proper card input UI
  Future<bool> processPaymentWithCard({
    required String paymentIntentClientSecret,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
  }) async {
    try {
      // NOTE: Direct card input is not supported in flutter_stripe 11.x API
      // You must use CardFormEditController widget to collect card details
      // This is a placeholder implementation
      // 
      // For production implementation:
      // 1. Use CardFormEditController in your UI to collect card details
      // 2. Get the payment method from the controller
      // 3. Confirm payment with that payment method
      
      // For now, just confirm with empty payment method data
      // The payment method should be attached server-side before calling this
      await Stripe.instance.confirmPayment(
        paymentIntentClientSecret: paymentIntentClientSecret,
        data: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: const BillingDetails(),
          ),
        ),
      );
      return true;
    } catch (e) {
      print('Payment processing error: $e');
      return false;
    }
  }

  // For Easypaisa integration (if needed)
  Future<bool> processEasypaisaPayment({
    required String amount,
    required String phoneNumber,
  }) async {
    // Placeholder for Easypaisa integration
    // This would require Easypaisa SDK integration
    return false;
  }
}
