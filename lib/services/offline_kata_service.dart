import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/kata_model.dart';

class OfflineKataService {
  static const String _katasKey = 'cached_katas';
  static const String _lastUpdatedKey = 'katas_last_updated';
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
}
