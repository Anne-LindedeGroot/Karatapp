import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interaction_models.dart';

/// Service for caching comment states locally
class CommentCacheService {
  static const String _cachedStatesKey = 'cached_comment_states';
  static const Duration _cacheExpiry = Duration(days: 7); // Cache expires after 7 days

  final SharedPreferences _prefs;
  final StreamController<Map<String, CachedCommentState>> _cacheController =
      StreamController<Map<String, CachedCommentState>>.broadcast();

  CommentCacheService(this._prefs) {
    _initializeCache();
  }

  Stream<Map<String, CachedCommentState>> get cacheStream =>
      _cacheController.stream;

  /// Initialize cache from storage
  Future<void> _initializeCache() async {
    final cache = await _loadCache();
    _cacheController.add(cache);
  }

  /// Get cache key for a comment
  String _getCacheKey(int commentId, String commentType) {
    return '${commentType}_$commentId';
  }

  /// Cache a comment state
  Future<void> cacheCommentState(CachedCommentState state) async {
    final cache = await _loadCache();
    final key = _getCacheKey(state.commentId, state.commentType);

    cache[key] = state.copyWith(lastUpdated: DateTime.now());
    await _saveCache(cache);
    _cacheController.add(cache);

    debugPrint('Cached comment state: ${state.commentType} ${state.commentId}');
  }

  /// Get cached comment state
  Future<CachedCommentState?> getCachedCommentState(int commentId, String commentType) async {
    final cache = await _loadCache();
    final key = _getCacheKey(commentId, commentType);

    final state = cache[key];

    // Check if cache is expired
    if (state != null && _isExpired(state.lastSynced)) {
      // Remove expired cache
      cache.remove(key);
      await _saveCache(cache);
      _cacheController.add(cache);
      return null;
    }

    return state;
  }

  /// Update cached like state
  Future<void> updateCachedLikeState(int commentId, String commentType, {
    required bool isLiked,
    required bool isDisliked,
    int? likeCount,
    int? dislikeCount,
  }) async {
    final cache = await _loadCache();
    final key = _getCacheKey(commentId, commentType);

    final existingState = cache[key];
    if (existingState != null) {
      final updatedState = existingState.copyWith(
        isLiked: isLiked,
        isDisliked: isDisliked,
        likeCount: likeCount ?? existingState.likeCount,
        dislikeCount: dislikeCount ?? existingState.dislikeCount,
        lastUpdated: DateTime.now(),
      );

      cache[key] = updatedState;
      await _saveCache(cache);
      _cacheController.add(cache);

      debugPrint('Updated cached like state: $commentType $commentId');
    }
  }

  /// Remove cached state
  Future<void> removeCachedState(int commentId, String commentType) async {
    final cache = await _loadCache();
    final key = _getCacheKey(commentId, commentType);

    if (cache.containsKey(key)) {
      cache.remove(key);
      await _saveCache(cache);
      _cacheController.add(cache);

      debugPrint('Removed cached state: $commentType $commentId');
    }
  }

  /// Get all cached states for a comment type
  Future<List<CachedCommentState>> getCachedStatesForType(String commentType) async {
    final cache = await _loadCache();
    return cache.values
        .where((state) => state.commentType == commentType)
        .where((state) => !_isExpired(state.lastSynced))
        .toList();
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    final cache = await _loadCache();
    final expiredKeys = cache.entries
        .where((entry) => _isExpired(entry.value.lastSynced))
        .map((entry) => entry.key)
        .toList();

    for (final key in expiredKeys) {
      cache.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      await _saveCache(cache);
      _cacheController.add(cache);
      debugPrint('Cleared ${expiredKeys.length} expired cache entries');
    }
  }

  /// Clear all cache for a comment type
  Future<void> clearCacheForType(String commentType) async {
    final cache = await _loadCache();
    final keysToRemove = cache.keys
        .where((key) => key.startsWith('${commentType}_'))
        .toList();

    for (final key in keysToRemove) {
      cache.remove(key);
    }

    await _saveCache(cache);
    _cacheController.add(cache);

    debugPrint('Cleared cache for type: $commentType');
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await _prefs.remove(_cachedStatesKey);
    _cacheController.add({});

    debugPrint('Cleared all comment cache');
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    final cache = await _loadCache();

    final stats = <String, dynamic>{
      'total_entries': cache.length,
      'by_type': <String, int>{},
      'expired_entries': 0,
      'oldest_entry': null as DateTime?,
      'newest_entry': null as DateTime?,
    };

    for (final state in cache.values) {
      // Count by type
      final byType = stats['by_type'] as Map<String, int>;
      byType[state.commentType] = (byType[state.commentType] ?? 0) + 1;

      // Check expiry
      if (_isExpired(state.lastSynced)) {
        stats['expired_entries'] = (stats['expired_entries'] as int) + 1;
      }

      // Track oldest/newest
      if (stats['oldest_entry'] == null ||
          state.lastSynced.isBefore(stats['oldest_entry'] as DateTime)) {
        stats['oldest_entry'] = state.lastSynced;
      }
      if (stats['newest_entry'] == null ||
          state.lastSynced.isAfter(stats['newest_entry'] as DateTime)) {
        stats['newest_entry'] = state.lastSynced;
      }
    }

    return stats;
  }

  /// Check if a cached state is expired
  bool _isExpired(DateTime lastSynced) {
    return DateTime.now().difference(lastSynced) > _cacheExpiry;
  }

  /// Load cache from storage
  Future<Map<String, CachedCommentState>> _loadCache() async {
    final cacheJson = _prefs.getString(_cachedStatesKey);
    if (cacheJson == null) return {};

    try {
      final cacheMap = jsonDecode(cacheJson) as Map<String, dynamic>;
      final result = <String, CachedCommentState>{};

      for (final entry in cacheMap.entries) {
        try {
          final value = entry.value as Map<String, dynamic>;
          result[entry.key] = CachedCommentState.fromJson(value);
        } catch (e) {
          debugPrint('Error parsing cached comment state: $e');
        }
      }

      return result;
    } catch (e) {
      debugPrint('Error loading comment cache: $e');
      return {};
    }
  }

  /// Save cache to storage
  Future<void> _saveCache(Map<String, CachedCommentState> cache) async {
    final cacheJson = jsonEncode(
      cache.map((key, value) => MapEntry(key, value.toJson()))
    );
    await _prefs.setString(_cachedStatesKey, cacheJson);
  }

  void dispose() {
    _cacheController.close();
  }
}
