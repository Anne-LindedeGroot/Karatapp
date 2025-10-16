import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import '../models/auth_state.dart';
import '../models/avatar_model.dart';
import '../services/auth_service.dart';
import '../core/initialization/app_initialization.dart';
import 'error_boundary_provider.dart';

// Provider for the AuthService instance - keep alive to maintain session state
final authServiceProvider = Provider<AuthService>((ref) {
  // Initialize Supabase immediately when auth service is first accessed
  ensureSupabaseInitialized();
  return AuthService();
});

// StateNotifier for authentication actions
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;
  final ErrorBoundaryNotifier _errorBoundary;

  AuthNotifier(this._authService, this._errorBoundary) : super(AuthState.initial()) {
    _initializeAuth();
    _listenToAuthChanges();
  }

  void _initializeAuth() async {
    print('🚀 AuthNotifier: Initializing auth...');
    
    // Set loading state during initialization
    if (mounted) {
      state = state.copyWith(isLoading: true);
    }
    
    try {
      // Ensure Supabase is initialized before checking session
      await ensureSupabaseInitialized();
      
      if (!mounted) return;
      
      // First check if there's a current user session
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        print('✅ AuthNotifier: Found existing Supabase session for user: ${currentUser.email}');
        if (mounted) {
          state = state.copyWith(
            user: currentUser,
            isAuthenticated: true,
            isLoading: false,
          );
        }
        return;
      }

      print('🔍 AuthNotifier: No existing Supabase session, trying to restore from storage...');
      
      // Try to restore session from local storage with timeout
      final restored = await _authService.restoreSession().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏰ AuthNotifier: Session restoration timed out');
          return false;
        },
      );
      
      if (!mounted) return;
      
      if (restored) {
        final user = _authService.currentUser;
        if (user != null) {
          print('✅ AuthNotifier: Session restored successfully for user: ${user.email}');
          if (mounted) {
            state = state.copyWith(
              user: user,
              isAuthenticated: true,
              isLoading: false,
            );
          }
        } else {
          print('❌ AuthNotifier: Session restored but no user found');
          if (mounted) {
            state = state.copyWith(isLoading: false);
          }
        }
      } else {
        print('❌ AuthNotifier: Session restoration failed or timed out');
        if (mounted) {
          state = state.copyWith(isLoading: false);
        }
      }
    } catch (e) {
      // Session restoration failed, continue with unauthenticated state
      print('❌ AuthNotifier: Session restoration error: $e');
      debugPrint('Session restoration failed: $e');
      if (mounted) {
        state = state.copyWith(isLoading: false, error: e.toString());
      }
    }
    
    print('🏁 AuthNotifier: Auth initialization complete. Authenticated: ${state.isAuthenticated}');
  }

  void _listenToAuthChanges() {
    // Listen to Supabase auth state changes to keep state in sync
    _authService.authStateChanges.listen((authState) {
      final user = authState.session?.user;
      final isAuthenticated = user != null;
      
      // Only update if the authentication status actually changed
      if (state.isAuthenticated != isAuthenticated) {
        print('🔄 AuthNotifier: Auth state changed - authenticated: $isAuthenticated');
        state = state.copyWith(
          user: user,
          isAuthenticated: isAuthenticated,
          isLoading: false,
          error: null,
        );
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await _authService.signInWithPersistence(email, password);
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
          error: null,
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isAuthenticated: false,
      );
      
      // Only report non-network auth errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportAuthError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Use the enhanced signup method that handles email confirmations reliably and creates user profiles
      final response = await _authService.signUpWithPersistence(email, password, name);
      
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt != null) {
          // User is immediately authenticated (email auto-confirmed)
          state = state.copyWith(
            user: response.user,
            isAuthenticated: true,
            isLoading: false,
            error: null,
          );
        } else {
          // User needs to confirm email
          state = state.copyWith(
            user: response.user,
            isAuthenticated: false,
            isLoading: false,
            error: 'Je account is aangemaakt maar nog niet geactiveerd. Controleer je e-mail (inclusief spam/junk folder) en klik op de bevestigingslink. Als je geen e-mail hebt ontvangen, probeer opnieuw in te loggen of neem contact op met de beheerder.',
          );
        }
      } else {
        // No user returned (likely email was resent)
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
          error: 'Een bevestigingsmail is verzonden naar $email. Controleer je e-mail (inclusief spam/junk folder) en klik op de bevestigingslink om je account te activeren.',
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isAuthenticated: false,
      );
      
      // Only report non-network auth errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportAuthError(errorMessage);
      }
      rethrow;
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  Future<void> signOut() async {
    if (!mounted) return;
    
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.signOut();
      if (mounted) {
        state = AuthState.initial();
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
      
      // Only report non-network auth errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportAuthError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> updateUserName(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.updateUserName(name);
      // Refresh user data
      final currentUser = _authService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network auth errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportAuthError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> updateUserAvatar(String avatarData, AvatarType avatarType) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      await _authService.updateUserAvatar(avatarData, avatarType.name);
      // Refresh user data
      final currentUser = _authService.currentUser;
      state = state.copyWith(
        user: currentUser,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = e.toString();
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network auth errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportAuthError(errorMessage);
      }
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void forceStopLoading() {
    if (mounted) {
      state = state.copyWith(isLoading: false);
    }
  }
}

// Provider for the AuthNotifier - keep alive to maintain session state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return AuthNotifier(authService, errorBoundary);
});

// Convenience providers for specific auth state properties
final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authNotifierProvider).error;
});

final authUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});

// Unified auth state provider for consistency across the app
final authStateProvider = Provider<AuthState>((ref) {
  return ref.watch(authNotifierProvider);
});

// Provider for current user (unified)
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authNotifierProvider).user;
});

// Provider for authentication status (unified)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authNotifierProvider).isAuthenticated;
});
