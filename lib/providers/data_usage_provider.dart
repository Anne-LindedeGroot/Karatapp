import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Data usage quality settings for different content types
enum DataUsageQuality {
  low,      // Minimal data usage - basic quality
  medium,   // Balanced quality and data usage
  high,     // Best quality - higher data usage
  auto,     // Automatically adjust based on connection
}

/// Data usage mode settings
enum DataUsageMode {
  unlimited,    // No restrictions
  moderate,     // Some restrictions on high-bandwidth content
  strict,       // Maximum data saving
  wifiOnly,     // Only download on Wi-Fi
}

/// Connection type detection
enum ConnectionType {
  wifi,
  cellular,
  unknown,
}

/// Data usage statistics
class DataUsageStats {
  final int totalBytesUsed;
  final int videosBytesUsed;
  final int imagesBytesUsed;
  final int forumBytesUsed;
  final DateTime lastReset;
  final int sessionCount;

  const DataUsageStats({
    required this.totalBytesUsed,
    required this.videosBytesUsed,
    required this.imagesBytesUsed,
    required this.forumBytesUsed,
    required this.lastReset,
    required this.sessionCount,
  });

  DataUsageStats copyWith({
    int? totalBytesUsed,
    int? videosBytesUsed,
    int? imagesBytesUsed,
    int? forumBytesUsed,
    DateTime? lastReset,
    int? sessionCount,
  }) {
    return DataUsageStats(
      totalBytesUsed: totalBytesUsed ?? this.totalBytesUsed,
      videosBytesUsed: videosBytesUsed ?? this.videosBytesUsed,
      imagesBytesUsed: imagesBytesUsed ?? this.imagesBytesUsed,
      forumBytesUsed: forumBytesUsed ?? this.forumBytesUsed,
      lastReset: lastReset ?? this.lastReset,
      sessionCount: sessionCount ?? this.sessionCount,
    );
  }

  String get formattedTotalUsage => _formatBytes(totalBytesUsed);
  String get formattedVideosUsage => _formatBytes(videosBytesUsed);
  String get formattedImagesUsage => _formatBytes(imagesBytesUsed);
  String get formattedForumUsage => _formatBytes(forumBytesUsed);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }
}

/// Data usage settings state
class DataUsageState {
  final DataUsageMode mode;
  final DataUsageQuality videoQuality;
  final DataUsageQuality imageQuality;
  final bool preloadFavorites;
  final bool backgroundSync;
  final bool showDataWarnings;
  final int monthlyDataLimit; // in MB
  final DataUsageStats stats;
  final ConnectionType connectionType;
  final bool isOfflineMode;

  const DataUsageState({
    required this.mode,
    required this.videoQuality,
    required this.imageQuality,
    required this.preloadFavorites,
    required this.backgroundSync,
    required this.showDataWarnings,
    required this.monthlyDataLimit,
    required this.stats,
    required this.connectionType,
    required this.isOfflineMode,
  });

  DataUsageState copyWith({
    DataUsageMode? mode,
    DataUsageQuality? videoQuality,
    DataUsageQuality? imageQuality,
    bool? preloadFavorites,
    bool? backgroundSync,
    bool? showDataWarnings,
    int? monthlyDataLimit,
    DataUsageStats? stats,
    ConnectionType? connectionType,
    bool? isOfflineMode,
  }) {
    return DataUsageState(
      mode: mode ?? this.mode,
      videoQuality: videoQuality ?? this.videoQuality,
      imageQuality: imageQuality ?? this.imageQuality,
      preloadFavorites: preloadFavorites ?? this.preloadFavorites,
      backgroundSync: backgroundSync ?? this.backgroundSync,
      showDataWarnings: showDataWarnings ?? this.showDataWarnings,
      monthlyDataLimit: monthlyDataLimit ?? this.monthlyDataLimit,
      stats: stats ?? this.stats,
      connectionType: connectionType ?? this.connectionType,
      isOfflineMode: isOfflineMode ?? this.isOfflineMode,
    );
  }

