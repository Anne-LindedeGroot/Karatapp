import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import '../providers/network_provider.dart';
import '../providers/data_usage_provider.dart';

/// Offline media cache service for images and videos
class OfflineMediaCacheService {
  static const String _cacheDirName = 'media_cache';
  static const String _imagesDirName = 'images';
  static const String _videosDirName = 'videos';
  static const int _maxCacheSizeMB = 500; // 500MB max cache size

  static Directory? _cacheDir;
  static Directory? _imagesDir;
  static Directory? _videosDir;

  /// Initialize cache directories
  static Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${appDir.path}/$_cacheDirName');
      _imagesDir = Directory('${_cacheDir!.path}/$_imagesDirName');
      _videosDir = Directory('${_cacheDir!.path}/$_videosDirName');

      // Create directories if they don't exist
      await _cacheDir!.create(recursive: true);
      await _imagesDir!.create(recursive: true);
      await _videosDir!.create(recursive: true);

      debugPrint('Offline media cache initialized at: ${_cacheDir!.path}');
    } catch (e) {
      debugPrint('Failed to initialize offline media cache: $e');
    }
  }

  /// Get cached file path for a media URL
  static String? getCachedFilePath(String url, bool isVideo) {
    if (_cacheDir == null) return null;

    final hash = _generateUrlHash(url);
    final dir = isVideo ? _videosDir! : _imagesDir!;
    final extension = _getFileExtension(url, isVideo);
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
                debugPrint('Found cached ohyo image: ${file.path}');
              }
            }
          }
          debugPrint('Found ${paths.length} cached images for ohyo $ohyoId via metadata');
          return paths;
        }
      }

      // If no metadata exists, try to scan for files with the ohyo pattern
      debugPrint('No metadata found for ohyo $ohyoId, scanning directory for cached files...');
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
            debugPrint('Found cached ohyo image via scan: ${file.path}');
          }
        }
      }

      debugPrint('Found ${paths.length} cached images for ohyo $ohyoId via directory scan');
    } catch (e) {
      debugPrint('Failed to get cached ohyo images for ohyo $ohyoId: $e');
    }

    return paths;
  }

  /// Cache media file from URL
  static Future<String?> cacheMediaFile(String url, bool isVideo, dynamic ref) async {
    try {
      if (_cacheDir == null) return null;

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
        debugPrint('Network/data usage providers not available, proceeding with cache');
      }

      if (!shouldCache) return null;

      final hash = _generateUrlHash(url);
      final dir = isVideo ? _videosDir! : _imagesDir!;
      final extension = _getFileExtension(url, isVideo);
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
        try {
          ref.read(dataUsageProvider.notifier).recordDataUsage(
            response.bodyBytes.length,
            type: isVideo ? 'video_cache' : 'image_cache',
          );
        } catch (e) {
          // Data usage provider not available, skip recording
        }

        // Clean up old cache if needed
        await _cleanupCacheIfNeeded();

        debugPrint('Cached ${isVideo ? 'video' : 'image'}: $url -> ${file.path} (${response.bodyBytes.length} bytes)');
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
        debugPrint('Network/data usage providers not available, proceeding with cache');
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

        debugPrint('Cached ohyo image: ohyo_$ohyoId/$fileName -> ${file.path} (${response.bodyBytes.length} bytes)');
        return file.path;
      }
    } catch (e) {
      debugPrint('Failed to cache ohyo image $url: $e');
    }
    return null;
  }

  /// Pre-cache multiple media files
  static Future<void> preCacheMediaFiles(List<String> urls, bool isVideo, dynamic ref) async {
    for (final url in urls) {
      if (url.isNotEmpty) {
        await cacheMediaFile(url, isVideo, ref);
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

  /// Get cached video path, or download if not cached
  static Future<String?> getVideoPath(String url, dynamic ref) async {
    // Check if already cached
    final cachedPath = getCachedFilePath(url, true);
    if (cachedPath != null) {
      return cachedPath;
    }

    // Cache the video
    return await cacheMediaFile(url, true, ref);
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
    if (_videosDir != null && await _videosDir!.exists()) {
      files.addAll(await _getFilesInDirectory(_videosDir!));
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

  /// Update metadata for cached ohyo images
  static Future<void> _updateOhyoMetadata(int ohyoId, String fileName) async {
    if (_imagesDir == null) return;

    try {
      final metadataFile = File('${_imagesDir!.path}/ohyo_metadata.json');
      Map<String, dynamic> metadata = {};

      if (await metadataFile.exists()) {
        metadata = json.decode(await metadataFile.readAsString());
      }

      final ohyoKey = ohyoId.toString();
      if (!metadata.containsKey(ohyoKey)) {
        metadata[ohyoKey] = <String>[];
      }

      final fileNames = metadata[ohyoKey] as List<dynamic>;
      if (!fileNames.contains(fileName)) {
        fileNames.add(fileName);
        metadata[ohyoKey] = fileNames;
      }

      await metadataFile.writeAsString(json.encode(metadata));
    } catch (e) {
      debugPrint('Failed to update ohyo metadata: $e');
    }
  }

  /// Update metadata for cached kata images
  static Future<void> updateKataMetadata(int kataId, String url) async {
    if (_imagesDir == null) return;

    try {
      final metadataFile = File('${_imagesDir!.path}/kata_metadata.json');
      Map<String, dynamic> metadata = {};

      if (await metadataFile.exists()) {
        metadata = json.decode(await metadataFile.readAsString());
      }

      final kataKey = kataId.toString();
      if (!metadata.containsKey(kataKey)) {
        metadata[kataKey] = <String>[];
      }

      final urls = metadata[kataKey] as List<dynamic>;
      if (!urls.contains(url)) {
        urls.add(url);
        metadata[kataKey] = urls;
      }

      await metadataFile.writeAsString(json.encode(metadata));
    } catch (e) {
      debugPrint('Failed to update kata metadata: $e');
    }
  }

  /// Get cached kata image URLs for offline access
  static Future<List<String>> getCachedKataImageUrls(int kataId) async {
    final urls = <String>[];
    if (_imagesDir == null) return urls;

    try {
      final metadataFile = File('${_imagesDir!.path}/kata_metadata.json');
      if (await metadataFile.exists()) {
        final metadata = json.decode(await metadataFile.readAsString());
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
          return urls;
        }
      }
    } catch (e) {
      debugPrint('Failed to get cached kata images for kata $kataId: $e');
    }

    return urls;
  }

  /// Check if media should be loaded from cache (when offline)
  static bool shouldUseCache(dynamic ref) {
    try {
      final networkState = ref.read(networkProvider);
      return !networkState.isConnected;
    } catch (e) {
      // Network provider not available, check if cached file exists
      return false; // Default to not using cache if we can't check network status
    }
  }

  /// Get media URL or cached path based on availability
  static Future<String> getMediaUrl(String originalUrl, bool isVideo, dynamic ref) async {
    // First, check if we have a cached file
    final cachedPath = getCachedFilePath(originalUrl, isVideo);
    if (cachedPath != null) {
      debugPrint('Using cached file for $originalUrl: $cachedPath');
      return cachedPath;
    }

    // No cached file available
    // Try to cache in background if network is available
    try {
      final networkState = ref.read(networkProvider);
      if (networkState.isConnected) {
        cacheMediaFile(originalUrl, isVideo, ref).then((cachedPath) {
          if (cachedPath != null) {
            debugPrint('Background cached: $originalUrl');
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

    // Return original URL if not cached
    return originalUrl;
  }
}
