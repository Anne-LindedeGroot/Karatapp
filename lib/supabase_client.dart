import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseClientManager {
  static final SupabaseClientManager _instance = SupabaseClientManager._internal();
  SupabaseClient? _client;
  
  factory SupabaseClientManager() {
    return _instance;
  }
  
  SupabaseClientManager._internal();
  
  SupabaseClient get client {
    if (_client == null) {
      try {
        _client = Supabase.instance.client;
      } catch (e) {
        throw Exception('Supabase not initialized. Call ensureSupabaseInitialized() first.');
      }
    }
    if (_client == null) {
      throw Exception('Supabase client not initialized. Call ensureSupabaseInitialized() first.');
    }
    return _client!;
  }
  
  // Method to initialize the client after Supabase is initialized
  void initializeClient() {
    try {
      _client = Supabase.instance.client;
      if (kDebugMode) {
        print('✅ SupabaseClientManager: Client initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SupabaseClientManager: Supabase not initialized yet: $e');
      }
    }
  }
}
