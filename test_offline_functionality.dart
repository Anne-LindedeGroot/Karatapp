import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karatapp/core/storage/local_storage.dart' as local_storage;
import 'package:karatapp/services/offline_sync_service.dart';
import 'package:karatapp/services/offline_media_cache_service.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://asvyjiuphcqfmwdpivsr.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s',
  );

  // Initialize local storage
  await local_storage.LocalStorage.initialize();

  print('🧪 Starting Offline Functionality Tests...');

  // Test 1: Check local storage initialization
  await testLocalStorageInitialization();

  // Test 2: Simulate offline sync
  await testOfflineSync();

  // Test 3: Test cached data retrieval
  await testCachedDataRetrieval();

  // Test 4: Test media caching
  await testMediaCaching();

  print('✅ Offline functionality tests completed!');
}

Future<void> testLocalStorageInitialization() async {
  print('\n📋 Test 1: Local Storage Initialization');

  try {
    final katas = local_storage.LocalStorage.getAllKatas();
    final ohyos = local_storage.LocalStorage.getAllOhyos();
    final forumPosts = local_storage.LocalStorage.getAllForumPosts();

    print('✅ Local storage initialized successfully');
    print('   Katas cached: ${katas.length}');
    print('   Ohyos cached: ${ohyos.length}');
    print('   Forum posts cached: ${forumPosts.length}');
  } catch (e) {
    print('❌ Local storage initialization failed: $e');
  }
}

Future<void> testOfflineSync() async {
  print('\n📋 Test 2: Offline Sync Simulation');

  try {
    // Test sync service initialization
    final syncService = OfflineSyncService();
    print('✅ Offline sync service created');

    // Test comprehensive cache check
    final isCompleted = await syncService.isComprehensiveCacheCompleted();
    print('✅ Comprehensive cache completed check: $isCompleted');

  } catch (e) {
    print('❌ Offline sync test failed: $e');
  }
}

Future<void> testCachedDataRetrieval() async {
  print('\n📋 Test 3: Cached Data Retrieval');

  try {
    // Test kata retrieval
    final katas = local_storage.LocalStorage.getAllKatas();
    if (katas.isNotEmpty) {
      final sampleKata = katas.first;
      print('✅ Sample kata retrieved: ${sampleKata.name} (ID: ${sampleKata.id})');
      print('   Liked: ${sampleKata.isLiked}, Like count: ${sampleKata.likeCount}');
      print('   Image URLs: ${sampleKata.imageUrls.length}');
    } else {
      print('⚠️  No katas cached yet');
    }

    // Test ohyo retrieval
    final ohyos = local_storage.LocalStorage.getAllOhyos();
    if (ohyos.isNotEmpty) {
      final sampleOhyo = ohyos.first;
      print('✅ Sample ohyo retrieved: ${sampleOhyo.name} (ID: ${sampleOhyo.id})');
      print('   Liked: ${sampleOhyo.isLiked}, Like count: ${sampleOhyo.likeCount}');
      print('   Image URLs: ${sampleOhyo.imageUrls.length}');
    } else {
      print('⚠️  No ohyos cached yet');
    }

    // Test forum post retrieval
    final forumPosts = local_storage.LocalStorage.getAllForumPosts();
    if (forumPosts.isNotEmpty) {
      final samplePost = forumPosts.first;
      print('✅ Sample forum post retrieved: ${samplePost.title} (ID: ${samplePost.id})');
      print('   Likes: ${samplePost.likesCount}, Comments: ${samplePost.commentsCount}');
    } else {
      print('⚠️  No forum posts cached yet');
    }

  } catch (e) {
    print('❌ Cached data retrieval test failed: $e');
  }
}

Future<void> testMediaCaching() async {
  print('\n📋 Test 4: Media Caching Test');

  try {
    // Initialize media cache
    await OfflineMediaCacheService.initialize();
    print('✅ Media cache service initialized');

    // Test cache directory creation
    final cacheDir = OfflineMediaCacheService.getCacheDirectory();
    print('✅ Cache directory: $cacheDir');

    // Test cache size
    final cacheSize = await OfflineMediaCacheService.getCacheSize();
    print('✅ Current cache size: ${cacheSize ~/ 1024} KB');

    // List all cached files
    print('\n📋 Checking existing cached files...');
    try {
      final files = Directory('$cacheDir/images').listSync();
      print('📁 Found $files.length files in images directory:');
      for (final file in files) {
        if (file is File) {
          final size = await file.length();
          print('  - ${file.path.split('/').last} ($size bytes)');
        }
      }
    } catch (e) {
      print('⚠️ Could not list cached files: $e');
    }

    // Test metadata methods
    print('\n📋 Testing cache metadata methods...');

    // Test kata metadata
    await OfflineMediaCacheService.updateKataMetadata(1, ['https://example.com/image1.jpg', 'https://example.com/image2.jpg']);
    final kataUrls = await OfflineMediaCacheService.getCachedKataImageUrls(1);
    print('✅ Kata metadata test: stored 2 URLs, retrieved ${kataUrls.length} cached paths');

    // Test ohyo metadata
    await OfflineMediaCacheService.cacheOhyoImage(1, 'image1.jpg', 'https://example.com/ohyo1.jpg', null);
    final ohyoPaths = await OfflineMediaCacheService.getCachedOhyoImagePaths(1);
    print('✅ Ohyo metadata test: cached 1 image, retrieved ${ohyoPaths.length} cached paths');

    // Check for real kata/ohyo cached files
    print('\n📋 Checking for real cached kata/ohyo files...');
    for (int id = 1; id <= 20; id++) {
      final kataCached = await OfflineMediaCacheService.getCachedKataImageUrls(id);
      if (kataCached.isNotEmpty) {
        print('✅ Kata $id has ${kataCached.length} cached images:');
        for (final path in kataCached) {
          final exists = File(path).existsSync();
          print('  - $path (${exists ? "EXISTS" : "MISSING"})');
        }
      }

      final ohyoCached = await OfflineMediaCacheService.getCachedOhyoImagePaths(id);
      if (ohyoCached.isNotEmpty) {
        print('✅ Ohyo $id has ${ohyoCached.length} cached images:');
        for (final path in ohyoCached) {
          final exists = File(path).existsSync();
          print('  - $path (${exists ? "EXISTS" : "MISSING"})');
        }
      }
    }

  } catch (e) {
    print('❌ Media caching test failed: $e');
  }
}
