import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kata_model.dart';
import '../models/interaction_models.dart';

class OfflineKataService {
  static const String _katasKey = 'cached_katas';
  static const String _lastUpdatedKey = 'katas_last_updated';
  static const String _kataCommentsKey = 'cached_kata_comments';
  static const Duration _cacheValidityDuration = Duration(hours: 24); // Cache for 24 hours

  final SharedPreferences _prefs;

  OfflineKataService(this._prefs);

  /// Cache katas locally
  Future<void> cacheKatas(List<Kata> katas) async {
    try {
      final kataMaps = katas.map((kata) => kata.toMap()).toList();
      final jsonString = jsonEncode(kataMaps);
      await _prefs.setString(_katasKey, jsonString);
      await _prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to cache katas: $e');
    }
  }

  /// Get cached katas
  Future<List<Kata>?> getCachedKatas() async {
    try {
      final jsonString = _prefs.getString(_katasKey);
      if (jsonString == null) return null;

      final kataMaps = jsonDecode(jsonString) as List<dynamic>;
      return kataMaps.map((map) => Kata.fromMap(map as Map<String, dynamic>)).toList();
    } catch (e) {
      // If there's an error reading cache, return null to trigger fresh load
      return null;
    }
  }

  /// Check if cache is valid (not expired)
  bool isCacheValid() {
    try {
      final lastUpdatedString = _prefs.getString(_lastUpdatedKey);
      if (lastUpdatedString == null) return false;

      final lastUpdated = DateTime.parse(lastUpdatedString);
      final now = DateTime.now();
      final difference = now.difference(lastUpdated);

      return difference < _cacheValidityDuration;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached katas
  Future<void> clearCache() async {
    await _prefs.remove(_katasKey);
    await _prefs.remove(_lastUpdatedKey);
  }

  /// Get cached katas if valid, otherwise return null
  Future<List<Kata>?> getValidCachedKatas() async {
    if (!isCacheValid()) {
      await clearCache(); // Clear expired cache
      return null;
    }
    return getCachedKatas();
  }

  /// Cache comments for a specific kata
  Future<void> cacheKataComments(int kataId, List<KataComment> comments) async {
    try {
      final allKataComments = await _getCachedKataCommentsMap() ?? {};
      allKataComments[kataId.toString()] = {
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(allKataComments);
      await _prefs.setString(_kataCommentsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache kata comments: $e');
    }
  }

  /// Get cached comments for a specific kata
  Future<List<KataComment>?> getCachedKataComments(int kataId, {int? limit, int? offset}) async {
    try {
      final allKataComments = await _getCachedKataCommentsMap();
      if (allKataComments == null) return null;

      final kataCommentsData = allKataComments[kataId.toString()];
      if (kataCommentsData == null) return null;

      final commentsJson = kataCommentsData['comments'] as List<dynamic>;
      var comments = commentsJson.map((json) => KataComment.fromJson(json)).toList();

      // Apply pagination if specified
      if (offset != null && offset > 0) {
        comments = comments.skip(offset).toList();
      }
      if (limit != null && limit > 0) {
        comments = comments.take(limit).toList();
      }

      return comments;
    } catch (e) {
      return null;
    }
  }

  /// Get cached kata comments map (internal method)
  Future<Map<String, dynamic>?> _getCachedKataCommentsMap() async {
    try {
      final jsonString = _prefs.getString(_kataCommentsKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data (katas and comments)
  Future<void> clearAllCache() async {
    await _prefs.remove(_katasKey);
    await _prefs.remove(_lastUpdatedKey);
    await _prefs.remove(_kataCommentsKey);
  }
}
