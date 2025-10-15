#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

/// Script to upload downloaded images to Supabase storage using HTTP requests
/// This bypasses Flutter compilation issues

void main() async {
  print('🔄 Uploading Images to Supabase Storage');
  print('=====================================');
  
  // Supabase configuration
  const supabaseUrl = 'https://asvyjiuphcqfmwdpivsr.supabase.co';
  const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s';
  const bucketName = 'kata_images';
  
  // Check if restored_images directory exists
  final restoredDir = Directory('restored_images');
  if (!restoredDir.existsSync()) {
    print('❌ restored_images directory not found. Please run simple_restore_images.dart first.');
    return;
  }
  
  print('\n📋 Step 1: Checking restored images...');
  
  int totalUploaded = 0;
  int totalFailed = 0;
  
  // Get all kata directories
  final kataDirs = restoredDir.listSync()
      .where((entity) => entity is Directory)
      .cast<Directory>()
      .toList();
  
  if (kataDirs.isEmpty) {
    print('❌ No kata directories found in restored_images');
    return;
  }
  
  print('Found ${kataDirs.length} kata directories');
  
  for (final kataDir in kataDirs) {
    final kataId = kataDir.path.split('/').last;
    print('\n🔄 Processing kata $kataId');
    
    // Get all image files in this kata directory
    final imageFiles = kataDir.listSync()
        .where((file) => file is File && file.path.endsWith('.jpg'))
        .cast<File>()
        .toList();
    
    print('  Found ${imageFiles.length} images');
    
    for (final imageFile in imageFiles) {
      try {
        final fileName = imageFile.path.split('/').last;
        final filePath = '$kataId/$fileName';
        
        print('  📤 Uploading: $fileName');
        
        // Read image file
        final imageBytes = await imageFile.readAsBytes();
        
        // Upload to Supabase storage
        final uploadUrl = '$supabaseUrl/storage/v1/object/$bucketName/$filePath';
        
        final client = HttpClient();
        final request = await client.putUrl(Uri.parse(uploadUrl));
        
        // Set headers
        request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
        request.headers.set('Content-Type', 'image/jpeg');
        request.headers.set('x-upsert', 'true'); // Allow overwriting
        
        // Write image data
        request.add(imageBytes);
        
        final response = await request.close();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('  ✅ Uploaded: $fileName (${_formatBytes(imageBytes.length)})');
          totalUploaded++;
        } else {
          final responseBody = await response.transform(utf8.decoder).join();
          print('  ❌ Upload failed: ${response.statusCode} - $responseBody');
          totalFailed++;
        }
        
        client.close();
        
      } catch (e) {
        print('  ❌ Error uploading ${imageFile.path.split('/').last}: $e');
        totalFailed++;
      }
    }
  }
  
  print('\n📊 Upload Summary:');
  print('  ✅ Successfully uploaded: $totalUploaded images');
  print('  ❌ Failed uploads: $totalFailed images');
  
  // Verify uploads by listing bucket contents
  print('\n📋 Step 2: Verifying uploads...');
  
  try {
    final listUrl = '$supabaseUrl/storage/v1/object/list/$bucketName';
    
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(listUrl));
    request.headers.set('Authorization', 'Bearer $supabaseAnonKey');
    
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final responseBody = await response.transform(utf8.decoder).join();
      final files = jsonDecode(responseBody) as List;
      
      print('📁 Files in bucket:');
      for (final file in files) {
        if (file is Map && file['name'] != null) {
          print('  - ${file['name']}');
        }
      }
    } else {
      print('❌ Failed to list bucket contents: ${response.statusCode}');
    }
    
    client.close();
    
  } catch (e) {
    print('❌ Error verifying uploads: $e');
  }
  
  print('\n✅ Upload process completed!');
  print('Your kata images should now be available in the app.');
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}
