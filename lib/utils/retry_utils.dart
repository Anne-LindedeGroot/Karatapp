import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';

/// Utility class for implementing retry mechanisms with exponential backoff
class RetryUtils {
  /// Default retry configuration
  static const int defaultMaxRetries = 3;
  static const Duration defaultInitialDelay = Duration(seconds: 1);
  static const double defaultBackoffMultiplier = 2.0;
  static const Duration defaultMaxDelay = Duration(seconds: 30);

  /// Executes a function with retry logic and exponential backoff
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = defaultMaxRetries,
    Duration initialDelay = defaultInitialDelay,
    double backoffMultiplier = defaultBackoffMultiplier,
    Duration maxDelay = defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (attempt <= maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempt++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // If we've exhausted all retries, throw the error
        if (attempt > maxRetries) {
          if (kDebugMode) {
            print('🔄 Retry failed after $maxRetries attempts: $error');
          }
          rethrow;
        }

        // Log retry attempt
        if (kDebugMode) {
          print('🔄 Retry attempt $attempt/$maxRetries after ${currentDelay.inMilliseconds}ms delay: $error');
        }

        // Call retry callback if provided
        onRetry?.call(attempt, error);

        // Wait before retrying
        await Future.delayed(currentDelay);

        // Calculate next delay with exponential backoff and jitter
        currentDelay = Duration(
          milliseconds: min(
            (currentDelay.inMilliseconds * backoffMultiplier).round(),
            maxDelay.inMilliseconds,
          ),
        );

        // Add jitter to prevent thundering herd
        final jitter = Random().nextDouble() * 0.1; // 10% jitter
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * (1 + jitter)).round(),
        );
      }
    }

    throw StateError('This should never be reached');
  }

  /// Determines if an error should be retried based on common network/temporary errors
  static bool shouldRetryError(dynamic error) {
    if (error is SocketException) {
      return true; // Network connectivity issues
    }
    
    if (error is TimeoutException) {
      return true; // Request timeouts
    }
    
    if (error is HttpException) {
      final statusCode = _extractStatusCode(error.message);
      // Retry on server errors (5xx) and some client errors
      return statusCode >= 500 || 
             statusCode == 408 || // Request Timeout
             statusCode == 429 || // Too Many Requests
             statusCode == 502 || // Bad Gateway
             statusCode == 503 || // Service Unavailable
             statusCode == 504;   // Gateway Timeout
    }

    // Check for Supabase-specific errors that should be retried
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('server error') ||
        errorString.contains('service unavailable') ||
        errorString.contains('rate limit')) {
      return true;
    }

    return false;
  }

  /// Determines if an auth error should be retried
  static bool shouldRetryAuthError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Don't retry authentication failures, invalid credentials, etc.
    if (errorString.contains('invalid') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('not found') ||
        errorString.contains('email') ||
        errorString.contains('password')) {
      return false;
    }

    // Retry network and server errors
    return shouldRetryError(error);
  }

  /// Determines if an image operation error should be retried
  static bool shouldRetryImageError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    
    // Don't retry file not found or permission errors
    if (errorString.contains('not found') ||
        errorString.contains('permission denied') ||
        errorString.contains('access denied') ||
        errorString.contains('file does not exist')) {
      return false;
    }

    // Retry network and server errors
    return shouldRetryError(error);
  }

  /// Extracts HTTP status code from error message
  static int _extractStatusCode(String message) {
    final regex = RegExp(r'(\d{3})');
    final match = regex.firstMatch(message);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 0;
    }
    return 0;
  }

  /// Creates a retry configuration for network operations
  static RetryConfig networkRetryConfig() {
    return RetryConfig(
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      backoffMultiplier: 2.0,
      maxDelay: const Duration(seconds: 10),
      shouldRetry: shouldRetryError,
    );
  }

  /// Creates a retry configuration for auth operations
  static RetryConfig authRetryConfig() {
    return RetryConfig(
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      backoffMultiplier: 2.0,
      maxDelay: const Duration(seconds: 5),
      shouldRetry: shouldRetryAuthError,
    );
  }

  /// Creates a retry configuration for image operations
  static RetryConfig imageRetryConfig() {
    return RetryConfig(
      maxRetries: 3,
      initialDelay: const Duration(seconds: 2),
      backoffMultiplier: 1.5,
      maxDelay: const Duration(seconds: 15),
      shouldRetry: shouldRetryImageError,
    );
  }
}

/// Configuration class for retry operations
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(dynamic error)? shouldRetry;

  const RetryConfig({
    required this.maxRetries,
    required this.initialDelay,
    required this.backoffMultiplier,
    required this.maxDelay,
    this.shouldRetry,
  });
}

/// Extension to make retry operations easier to use
extension RetryExtension<T> on Future<T> {
  /// Adds retry capability to any Future
  Future<T> withRetry({
    int maxRetries = RetryUtils.defaultMaxRetries,
    Duration initialDelay = RetryUtils.defaultInitialDelay,
    double backoffMultiplier = RetryUtils.defaultBackoffMultiplier,
    Duration maxDelay = RetryUtils.defaultMaxDelay,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
  }) {
    return RetryUtils.executeWithRetry(
      () => this,
      maxRetries: maxRetries,
      initialDelay: initialDelay,
      backoffMultiplier: backoffMultiplier,
      maxDelay: maxDelay,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
    );
  }

  /// Adds retry capability with a predefined configuration
  Future<T> withRetryConfig(RetryConfig config) {
    return RetryUtils.executeWithRetry(
      () => this,
      maxRetries: config.maxRetries,
      initialDelay: config.initialDelay,
      backoffMultiplier: config.backoffMultiplier,
      maxDelay: config.maxDelay,
      shouldRetry: config.shouldRetry,
    );
  }
}