  /// Check if we should allow data usage based on current settings
  bool get shouldAllowDataUsage {
    if (isOfflineMode) return false;
    if (mode == DataUsageMode.wifiOnly && connectionType != ConnectionType.wifi) {
      return false;
    }
    return true;
  }

  /// Check if we should show data warning
  bool get shouldShowDataWarning {
    if (!showDataWarnings) return false;
    if (connectionType != ConnectionType.cellular) return false;
    if (monthlyDataLimit <= 0) return false;
    
    final monthlyUsageMB = stats.totalBytesUsed / (1024 * 1024);
    return monthlyUsageMB > (monthlyDataLimit * 0.8); // Warn at 80%
  }

  /// Get recommended quality based on connection and settings
  DataUsageQuality getRecommendedQuality(DataUsageQuality requestedQuality) {
    if (mode == DataUsageMode.strict) return DataUsageQuality.low;
    if (mode == DataUsageMode.moderate && connectionType == ConnectionType.cellular) {
      return requestedQuality == DataUsageQuality.high ? DataUsageQuality.medium : requestedQuality;
    }
    return requestedQuality;
  }
}

/// Data usage notifier
class DataUsageNotifier extends StateNotifier<DataUsageState> {
  static const String _modeKey = 'data_usage_mode';
  static const String _videoQualityKey = 'data_usage_video_quality';
  static const String _imageQualityKey = 'data_usage_image_quality';
  static const String _preloadFavoritesKey = 'data_usage_preload_favorites';
  static const String _backgroundSyncKey = 'data_usage_background_sync';
  static const String _showDataWarningsKey = 'data_usage_show_warnings';
  static const String _monthlyDataLimitKey = 'data_usage_monthly_limit';
  static const String _totalBytesKey = 'data_usage_total_bytes';
  static const String _videosBytesKey = 'data_usage_videos_bytes';
  static const String _imagesBytesKey = 'data_usage_images_bytes';
  static const String _forumBytesKey = 'data_usage_forum_bytes';
  static const String _lastResetKey = 'data_usage_last_reset';
  static const String _sessionCountKey = 'data_usage_session_count';

  Timer? _periodicTimer;

  DataUsageNotifier() : super(DataUsageState(
    mode: DataUsageMode.unlimited,
    videoQuality: DataUsageQuality.auto,
    imageQuality: DataUsageQuality.medium,
    preloadFavorites: true,
    backgroundSync: true,
    showDataWarnings: true,
    monthlyDataLimit: 1000, // 1GB default
    stats: DataUsageStats(
      totalBytesUsed: 0,
      videosBytesUsed: 0,
      imagesBytesUsed: 0,
      forumBytesUsed: 0,
      lastReset: DateTime.now(),
      sessionCount: 0,
    ),
    connectionType: ConnectionType.unknown,
    isOfflineMode: false,
  )) {
    _loadSettings();
    _startPeriodicUpdates();
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  /// Load settings from SharedPreferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load mode
      final modeString = prefs.getString(_modeKey);
      DataUsageMode mode = DataUsageMode.unlimited;
      if (modeString != null) {
        mode = DataUsageMode.values.firstWhere(
          (m) => m.toString() == modeString,
          orElse: () => DataUsageMode.unlimited,
        );
      }

      // Load video quality
      final videoQualityString = prefs.getString(_videoQualityKey);
      DataUsageQuality videoQuality = DataUsageQuality.auto;
      if (videoQualityString != null) {
        videoQuality = DataUsageQuality.values.firstWhere(
          (q) => q.toString() == videoQualityString,
          orElse: () => DataUsageQuality.auto,
        );
      }

      // Load image quality
      final imageQualityString = prefs.getString(_imageQualityKey);
      DataUsageQuality imageQuality = DataUsageQuality.medium;
      if (imageQualityString != null) {
        imageQuality = DataUsageQuality.values.firstWhere(
          (q) => q.toString() == imageQualityString,
          orElse: () => DataUsageQuality.medium,
        );
      }

      // Load other settings
      final preloadFavorites = prefs.getBool(_preloadFavoritesKey) ?? true;
      final backgroundSync = prefs.getBool(_backgroundSyncKey) ?? true;
      final showDataWarnings = prefs.getBool(_showDataWarningsKey) ?? true;
      final monthlyDataLimit = prefs.getInt(_monthlyDataLimitKey) ?? 1000;

      // Load stats
      final totalBytes = prefs.getInt(_totalBytesKey) ?? 0;
      final videosBytes = prefs.getInt(_videosBytesKey) ?? 0;
      final imagesBytes = prefs.getInt(_imagesBytesKey) ?? 0;
      final forumBytes = prefs.getInt(_forumBytesKey) ?? 0;
      final lastResetMs = prefs.getInt(_lastResetKey);
      final sessionCount = prefs.getInt(_sessionCountKey) ?? 0;

      final lastReset = lastResetMs != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastResetMs)
          : DateTime.now();

