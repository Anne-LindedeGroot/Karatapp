import 'package:flutter_test/flutter_test.dart';
import 'package:karatapp/models/auth_state.dart';

void main() {
  group('AuthState Tests', () {
    test('AuthState.initial() should create correct initial state', () {
      final initialState = AuthState.initial();
      
      expect(initialState.user, null);
      expect(initialState.isAuthenticated, false);
      expect(initialState.isLoading, false);
      expect(initialState.error, null);
    });

    test('AuthState.copyWith() should update only specified fields', () {
      final originalState = AuthState(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );

      final updatedState = originalState.copyWith(
        isLoading: true,
        error: 'Test error',
      );

      expect(updatedState.user, null);
      expect(updatedState.isAuthenticated, false);
      expect(updatedState.isLoading, true);
      expect(updatedState.error, 'Test error');
    });

    test('AuthState equality should work correctly', () {
      final state1 = AuthState(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );

      final state2 = AuthState(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: null,
      );

      final state3 = AuthState(
        user: null,
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('AuthState.copyWith() with null values should clear fields', () {
      final originalState = AuthState(
        user: null,
        isAuthenticated: true,
        isLoading: true,
        error: 'Some error',
      );

      final updatedState = originalState.copyWith(
        isLoading: false,
        error: null,
      );

      expect(updatedState.user, null);
      expect(updatedState.isAuthenticated, true);
      expect(updatedState.isLoading, false);
      expect(updatedState.error, null);
    });

    test('AuthState should handle different combinations of properties', () {
      // Test authenticated state
      final authenticatedState = AuthState(
        user: null, // In real app this would be a User object
        isAuthenticated: true,
        isLoading: false,
        error: null,
      );

      expect(authenticatedState.isAuthenticated, true);
      expect(authenticatedState.isLoading, false);
      expect(authenticatedState.error, null);

      // Test loading state
      final loadingState = AuthState(
        user: null,
        isAuthenticated: false,
        isLoading: true,
        error: null,
      );

      expect(loadingState.isAuthenticated, false);
      expect(loadingState.isLoading, true);
      expect(loadingState.error, null);

      // Test error state
      final errorState = AuthState(
        user: null,
        isAuthenticated: false,
        isLoading: false,
        error: 'Authentication failed',
      );

      expect(errorState.isAuthenticated, false);
      expect(errorState.isLoading, false);
      expect(errorState.error, 'Authentication failed');
    });
  });
}
