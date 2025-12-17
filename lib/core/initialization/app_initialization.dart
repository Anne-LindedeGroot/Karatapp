import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../config/environment.dart';
import '../../core/storage/local_storage.dart' as app_storage;
import '../../supabase_client.dart';

// Global initialization state
bool _supabaseInitialized = false;
bool _hiveInitialized = false;

// Lazy initialization - only when needed
Future<void> ensureSupabaseInitialized() async {
  if (!_supabaseInitialized) {
    try {
      // Try to access the client to check if Supabase is already initialized
      try {
        final testClient = Supabase.instance.client;
        // Test that the client is actually working by trying to access auth
        final _ = testClient.auth;
        _supabaseInitialized = true;
        // Initialize the client manager
        SupabaseClientManager().initializeClient();
        debugPrint('✅ Supabase already initialized and working');
        return;
      } catch (e) {
        // If accessing client fails, Supabase is not initialized yet
        debugPrint('🔄 Supabase not initialized yet, but instance exists. This is normal.');
      }

      // Try to initialize Supabase
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
      );
      _supabaseInitialized = true;
      // Initialize the client manager
      SupabaseClientManager().initializeClient();
      debugPrint('✅ Supabase initialized successfully in ensureSupabaseInitialized');
    } catch (e) {
      // Check if the error is about double initialization or already initialized
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('already initialized') ||
          errorString.contains('has already been initialized')) {
        _supabaseInitialized = true;
        // Initialize the client manager even if Supabase was already initialized
        try {
          SupabaseClientManager().initializeClient();
          debugPrint('✅ Supabase was already initialized (handled double init)');
        } catch (clientError) {
          debugPrint('⚠️ Client manager init failed after double init: $clientError');
        }
        return;
      }

      debugPrint('❌ Supabase initialization error in ensureSupabaseInitialized: $e');
      // Don't throw - let the app continue
      // The network provider will handle connection status
      rethrow; // Re-throw so callers know initialization failed
    }
  }
}

// Lazy Hive initialization
Future<void> ensureHiveInitialized() async {
  if (!_hiveInitialized) {
    try {
      await Hive.initFlutter();
      _hiveInitialized = true;
    } catch (e) {
      debugPrint('Hive initialization error: $e');
    }
  }
}

// Initialize local storage boxes
Future<void> initializeLocalStorage() async {
  try {
    await app_storage.LocalStorage.initialize();
  } catch (e) {
    debugPrint('Local storage initialization error: $e');
  }
}
