import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientManager {
  static final SupabaseClientManager _instance = SupabaseClientManager._internal();
  late SupabaseClient _client;
  
  factory SupabaseClientManager() {
    return _instance;
  }
  
  SupabaseClientManager._internal() {
    _client = Supabase.instance.client;
  }
  
  SupabaseClient get client => _client;
}
