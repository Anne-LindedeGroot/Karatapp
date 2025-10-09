import 'package:flutter/material.dart';

/// TTS Cache Manager - Handles content caching for performance optimization
class TTSCacheManager {
  // Content caching for performance optimization
  static final Map<String, String> _contentCache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheValidityDuration = Duration(minutes: 2);

  /// Get cached content if available and not expired
  static String getCachedContent(String cacheKey) {
    try {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp == null) return '';
      
      final now = DateTime.now();
      if (now.difference(timestamp) > _cacheValidityDuration) {
        // Cache expired, remove it
        _contentCache.remove(cacheKey);
        _cacheTimestamps.remove(cacheKey);
        return '';
      }
      
      return _contentCache[cacheKey] ?? '';
    } catch (e) {
      debugPrint('TTS: Error getting cached content: $e');
      return '';
    }
  }

  /// Cache content with timestamp
  static void cacheContent(String cacheKey, String content) {
    try {
      _contentCache[cacheKey] = content;
      _cacheTimestamps[cacheKey] = DateTime.now();
      debugPrint('TTS: Cached content for key: $cacheKey');
    } catch (e) {
      debugPrint('TTS: Error caching content: $e');
    }
  }

  /// Clear all cached content (useful for memory management)
  static void clearCache() {
    _contentCache.clear();
    _cacheTimestamps.clear();
    debugPrint('TTS: Cache cleared');
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedItems': _contentCache.length,
      'cacheKeys': _contentCache.keys.toList(),
      'oldestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isBefore(b) ? a : b)
          : null,
      'newestCache': _cacheTimestamps.values.isNotEmpty 
          ? _cacheTimestamps.values.reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}
