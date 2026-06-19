// lib/business_logic/error_logger.dart
import 'dart:developer' as developer;

class ErrorLogger {
  // Log error
  Future<void> logError({
    required String error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to console
      developer.log(
        error,
        name: 'ErrorLogger',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (e) {
      // Fallback to console only
      developer.log('Failed to log error: $e');
    }
  }

  // Log info
  void logInfo(String message, {String? context}) {
    developer.log(
      message,
      name: 'InfoLogger',
    );
  }

  // Log warning
  void logWarning(String message, {String? context}) {
    developer.log(
      message,
      name: 'WarningLogger',
      level: 900, // Warning level
    );
  }
}
