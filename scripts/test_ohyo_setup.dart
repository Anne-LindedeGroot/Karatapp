#!/usr/bin/env dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Simple test to verify Ohyo database setup
Future<void> main() async {
  print('🧪 Testing Ohyo Database Setup...\n');

  try {
    // Initialize Supabase
    print('🔄 Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://asvyjiuphcqfmwdpivsr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQ5NzQ4NzAsImV4cCI6MjA1MDU1MDg3MH0.placeholder-key',
    );
    print('✅ Supabase initialized\n');

    final supabase = Supabase.instance.client;

    // Test 1: Check if ohyo table exists
    print('🔍 Testing ohyo table...');
    try {
      final response = await supabase.from('ohyo').select('count').limit(1);
      print('✅ Ohyo table exists');
    } catch (e) {
      print('❌ Ohyo table NOT found: $e');
      print('💡 SOLUTION: Create the ohyo table in Supabase SQL Editor:\n');
      print('''
CREATE TABLE ohyo (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  style TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  video_urls TEXT[],
  "order" INTEGER DEFAULT 0
);
      ''');
      return;
    }

    // Test 2: Check ohyo_images bucket
    print('\n🖼️ Testing ohyo_images storage bucket...');
    try {
      final buckets = await supabase.storage.listBuckets();
      final hasBucket = buckets.any((b) => b.id == 'ohyo_images');
      if (hasBucket) {
        print('✅ ohyo_images bucket exists');

        // Test storage policies by trying to list objects
        try {
          await supabase.storage.from('ohyo_images').list();
          print('✅ Storage policies allow access');
        } catch (e) {
          print('❌ Storage policies NOT configured properly: $e');
          print('💡 SOLUTION: Set up storage policies in Supabase Dashboard → Storage → Policies');
          print('   Create policies for SELECT, INSERT, UPDATE, DELETE on bucket_id = \'ohyo_images\'');
        }
      } else {
        print('❌ ohyo_images bucket NOT found');
        print('💡 SOLUTION: Create bucket in Supabase Dashboard → Storage → New bucket');
        print('   Name: ohyo_images, Make it Public: ✅');
      }
    } catch (e) {
      print('❌ Error checking storage: $e');
      print('💡 Make sure you have proper storage permissions');
    }

    // Test 3: Try inserting a test record
    print('\n📝 Testing ohyo insertion...');
    try {
      final testData = {
        'name': 'Test Ohyo - Please Delete',
        'description': 'This is a test record to verify database setup',
        'style': 'Test Stijl',
        'video_urls': <String>[],
        'order': 999,
      };

      final result = await supabase.from('ohyo').insert(testData).select().single();
      print('✅ Successfully inserted test ohyo');

      // Clean up
      await supabase.from('ohyo').delete().eq('id', result['id']);
      print('🧹 Cleaned up test data');

    } catch (e) {
      print('❌ Failed to insert ohyo: $e');
    }

    print('\n🎉 Database setup looks good! Try creating an Ohyo in the app now.');

  } catch (e) {
    print('❌ Test failed: $e');
    print('💡 Make sure your Supabase credentials are correct');
  }
}