      final stats = DataUsageStats(
        totalBytesUsed: totalBytes,
        videosBytesUsed: videosBytes,
        imagesBytesUsed: imagesBytes,
        forumBytesUsed: forumBytes,
        lastReset: lastReset,
        sessionCount: sessionCount,
      );

      state = state.copyWith(
        mode: mode,
        videoQuality: videoQuality,
        imageQuality: imageQuality,
        preloadFavorites: preloadFavorites,
        backgroundSync: backgroundSync,
        showDataWarnings: showDataWarnings,
        monthlyDataLimit: monthlyDataLimit,
        stats: stats,
      );

      // Check if we need to reset monthly stats
      _checkMonthlyReset();
    } catch (e) {
      debugPrint('Error loading data usage settings: $e');
    }
  }

  /// Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.setString(_modeKey, state.mode.toString()),
        prefs.setString(_videoQualityKey, state.videoQuality.toString()),
        prefs.setString(_imageQualityKey, state.imageQuality.toString()),
        prefs.setBool(_preloadFavoritesKey, state.preloadFavorites),
        prefs.setBool(_backgroundSyncKey, state.backgroundSync),
        prefs.setBool(_showDataWarningsKey, state.showDataWarnings),
        prefs.setInt(_monthlyDataLimitKey, state.monthlyDataLimit),
        prefs.setInt(_totalBytesKey, state.stats.totalBytesUsed),
        prefs.setInt(_videosBytesKey, state.stats.videosBytesUsed),
        prefs.setInt(_imagesBytesKey, state.stats.imagesBytesUsed),
        prefs.setInt(_forumBytesKey, state.stats.forumBytesUsed),
        prefs.setInt(_lastResetKey, state.stats.lastReset.millisecondsSinceEpoch),
        prefs.setInt(_sessionCountKey, state.stats.sessionCount),
      ]);
    } catch (e) {
      debugPrint('Error saving data usage settings: $e');
    }
  }

  /// Start periodic updates for connection monitoring
  void _startPeriodicUpdates() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _updateConnectionType();
    });
  }

  /// Update connection type (simplified - in real app you'd use connectivity_plus)
  void _updateConnectionType() {
    // This is a simplified version - in a real app you'd use connectivity_plus
    // to detect actual connection type
    final newConnectionType = ConnectionType.unknown; // Placeholder
    if (state.connectionType != newConnectionType) {
      state = state.copyWith(connectionType: newConnectionType);
    }
  }

  /// Check if monthly stats need to be reset
  void _checkMonthlyReset() {
    final now = DateTime.now();
    final lastReset = state.stats.lastReset;
    
    // Reset if it's been more than 30 days
    if (now.difference(lastReset).inDays >= 30) {
      resetMonthlyStats();
    }
  }

  /// Set data usage mode
  Future<void> setMode(DataUsageMode mode) async {
    state = state.copyWith(mode: mode);
    await _saveSettings();
  }

  /// Set video quality
  Future<void> setVideoQuality(DataUsageQuality quality) async {
    state = state.copyWith(videoQuality: quality);
    await _saveSettings();
  }

  /// Set image quality
  Future<void> setImageQuality(DataUsageQuality quality) async {
    state = state.copyWith(imageQuality: quality);
    await _saveSettings();
  }

  /// Set preload favorites
  Future<void> setPreloadFavorites(bool enabled) async {
    state = state.copyWith(preloadFavorites: enabled);
    await _saveSettings();
  }

  /// Set background sync
  Future<void> setBackgroundSync(bool enabled) async {
    state = state.copyWith(backgroundSync: enabled);
    await _saveSettings();
  }

  /// Set show data warnings
  Future<void> setShowDataWarnings(bool enabled) async {
    state = state.copyWith(showDataWarnings: enabled);
    await _saveSettings();
  }

  /// Set monthly data limit
  Future<void> setMonthlyDataLimit(int limitMB) async {
    state = state.copyWith(monthlyDataLimit: limitMB);
    await _saveSettings();
  }

  /// Record data usage
  Future<void> recordDataUsage(int bytes, {String type = 'general'}) async {
    if (bytes <= 0) return;

    final currentStats = state.stats;
    DataUsageStats newStats;

    switch (type) {
      case 'video':
        newStats = currentStats.copyWith(
          totalBytesUsed: currentStats.totalBytesUsed + bytes,
          videosBytesUsed: currentStats.videosBytesUsed + bytes,
        );
        break;
      case 'image':
        newStats = currentStats.copyWith(
          totalBytesUsed: currentStats.totalBytesUsed + bytes,
          imagesBytesUsed: currentStats.imagesBytesUsed + bytes,
        );
        break;
      case 'forum':
        newStats = currentStats.copyWith(
          totalBytesUsed: currentStats.totalBytesUsed + bytes,
          forumBytesUsed: currentStats.forumBytesUsed + bytes,
        );
        break;
      default:
        newStats = currentStats.copyWith(
          totalBytesUsed: currentStats.totalBytesUsed + bytes,
        );
    }

    state = state.copyWith(stats: newStats);
    await _saveSettings();
  }

  /// Reset monthly statistics
  Future<void> resetMonthlyStats() async {
    final newStats = DataUsageStats(
      totalBytesUsed: 0,
      videosBytesUsed: 0,
      imagesBytesUsed: 0,
      forumBytesUsed: 0,
      lastReset: DateTime.now(),
      sessionCount: state.stats.sessionCount + 1,
    );

    state = state.copyWith(stats: newStats);
    await _saveSettings();
  }

  /// Set offline mode
  void setOfflineMode(bool isOffline) {
    state = state.copyWith(isOfflineMode: isOffline);
  }

  /// Set connection type
  void setConnectionType(ConnectionType type) {
    state = state.copyWith(connectionType: type);
  }

  /// Get estimated data usage for an operation
  int getEstimatedUsage(String operation, {int? duration, int? size}) {
    switch (operation) {
      case 'video_stream':
        switch (state.videoQuality) {
          case DataUsageQuality.low:
            return (duration ?? 60) * 50; // ~50KB per second
          case DataUsageQuality.medium:
            return (duration ?? 60) * 200; // ~200KB per second
          case DataUsageQuality.high:
            return (duration ?? 60) * 500; // ~500KB per second
          case DataUsageQuality.auto:
            return (duration ?? 60) * 200; // Default to medium
        }
      case 'image_load':
        switch (state.imageQuality) {
          case DataUsageQuality.low:
            return 50; // ~50KB
          case DataUsageQuality.medium:
            return 200; // ~200KB
          case DataUsageQuality.high:
            return 500; // ~500KB
          case DataUsageQuality.auto:
            return 200; // Default to medium
        }
      case 'forum_sync':
        return 100; // ~100KB for forum data
      default:
        return size ?? 0;
    }
  }
}

// Providers
final dataUsageProvider = StateNotifierProvider<DataUsageNotifier, DataUsageState>((ref) {
  return DataUsageNotifier();
});

final shouldAllowDataUsageProvider = Provider<bool>((ref) {
  return ref.watch(dataUsageProvider).shouldAllowDataUsage;
});

final shouldShowDataWarningProvider = Provider<bool>((ref) {
  return ref.watch(dataUsageProvider).shouldShowDataWarning;
});

final isOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(dataUsageProvider).isOfflineMode;
});
