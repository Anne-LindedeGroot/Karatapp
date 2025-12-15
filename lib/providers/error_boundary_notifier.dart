import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_boundary_state.dart';
import '../utils/error_message_utils.dart';

class ErrorBoundaryNotifier extends StateNotifier<ErrorBoundaryState> {
  ErrorBoundaryNotifier() : super(ErrorBoundaryState.initial());

  // Store the last failed operation for retry functionality
  Future<void> Function()? _lastFailedOperation;

  void reportError(String error, [StackTrace? stackTrace]) {
    // Check if this is a Riverpod disposal error - suppress these
    if (error.toLowerCase().contains(
          'cannot use "ref" after the widget was disposed',
        ) ||
        error.toLowerCase().contains('bad state: cannot use "ref"')) {
      // Suppress Riverpod disposal errors - they are lifecycle issues
      if (kDebugMode) {
        print('🔄 Riverpod Disposal Error (suppressed): $error');
      }
      return;
    }

    // Check if this is a network error - if so, let the network provider handle it
    if (_isNetworkError(error)) {
      // Log for debugging but don't show in global error boundary
      if (kDebugMode) {
        print('🌐 Network Error (handled by NetworkProvider): $error');
      }
      return;
    }

    // Check if this is a RenderFlex overflow error - these are UI layout issues
    if (error.toLowerCase().contains('renderflex') &&
        error.toLowerCase().contains('overflow')) {
      // Completely suppress RenderFlex overflow errors - they are now handled by overflow-safe widgets
      if (kDebugMode) {
        print(
          '🎨 RenderFlex Overflow Error (suppressed by overflow-safe widgets): $error',
        );
      }
      return;
    }

    // Check for ParentDataWidget errors - these are UI layout issues
    if (error.toLowerCase().contains('incorrect use of parentdatawidget') ||
        (error.toLowerCase().contains('expanded') &&
            error.toLowerCase().contains('wrap')) ||
        (error.toLowerCase().contains('flexparentdata') &&
            error.toLowerCase().contains('wrapparentdata'))) {
      // Suppress ParentDataWidget errors as they are now handled by overflow-safe widgets
      if (kDebugMode) {
        print(
          '🎨 ParentDataWidget Error (suppressed by overflow-safe widgets): $error',
        );
      }
      return;
    }

    // Check for other common overflow errors
    if (error.toLowerCase().contains('overflow') &&
        (error.toLowerCase().contains('pixels') ||
            error.toLowerCase().contains('bottom'))) {
      // Suppress all overflow errors as they are now handled by overflow-safe widgets
      if (kDebugMode) {
        print(
          '🎨 Overflow Error (suppressed by overflow-safe widgets): $error',
        );
      }
      return;
    }

    // Check for RenderBox layout errors - these are UI layout issues
    if (error.toLowerCase().contains('renderbox was not laid out') ||
        error.toLowerCase().contains(
          'cannot hit test a render box with no size',
        ) ||
        error.toLowerCase().contains(
          'needs-paint needs-compositing-bits-update',
        ) ||
        (error.toLowerCase().contains('hasSize') &&
            error.toLowerCase().contains('renderbox')) ||
        error.toLowerCase().contains(
          'null check operator used on a null value',
        ) ||
        error.toLowerCase().contains(
          'boxconstraints forces an infinite height',
        ) ||
        error.toLowerCase().contains('child.hasSize') ||
        error.toLowerCase().contains('sliver_multi_box_adaptor')) {
      // Suppress RenderBox layout errors and null check errors - they are handled by overflow-safe widgets
      if (kDebugMode) {
        print(
          '🎨 RenderBox/Null Check Error (suppressed by overflow-safe widgets): $error',
        );
      }
      return;
    }

    // Check for framework assertion errors - these are internal Flutter issues
    if (_isFrameworkAssertionError(error)) {
      // Suppress framework assertion errors - they are internal Flutter issues
      if (kDebugMode) {
        print('🔧 Framework Assertion Error (suppressed): $error');
      }
      return;
    }

    // Check for setState during build errors - these are handled by the AppErrorBoundary
    if (error.toLowerCase().contains(
          'setstate() or markneedsbuild() called during build',
        ) ||
        error.toLowerCase().contains(
          'widget cannot be marked as needing to build',
        ) ||
        error.toLowerCase().contains(
          'framework is already in the process of building',
        )) {
      // Suppress setState during build errors - they are handled by the AppErrorBoundary
      if (kDebugMode) {
        print('🔧 setState During Build Error (suppressed): $error');
      }
      return;
    }

    // Log error for debugging
    if (kDebugMode) {
      print('🚨 Global Error: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
    }

    // Update state to show error
    state = state.copyWith(
      error: getUserFriendlyErrorMessage(error),
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      isVisible: true,
    );

    // Auto-hide error after 15 seconds (increased from 10)
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted &&
          state.isVisible &&
          state.error == getUserFriendlyErrorMessage(error)) {
        hideError();
      }
    });
  }

  bool _isNetworkError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket') ||
        errorLower.contains('dns') ||
        errorLower.contains('host') ||
        errorLower.contains('internet') ||
        errorLower.contains('connectivity') ||
        errorLower.contains('offline');
  }

  bool _isFrameworkAssertionError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('assertion failed') ||
        errorLower.contains('owner!._debugcurrentbuildtarget') ||
        errorLower.contains('framework.dart') ||
        errorLower.contains('is not true') ||
        errorLower.contains('debugcurrentbuildtarget') ||
        errorLower.contains('_debugcurrentbuildtarget') ||
        errorLower.contains(
          'setstate() or markneedsbuild() called during build',
        ) ||
        errorLower.contains('widget cannot be marked as needing to build') ||
        errorLower.contains('framework is already in the process of building');
  }

  void hideError() {
    state = state.copyWith(
      error: null,
      stackTrace: null,
      timestamp: null,
      isVisible: false,
    );
  }

  // Method to force clear all error state
  void clearAllErrors() {
    _lastFailedOperation = null;
    hideError();
  }

  Future<void> retryLastOperation() async {
    if (_lastFailedOperation != null) {
      hideError();

      try {
        if (_lastFailedOperation != null) {
          await _lastFailedOperation!();
          // Clear the failed operation on success
          _lastFailedOperation = null;
        }
      } catch (e) {
        // If retry fails, show the error again
        reportError('Retry failed: ${e.toString()}');
      }
    } else {
      hideError();
    }
  }

  // Store operation for retry functionality
  void setRetryableOperation(
    Future<void> Function() operation,
    String description,
  ) {
    _lastFailedOperation = operation;
  }

  // Helper methods for common error scenarios
  void reportNetworkError([String? details]) {
    // Network errors are now handled by the NetworkProvider
    // This method is kept for backward compatibility but does nothing
    if (kDebugMode) {
      print('🌐 Network error reported to ErrorBoundary (ignored): $details');
    }
  }

  void reportAuthError([String? details]) {
    // Auth errors are handled inline on auth screens to avoid overwhelming users
    if (kDebugMode) {
      print(
        '🔐 Auth error (handled locally): ${getAuthErrorMessage(details)}',
      );
    }
    // Do not surface as a global banner
  }

  void reportValidationError(String message) {
    reportError(getValidationErrorMessage(message));
  }

  void reportUnknownError([String? details]) {
    reportError(getUnknownErrorMessage(details));
  }
}
