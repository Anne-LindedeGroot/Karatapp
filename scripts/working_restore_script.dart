#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Working script to restore kata images to Supabase bucket
/// This version bypasses Flutter compilation issues by using direct HTTP calls

void main() async {
  print('🔄 Restoring Kata Images to Supabase Bucket');
  print('==========================================');
  
  try {
    // Supabase configuration
    const supabaseUrl = 'https://asvyjiuphcqfmwdpivsr.supabase.co';
    const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s';
    
    // Sample kata data with image URLs
    final sampleKatas = [
      {
        'id': 1, 
        'name': 'Heian Shodan',
        'style': 'Shotokan',
        'images': [
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
        ]
      },
      {
        'id': 2,
        'name': 'Heian Nidan',
        'style': 'Shotokan',
        'images': [
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop',
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
        ]
      },
      {
        'id': 3,
        'name': 'Bassai Dai',
        'style': 'Shotokan',
        'images': [
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop',
        ]
      },
      {
        'id': 4,
        'name': 'Kanku Dai',
        'style': 'Shotokan',
        'images': [
          'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop',
        ]
      },
      {
        'id': 5,
        'name': 'Empi',
        'style': 'Shotokan',
        'images': [
          'https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=800&h=600&fit=crop',
        ]
      }
    ];
    
    print('\n📋 Step 1: Downloading and uploading sample images...');
    
    int totalUploaded = 0;
    int totalFailed = 0;
    
    for (final kata in sampleKatas) {
      final kataId = kata['id'] as int;
      final kataName = kata['name'] as String;
      final images = kata['images'] as List<String>;
      
      print('\n🔄 Processing kata $kataId: $kataName');
      
      for (int i = 0; i < images.length; i++) {
        try {
          final imageUrl = images[i];
          final fileName = 'kata_${kataId}_image_${i + 1}.jpg';
          
          print('  📥 Downloading: $fileName');
          
          // Download image
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode != 200) {
            print('  ❌ Failed to download image: ${response.statusCode}');
            totalFailed++;
            continue;
          }
          
          final imageBytes = response.bodyBytes;
          if (imageBytes.isEmpty) {
            print('  ❌ Downloaded image is empty');
            totalFailed++;
            continue;
          }
          
          // Upload to Supabase using direct HTTP call
          final filePath = '$kataId/$fileName';
          final uploadUrl = '$supabaseUrl/storage/v1/object/kata_images/$filePath';
          
          final uploadResponse = await http.post(
            Uri.parse(uploadUrl),
            headers: {
              'apikey': supabaseKey,
              'Authorization': 'Bearer $supabaseKey',
              'Content-Type': 'image/jpeg',
            },
            body: imageBytes,
          );
          
          if (uploadResponse.statusCode == 200) {
            print('  ✅ Uploaded: $fileName (${_formatBytes(imageBytes.length)})');
            totalUploaded++;
          } else {
            print('  ❌ Upload failed: ${uploadResponse.statusCode}');
            print('     Response: ${uploadResponse.body}');
            totalFailed++;
          }
          
        } catch (e) {
          print('  ❌ Error processing image ${i + 1}: $e');
          totalFailed++;
        }
      }
    }
    
    print('\n📊 Upload Summary:');
    print('  ✅ Successfully uploaded: $totalUploaded images');
    print('  ❌ Failed uploads: $totalFailed images');
    
    // Verify uploads
    print('\n📋 Step 2: Verifying uploads...');
    for (final kata in sampleKatas) {
      final kataId = kata['id'] as int;
      final kataName = kata['name'] as String;
      
      try {
        final listUrl = '$supabaseUrl/storage/v1/object/list/kata_images';
        final listResponse = await http.post(
          Uri.parse(listUrl),
          headers: {
            'apikey': supabaseKey,
            'Authorization': 'Bearer $supabaseKey',
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'prefix': '$kataId/',
            'limit': 100,
            'offset': 0,
            'sortBy': {'column': 'name', 'order': 'asc'}
          }),
        );
        
        if (listResponse.statusCode == 200) {
          final files = json.decode(listResponse.body);
          final imageFiles = files.where((f) => 
            f['name'].toString().isNotEmpty && 
            !f['name'].toString().startsWith('.') && 
            _isImageFile(f['name'].toString())
          ).toList();
          
          print('  📁 Kata $kataId ($kataName): ${imageFiles.length} images');
          for (final file in imageFiles) {
            print('    - ${file['name']}');
          }
        } else {
          print('  ❌ Error listing files for kata $kataId: ${listResponse.statusCode}');
        }
      } catch (e) {
        print('  ❌ Error listing files for kata $kataId: $e');
      }
    }
    
    print('\n✅ Image restoration completed!');
    print('Your kata images should now be available in the app.');
    
  } catch (e) {
    print('❌ Script failed: $e');
    print('\n🔧 Manual restoration steps:');
    print('1. Go to your Supabase dashboard');
    print('2. Navigate to Storage → kata_images bucket');
    print('3. Manually upload images organized by kata ID folders');
    print('4. Use the folder structure: kata_images/{kata_id}/image_name.jpg');
  }
}

String _formatBytes(int bytes) {
  if (bytes < 1024) return '${bytes}B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
}

bool _isImageFile(String fileName) {
  final extension = fileName.toLowerCase().split('.').last;
  return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
}
