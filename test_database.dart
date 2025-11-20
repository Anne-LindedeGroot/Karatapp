import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://asvyjiuphcqfmwdpivsr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s',
  );

  final supabase = Supabase.instance.client;

  try {
    // Check if likes table exists
    final result = await supabase.from('likes').select('*').limit(1);
    print('Likes table exists, sample data: $result');

    // Check table structure by trying to select specific columns
    try {
      final columns = await supabase.from('likes').select('id, user_id, target_type, target_id, is_dislike, created_at').limit(1);
      print('Likes table columns: $columns');
    } catch (e) {
      print('Error checking likes table columns: $e');
    }
  } catch (e) {
    print('Error accessing likes table: $e');
  }
}
