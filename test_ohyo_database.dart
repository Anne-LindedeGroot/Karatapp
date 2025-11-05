import 'package:supabase_flutter/supabase_flutter.dart';
import '../lib/config/environment.dart';

/// Simple test to check if Ohyo database is properly set up
Future<void> testOhyoDatabase() async {
  try {
    print('🔄 Initializing Supabase...');
    await Supabase.initialize(
      url: Environment.supabaseUrl,
      anonKey: Environment.supabaseAnonKey,
    );

    final supabase = Supabase.instance.client;
    print('✅ Supabase initialized');

    // Test 1: Check if ohyo table exists
    print('🔍 Testing ohyo table access...');
    try {
      final response = await supabase.from('ohyo').select('count').limit(1);
      print('✅ Ohyo table exists and is accessible');
      print('📊 Current record count: ${response.length}');
    } catch (e) {
      print('❌ Ohyo table does not exist or is not accessible: $e');
      print('💡 You need to create the ohyo table in Supabase');
      return;
    }

    // Test 2: Try to insert a test ohyo
    print('🧪 Testing ohyo insertion...');
    try {
      final testData = {
        'name': 'Test Ohyo',
        'description': 'This is a test ohyo to verify database setup',
        'style': 'Test Stijl',
        'video_urls': <String>[],
        'order': 0,
      };

      final insertResponse = await supabase
          .from('ohyo')
          .insert(testData)
          .select()
          .single();

      print('✅ Ohyo insertion successful');
      print('📋 Inserted ohyo: $insertResponse');

      // Clean up test data
      if (insertResponse['id'] != null) {
        await supabase.from('ohyo').delete().eq('id', insertResponse['id']);
        print('🧹 Cleaned up test data');
      }
    } catch (e) {
      print('❌ Ohyo insertion failed: $e');
    }

    // Test 3: Check ohyo_images storage bucket
    print('🖼️ Testing ohyo_images storage bucket...');
    try {
      final buckets = await supabase.storage.listBuckets();
      final ohyoBucket = buckets.firstWhere(
        (bucket) => bucket.id == 'ohyo_images',
        orElse: () => throw Exception('Bucket not found'),
      );
      print('✅ ohyo_images bucket exists');
    } catch (e) {
      print('❌ ohyo_images bucket does not exist: $e');
      print('💡 You need to create the ohyo_images storage bucket in Supabase');
    }

  } catch (e) {
    print('❌ Supabase initialization failed: $e');
    print('💡 Check your Supabase URL and anon key in environment.dart');
  }
}
