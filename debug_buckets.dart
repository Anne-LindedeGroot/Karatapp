import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  print('🔍 Checking Supabase buckets...');

  try {
    await Supabase.initialize(
      url: 'https://asvyjiuphcqfmwdpivsr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s',
    );

    final supabase = Supabase.instance.client;

    print('\n📋 All buckets in your Supabase project:');
    final buckets = await supabase.storage.listBuckets();

    if (buckets.isEmpty) {
      print('❌ No buckets found at all!');
      return;
    }

    for (final bucket in buckets) {
      print('  - ${bucket.id} (public: ${bucket.public})');
    }

    // Check specifically for ohyo_images
    print('\n🎯 Checking ohyo_images specifically:');
    try {
      final bucket = await supabase.storage.getBucket('ohyo_images');
      print('✅ ohyo_images bucket exists (public: ${bucket.public})');

      // Try to list contents
      try {
        final files = await supabase.storage.from('ohyo_images').list();
        print('📁 Root contents: ${files.length} items');
      } catch (e) {
        print('❌ Cannot list contents: $e');
      }
    } catch (e) {
      print('❌ ohyo_images bucket not found: $e');
    }

  } catch (e) {
    print('❌ Error: $e');
  }
}
