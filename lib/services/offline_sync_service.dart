import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/storage/local_storage.dart';
import '../models/kata_model.dart';
import '../models/forum_models.dart';
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import '../utils/retry_utils.dart';

/// Offline sync status
enum SyncStatus {
  idle,
  syncing,
  completed,
  failed,
  paused,
}

/// Sync operation type
enum SyncOperation {
  katas,
  forumPosts,
  userData,
  videos,
  images,
}

/// Sync result
class SyncResult {
  final SyncOperation operation;
  final bool success;
  final int itemsProcessed;
  final int itemsFailed;
  final String? error;
  final DateTime timestamp;

  const SyncResult({
    required this.operation,
    required this.success,
    required this.itemsProcessed,
    required this.itemsFailed,
    required this.error,
    required this.timestamp,
  });
}

/// Offline sync state
class OfflineSyncState {
  final SyncStatus status;
  final SyncOperation? currentOperation;
  final double progress; // 0.0 to 1.0
  final List<SyncResult> recentResults;
  final DateTime? lastSyncTime;
  final String? lastError;
  final bool isBackgroundSyncEnabled;
  final int pendingItems;

  const OfflineSyncState({
    required this.status,
    this.currentOperation,
    required this.progress,
    required this.recentResults,
    this.lastSyncTime,
    this.lastError,
    required this.isBackgroundSyncEnabled,
    required this.pendingItems,
  });

  OfflineSyncState copyWith({
    SyncStatus? status,
    SyncOperation? currentOperation,
    double? progress,
    List<SyncResult>? recentResults,
    DateTime? lastSyncTime,
    String? lastError,
    bool? isBackgroundSyncEnabled,
    int? pendingItems,
  }) {
    return OfflineSyncState(
      status: status ?? this.status,
      currentOperation: currentOperation ?? this.currentOperation,
      progress: progress ?? this.progress,
      recentResults: recentResults ?? this.recentResults,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastError: lastError ?? this.lastError,
      isBackgroundSyncEnabled: isBackgroundSyncEnabled ?? this.isBackgroundSyncEnabled,
      pendingItems: pendingItems ?? this.pendingItems,
    );
  }

  bool get isSyncing => status == SyncStatus.syncing;
  bool get hasRecentErrors => recentResults.any((r) => !r.success);
  int get totalItemsProcessed => recentResults.fold(0, (sum, r) => sum + r.itemsProcessed);
  int get totalItemsFailed => recentResults.fold(0, (sum, r) => sum + r.itemsFailed);
}

