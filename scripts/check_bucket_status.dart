#!/usr/bin/env dart

import 'dart:convert';
import 'package:http/http.dart' as http;

/// Script to check the current status of the kata_images bucket
/// This will help us understand what's blocking the uploads

void main() async {
  print('🔍 Checking Kata Images Bucket Status');
  print('====================================');
  
  try {
    // Supabase configuration
    const supabaseUrl = 'https://asvyjiuphcqfmwdpivsr.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s';
    
    print('\n📋 Step 1: Checking if kata_images bucket exists...');
    
    // Check if bucket exists
    final bucketUrl = '$supabaseUrl/storage/v1/bucket/kata_images';
    final bucketResponse = await http.get(
      Uri.parse(bucketUrl),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
      },
    );
    
    if (bucketResponse.statusCode == 200) {
      final bucketData = json.decode(bucketResponse.body);
      print('✅ kata_images bucket exists:');
      print('  - ID: ${bucketData['id']}');
      print('  - Name: ${bucketData['name']}');
      print('  - Public: ${bucketData['public']}');
      print('  - File size limit: ${bucketData['file_size_limit']} bytes');
      print('  - Allowed MIME types: ${bucketData['allowed_mime_types']}');
    } else {
      print('❌ kata_images bucket not found (${bucketResponse.statusCode})');
      print('Response: ${bucketResponse.body}');
      return;
    }
    
    print('\n📋 Step 2: Listing current files in bucket...');
    
    // List files in bucket
    final listUrl = '$supabaseUrl/storage/v1/object/list/kata_images';
    final listResponse = await http.post(
      Uri.parse(listUrl),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'limit': 100,
        'offset': 0,
        'sortBy': {'column': 'name', 'order': 'asc'}
      }),
    );
    
    if (listResponse.statusCode == 200) {
      final files = json.decode(listResponse.body);
      if (files.isEmpty) {
        print('📁 Bucket is empty - no files found');
      } else {
        print('📁 Found ${files.length} files in bucket:');
        for (final file in files) {
          print('  - ${file['name']} (${_formatBytes(file['metadata']?['size'] ?? 0)})');
        }
      }
    } else {
      print('❌ Error listing files: ${listResponse.statusCode}');
      print('Response: ${listResponse.body}');
    }
    
    print('\n📋 Step 3: Testing upload permissions...');
    
    // Test upload with a small dummy file
    final testData = 'test';
    final testUrl = '$supabaseUrl/storage/v1/object/kata_images/test_upload.txt';
    
    final testResponse = await http.post(
      Uri.parse(testUrl),
      headers: {
        'apikey': supabaseKey,
        'Authorization': 'Bearer $supabaseKey',
        'Content-Type': 'text/plain',
      },
      body: testData,
    );
    
    if (testResponse.statusCode == 200) {
      print('✅ Upload test successful - permissions are working');
      
      // Clean up test file
      final deleteUrl = '$supabaseUrl/storage/v1/object/kata_images/test_upload.txt';
      await http.delete(
        Uri.parse(deleteUrl),
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
        },
      );
      print('🧹 Test file cleaned up');
    } else {
      print('❌ Upload test failed: ${testResponse.statusCode}');
      print('Response: ${testResponse.body}');
      
      if (testResponse.statusCode == 403) {
        print('\n🔧 SOLUTION: The bucket has Row Level Security (RLS) enabled');
        print('You need to either:');
        print('1. Run the SQL fix script in your Supabase dashboard');
        print('2. Or modify the bucket to allow public uploads');
        print('3. Or use authenticated requests instead of anon key');
      }
    }
    
  } catch (e) {
    print('❌ Script failed: $e');
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
