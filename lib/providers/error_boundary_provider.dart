import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class ErrorBoundaryState {
  final String? error;
  final StackTrace? stackTrace;
  final DateTime? timestamp;
  final bool isVisible;

  const ErrorBoundaryState({
    this.error,
    this.stackTrace,
    this.timestamp,
    this.isVisible = false,
  });

  ErrorBoundaryState.initial()
      : error = null,
        stackTrace = null,
        timestamp = null,
        isVisible = false;

  ErrorBoundaryState copyWith({
    String? error,
    StackTrace? stackTrace,
    DateTime? timestamp,
    bool? isVisible,
  }) {
    return ErrorBoundaryState(
      error: error,
      stackTrace: stackTrace,
      timestamp: timestamp,
      isVisible: isVisible ?? this.isVisible,
    );
  }

  @override
  String toString() {
    return 'ErrorBoundaryState(error: $error, isVisible: $isVisible, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ErrorBoundaryState &&
        other.error == error &&
        other.stackTrace == stackTrace &&
        other.timestamp == timestamp &&
        other.isVisible == isVisible;
  }

  @override
  int get hashCode {
    return error.hashCode ^
        stackTrace.hashCode ^
        timestamp.hashCode ^
        isVisible.hashCode;
  }
}

class ErrorBoundaryNotifier extends StateNotifier<ErrorBoundaryState> {
  ErrorBoundaryNotifier() : super(ErrorBoundaryState.initial());
  
  // Store the last failed operation for retry functionality
  Future<void> Function()? _lastFailedOperation;

  void reportError(String error, [StackTrace? stackTrace]) {
    // Check if this is a network error - if so, let the network provider handle it
    if (_isNetworkError(error)) {
      // Log for debugging but don't show in global error boundary
      if (kDebugMode) {
        print('🌐 Network Error (handled by NetworkProvider): $error');
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
      error: _getUserFriendlyErrorMessage(error),
      stackTrace: stackTrace,
      timestamp: DateTime.now(),
      isVisible: true,
    );

    // Auto-hide error after 15 seconds (increased from 10)
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && state.isVisible && state.error == _getUserFriendlyErrorMessage(error)) {
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

  void hideError() {
    state = state.copyWith(
      error: null,
      stackTrace: null,
      timestamp: null,
      isVisible: false,
    );
  }

  Future<void> retryLastOperation() async {
    if (_lastFailedOperation != null) {
      hideError();
      
      try {
        await _lastFailedOperation!();
        // Clear the failed operation on success
        _lastFailedOperation = null;
      } catch (e) {
        // If retry fails, show the error again
        reportError('Retry failed: ${e.toString()}');
      }
    } else {
      hideError();
    }
  }

  // Store operation for retry functionality
  void setRetryableOperation(Future<void> Function() operation, String description) {
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
    final userMessage = _getAuthErrorMessage(details);
    reportError(userMessage);
  }

  void reportValidationError(String message) {
    reportError(_getValidationErrorMessage(message));
  }

  void reportUnknownError([String? details]) {
    reportError(_getUnknownErrorMessage(details));
  }

  // Convert technical error messages to user-friendly ones
  String _getUserFriendlyErrorMessage(String error) {
    final errorLower = error.toLowerCase();
    
    // Network-related errors
    if (errorLower.contains('network') || 
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('socket')) {
      return 'Connection problem. Please check your internet and try again.';
    }
    
    // Authentication errors
    if (errorLower.contains('unauthorized') || 
        errorLower.contains('invalid email or password') ||
        errorLower.contains('authentication')) {
      return 'Sign in failed. Please check your credentials and try again.';
    }
    
    // Storage/Upload errors
    if (errorLower.contains('storage') || 
        errorLower.contains('upload') ||
        errorLower.contains('bucket')) {
      return 'File operation failed. Please try again.';
    }
    
    // Server errors
    if (errorLower.contains('server error') || 
        errorLower.contains('500') ||
        errorLower.contains('502') ||
        errorLower.contains('503')) {
      return 'Server is temporarily unavailable. Please try again later.';
    }
    
    // Rate limiting
    if (errorLower.contains('rate limit') || 
        errorLower.contains('too many requests')) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    
    // Permission errors
    if (errorLower.contains('permission') || 
        errorLower.contains('access denied') ||
        errorLower.contains('forbidden')) {
      return 'Access denied. Please check your permissions.';
    }
    
    // Return original error if no pattern matches, but clean it up
    return _cleanErrorMessage(error);
  }


  String _getAuthErrorMessage(String? details) {
    if (details == null) {
      return 'Authentication failed. Please try signing in again.';
    }
    
    final detailsLower = details.toLowerCase();
    if (detailsLower.contains('invalid email or password')) {
      return 'Invalid email or password. Please check your credentials.';
    } else if (detailsLower.contains('email')) {
      return 'Please enter a valid email address.';
    } else if (detailsLower.contains('password')) {
      return 'Password must be at least 6 characters long.';
    } else if (detailsLower.contains('already registered')) {
      return 'This email is already registered. Try signing in instead.';
    } else {
      return 'Authentication failed. Please try again.';
    }
  }

  String _getValidationErrorMessage(String message) {
    return 'Please check your input: ${_cleanErrorMessage(message)}';
  }

  String _getUnknownErrorMessage(String? details) {
    if (details == null) {
      return 'Something went wrong. Please try again.';
    }
    return 'Unexpected error: ${_cleanErrorMessage(details)}';
  }

  String _cleanErrorMessage(String error) {
    // Remove common technical prefixes
    String cleaned = error
        .replaceAll(RegExp(r'^Exception:\s*'), '')
        .replaceAll(RegExp(r'^Error:\s*'), '')
        .replaceAll(RegExp(r'^Failed to\s*'), '')
        .replaceAll(RegExp(r':\s*null$'), '');
    
    // Capitalize first letter
    if (cleaned.isNotEmpty) {
      cleaned = cleaned[0].toUpperCase() + cleaned.substring(1);
    }
    
    // Ensure it ends with a period
    if (cleaned.isNotEmpty && !cleaned.endsWith('.')) {
      cleaned += '.';
    }
    
    return cleaned.isEmpty ? 'An error occurred.' : cleaned;
  }
}

// Provider for the ErrorBoundaryNotifier
final errorBoundaryProvider = StateNotifierProvider<ErrorBoundaryNotifier, ErrorBoundaryState>((ref) {
  return ErrorBoundaryNotifier();
});

// Convenience providers
final hasErrorProvider = Provider<bool>((ref) {
  return ref.watch(errorBoundaryProvider).isVisible;
});

final currentErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(errorBoundaryProvider);
  return state.isVisible ? state.error : null;
});

final errorTimestampProvider = Provider<DateTime?>((ref) {
  return ref.watch(errorBoundaryProvider).timestamp;
});
