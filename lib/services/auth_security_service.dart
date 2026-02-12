import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../config/environment.dart';
import '../supabase_client.dart';
import '../utils/retry_utils.dart';

/// Service for handling enhanced authentication security features
class AuthSecurityService {
  final SupabaseClient _supabase = SupabaseClientManager().client;

  // RegExp constants for password validation
  static final RegExp _uppercaseRegex = RegExp(r'[A-Z]'); // ignore: deprecated_member_use
  static final RegExp _lowercaseRegex = RegExp(r'[a-z]'); // ignore: deprecated_member_use
  static final RegExp _numberRegex = RegExp(r'[0-9]'); // ignore: deprecated_member_use
  static final RegExp _specialCharRegex = RegExp(r'[!@#$%^&*(),.?":{}|<>]'); // ignore: deprecated_member_use

  /// Check if user has MFA enabled using custom database function
  Future<bool> isMFAEnabled() async {
    try {
      final response = await _supabase.rpc('is_mfa_enabled');
      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Check if password protection is enabled using custom database function
  Future<bool> isPasswordProtectionEnabled() async {
    try {
      final response = await _supabase.rpc('is_password_protection_enabled');
      return response as bool? ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get all security settings from database
  Future<Map<String, String>> getSecuritySettings() async {
    try {
      final response = await _supabase.rpc('get_security_settings');
      final Map<String, String> settings = {};
      
      if (response is List) {
        for (final item in response) {
          if (item is Map<String, dynamic>) {
            final key = item['setting_key'] as String?;
            final value = item['setting_value'] as String?;
            if (key != null && value != null) {
              settings[key] = value;
            }
          }
        }
      }
      
      return settings;
    } catch (e) {
      return {};
    }
  }

  /// Validate password strength using server-side function
  Future<bool> validatePasswordStrengthServer(String password) async {
    try {
      await _supabase.rpc('validate_password_strength', params: {
        'password_input': password,
      });
      return true;
    } catch (e) {
      // The function throws an exception for invalid passwords
      // Re-throw with a more user-friendly message
      final errorMessage = e.toString();
      final cleanMessage = errorMessage.replaceAll('Exception: ', '');
      throw Exception(cleanMessage);
    }
  }

  /// Get the current user's authentication level
  Future<String> getAuthenticationLevel() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return 'none';
    
    // Check if MFA is enabled for enhanced security level
    final mfaEnabled = await isMFAEnabled();
    return mfaEnabled ? 'enhanced' : 'basic';
  }

  /// Check if current session meets required security level
  Future<bool> meetsSecurityRequirements() async {
    final session = _supabase.auth.currentSession;
    if (session == null) return false;
    
    // Check if password protection is enabled
    final passwordProtection = await isPasswordProtectionEnabled();
    return passwordProtection;
  }

  /// Enhanced sign-in with password strength validation
  /// Note: This is client-side validation. Server-side leaked password protection
  /// must be enabled in Supabase dashboard
  Future<AuthResponse> signInWithPasswordValidation(
    String email, 
    String password,
  ) async {
    // Client-side password strength validation
    _validatePasswordStrength(password);
    
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final response = await _supabase.auth.signInWithPassword(
            email: email,
            password: password,
          );
          return response;
        } on AuthException catch (e) {
          throw _handleAuthException(e);
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

  /// Enhanced sign-up with password strength validation and breach checking
  /// This provides equivalent security to Supabase Pro's leaked password protection
  Future<AuthResponse> signUpWithPasswordValidation(
    String email, 
    String password, 
    String name,
  ) async {
    // Enhanced password validation with breach checking
    await validatePasswordWithBreachCheck(password);
    
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          print('📧 Attempting signup with password validation for: $email');
          
          final response = await _supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': name,
            },
            emailRedirectTo: _getEmailConfirmationUrl(),
          );
          
          if (response.user != null) {
            print('✅ User created successfully: ${response.user!.id}');
            print('📧 Email confirmed: ${response.user!.emailConfirmedAt != null ? "Yes" : "No"}');
            
            if (response.user!.emailConfirmedAt == null) {
              print('📬 Email confirmation sent to: $email');
              print('ℹ️ User must confirm email before they can sign in');
            }
          }
          
          return response;
        } on AuthException catch (e) {
          // Handle specific cases for email reuse
          if (e.message.contains('email') && e.message.contains('already')) {
            print('⚠️ Email already exists, attempting to resend confirmation...');
            // Try to resend confirmation email for existing unconfirmed user
            try {
              await _supabase.auth.resend(
                type: OtpType.signup,
                email: email,
                emailRedirectTo: _getEmailConfirmationUrl(),
              );
              print('📧 Confirmation email resent to: $email');
              // Return a mock response indicating email was sent
              return AuthResponse(
                user: null,
                session: null,
              );
            } catch (resendError) {
              print('❌ Failed to resend confirmation: $resendError');
              throw _handleAuthException(e);
            }
          }
          throw _handleAuthException(e);
        } catch (e) {
          throw Exception('Sign up failed: $e');
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(milliseconds: 500),
      shouldRetry: RetryUtils.shouldRetryAuthError,
      onRetry: (attempt, error) {
        print('🔄 Retry attempt $attempt for signup: $error');
      },
    );
  }

  /// Enhanced sign-up with basic validation (without breach checking)
  /// Use this if you want faster sign-up without API calls
  Future<AuthResponse> signUpWithBasicValidation(
    String email, 
    String password, 
    String name,
  ) async {
    // Basic password strength validation only
    _validatePasswordStrength(password);
    
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final response = await _supabase.auth.signUp(
            email: email,
            password: password,
            data: {
              'full_name': name,
            },
            emailRedirectTo: _getEmailConfirmationUrl(),
          );
          return response;
        } on AuthException catch (e) {
          throw _handleAuthException(e);
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

  /// Check if password has been compromised using HaveIBeenPwned API
  /// This provides equivalent functionality to Supabase Pro's leaked password protection
  Future<bool> checkPasswordBreach(String password) async {
    try {
      // Hash the password using SHA-1 (required by HaveIBeenPwned API)
      final bytes = utf8.encode(password);
      final digest = sha1.convert(bytes);
      final hash = digest.toString().toUpperCase();
      
      // Use k-anonymity: send only first 5 characters of hash
      final prefix = hash.substring(0, 5);
      final suffix = hash.substring(5);
      
      // Make API request to HaveIBeenPwned
      final url = Uri.parse('https://api.pwnedpasswords.com/range/$prefix');
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'Karate-Flutter-App-Security-Check',
          'Add-Padding': 'true', // Adds padding for additional privacy
        },
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        // Check if our password hash suffix appears in the response
        final lines = response.body.split('\n');
        for (final line in lines) {
          if (line.startsWith(suffix)) {
            // Password found in breach database
            final parts = line.split(':');
            if (parts.length == 2) {
              final count = int.tryParse(parts[1]) ?? 0;
              // Return true if password appears in breaches
              return count > 0;
            }
          }
        }
        // Password not found in breach database
        return false;
      } else if (response.statusCode == 429) {
        // Rate limited - assume password is safe rather than blocking user
        return false;
      } else {
        // API error - assume password is safe rather than blocking user
        return false;
      }
    } catch (e) {
      // Network error or timeout - assume password is safe rather than blocking user
      return false;
    }
  }

