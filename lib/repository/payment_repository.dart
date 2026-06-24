// lib/repository/payment_repository.dart
import 'dart:convert';
import '../backend/api_client.dart';

class PaymentRepository {
  final ApiClient _apiClient = ApiClient.instance;

  Future<bool> hasUserPaidForCourse({required String uid, required String courseId}) async {
    return false; // Real implementation would query backend for payments
  }

  Stream<bool> watchUserPaidForCourse({required String uid, required String courseId}) async* {
    yield false;
  }

  Future<void> createPendingPayment({
    required String uid,
    required String courseId,
    required int amountCents,
    required String currency,
  }) async {
    // In production, backend handles pending payment creation
  }

  Future<void> markPaidForCourse({required String uid, required String courseId}) async {
    // Endpoint to mark course paid/enrolled after successful stripe webhook
  }

  Future<Map<String, dynamic>> getFinancialStats() async {
    try {
      final response = await _apiClient.get('/finance/stats');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      return {};
    }
  }
}
