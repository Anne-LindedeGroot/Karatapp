import 'dart:async';
import 'package:flutter/foundation.dart';
import '../providers/network_provider.dart';
import '../providers/data_usage_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/ohyo_provider.dart';
import 'offline_media_cache_service.dart';
import '../utils/image_utils.dart';

/// Service for pre-caching media files in the background
class PreCachingService {
  static Timer? _backgroundTimer;
  static bool _isRunning = false;
  static const Duration _cacheInterval = Duration(hours: 6); // Cache every 6 hours
  static Duration _initialDelay = const Duration(seconds: 30); // Start after 30 seconds

  static bool _isRefMounted(dynamic ref) {
    try {
      final mounted = ref.mounted;
      if (mounted is bool) {
        return mounted;
      }
    } catch (_) {
      // Ref doesn't expose mounted, assume valid
    }
    return true;
  }

  /// Initialize the pre-caching service
  static void initialize() {
    // Start background caching after initial delay
    _initialDelay = _getInitialDelay();
    Future.delayed(_initialDelay, () {
      _startBackgroundCaching();
    });
  }

  static Duration _getInitialDelay() {
    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android || platform == TargetPlatform.iOS) {
      // Defer longer on mobile to reduce startup work
      return const Duration(minutes: 2);
    }
    return const Duration(seconds: 30);
  }

  /// Start background caching with periodic checks
  static void _startBackgroundCaching() {
    if (_isRunning) return;

    _isRunning = true;
    // Silent: Pre-caching service start not logged

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
  }

  /// Perform background caching of all media
  static Future<void> _performBackgroundCaching() async {
    try {
      // Silent: Background media caching start not logged

      // We'll use a callback approach since we can't directly access providers here
      // The actual caching will be triggered from the UI when providers are available

    } catch (e) {
      debugPrint('❌ Background caching failed: $e');
    }
  }

  /// Pre-cache all kata images
  static Future<void> preCacheAllKataImages(dynamic ref) async {
    try {
      if (!_isRefMounted(ref)) return;
      // Check network status
      final networkState = ref.read(networkProvider);
      if (!networkState.isConnected) {
        return;
      }

      // Check data usage permission
      final dataUsageState = ref.read(dataUsageProvider);
      if (!dataUsageState.shouldAllowDataUsage) {
        return;
      }

      // Silent: Kata pre-caching info not logged

      final currentState = ref.read(kataNotifierProvider);

      // Get all katas
      final allKatas = currentState.katas;

      if (allKatas.isEmpty) {
        return;
      }

      // Silent: Kata count info not logged

      // Pre-cache images for each kata
      for (final kata in allKatas) {
        if (!_isRefMounted(ref)) return;
        if (kata.imageUrls != null && kata.imageUrls!.isNotEmpty) {
          // Silent: Kata caching info not logged

          final successfullyCachedUrls = <String>[];
          for (final imageUrl in kata.imageUrls!) {
            if (!_isRefMounted(ref)) return;
            try {
              final cachedPath = await OfflineMediaCacheService.cacheMediaFile(imageUrl, false, ref);
              if (cachedPath != null) {
                successfullyCachedUrls.add(imageUrl);
              }
              final fileName = _extractFileNameFromUrl(imageUrl);
              if (fileName != null) {
                await OfflineMediaCacheService.cacheKataImage(kata.id, fileName, imageUrl, ref);
              }
            } catch (e) {
              debugPrint('❌ Failed to cache image $imageUrl: $e');
            }
          }

          // Update metadata once with all successfully cached URLs
          if (successfullyCachedUrls.isNotEmpty) {
            await OfflineMediaCacheService.updateKataMetadata(kata.id, successfullyCachedUrls);
          }
        }
      }

      // Silent: Kata caching completion not logged

    } catch (e) {
      debugPrint('❌ Kata pre-caching failed: $e');
    }
  }

  /// Pre-cache all ohyo images
  static Future<void> preCacheAllOhyoImages(dynamic ref) async {
    try {
      if (!_isRefMounted(ref)) return;
      // Check network status
      final networkState = ref.read(networkProvider);
      if (!networkState.isConnected) {
        return;
      }

      // Check data usage permission
      final dataUsageState = ref.read(dataUsageProvider);
      if (!dataUsageState.shouldAllowDataUsage) {
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
        if (!_isRefMounted(ref)) return;
        // Prefer bucket listing so we always get the full set of images
        List<String> bucketUrls = [];
        try {
          bucketUrls = await ImageUtils.fetchOhyoImagesFromBucket(ohyo.id, ref: ref);
        } catch (_) {
          // Fall back to stored URLs if bucket listing fails.
        }

        if (bucketUrls.isNotEmpty) {
          totalImages += bucketUrls.length;
          cachedImages += bucketUrls.length;
          debugPrint('📸 Cached ${bucketUrls.length} images for ohyo: ${ohyo.name}');
          continue;
        }

        if (ohyo.imageUrls != null && ohyo.imageUrls!.isNotEmpty) {
          debugPrint('📸 Caching images for ohyo: ${ohyo.name} (${ohyo.imageUrls!.length} images)');

          for (final imageUrl in ohyo.imageUrls!) {
            if (!_isRefMounted(ref)) return;
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
    // Silent: Pre-caching start not logged

    await preCacheAllKataImages(ref);
    await preCacheAllOhyoImages(ref);

    // Silent: Pre-caching completion not logged
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

  static String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (_) {}
    return null;
  }
}
