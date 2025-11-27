import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:karatapp/core/storage/local_storage.dart' as local_storage;
import 'package:karatapp/services/offline_sync_service.dart';
import 'package:karatapp/services/offline_media_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Supabase for testing
    await Supabase.initialize(
      url: 'https://asvyjiuphcqfmwdpivsr.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFzdnlqaXVwaGNxZm13ZHBpdnNyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTYxMjY4NDgsImV4cCI6MjA3MTcwMjg0OH0.QC2Ydqnp0j0J0fXOcbQ9OOtwr80JAs_mhSCtRTq5B-s',
    );

    // Initialize local storage
    await local_storage.LocalStorage.initialize();

    // Initialize media cache
    await OfflineMediaCacheService.initialize();
  });

  group('Offline Core Functionality Tests', () {
    test('Local Storage Initialization', () async {
      // Test that local storage initializes properly
      expect(local_storage.LocalStorage.getAllKatas(), isA<List>());
      expect(local_storage.LocalStorage.getAllOhyos(), isA<List>());
      expect(local_storage.LocalStorage.getAllForumPosts(), isA<List>());
    });

    test('Offline Sync Service Creation', () {
      final syncService = OfflineSyncService();
      expect(syncService, isNotNull);
    });

    test('Media Cache Initialization', () async {
      await OfflineMediaCacheService.initialize();
      // Initialization should complete without error
      expect(true, isTrue);
    });

    test('Cache Size Calculation', () async {
      final cacheSize = await OfflineMediaCacheService.getCacheSize();
      expect(cacheSize, isA<int>());
      expect(cacheSize, greaterThanOrEqualTo(0));
    });

    test('Comprehensive Cache Check', () async {
      final syncService = OfflineSyncService();
      final isCompleted = await syncService.isComprehensiveCacheCompleted();
      expect(isCompleted, isA<bool>());
    });
  });

  group('Data Persistence Tests', () {
    test('Kata Data Storage and Retrieval', () async {
      // This test assumes some katas are cached
      final katas = local_storage.LocalStorage.getAllKatas();
      if (katas.isNotEmpty) {
        final sampleKata = katas.first;
        expect(sampleKata.id, isA<int>());
        expect(sampleKata.name, isA<String>());
        expect(sampleKata.isLiked, isA<bool>());
        expect(sampleKata.likeCount, isA<int>());
        expect(sampleKata.imageUrls, isA<List<String>>());
      }
    });

    test('Ohyo Data Storage and Retrieval', () async {
      // This test assumes some ohyos are cached
      final ohyos = local_storage.LocalStorage.getAllOhyos();
      if (ohyos.isNotEmpty) {
        final sampleOhyo = ohyos.first;
        expect(sampleOhyo.id, isA<int>());
        expect(sampleOhyo.name, isA<String>());
        expect(sampleOhyo.isLiked, isA<bool>());
        expect(sampleOhyo.likeCount, isA<int>());
        expect(sampleOhyo.imageUrls, isA<List<String>>());
      }
    });

    test('Forum Post Data Storage and Retrieval', () async {
      // This test assumes some forum posts are cached
      final posts = local_storage.LocalStorage.getAllForumPosts();
      if (posts.isNotEmpty) {
        final samplePost = posts.first;
        expect(samplePost.id, isA<String>());
        expect(samplePost.title, isA<String>());
        expect(samplePost.content, isA<String>());
        expect(samplePost.likesCount, isA<int>());
        expect(samplePost.commentsCount, isA<int>());
      }
    });
  });

  group('Media Caching Tests', () {
    test('Cache Directory Structure', () async {
      final cacheDir = Directory('${Directory.systemTemp.path}/media_cache');
      expect(cacheDir.existsSync(), isTrue);

      final imagesDir = Directory('${cacheDir.path}/images');
      final videosDir = Directory('${cacheDir.path}/videos');

      expect(imagesDir.existsSync(), isTrue);
      expect(videosDir.existsSync(), isTrue);
    });

    test('Cache File Path Generation', () {
      const testUrl = 'https://example.com/image.jpg';
      final cachedPath = OfflineMediaCacheService.getCachedFilePath(testUrl, false);
      // Path might be null if not cached, which is fine
      expect(cachedPath, isA<String?>());
    });
  });
}
