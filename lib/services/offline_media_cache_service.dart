import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../providers/network_provider.dart';
import '../providers/data_usage_provider.dart';

/// Offline media cache service for images (videos work online only)
class OfflineMediaCacheService {
  static const String _cacheDirName = 'media_cache';
  static const String _imagesDirName = 'images';
  static const int _maxCacheSizeMB = 500; // 500MB max cache size

  static Directory? _cacheDir;
  static Directory? _imagesDir;

  /// Get the cache directory (must call initialize() first)
  static Directory? getCacheDirectory() {
    return _cacheDir;
  }

  /// Initialize cache directories
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      _imagesDir = Directory('${_cacheDir!.path}/$_imagesDirName');

      // Create directories if they don't exist
      await _cacheDir!.create(recursive: true);
      await _imagesDir!.create(recursive: true);

    } catch (e) {
      debugPrint('Failed to initialize offline image cache: $e');
    }
  }

  /// Get cached file path for a media URL (images only - videos work online only)
  static String? getCachedFilePath(String url, bool isVideo) {
    // Videos are not cached - they work online only
    if (isVideo) {
      return null;
    }

    if (_cacheDir == null) return null;

    final hash = _generateUrlHash(url);
    final dir = _imagesDir!;
    final extension = _getFileExtension(url, false);
    final fileName = '$hash$extension';
    final file = File('${dir.path}/$fileName');

    // Check if file exists and is not empty
    if (file.existsSync()) {
      final fileSize = file.lengthSync();
      if (fileSize > 0) {
        return file.path;
      } else {
        // Delete empty/corrupted cache file
        try {
          file.deleteSync();
          debugPrint('Deleted empty cached file: ${file.path}');
        } catch (e) {
          debugPrint('Failed to delete empty cached file: $e');
        }
      }
    }

    return null;
  }

  /// Check if a ref is a valid Riverpod ref
  static bool _isValidRef(dynamic ref) {
    try {
      // Check if this is a Riverpod ref by testing if it has the read method
      return ref != null && ref.read != null;
    } catch (e) {
      return false;
    }
  }

  /// Get cached file path for ohyo images using stable key (ohyoId_filename)
  static String? getCachedOhyoImagePath(int ohyoId, String fileName) {
    if (_imagesDir == null) return null;

    final stableKey = 'ohyo_${ohyoId}_$fileName';
    final hash = _generateUrlHash(stableKey);
    final file = File('${_imagesDir!.path}/$hash.jpg');

    // Check if file exists and is not empty
    if (file.existsSync()) {
      final fileSize = file.lengthSync();
      if (fileSize > 0) {
        return file.path;
      } else {
        // Delete empty/corrupted cache file
        try {
          file.deleteSync();
          debugPrint('Deleted empty cached ohyo image file: ${file.path}');
        } catch (e) {
          debugPrint('Failed to delete empty cached ohyo image file: $e');
        }
      }
    }

    return null;
  }

  /// Get all cached ohyo image paths for a specific ohyo ID
  static Future<List<String>> getCachedOhyoImagePaths(int ohyoId) async {
    final paths = <String>[];
    if (_imagesDir == null) return paths;

    try {
      // Try to read metadata file first
      final metadataFile = File('${_imagesDir!.path}/ohyo_metadata.json');
      if (await metadataFile.exists()) {
        final metadata = json.decode(await metadataFile.readAsString());
        final ohyoKey = ohyoId.toString();
        if (metadata.containsKey(ohyoKey)) {
          final fileNames = metadata[ohyoKey] as List<dynamic>;
          for (final fileName in fileNames) {
            final stableKey = 'ohyo_${ohyoId}_$fileName';
            final hash = _generateUrlHash(stableKey);
            final file = File('${_imagesDir!.path}/$hash.jpg');
            if (await file.exists()) {
              final fileSize = await file.length();
              if (fileSize > 0) {
                paths.add(file.path);
              }
            }
          }
          return paths;
        }
      }

      // If no metadata exists, try to scan for files with the ohyo pattern
      final files = await _getFilesInDirectory(_imagesDir!);
      for (final file in files) {
        final fileName = file.uri.pathSegments.last;
        // Skip metadata files
        if (fileName == 'ohyo_metadata.json' || fileName == 'kata_metadata.json') continue;

        // Check if this file matches the ohyo pattern (contains the ohyo ID)
        if (fileName.contains('ohyo_${ohyoId}_')) {
          final fileSize = await file.length();
          if (fileSize > 0) {
            paths.add(file.path);
          }
        }
      }

    } catch (e) {
      debugPrint('Failed to get cached ohyo images for ohyo $ohyoId: $e');
    }

    return paths;
  }

  /// Cache media file from URL
  static Future<String?> cacheMediaFile(String url, bool isVideo, dynamic ref) async {
    try {
      if (_cacheDir == null) return null;

      // Don't cache streaming video URLs (YouTube, Vimeo, etc.) as they can't be downloaded as files
      if (_isStreamingVideoUrl(url)) {
        // Silent: Video caching warnings are not logged
        return null;
      }

      // Try to read network and data usage state, but don't fail if providers aren't available
      bool shouldCache = true;
      if (_isValidRef(ref)) {
        try {
          final networkState = ref.read(networkProvider);
          final dataUsageState = ref.read(dataUsageProvider);

          // Don't cache if not connected or data usage not allowed
          if (!networkState.isConnected || !dataUsageState.shouldAllowDataUsage) {
            shouldCache = false;
          }
        } catch (e) {
          // If providers aren't available, assume we can cache
          // Silent: Network provider status not logged to reduce spam
        }
      }

      if (!shouldCache) return null;

      final hash = _generateUrlHash(url);
      final dir = _imagesDir!;
      final extension = _getFileExtension(url, false);
      final fileName = '$hash$extension';
      final file = File('${dir.path}/$fileName');

      // Check if already cached
      if (await file.exists()) {
        return file.path;
      }

      // Download and cache the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);

        // Record data usage (if provider is available)
        if (_isValidRef(ref)) {
          try {
            ref.read(dataUsageProvider.notifier).recordDataUsage(
              response.bodyBytes.length,
              type: isVideo ? 'video_cache' : 'image_cache',
            );
          } catch (e) {
            // Data usage provider not available, skip recording
          }
        }

        // Clean up old cache if needed
        await _cleanupCacheIfNeeded();

        // Reduced spam: Caching operations are now silent
        return file.path;
      }
    } catch (e) {
      debugPrint('Failed to cache media file $url: $e');
    }
    return null;
  }

  /// Cache ohyo image with stable key for offline access
  static Future<String?> cacheOhyoImage(int ohyoId, String fileName, String url, dynamic ref) async {
    try {
      if (_imagesDir == null) return null;

      // Try to read network and data usage state, but don't fail if providers aren't available
      bool shouldCache = true;
      try {
        final networkState = ref.read(networkProvider);
        final dataUsageState = ref.read(dataUsageProvider);

        // Don't cache if not connected or data usage not allowed
        if (!networkState.isConnected || !dataUsageState.shouldAllowDataUsage) {
          shouldCache = false;
        }
      } catch (e) {
        // If providers aren't available, assume we can cache
      }

      if (!shouldCache) return null;

      final stableKey = 'ohyo_${ohyoId}_$fileName';
      final hash = _generateUrlHash(stableKey);
      final file = File('${_imagesDir!.path}/$hash.jpg');

      // Check if already cached
      if (await file.exists()) {
        // Still update metadata
        await _updateOhyoMetadata(ohyoId, fileName);
        return file.path;
      }

      // Download and cache the file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);

        // Update metadata
        await _updateOhyoMetadata(ohyoId, fileName);

        // Record data usage (if provider is available)
        try {
          ref.read(dataUsageProvider.notifier).recordDataUsage(
            response.bodyBytes.length,
            type: 'ohyo_image_cache',
          );
        } catch (e) {
          // Data usage provider not available, skip recording
        }

        // Clean up old cache if needed
        await _cleanupCacheIfNeeded();

        // Reduced spam: Ohyo image caching is now silent
        return file.path;
      }
    } catch (e) {
      debugPrint('Failed to cache ohyo image $url: $e');
    }
    return null;
  }

  /// Pre-cache multiple media files (images only - videos work online only)
  static Future<void> preCacheMediaFiles(List<String> urls, bool isVideo, dynamic ref) async {
    // Only cache images, videos work online only
    if (isVideo) {
      // Silent: Video caching info is not logged
      return;
    }

    for (final url in urls) {
      if (url.isNotEmpty) {
        await cacheMediaFile(url, false, ref); // Always pass false for isVideo since we don't cache videos
      }
    }
  }

  /// Get cached image path, or download if not cached
  static Future<String?> getImagePath(String url, dynamic ref) async {
    // Check if already cached
    final cachedPath = getCachedFilePath(url, false);
    if (cachedPath != null) {
      return cachedPath;
    }

    // Cache the image
    return await cacheMediaFile(url, false, ref);
  }

  /// Get video path (videos are not cached - they work online only)
  static Future<String?> getVideoPath(String url, dynamic ref) async {
    // Videos are not cached - return original URL for online playback
    debugPrint('📹 Video caching disabled - returning original URL for online playback: $url');
    return url;
  }

  /// Clear all cached media files
  static Future<void> clearCache() async {
    try {
      if (_cacheDir != null && await _cacheDir!.exists()) {
        await _cacheDir!.delete(recursive: true);
        await initialize(); // Recreate directories
        debugPrint('Media cache cleared');
      }
    } catch (e) {
      debugPrint('Failed to clear media cache: $e');
    }
  }

  /// Get cache size in bytes
  static Future<int> getCacheSize() async {
    if (_cacheDir == null) return 0;

    int totalSize = 0;
    try {
      final files = await _getAllCacheFiles();
      for (final file in files) {
        if (await file.exists()) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      debugPrint('Failed to get cache size: $e');
    }
    return totalSize;
  }

  /// Generate hash for URL to use as filename
  static String _generateUrlHash(String url) {
    return sha256.convert(utf8.encode(url)).toString().substring(0, 16);
  }

  /// Check if URL is a streaming video service that can't be cached
  static bool _isStreamingVideoUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') ||
           lowerUrl.contains('youtu.be') ||
           lowerUrl.contains('vimeo.com') ||
           lowerUrl.contains('dailymotion.com') ||
           lowerUrl.contains('twitch.tv') ||
           lowerUrl.contains('facebook.com/video') ||
           lowerUrl.contains('instagram.com') ||
           lowerUrl.contains('tiktok.com');
  }

  /// Get file extension from URL
  static String _getFileExtension(String url, bool isVideo) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path;
      final extension = path.substring(path.lastIndexOf('.'));
      if (extension.contains('?')) {
        return extension.substring(0, extension.indexOf('?'));
      }
      return extension;
    } catch (e) {
      // Default extensions
      return isVideo ? '.mp4' : '.jpg';
    }
  }

  /// Get all cache files
  static Future<List<File>> _getAllCacheFiles() async {
    final files = <File>[];
    if (_imagesDir != null && await _imagesDir!.exists()) {
      files.addAll(await _getFilesInDirectory(_imagesDir!));
    }
    return files;
  }

  /// Get files in directory
  static Future<List<File>> _getFilesInDirectory(Directory dir) async {
    final files = <File>[];
    try {
      await for (final entity in dir.list()) {
        if (entity is File) {
          files.add(entity);
        }
      }
    } catch (e) {
      debugPrint('Failed to list files in ${dir.path}: $e');
    }
    return files;
  }

  /// Clean up cache if size exceeds limit
  static Future<void> _cleanupCacheIfNeeded() async {
    try {
      final cacheSize = await getCacheSize();
      final maxSizeBytes = _maxCacheSizeMB * 1024 * 1024;

      if (cacheSize > maxSizeBytes) {
        final files = await _getAllCacheFiles();

        // Sort by last modified time (oldest first)
        files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

        int freedSpace = 0;
        for (final file in files) {
          if (cacheSize - freedSpace <= maxSizeBytes * 0.8) break; // Keep 80% of max size

          try {
            final size = await file.length();
            await file.delete();
            freedSpace += size;
            debugPrint('Deleted cached file: ${file.path}');
          } catch (e) {
            debugPrint('Failed to delete cached file ${file.path}: $e');
          }
        }

        debugPrint('Cache cleanup: freed ${freedSpace ~/ 1024}KB');
      }
    } catch (e) {
      debugPrint('Cache cleanup failed: $e');
    }
  }

  /// Update metadata for cached ohyo images (replaces existing entries)
  static Future<void> _updateOhyoMetadata(int ohyoId, String fileName) async {
    if (_imagesDir == null) return;

    try {
      final metadataFile = File('${_imagesDir!.path}/ohyo_metadata.json');
      Map<String, dynamic> metadata = {};

      if (await metadataFile.exists()) {
        metadata = json.decode(await metadataFile.readAsString());
      }

      final ohyoKey = ohyoId.toString();
      // Replace the entire list for this ohyo with the new filename
      metadata[ohyoKey] = [fileName];

      await metadataFile.writeAsString(json.encode(metadata));
    } catch (e) {
      // Silent: Metadata update failures are not logged to reduce spam
    }
  }

  /// Clear all cached media for a specific kata
  static Future<void> clearKataCache(int kataId) async {
    if (_imagesDir == null) return;

    try {
      debugPrint('Clearing old cache for kata $kataId...');

      // Remove from metadata
      final metadataFile = File('${_imagesDir!.path}/kata_metadata.json');
      if (await metadataFile.exists()) {
        final metadata = json.decode(await metadataFile.readAsString()) as Map<String, dynamic>;
        if (metadata.containsKey(kataId.toString())) {
          metadata.remove(kataId.toString());
          await metadataFile.writeAsString(json.encode(metadata));
        }
      }

      // Remove cached files with kata pattern
      final allFiles = <File>[];
      if (_imagesDir != null) {
        allFiles.addAll(await _getFilesInDirectory(_imagesDir!));
      }

      for (final file in allFiles) {
        final fileName = file.uri.pathSegments.last;
        // Check if this file is for this kata (contains kata ID in filename or matches kata pattern)
        if (fileName.contains('kata_${kataId}_') || fileName.contains('_kata${kataId}_')) {
          try {
            await file.delete();
            debugPrint('Deleted old cached file for kata $kataId: ${file.path}');
          } catch (e) {
            debugPrint('Failed to delete old cached file ${file.path}: $e');
          }
        }
      }

      debugPrint('Cleared old cache for kata $kataId');
    } catch (e) {
      debugPrint('Failed to clear kata cache for kata $kataId: $e');
    }
  }

  /// Clear all cached media for a specific ohyo
  static Future<void> clearOhyoCache(int ohyoId) async {
    if (_imagesDir == null) return;

    try {
      debugPrint('Clearing old cache for ohyo $ohyoId...');

      // Remove from metadata
      final metadataFile = File('${_imagesDir!.path}/ohyo_metadata.json');
      if (await metadataFile.exists()) {
        final metadata = json.decode(await metadataFile.readAsString()) as Map<String, dynamic>;
        if (metadata.containsKey(ohyoId.toString())) {
          metadata.remove(ohyoId.toString());
          await metadataFile.writeAsString(json.encode(metadata));
        }
      }

      // Remove cached files with ohyo pattern
      final allFiles = <File>[];
      if (_imagesDir != null) {
        allFiles.addAll(await _getFilesInDirectory(_imagesDir!));
      }

      for (final file in allFiles) {
        final fileName = file.uri.pathSegments.last;
        // Check if this file is for this ohyo (contains ohyo ID in filename)
        if (fileName.contains('ohyo_${ohyoId}_')) {
          try {
            await file.delete();
            debugPrint('Deleted old cached file for ohyo $ohyoId: ${file.path}');
          } catch (e) {
            debugPrint('Failed to delete old cached file ${file.path}: $e');
          }
        }
      }

      debugPrint('Cleared old cache for ohyo $ohyoId');
    } catch (e) {
      debugPrint('Failed to clear ohyo cache for ohyo $ohyoId: $e');
    }
  }

  /// Update metadata for cached kata images (accumulates URLs)
  static Future<void> updateKataMetadata(int kataId, dynamic urlsOrUrl) async {
    if (_imagesDir == null) return;

    try {
      final metadataFile = File('${_imagesDir!.path}/kata_metadata.json');
      Map<String, dynamic> metadata = {};

      if (await metadataFile.exists()) {
        metadata = json.decode(await metadataFile.readAsString());
      }

      final kataKey = kataId.toString();
      List<String> urlsToStore;

      // Handle both single URL and list of URLs
      if (urlsOrUrl is List<String>) {
        urlsToStore = urlsOrUrl;
      } else if (urlsOrUrl is String) {
        // For single URL, add to existing list or create new list
        final existingUrls = metadata[kataKey] as List<dynamic>? ?? [];
        final existingUrlStrings = existingUrls.map((url) => url.toString()).toList();
        if (!existingUrlStrings.contains(urlsOrUrl)) {
          urlsToStore = [...existingUrlStrings, urlsOrUrl];
        } else {
          urlsToStore = existingUrlStrings;
        }
      } else {
        debugPrint('Invalid parameter type for updateKataMetadata');
        return;
      }

      // Store all URLs for this kata
      metadata[kataKey] = urlsToStore;

      await metadataFile.writeAsString(json.encode(metadata));
      debugPrint('Updated kata metadata for kata $kataId with ${urlsToStore.length} URLs');
    } catch (e) {
      // Silent: Metadata update failures are not logged to reduce spam
    }
  }

  /// Get cached kata image URLs for offline access
  static Future<List<String>> getCachedKataImageUrls(int kataId) async {
    final urls = <String>[];
    if (_imagesDir == null) return urls;

    try {
      // First try to get from metadata (for exact URL matches)
      final metadataFile = File('${_imagesDir!.path}/kata_metadata.json');
      if (await metadataFile.exists()) {
        try {
          final content = await metadataFile.readAsString();
          if (content.trim().isEmpty) {
            debugPrint('Metadata file is empty, skipping metadata lookup');
          } else {
            final metadata = json.decode(content);
            final kataKey = kataId.toString();
            if (metadata.containsKey(kataKey)) {
              final storedUrls = metadata[kataKey] as List<dynamic>;
              for (final url in storedUrls) {
                // Check if this URL is cached locally
                final cachedPath = getCachedFilePath(url, false);
                if (cachedPath != null) {
                  urls.add(cachedPath);
                }
              }
              if (urls.isNotEmpty) {
                debugPrint('Found ${urls.length} cached images for kata $kataId via metadata');
                return urls;
              }
            }
          }
        } catch (e) {
          debugPrint('Metadata file is corrupted, attempting to repair: $e');
          // Try to repair the corrupted file by recreating it
          try {
            await metadataFile.writeAsString('{}');
            debugPrint('Successfully repaired corrupted metadata file');
          } catch (repairError) {
            debugPrint('Failed to repair metadata file: $repairError');
          }
        }
      }

      // If no cached images found via metadata, try to scan for files with kata pattern
      // This handles cases where signed URLs have changed due to token expiration
      debugPrint('No metadata found for kata $kataId, scanning directory for cached files...');
      final dir = Directory(_imagesDir!.path);
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>();
        final kataPattern = RegExp(r'kata_${kataId}_\d+\.jpg$');
        final foundFiles = files.where((file) {
          final fileName = file.uri.pathSegments.last;
          return kataPattern.hasMatch(fileName) && file.lengthSync() > 0;
        }).toList();

        if (foundFiles.isNotEmpty) {
          urls.addAll(foundFiles.map((file) => file.path));
          debugPrint('Found ${urls.length} cached images for kata $kataId via directory scan');
        } else {
          debugPrint('Found 0 cached images for kata $kataId via directory scan');
        }
      }
    } catch (e) {
      debugPrint('Failed to get cached kata images for kata $kataId: $e');
    }

    return urls;
  }

  /// Check if media should be loaded from cache (when offline)
  static bool shouldUseCache(dynamic ref) {
    if (_isValidRef(ref)) {
      try {
        final networkState = ref.read(networkProvider);
        return !networkState.isConnected;
      } catch (e) {
        // Network provider not available, check if cached file exists
        return false; // Default to not using cache if we can't check network status
      }
    }
    return false; // No valid ref, don't use cache
  }

  /// Clean up orphaned cache files that are no longer referenced in metadata
  static Future<void> cleanupOrphanedCacheFiles() async {
    if (_imagesDir == null) return;

    try {
      debugPrint('Starting orphaned cache file cleanup...');

      // Collect all referenced URLs from metadata
      final referencedUrls = <String>{};
      final referencedStableKeys = <String>{};

      // Load kata metadata
      if (_imagesDir != null) {
        final kataMetadataFile = File('${_imagesDir!.path}/kata_metadata.json');
        if (await kataMetadataFile.exists()) {
          final kataMetadata = json.decode(await kataMetadataFile.readAsString()) as Map<String, dynamic>;
          for (final urls in kataMetadata.values) {
            if (urls is List) {
              referencedUrls.addAll(urls.map((url) => url.toString()));
            }
          }
        }

        // Load ohyo metadata
        final ohyoMetadataFile = File('${_imagesDir!.path}/ohyo_metadata.json');
        if (await ohyoMetadataFile.exists()) {
          final ohyoMetadata = json.decode(await ohyoMetadataFile.readAsString()) as Map<String, dynamic>;
          for (final entry in ohyoMetadata.entries) {
            final ohyoId = entry.key;
            final fileNames = entry.value;
            if (fileNames is List) {
              for (final fileName in fileNames) {
                // Construct the stable key used for caching: 'ohyo_${ohyoId}_$fileName'
                final stableKey = 'ohyo_${ohyoId}_$fileName';
                referencedStableKeys.add(stableKey);
              }
            }
          }
        }
      }

      // Get all cache files
      final allCacheFiles = await _getAllCacheFiles();
      int deletedCount = 0;
      int failedCount = 0;
      final failedFiles = <String>[];

      for (final file in allCacheFiles) {
        final fileName = file.uri.pathSegments.last;

        // Skip metadata files
        if (fileName == 'kata_metadata.json' || fileName == 'ohyo_metadata.json') {
          continue;
        }

        bool isReferenced = false;

        // Check if this file is referenced
        // For URL-based files (katas), check if URL hash matches
        for (final url in referencedUrls) {
          final urlHash = _generateUrlHash(url);
          if (fileName.startsWith(urlHash)) {
            isReferenced = true;
            break;
          }
        }

        // For stable key-based files (ohyos), check if stable key hash matches
        if (!isReferenced) {
          for (final stableKey in referencedStableKeys) {
            final stableKeyHash = _generateUrlHash(stableKey);
            if (fileName.startsWith(stableKeyHash)) {
              isReferenced = true;
              break;
            }
          }
        }

        // Delete if not referenced
        if (!isReferenced) {
          try {
            await file.delete();
            deletedCount++;
            // Removed per-file logging to reduce spam - only log summary at end
          } catch (e) {
            failedCount++;
            // Only keep first 5 failed files for logging to avoid spam
            if (failedFiles.length < 5) {
              failedFiles.add(fileName);
            }
          }
        }
      }

      // Log summary instead of per-file logs
      final totalChecked = allCacheFiles.length;
      if (deletedCount > 0 || failedCount > 0) {
        debugPrint('🧹 Cache cleanup: checked $totalChecked files, deleted $deletedCount orphaned files${failedCount > 0 ? ', $failedCount failed' : ''}');
        if (failedFiles.isNotEmpty) {
          debugPrint('   Failed files: ${failedFiles.join(', ')}${failedCount > failedFiles.length ? ' (+${failedCount - failedFiles.length} more)' : ''}');
        }
      } else {
        debugPrint('🧹 Cache cleanup: checked $totalChecked files, no orphaned files found');
      }
    } catch (e) {
      debugPrint('Failed to cleanup orphaned cache files: $e');
    }
  }

  /// Get media URL or cached path based on availability
  static Future<String> getMediaUrl(String originalUrl, bool isVideo, dynamic ref) async {
    // First, check if we have a cached file
    final cachedPath = getCachedFilePath(originalUrl, isVideo);
    if (cachedPath != null) {
      // Reduced spam: Using cached files is now silent
      return cachedPath;
    }

    // No cached file available
    // Try to cache in background if network is available
    if (_isValidRef(ref)) {
      try {
        final networkState = ref.read(networkProvider);
        if (networkState.isConnected) {
          cacheMediaFile(originalUrl, isVideo, ref).then((cachedPath) {
            if (cachedPath != null) {
              // Silent: Background caching not logged
            }
          });
        }
      } catch (e) {
        // Network provider not available, still try to cache
        cacheMediaFile(originalUrl, isVideo, ref).catchError((e) {
          debugPrint('Failed to cache $originalUrl: $e');
          return null; // Return null to satisfy the return type
        });
      }
    } else {
      // No valid ref, try to cache anyway
      cacheMediaFile(originalUrl, isVideo, ref).catchError((e) {
        debugPrint('Failed to cache $originalUrl: $e');
        return null; // Return null to satisfy the return type
      });
    }

    // Return original URL if not cached
    return originalUrl;
  }
}
