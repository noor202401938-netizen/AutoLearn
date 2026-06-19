// lib/business_logic/crash_log_reporter.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'error_logger.dart';

class CrashLogReporter {
  final ErrorLogger _errorLogger = ErrorLogger();

  // Initialize crash reporting
  void initialize() {
    // Catch Flutter errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _errorLogger.logError(
        error: details.exceptionAsString(),
        stackTrace: details.stack ?? StackTrace.current,
        context: 'Flutter Error',
        additionalData: {
          'library': details.library,
          'informationCollector': details.informationCollector?.call().toString(),
        },
      );
    };

    // Catch async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _errorLogger.logError(
        error: error.toString(),
        stackTrace: stack,
        context: 'Async Error',
      );
      return true;
    };

    // Catch zone errors
    runZonedGuarded(
      () {},
      (error, stack) {
        _errorLogger.logError(
          error: error.toString(),
          stackTrace: stack,
          context: 'Zone Error',
        );
      },
    );
  }

  // Report custom error
  Future<void> reportError(
    dynamic error,
    StackTrace stackTrace, {
    String? context,
  }) async {
    await _errorLogger.logError(
      error: error.toString(),
      stackTrace: stackTrace,
      context: context,
    );
  }
}

