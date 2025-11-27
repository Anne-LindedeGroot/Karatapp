import 'dart:io';
import 'package:flutter/material.dart';
import 'package:karatapp/core/storage/local_storage.dart' as local_storage;
import 'package:karatapp/services/offline_sync_service.dart';
import 'package:karatapp/services/offline_media_cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🔍 Verifying Offline Functionality Status...\n');

  // Initialize local storage
  try {
    await local_storage.LocalStorage.initialize();
    print('✅ Local storage initialized');
  } catch (e) {
    print('❌ Local storage initialization failed: $e');
    return;
  }

  // Check cached data
  await checkCachedData();

  // Check media cache
  await checkMediaCache();

  // Check sync status
  await checkSyncStatus();

  print('\n🏁 Offline status verification completed');
}

Future<void> checkCachedData() async {
  print('\n📊 Checking Cached Data:');

  final katas = local_storage.LocalStorage.getAllKatas();
  final ohyos = local_storage.LocalStorage.getAllOhyos();
  final forumPosts = local_storage.LocalStorage.getAllForumPosts();

  print('  Katas cached: ${katas.length}');
  print('  Ohyos cached: ${ohyos.length}');
  print('  Forum posts cached: ${forumPosts.length}');

  if (katas.isNotEmpty) {
    final sampleKata = katas.first;
    print('  Sample kata: "${sampleKata.name}" (ID: ${sampleKata.id})');
    print('    Liked: ${sampleKata.isLiked}, Likes: ${sampleKata.likeCount}');
    print('    Images: ${sampleKata.imageUrls.length} URLs');
  }

  if (ohyos.isNotEmpty) {
    final sampleOhyo = ohyos.first;
    print('  Sample ohyo: "${sampleOhyo.name}" (ID: ${sampleOhyo.id})');
    print('    Liked: ${sampleOhyo.isLiked}, Likes: ${sampleOhyo.likeCount}');
    print('    Images: ${sampleOhyo.imageUrls.length} URLs');
  }

  if (forumPosts.isNotEmpty) {
    final samplePost = forumPosts.first;
    print('  Sample forum post: "${samplePost.title}"');
    print('    Likes: ${samplePost.likesCount}, Comments: ${samplePost.commentsCount}');
  }
}

Future<void> checkMediaCache() async {
  print('\n🖼️  Checking Media Cache:');

  try {
    // Initialize media cache
    await OfflineMediaCacheService.initialize();
    print('  ✅ Media cache service initialized');

    // Check cache size
    final cacheSize = await OfflineMediaCacheService.getCacheSize();
    print('  📏 Cache size: ${cacheSize ~/ 1024} KB (${cacheSize ~/ (1024 * 1024)} MB)');

    // Check cache directory
    final cacheDir = Directory('${Directory.systemTemp.path}/media_cache');
    if (cacheDir.existsSync()) {
      final imagesDir = Directory('${cacheDir.path}/images');
      final videosDir = Directory('${cacheDir.path}/videos');

      print('  📁 Cache directory exists');
      print('  📁 Images directory: ${imagesDir.existsSync() ? 'exists' : 'missing'}');
      print('  📁 Videos directory: ${videosDir.existsSync() ? 'exists' : 'missing'}');

      // Count files in directories
      if (imagesDir.existsSync()) {
        final imageFiles = imagesDir.listSync().whereType<File>().length;
        print('  🖼️  Cached images: $imageFiles files');
      }

      if (videosDir.existsSync()) {
        final videoFiles = videosDir.listSync().whereType<File>().length;
        print('  🎬 Cached videos: $videoFiles files');
      }
    } else {
      print('  ❌ Cache directory missing');
    }
  } catch (e) {
    print('  ❌ Media cache check failed: $e');
  }
}

Future<void> checkSyncStatus() async {
  print('\n🔄 Checking Sync Status:');

  try {
    final syncService = OfflineSyncService();

    // Check if comprehensive cache is completed
    final isCompleted = await syncService.isComprehensiveCacheCompleted();
    print('  📋 Comprehensive cache completed: $isCompleted');

    // Check settings
    final comprehensiveCacheCompleted = local_storage.LocalStorage.getSetting('comprehensive_cache_completed', defaultValue: false);
    print('  ⚙️  Comprehensive cache setting: $comprehensiveCacheCompleted');

  } catch (e) {
    print('  ❌ Sync status check failed: $e');
  }
}
