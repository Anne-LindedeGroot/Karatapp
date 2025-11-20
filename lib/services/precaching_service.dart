import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/network_provider.dart';
import '../providers/data_usage_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/ohyo_provider.dart';
import 'offline_media_cache_service.dart';

/// Service for pre-caching media files in the background
class PreCachingService {
  static Timer? _backgroundTimer;
  static bool _isRunning = false;
  static const Duration _cacheInterval = Duration(hours: 6); // Cache every 6 hours
  static const Duration _initialDelay = Duration(seconds: 30); // Start after 30 seconds

  /// Initialize the pre-caching service
  static void initialize() {
    // Start background caching after initial delay
    Future.delayed(_initialDelay, () {
      _startBackgroundCaching();
    });
  }

  /// Start background caching with periodic checks
  static void _startBackgroundCaching() {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint('🗄️ Pre-caching service started');

    // Initial cache run
    _performBackgroundCaching();

    // Set up periodic caching
    _backgroundTimer = Timer.periodic(_cacheInterval, (_) {
      _performBackgroundCaching();
    });
  }

  /// Stop the pre-caching service
  static void stop() {
    _backgroundTimer?.cancel();
    _backgroundTimer = null;
    _isRunning = false;
    debugPrint('🗄️ Pre-caching service stopped');
  }

  /// Perform background caching of all media
  static Future<void> _performBackgroundCaching() async {
    try {
      debugPrint('🗄️ Starting background media caching...');

      // We'll use a callback approach since we can't directly access providers here
      // The actual caching will be triggered from the UI when providers are available

    } catch (e) {
      debugPrint('❌ Background caching failed: $e');
    }
  }

  /// Pre-cache all kata images
  static Future<void> preCacheAllKataImages(dynamic ref) async {
    try {
      // Check network status
      final networkState = ref.read(networkProvider);
      if (!networkState.isConnected) {
        debugPrint('📶 Skipping kata image caching - offline');
        return;
      }

      // Check data usage permission
      final dataUsageState = ref.read(dataUsageProvider);
      if (!dataUsageState.shouldAllowDataUsage) {
        debugPrint('📊 Skipping kata image caching - data usage disabled');
        return;
      }

      debugPrint('🗄️ Pre-caching kata images...');

      final currentState = ref.read(kataNotifierProvider);

      // Get all katas
      final allKatas = currentState.katas;

      if (allKatas.isEmpty) {
        debugPrint('📂 No katas found to cache - kata state: ${currentState.toString()}');
        return;
      }

      debugPrint('📂 Found ${allKatas.length} katas to check for images');

      int totalImages = 0;
      int cachedImages = 0;

      // Pre-cache images for each kata
      for (final kata in allKatas) {
        if (kata.imageUrls != null && kata.imageUrls!.isNotEmpty) {
          debugPrint('📸 Caching images for kata: ${kata.name} (${kata.imageUrls!.length} images)');

          for (final imageUrl in kata.imageUrls!) {
            totalImages++;
            try {
              final cachedPath = await OfflineMediaCacheService.cacheMediaFile(imageUrl, false, ref);
              if (cachedPath != null) {
                cachedImages++;
                // Update metadata for kata
                await OfflineMediaCacheService.updateKataMetadata(kata.id, imageUrl);
              }
            } catch (e) {
              debugPrint('❌ Failed to cache image $imageUrl: $e');
            }
          }
        }
      }

      debugPrint('✅ Kata image caching complete: $cachedImages/$totalImages images cached');

    } catch (e) {
      debugPrint('❌ Kata pre-caching failed: $e');
    }
  }

  /// Pre-cache all ohyo images
  static Future<void> preCacheAllOhyoImages(dynamic ref) async {
    try {
      // Check network status
      final networkState = ref.read(networkProvider);
      if (!networkState.isConnected) {
        debugPrint('📶 Skipping ohyo image caching - offline');
        return;
      }

      // Check data usage permission
      final dataUsageState = ref.read(dataUsageProvider);
      if (!dataUsageState.shouldAllowDataUsage) {
        debugPrint('📊 Skipping ohyo image caching - data usage disabled');
        return;
      }

      debugPrint('🗄️ Pre-caching ohyo images...');

      final currentState = ref.read(ohyoNotifierProvider);

      // Get all ohyos
      final allOhyos = currentState.ohyos;

      if (allOhyos.isEmpty) {
        debugPrint('📂 No ohyos found to cache');
        return;
      }

      int totalImages = 0;
      int cachedImages = 0;

      // Pre-cache images for each ohyo
      for (final ohyo in allOhyos) {
        if (ohyo.imageUrls != null && ohyo.imageUrls!.isNotEmpty) {
          debugPrint('📸 Caching images for ohyo: ${ohyo.name} (${ohyo.imageUrls!.length} images)');

          for (final imageUrl in ohyo.imageUrls!) {
            totalImages++;
            try {
              // For ohyo images, we need filename from URL to use stable caching
              final uri = Uri.parse(imageUrl);
              final filename = uri.pathSegments.last;
              final cachedPath = await OfflineMediaCacheService.cacheOhyoImage(ohyo.id, filename, imageUrl, ref);
              if (cachedPath != null) {
                cachedImages++;
              }
            } catch (e) {
              debugPrint('❌ Failed to cache ohyo image $imageUrl: $e');
            }
          }
        }
      }

      debugPrint('✅ Ohyo image caching complete: $cachedImages/$totalImages images cached');

    } catch (e) {
      debugPrint('❌ Ohyo pre-caching failed: $e');
    }
  }

  /// Pre-cache all media (kata + ohyo images)
  static Future<void> preCacheAllMedia(dynamic ref) async {
    debugPrint('🚀 Starting comprehensive media pre-caching...');

    await preCacheAllKataImages(ref);
    await preCacheAllOhyoImages(ref);

    debugPrint('🎉 All media pre-caching completed');
  }

  /// Get cache statistics
  static Future<Map<String, dynamic>> getCacheStats() async {
    final cacheSize = await OfflineMediaCacheService.getCacheSize();
    final cacheSizeMB = (cacheSize / (1024 * 1024)).round();

    return {
      'cacheSize': cacheSize,
      'cacheSizeMB': cacheSizeMB,
      'maxCacheSizeMB': 500, // From OfflineMediaCacheService
      'isRunning': _isRunning,
    };
  }

  /// Force immediate pre-caching (useful for manual triggers)
  static Future<void> forcePreCacheAll(dynamic ref) async {
    debugPrint('🔄 Force pre-caching all media...');
    await preCacheAllMedia(ref);
  }
}
