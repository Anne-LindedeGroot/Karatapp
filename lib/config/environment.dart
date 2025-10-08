import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'https://asvyjiuphcqfmwdpivsr.supabase.co';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzQ4NzAsImV4cCI6MjA1MDU1MDg3MH0.placeholder-key';
  static String get appName => dotenv.env['APP_NAME'] ?? 'Karatapp';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (e) {
      // .env file not found or couldn't be loaded
      // This is normal for development - app will use default values
      debugPrint('Environment file not found, using default values');
    }
  }
}
