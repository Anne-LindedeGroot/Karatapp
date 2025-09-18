import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import '../utils/retry_utils.dart';
import '../core/storage/local_storage.dart' as app_storage;
import 'auth_security_service.dart';
import 'role_service.dart';

class AuthService {
  final SupabaseClient _supabase = SupabaseClientManager().client;
  final AuthSecurityService _securityService = AuthSecurityService();
  final RoleService _roleService = RoleService();
  
  // Enhanced sign up with password validation
  Future<AuthResponse> signUp(String email, String password, String name) async {
    // Use enhanced security service for password validation
    return await _securityService.signUpWithPasswordValidation(email, password, name);
  }
  
  // Legacy sign up method (kept for compatibility)
  Future<AuthResponse> signUpLegacy(String email, String password, String name) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final response = await _supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': name,
            },
          );
          return response;
        } on AuthException catch (e) {
          throw _handleAuthException(e, 'Sign up failed');
        } catch (e) {
          throw Exception('Sign up failed: $e');
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        // Retry attempt for sign up
      },
    );
  }
  
  // Sign in with email and password
  Future<AuthResponse> signIn(String email, String password) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final response = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return response;
        } on AuthException catch (e) {
          throw _handleAuthException(e, 'Sign in failed');
        } catch (e) {
          throw Exception('Sign in failed: $e');
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        // Retry attempt for sign in
      },
    );
  }
  
  // Update user name
  Future<void> updateUserName(String name) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final user = _supabase.auth.currentUser;
          if (user == null) {
            throw Exception('No authenticated user found');
          }
          
          await _supabase.auth.updateUser(
            UserAttributes(
              data: {
                'full_name': name,
              },
            ),
          );
        } on AuthException catch (e) {
          throw _handleAuthException(e, 'Update name failed');
        } catch (e) {
          throw Exception('Update name failed: $e');
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        // Retry attempt for updating user name
      },
    );
  }

  // Update user avatar
  Future<void> updateUserAvatar(String avatarData, String avatarType) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final user = _supabase.auth.currentUser;
          if (user == null) {
            throw Exception('No authenticated user found');
          }
          
          await _supabase.auth.updateUser(
            UserAttributes(
              data: {
                'avatar_id': avatarType == 'preset' ? avatarData : null,
                'avatar_url': avatarType == 'custom' ? avatarData : null,
                'avatar_type': avatarType,
              },
            ),
          );
        } on AuthException catch (e) {
          throw _handleAuthException(e, 'Update avatar failed');
        } catch (e) {
          throw Exception('Update avatar failed: $e');
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        // Retry attempt for updating user avatar
      },
    );
  }
  
  // Sign out
  Future<void> signOut() async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          await _supabase.auth.signOut();
          // Clear stored session on sign out
          await app_storage.LocalStorage.clearAuthSession();
        } on AuthException catch (e) {
          throw _handleAuthException(e, 'Sign out failed');
        } catch (e) {
          throw Exception('Sign out failed: $e');
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(milliseconds: 500),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        // Retry attempt for sign out
      },
    );
  }

  // Restore session from local storage
  Future<bool> restoreSession() async {
    try {
      print('🔄 Attempting to restore session...');
      
      // First try to use Supabase's built-in session recovery
      try {
        print('🔄 Trying Supabase built-in session recovery...');
        final session = _supabase.auth.currentSession;
        if (session?.user != null) {
          print('✅ Found existing Supabase session for user: ${session!.user.email}');
          return true;
        }
      } catch (e) {
        print('❌ No existing Supabase session: $e');
      }
      
      if (!app_storage.LocalStorage.hasValidAuthSession) {
        print('❌ No valid auth session found in storage');
        return false;
      }

      final session = app_storage.LocalStorage.getAuthSession();
      final accessToken = session['access_token'];
      final refreshToken = session['refresh_token'];
      final userId = session['user_id'];

      print('📱 Found stored session: userId=$userId');
      print('   Access token length: ${accessToken?.length ?? 0}');
      print('   Refresh token length: ${refreshToken?.length ?? 0}');
      print('   Access token preview: ${accessToken?.substring(0, 20)}...');
      print('   Refresh token preview: ${refreshToken?.substring(0, 20)}...');

      if (accessToken == null || refreshToken == null) {
        print('❌ Missing tokens in stored session');
        return false;
      }

      // Try to restore the session with Supabase using refresh token
      print('🔄 Restoring session with refresh token...');
      try {
        final refreshResponse = await _supabase.auth.refreshSession(refreshToken);
        if (refreshResponse.session?.user != null) {
          print('✅ Session refreshed successfully for user: ${refreshResponse.user?.email}');
          await _saveAuthSession(refreshResponse.session!);
          return true;
        }
      } catch (refreshError) {
        print('❌ Refresh token failed: $refreshError');
        
        // If refresh token fails, try to recover with access token
        print('🔄 Trying to recover with access token...');
        try {
          // Try to set the session manually
          await _supabase.auth.recoverSession(refreshToken);
          final currentUser = _supabase.auth.currentUser;
          if (currentUser != null) {
            print('✅ Session recovered successfully for user: ${currentUser.email}');
            return true;
          }
        } catch (recoverError) {
          print('❌ Session recovery failed: $recoverError');
        }
      }
      
      print('❌ All session restoration attempts failed');
      // Session is invalid, clear it
      await app_storage.LocalStorage.clearAuthSession();
      return false;
    } catch (e) {
      print('❌ Session restoration error: $e');
      // Session restoration failed, clear stored session
      await app_storage.LocalStorage.clearAuthSession();
      return false;
    }
  }

  // Save authentication session to local storage
  Future<void> _saveAuthSession(Session session) async {
    final refreshToken = session.refreshToken;
    final user = session.user;
    
    print('💾 Saving auth session to storage...');
    print('   User: ${user.email}');
    print('   Has access token: ${session.accessToken.isNotEmpty}');
    print('   Has refresh token: ${refreshToken?.isNotEmpty ?? false}');
    
      if (session.accessToken.isNotEmpty && 
        refreshToken != null && refreshToken.isNotEmpty) {
      await app_storage.LocalStorage.saveAuthSession(
        session.accessToken,
        refreshToken,
        user.id,
      );
      print('✅ Auth session saved successfully');
    } else {
      print('❌ Cannot save auth session - missing required data');
    }
  }

  // Enhanced sign in with session persistence
  Future<AuthResponse> signInWithPersistence(String email, String password) async {
    final response = await signIn(email, password);
    
    // Save session for persistence if sign in was successful
    if (response.session != null) {
      await _saveAuthSession(response.session!);
    }
    
    return response;
  }

  // Enhanced sign up with session persistence and user profile creation
  Future<AuthResponse> signUpWithPersistence(String email, String password, String name) async {
    final response = await signUp(email, password, name);
    
    // Save session for persistence if sign up was successful
    if (response.session != null) {
      await _saveAuthSession(response.session!);
      
      // Create user profile for user management
      if (response.user != null) {
        await _createUserProfile(response.user!, email, name);
      }
    }
    
    return response;
  }

  // Create user profile after successful registration
  Future<void> _createUserProfile(User user, String email, String name) async {
    try {
      print('📝 Creating user profile for: $email');
      await _roleService.createUserProfile(user.id, email, name);
      print('✅ User profile created successfully');
    } catch (e) {
      print('❌ Failed to create user profile: $e');
      // Don't throw error as this is not critical for auth flow
    }
  }

  // Enhanced sign up with profile creation (for both methods)
  Future<AuthResponse> signUpWithProfile(String email, String password, String name) async {
    final response = await signUp(email, password, name);
    
    // Create user profile if sign up was successful
    if (response.user != null) {
      await _createUserProfile(response.user!, email, name);
    }
    
    return response;
  }

  // Legacy sign up with profile creation
  Future<AuthResponse> signUpLegacyWithProfile(String email, String password, String name) async {
    final response = await signUpLegacy(email, password, name);
    
    // Create user profile if sign up was successful
    if (response.user != null) {
      await _createUserProfile(response.user!, email, name);
    }
    
    return response;
  }

  /// Handles AuthException and provides user-friendly error messages
  Exception _handleAuthException(AuthException e, String operation) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('email')) {
          return Exception('Invalid email address');
        } else if (e.message.contains('password')) {
          return Exception('Password must be at least 6 characters');
        }
        return Exception('Invalid request: ${e.message}');
      
      case '401':
        return Exception('Invalid email or password');
      
      case '403':
        return Exception('Access denied. Please check your permissions');
      
      case '422':
        if (e.message.contains('email')) {
          return Exception('Email address is already registered');
        }
        return Exception('Invalid data provided: ${e.message}');
      
      case '429':
        return Exception('Too many requests. Please wait a moment and try again');
      
      case '500':
      case '502':
      case '503':
      case '504':
        return Exception('Server error. Please try again later');
      
      default:
        return Exception('$operation: ${e.message}');
    }
  }
  
  // Get current user
  User? get currentUser => _supabase.auth.currentUser;
  
  // Get auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
}