/// Offline sync service
class OfflineSyncService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  Timer? _backgroundSyncTimer;
  static const Duration _backgroundSyncInterval = Duration(minutes: 15);
  static const Duration _retryInterval = Duration(minutes: 5);

  /// Start background sync if enabled
  void startBackgroundSync(Ref ref) {
    final dataUsageState = ref.read(dataUsageProvider);
    if (!dataUsageState.backgroundSync) return;

    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(_backgroundSyncInterval, (_) {
      _performBackgroundSync(ref);
    });
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = null;
  }

  /// Perform background sync
  Future<void> _performBackgroundSync(Ref ref) async {
    final networkState = ref.read(networkProvider);
    final dataUsageState = ref.read(dataUsageProvider);

    // Only sync if connected and data usage is allowed
    if (!networkState.isConnected || !dataUsageState.shouldAllowDataUsage) {
      return;
    }

    try {
      await syncKatas(ref, background: true);
      await syncForumPosts(ref, background: true);
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Sync katas from server to local storage
  Future<SyncResult> syncKatas(Ref ref, {bool background = false}) async {
    final completer = Completer<SyncResult>();
    int processed = 0;
    int failed = 0;
    String? error;

    try {
      if (!background) {
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.syncing,
          SyncOperation.katas,
          0.0,
        );
      }

      // Fetch katas from server
      final response = await _supabase
          .from('katas')
          .select()
          .order('id');

      if (response.isEmpty) {
        return SyncResult(
          operation: SyncOperation.katas,
          success: true,
          itemsProcessed: 0,
          itemsFailed: 0,
          error: null,
          timestamp: DateTime.now(),
        );
      }

      final List<CachedKata> katasToCache = [];
      
      for (int i = 0; i < response.length; i++) {
        try {
          final kataData = response[i];
          final kata = CachedKata(
            id: kataData['id'],
            name: kataData['name'],
            description: kataData['description'] ?? '',
            beltLevel: kataData['belt_level'] ?? '',
            difficulty: kataData['difficulty'] ?? 1,
            steps: List<String>.from(kataData['steps'] ?? []),
            tips: List<String>.from(kataData['tips'] ?? []),
            isFavorite: kataData['is_favorite'] ?? false,
            lastViewed: DateTime.tryParse(kataData['last_viewed'] ?? '') ?? DateTime.now(),
            needsSync: false,
          );
          
          katasToCache.add(kata);
          processed++;

          // Update progress
          if (!background) {
            final progress = (i + 1) / response.length;
            ref.read(offlineSyncProvider.notifier).updateProgress(progress);
          }
        } catch (e) {
          failed++;
          debugPrint('Error processing kata ${response[i]['id']}: $e');
        }
      }

      // Save to local storage
      await LocalStorage.saveKatas(katasToCache);
      
      // Record data usage
      final estimatedBytes = response.length * 1024; // ~1KB per kata
      ref.read(dataUsageProvider.notifier).recordDataUsage(estimatedBytes, type: 'forum');

      final result = SyncResult(
        operation: SyncOperation.katas,
        success: failed == 0,
        itemsProcessed: processed,
        itemsFailed: failed,
        error: failed > 0 ? '$failed items failed to sync' : null,
        timestamp: DateTime.now(),
      );

      if (!background) {
        ref.read(offlineSyncProvider.notifier).addSyncResult(result);
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.completed,
          null,
          1.0,
        );
      }

      return result;
    } catch (e) {
      error = e.toString();
      debugPrint('Error syncing katas: $e');
      
      final result = SyncResult(
        operation: SyncOperation.katas,
        success: false,
        itemsProcessed: processed,
        itemsFailed: failed + 1,
        error: error,
        timestamp: DateTime.now(),
      );

      if (!background) {
        ref.read(offlineSyncProvider.notifier).addSyncResult(result);
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.failed,
          null,
          0.0,
          error: error,
        );
      }

      return result;
    }
  }

  /// Sync forum posts from server to local storage
  Future<SyncResult> syncForumPosts(Ref ref, {bool background = false}) async {
    int processed = 0;
    int failed = 0;
    String? error;

    try {
      if (!background) {
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.syncing,
          SyncOperation.forumPosts,
          0.0,
        );
      }

      // Fetch recent forum posts
      final response = await _supabase
          .from('forum_posts')
          .select()
          .order('created_at', ascending: false)
          .limit(50); // Limit for offline storage

      if (response.isEmpty) {
        return SyncResult(
          operation: SyncOperation.forumPosts,
          success: true,
          itemsProcessed: 0,
          itemsFailed: 0,
          error: null,
          timestamp: DateTime.now(),
        );
      }

      final List<CachedForumPost> postsToCache = [];
      
      for (int i = 0; i < response.length; i++) {
        try {
          final postData = response[i];
          final post = CachedForumPost(
            id: postData['id'],
            title: postData['title'],
            content: postData['content'],
            authorId: postData['author_id'],
            authorName: postData['author_name'] ?? 'Unknown',
            createdAt: DateTime.parse(postData['created_at']),
            updatedAt: DateTime.tryParse(postData['updated_at'] ?? '') ?? DateTime.now(),
            likes: postData['likes'] ?? 0,
            replies: postData['replies'] ?? 0,
            category: postData['category'] ?? 'General',
            isLiked: postData['is_liked'] ?? false,
            needsSync: false,
          );
          
          postsToCache.add(post);
          processed++;

          // Update progress
          if (!background) {
            final progress = (i + 1) / response.length;
            ref.read(offlineSyncProvider.notifier).updateProgress(progress);
          }
        } catch (e) {
          failed++;
          debugPrint('Error processing forum post ${response[i]['id']}: $e');
        }
      }

      // Save to local storage
      await LocalStorage.saveForumPosts(postsToCache);
      
      // Record data usage
      final estimatedBytes = response.length * 2048; // ~2KB per post
      ref.read(dataUsageProvider.notifier).recordDataUsage(estimatedBytes, type: 'forum');

      final result = SyncResult(
        operation: SyncOperation.forumPosts,
        success: failed == 0,
        itemsProcessed: processed,
        itemsFailed: failed,
        error: failed > 0 ? '$failed items failed to sync' : null,
        timestamp: DateTime.now(),
      );

      if (!background) {
        ref.read(offlineSyncProvider.notifier).addSyncResult(result);
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.completed,
          null,
          1.0,
        );
      }

      return result;
    } catch (e) {
      error = e.toString();
      debugPrint('Error syncing forum posts: $e');
      
      final result = SyncResult(
        operation: SyncOperation.forumPosts,
        success: false,
        itemsProcessed: processed,
        itemsFailed: failed + 1,
        error: error,
        timestamp: DateTime.now(),
      );

      if (!background) {
        ref.read(offlineSyncProvider.notifier).addSyncResult(result);
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.failed,
          null,
          0.0,
          error: error,
        );
      }

      return result;
    }
  }

  /// Preload favorite content when on Wi-Fi
  Future<void> preloadFavorites(Ref ref) async {
    final dataUsageState = ref.read(dataUsageProvider);
    final networkState = ref.read(networkProvider);

    // Only preload if enabled and on Wi-Fi
    if (!dataUsageState.preloadFavorites || 
        !networkState.isConnected ||
        dataUsageState.connectionType != ConnectionType.wifi) {
      return;
    }

    try {
      debugPrint('🔄 Starting favorite content preload...');
      
      // Get favorite katas
      final favoriteKatas = LocalStorage.getFavoriteKatas();
      
      for (final kata in favoriteKatas) {
        try {
          // Preload kata videos if available
          await _preloadKataVideos(kata.id, ref);
          
          // Small delay to avoid overwhelming the network
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Error preloading kata ${kata.id}: $e');
        }
      }
      
      debugPrint('✅ Favorite content preload completed');
    } catch (e) {
      debugPrint('Error during favorite content preload: $e');
    }
  }

  /// Preload videos for a specific kata
  Future<void> _preloadKataVideos(int kataId, Ref ref) async {
    try {
      // This would integrate with your existing video service
      // For now, we'll just mark it as a placeholder
      debugPrint('Preloading videos for kata $kataId');
      
      // Record data usage for preloading
      const estimatedBytes = 1024 * 1024; // 1MB estimate
      ref.read(dataUsageProvider.notifier).recordDataUsage(estimatedBytes, type: 'video');
    } catch (e) {
      debugPrint('Error preloading videos for kata $kataId: $e');
    }
  }

  /// Get pending items count
  int getPendingItemsCount() {
    // This would check for items that need to be synced
    // For now, return 0 as placeholder
    return 0;
  }
}

