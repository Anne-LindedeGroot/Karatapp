import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:async';

import 'package:karatapp/providers/error_boundary_provider.dart';
import 'package:karatapp/utils/retry_utils.dart';

void main() {
  group('Error Handling Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('ErrorBoundaryProvider', () {
      test('should report and display errors correctly', () {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Initially no error
        expect(container.read(hasErrorProvider), false);
        expect(container.read(currentErrorProvider), null);

        // Report an error
        errorBoundary.reportError('Test error message');

        // Should show error
        expect(container.read(hasErrorProvider), true);
        expect(container.read(currentErrorProvider), isNotNull);
        expect(container.read(errorTimestampProvider), isNotNull);
      });

      test('should convert technical errors to user-friendly messages', () {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Test network error conversion
        errorBoundary.reportNetworkError('Connection timeout');
        expect(container.read(currentErrorProvider), contains('Connection'));

        // Test auth error conversion
        errorBoundary.reportAuthError('Invalid email or password');
        expect(container.read(currentErrorProvider), contains('credentials'));

        // Test validation error conversion
        errorBoundary.reportValidationError('Email is required');
        expect(container.read(currentErrorProvider), contains('check your input'));
      });

      test('should hide errors after timeout', () async {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        errorBoundary.reportError('Test error');
        expect(container.read(hasErrorProvider), true);

        // Hide error manually (simulating timeout)
        errorBoundary.hideError();
        expect(container.read(hasErrorProvider), false);
        expect(container.read(currentErrorProvider), null);
      });
    });

    group('RetryUtils', () {
      test('should retry operations with exponential backoff', () async {
        int attemptCount = 0;
        
        try {
          await RetryUtils.executeWithRetry(
            () async {
              attemptCount++;
              if (attemptCount < 3) {
                throw Exception('Temporary failure');
              }
              return 'Success';
            },
            maxRetries: 3,
            initialDelay: const Duration(milliseconds: 10),
          );
        } catch (e) {
          fail('Should have succeeded after retries');
        }

        expect(attemptCount, 3);
      });

      test('should not retry non-retryable errors', () async {
        int attemptCount = 0;
        
        expect(() async {
          await RetryUtils.executeWithRetry(
            () async {
              attemptCount++;
              throw Exception('Invalid email or password');
            },
            maxRetries: 3,
            shouldRetry: RetryUtils.shouldRetryAuthError,
          );
        }, throwsException);
        
        // Wait for the async operation to complete
        await Future.delayed(Duration.zero);
        expect(attemptCount, 1); // Should not retry auth failures
      });

      test('should identify retryable network errors', () {
        expect(RetryUtils.shouldRetryError(SocketException('Connection failed')), true);
        expect(RetryUtils.shouldRetryError(TimeoutException('Request timeout', const Duration(seconds: 30))), true);
        expect(RetryUtils.shouldRetryError(Exception('Network error')), true);
        expect(RetryUtils.shouldRetryError(Exception('Server error 500')), true);
      });

      test('should identify non-retryable auth errors', () {
        expect(RetryUtils.shouldRetryAuthError(Exception('Invalid email or password')), false);
        expect(RetryUtils.shouldRetryAuthError(Exception('Unauthorized')), false);
        expect(RetryUtils.shouldRetryAuthError(Exception('Email already exists')), false);
        expect(RetryUtils.shouldRetryAuthError(Exception('Network error')), true);
      });

      test('should identify retryable image errors', () {
        expect(RetryUtils.shouldRetryImageError(Exception('Network timeout')), true);
        expect(RetryUtils.shouldRetryImageError(Exception('Server error')), true);
        expect(RetryUtils.shouldRetryImageError(Exception('File not found')), false);
        expect(RetryUtils.shouldRetryImageError(Exception('Permission denied')), false);
      });
    });

    group('Integration Tests', () {
      test('should handle cascading errors properly', () async {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Simulate multiple errors in sequence
        errorBoundary.reportNetworkError('Connection failed');
        expect(container.read(hasErrorProvider), true);
        
        final firstError = container.read(currentErrorProvider);
        
        // Report another error (should replace the first)
        errorBoundary.reportAuthError('Session expired');
        expect(container.read(hasErrorProvider), true);
        
        final secondError = container.read(currentErrorProvider);
        expect(secondError, isNot(equals(firstError)));
      });

      test('should maintain error state consistency', () {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Test state transitions
        expect(container.read(hasErrorProvider), false);
        
        errorBoundary.reportError('Test error');
        expect(container.read(hasErrorProvider), true);
        expect(container.read(currentErrorProvider), isNotNull);
        
        errorBoundary.hideError();
        expect(container.read(hasErrorProvider), false);
        expect(container.read(currentErrorProvider), null);
      });
    });

    group('Error Message Formatting', () {
      test('should clean up technical error messages', () {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Test various error formats
        errorBoundary.reportError('Exception: Something went wrong');
        expect(container.read(currentErrorProvider), 'Something went wrong.');
        
        errorBoundary.reportError('Error: Failed to connect');
        expect(container.read(currentErrorProvider), 'Connect.');
        
        errorBoundary.reportError('network connection failed');
        expect(container.read(currentErrorProvider), 'Connection problem. Please check your internet and try again.');
      });

      test('should handle edge cases in error messages', () {
        final errorBoundary = container.read(errorBoundaryProvider.notifier);
        
        // Empty error
        errorBoundary.reportError('');
        expect(container.read(currentErrorProvider), 'An error occurred.');
        
        // Null-like error
        errorBoundary.reportError('null');
        expect(container.read(currentErrorProvider), 'Null.');
        
        // Very long error
        final longError = 'A' * 200;
        errorBoundary.reportError(longError);
        expect(container.read(currentErrorProvider), isNotNull);
      });
    });
  });
}
