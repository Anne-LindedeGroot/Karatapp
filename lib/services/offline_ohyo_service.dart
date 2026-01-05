import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ohyo_model.dart';
import '../models/interaction_models.dart';

class OfflineOhyoService {
  static const String _ohyosKey = 'cached_ohyos';
  static const String _lastUpdatedKey = 'ohyos_last_updated';
  static const String _ohyoCommentsKey = 'cached_ohyo_comments';
  static const Duration _cacheValidityDuration = Duration(hours: 24); // Cache for 24 hours

  final SharedPreferences _prefs;

  OfflineOhyoService(this._prefs);

  /// Cache ohyos locally
  Future<void> cacheOhyos(List<Ohyo> ohyos) async {
    try {
      final ohyoMaps = ohyos.map((ohyo) => ohyo.toMap()).toList();
      final jsonString = jsonEncode(ohyoMaps);
      await _prefs.setString(_ohyosKey, jsonString);
      await _prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to cache ohyos: $e');
    }
  }

  /// Get cached ohyos
  Future<List<Ohyo>?> getCachedOhyos() async {
    try {
      final jsonString = _prefs.getString(_ohyosKey);
      if (jsonString == null) return null;

      final ohyoMaps = jsonDecode(jsonString) as List<dynamic>;
      return ohyoMaps.map((map) => Ohyo.fromMap(map as Map<String, dynamic>)).toList();
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

  /// Clear cached ohyos
  Future<void> clearCache() async {
    await _prefs.remove(_ohyosKey);
    await _prefs.remove(_lastUpdatedKey);
  }

  /// Get cached ohyos if valid, otherwise return null
  Future<List<Ohyo>?> getValidCachedOhyos() async {
    if (!isCacheValid()) {
      await clearCache(); // Clear expired cache
      return null;
    }
    return getCachedOhyos();
  }

  /// Cache comments for a specific ohyo
  Future<void> cacheOhyoComments(int ohyoId, List<OhyoComment> comments) async {
    try {
      final allOhyoComments = await _getCachedOhyoCommentsMap() ?? {};
      allOhyoComments[ohyoId.toString()] = {
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(allOhyoComments);
      await _prefs.setString(_ohyoCommentsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache ohyo comments: $e');
    }
  }

  /// Get cached comments for a specific ohyo
  Future<List<OhyoComment>?> getCachedOhyoComments(int ohyoId, {int? limit, int? offset}) async {
    try {
      final allOhyoComments = await _getCachedOhyoCommentsMap();
      if (allOhyoComments == null) return null;

      final ohyoCommentsData = allOhyoComments[ohyoId.toString()];
      if (ohyoCommentsData == null) return null;

      final commentsJson = ohyoCommentsData['comments'] as List<dynamic>;
      var comments = commentsJson.map((json) => OhyoComment.fromJson(json)).toList();

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

  /// Get cached ohyo comments map (internal method)
  Future<Map<String, dynamic>?> _getCachedOhyoCommentsMap() async {
    try {
      final jsonString = _prefs.getString(_ohyoCommentsKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data (ohyos and comments)
  Future<void> clearAllCache() async {
    await _prefs.remove(_ohyosKey);
    await _prefs.remove(_lastUpdatedKey);
    await _prefs.remove(_ohyoCommentsKey);
  }
}