/// Offline sync notifier
class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final OfflineSyncService _syncService = OfflineSyncService();

  OfflineSyncNotifier() : super(const OfflineSyncState(
    status: SyncStatus.idle,
    progress: 0.0,
    recentResults: [],
    isBackgroundSyncEnabled: true,
    pendingItems: 0,
  ));

  /// Update sync status
  void updateStatus(SyncStatus status, SyncOperation? operation, double progress, {String? error}) {
    state = state.copyWith(
      status: status,
      currentOperation: operation,
      progress: progress,
      lastError: error,
      lastSyncTime: status == SyncStatus.completed ? DateTime.now() : state.lastSyncTime,
    );
  }

  /// Update progress
  void updateProgress(double progress) {
    state = state.copyWith(progress: progress);
  }

  /// Add sync result
  void addSyncResult(SyncResult result) {
    final newResults = List<SyncResult>.from(state.recentResults);
    newResults.insert(0, result);
    
    // Keep only last 10 results
    if (newResults.length > 10) {
      newResults.removeRange(10, newResults.length);
    }

    state = state.copyWith(recentResults: newResults);
  }

  /// Start full sync
  Future<void> startFullSync(Ref ref) async {
    if (state.isSyncing) return;

    try {
      await _syncService.syncKatas(ref);
      await _syncService.syncForumPosts(ref);
    } catch (e) {
      debugPrint('Full sync failed: $e');
    }
  }

  /// Start background sync
  void startBackgroundSync(Ref ref) {
    _syncService.startBackgroundSync(ref);
    state = state.copyWith(isBackgroundSyncEnabled: true);
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _syncService.stopBackgroundSync();
    state = state.copyWith(isBackgroundSyncEnabled: false);
  }

  /// Preload favorites
  Future<void> preloadFavorites(Ref ref) async {
    await _syncService.preloadFavorites(ref);
  }

  /// Update pending items count
  void updatePendingItems() {
    final count = _syncService.getPendingItemsCount();
    state = state.copyWith(pendingItems: count);
  }
}

// Providers
final offlineSyncProvider = StateNotifierProvider<OfflineSyncNotifier, OfflineSyncState>((ref) {
  return OfflineSyncNotifier();
});

final isSyncingProvider = Provider<bool>((ref) {
  return ref.watch(offlineSyncProvider).isSyncing;
});

final syncProgressProvider = Provider<double>((ref) {
  return ref.watch(offlineSyncProvider).progress;
});
