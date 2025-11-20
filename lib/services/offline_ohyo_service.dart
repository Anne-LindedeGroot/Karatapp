import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ohyo_model.dart';

class OfflineOhyoService {
  static const String _ohyosKey = 'cached_ohyos';
  static const String _lastUpdatedKey = 'ohyos_last_updated';
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
}