  /// Enhanced password validation with breach checking
  /// This provides equivalent security to Supabase Pro's leaked password protection
  Future<void> validatePasswordWithBreachCheck(String password) async {
    // First, run standard password strength validation
    _validatePasswordStrength(password);
    
    // Then check for breaches using HaveIBeenPwned API
    final isBreached = await checkPasswordBreach(password);
    if (isBreached) {
      throw Exception('This password has been found in data breaches and is not secure. Please choose a different password.');
    }
  }

  /// Client-side password strength validation
  void _validatePasswordStrength(String password) {
    if (password.length < 8) {
      throw Exception('Password must be at least 8 characters long');
    }
    
    if (!password.contains(_uppercaseRegex)) {
      throw Exception('Password must contain at least one uppercase letter');
    }

    if (!password.contains(_lowercaseRegex)) {
      throw Exception('Password must contain at least one lowercase letter');
    }

    if (!password.contains(_numberRegex)) {
      throw Exception('Password must contain at least one number');
    }

    if (!password.contains(_specialCharRegex)) {
      throw Exception('Password must contain at least one special character');
    }
    
    // Check for common weak passwords (expanded list)
    final commonPasswords = [
      'password', '123456', '123456789', 'qwerty', 'abc123',
      'password123', 'admin', 'letmein', 'welcome', 'monkey',
      '12345678', 'football', 'iloveyou', 'princess', 'dragon',
      'password1', 'sunshine', 'master', 'hello', 'freedom',
      'whatever', 'qazwsx', 'trustno1', 'jordan23', 'harley',
      'robert', 'matthew', 'jordan', 'michelle', 'daniel',
      'christopher', 'anthony', 'william', 'joshua', 'andrew'
    ];
    
    if (commonPasswords.contains(password.toLowerCase())) {
      throw Exception('Password is too common. Please choose a stronger password');
    }
  }


  /// Get the email confirmation URL for professional email links
  String _getEmailConfirmationUrl() {
    // Build from configured Supabase URL to avoid hardcoded project ids.
    final baseUrl = Environment.supabaseUrl;
    return '$baseUrl/auth/v1/verify';
  }

  /// Handle general auth exceptions
  Exception _handleAuthException(AuthException e) {
    switch (e.statusCode) {
      case '400':
        if (e.message.contains('email')) {
          return Exception('Ongeldig e-mailadres');
        } else if (e.message.contains('password')) {
          return Exception('Wachtwoord voldoet niet aan de beveiligingseisen');
        } else if (e.message.contains('leaked')) {
          return Exception('Dit wachtwoord is aangetroffen in datalekken. Kies een ander wachtwoord');
        }
        return Exception('Ongeldige aanvraag: ${e.message}');
      
      case '401':
        return Exception('E-mailadres of wachtwoord is onjuist');
      
      case '403':
        return Exception('Toegang geweigerd. Controleer je rechten');
      
      case '422':
        if (e.message.contains('email')) {
          return Exception('E-mailadres is al geregistreerd');
        } else if (e.message.contains('password')) {
          return Exception('Wachtwoord is gecompromitteerd. Kies een ander wachtwoord');
        }
        return Exception('Ongeldige gegevens opgegeven: ${e.message}');
      
      case '429':
        return Exception('Te veel pogingen. Wacht even en probeer het opnieuw');
      
      case '500':
      case '502':
      case '503':
      case '504':
        return Exception('Serverfout. Probeer het later opnieuw');
      
      default:
        return Exception('Authenticatie mislukt: ${e.message}');
    }
  }
}
