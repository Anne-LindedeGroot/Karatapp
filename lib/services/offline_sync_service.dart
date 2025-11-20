import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/storage/local_storage.dart' as app_storage;
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import 'offline_queue_service.dart';
import 'comment_cache_service.dart';
import 'conflict_resolution_service.dart';
import 'interaction_service.dart';
import 'offline_media_cache_service.dart';
import '../models/interaction_models.dart';

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

  // Offline services - will be injected
  OfflineQueueService? _offlineQueueService;
  CommentCacheService? _commentCacheService;
  ConflictResolutionService? _conflictResolutionService;
  InteractionService? _interactionService;

  void initializeOfflineServices(
    OfflineQueueService queueService,
    CommentCacheService cacheService,
    ConflictResolutionService conflictResolutionService,
    InteractionService interactionService,
  ) {
    _offlineQueueService = queueService;
    _commentCacheService = cacheService;
    _conflictResolutionService = conflictResolutionService;
    _interactionService = interactionService;
  }

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
      await syncCommentOperations(ref, background: true);
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }

  /// Sync katas from server to local storage
  Future<SyncResult> syncKatas(Ref ref, {bool background = false}) async {
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

      final List<app_storage.CachedKata> katasToCache = [];
      
      for (int i = 0; i < response.length; i++) {
        try {
          final kataData = response[i];
          final kata = app_storage.CachedKata(
            id: kataData['id'],
            name: kataData['name'],
            description: kataData['description'] ?? '',
            createdAt: DateTime.tryParse(kataData['created_at'] ?? '') ?? DateTime.now(),
            lastSynced: DateTime.now(),
            imageUrls: List<String>.from(kataData['image_urls'] ?? []),
            style: kataData['style'] ?? '',
            isFavorite: kataData['is_favorite'] ?? false,
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
      await app_storage.LocalStorage.saveKatas(katasToCache);

      // Cache media files (images and videos) for offline use
      await _cacheKataMedia(katasToCache, ref);

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

      final List<app_storage.CachedForumPost> postsToCache = [];
      
      for (int i = 0; i < response.length; i++) {
        try {
          final postData = response[i];
          final post = app_storage.CachedForumPost(
            id: postData['id'],
            title: postData['title'],
            content: postData['content'],
            authorId: postData['author_id'],
            authorName: postData['author_name'] ?? 'Unknown',
            createdAt: DateTime.parse(postData['created_at']),
            lastSynced: DateTime.now(),
            likesCount: postData['likes'] ?? 0,
            commentsCount: postData['replies'] ?? 0,
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
      await app_storage.LocalStorage.saveForumPosts(postsToCache);
      
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
      final favoriteKatas = app_storage.LocalStorage.getFavoriteKatas();
      
      for (final kata in favoriteKatas) {
        try {
          // Cache kata videos for offline use
          await _cacheKataVideos(kata.id, ref);
          
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
  /// Cache media files for katas (images and videos)
  Future<void> _cacheKataMedia(List<app_storage.CachedKata> katas, Ref ref) async {
    try {
      for (final kata in katas) {
        // Cache images
        if (kata.imageUrls.isNotEmpty) {
          await OfflineMediaCacheService.preCacheMediaFiles(kata.imageUrls, false, ref);
        }

        // Fetch and cache videos for this kata
        await _cacheKataVideos(kata.id, ref);
      }
      debugPrint('Media caching completed for ${katas.length} katas');
    } catch (e) {
      debugPrint('Error caching kata media: $e');
    }
  }

  Future<void> _cacheKataVideos(int kataId, Ref ref) async {
    try {
      // Fetch video URLs for this kata from the database
      final response = await _supabase
          .from('katas')
          .select('video_urls')
          .eq('id', kataId)
          .single();

      final videoUrls = List<String>.from(response['video_urls'] ?? []);

      if (videoUrls.isNotEmpty) {
        // Cache video files
        await OfflineMediaCacheService.preCacheMediaFiles(videoUrls, true, ref);
        debugPrint('Cached ${videoUrls.length} videos for kata $kataId');
      }
    } catch (e) {
      debugPrint('Error caching videos for kata $kataId: $e');
    }
  }

  /// Sync comment operations from offline queue
  Future<SyncResult> syncCommentOperations(Ref ref, {bool background = false}) async {
    if (_offlineQueueService == null || _interactionService == null) {
      return SyncResult(
        operation: SyncOperation.userData,
        success: true,
        itemsProcessed: 0,
        itemsFailed: 0,
        error: null,
        timestamp: DateTime.now(),
      );
    }

    int processed = 0;
    int failed = 0;
    String? error;

    try {
      if (!background) {
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.syncing,
          SyncOperation.userData,
          0.0,
        );
      }

      // Get all pending operations
      final pendingOperations = await _offlineQueueService!.getPendingOperations();

      if (pendingOperations.isEmpty) {
        return SyncResult(
          operation: SyncOperation.userData,
          success: true,
          itemsProcessed: 0,
          itemsFailed: 0,
          error: null,
          timestamp: DateTime.now(),
        );
      }

      // Process operations in batches
      const batchSize = 5;
      for (int i = 0; i < pendingOperations.length; i += batchSize) {
        final batchEnd = (i + batchSize).clamp(0, pendingOperations.length);
        final batch = pendingOperations.sublist(i, batchEnd);

        // Process batch concurrently
        final batchResults = await Future.wait(
          batch.map((operation) => _processCommentOperation(operation)),
        );

        // Count results
        for (final success in batchResults) {
          if (success) {
            processed++;
          } else {
            failed++;
          }
        }

        // Update progress
        if (!background) {
          final progress = batchEnd / pendingOperations.length;
          ref.read(offlineSyncProvider.notifier).updateProgress(progress);
        }
      }

      final result = SyncResult(
        operation: SyncOperation.userData,
        success: failed == 0,
        itemsProcessed: processed,
        itemsFailed: failed,
        error: failed > 0 ? '$failed operations failed to sync' : null,
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
      debugPrint('Error syncing comment operations: $e');

      final result = SyncResult(
        operation: SyncOperation.userData,
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

  /// Process a single comment operation
  Future<bool> _processCommentOperation(OfflineOperation operation) async {
    if (_offlineQueueService == null || _interactionService == null) return false;

    try {
      // Mark operation as processing
      await _offlineQueueService!.updateOperation(
        operation.id,
        status: OfflineOperationStatus.processing,
      );

      bool success = false;

      switch (operation.type) {
        case OfflineOperationType.addComment:
          final content = operation.data['content'] as String;
          final targetId = operation.data['target_id'] as int;
          final targetType = operation.data['target_type'] as String;

          if (targetType == 'kata') {
            await _interactionService!.addKataComment(kataId: targetId, content: content);
          } else if (targetType == 'ohyo') {
            await _interactionService!.addOhyoComment(ohyoId: targetId, content: content);
          }
          success = true;
          break;

        case OfflineOperationType.updateComment:
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;
          final content = operation.data['content'] as String;
          final localVersion = operation.data['version'] as int? ?? 1;

          // Try to update the comment with conflict detection
          success = await _updateCommentWithConflictResolution(
            commentId,
            commentType,
            content,
            localVersion,
            operation.userId!,
          );
          break;

        case OfflineOperationType.deleteComment:
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;

          if (commentType == 'kata_comment') {
            await _interactionService!.deleteKataComment(commentId);
          } else if (commentType == 'ohyo_comment') {
            await _interactionService!.deleteOhyoComment(commentId);
          }
          success = true;
          break;

        case OfflineOperationType.toggleLike:
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;
          await _interactionService!.executeToggleCommentLike(commentId, commentType, operation.userId!);
          success = true;
          break;

        case OfflineOperationType.toggleDislike:
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;
          await _interactionService!.executeToggleCommentDislike(commentId, commentType, operation.userId!);
          success = true;
          break;
      }

      if (success) {
        // Mark as completed
        await _offlineQueueService!.updateOperation(
          operation.id,
          status: OfflineOperationStatus.completed,
          processedAt: DateTime.now(),
        );

        // Update cache if needed
        if (_commentCacheService != null && operation.data.containsKey('comment_id')) {
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;
          await _commentCacheService!.removeCachedState(commentId, commentType); // Clear cache to force refresh
        }
      }

      return success;
    } catch (e) {
      debugPrint('Failed to process operation ${operation.id}: $e');

      // Check if this is a conflict that can be resolved
      if (_conflictResolutionService != null && e.toString().contains('version_conflict')) {
        // Create a conflict for manual resolution
        final conflictData = operation.data;
        final serverData = await _fetchCurrentCommentData(
          conflictData['comment_id'] as int,
          conflictData['comment_type'] as String,
        );

        if (serverData != null) {
          await _conflictResolutionService!.detectConflict(
            commentType: conflictData['comment_type'] as String,
            commentId: conflictData['comment_id'] as int,
            localData: conflictData,
            serverData: serverData,
            userId: operation.userId,
          );

          // Mark operation as failed but don't retry automatically
          await _offlineQueueService!.updateOperation(
            operation.id,
            status: OfflineOperationStatus.failed,
            error: 'Conflict detected - manual resolution required',
          );
          return false; // Don't retry
        }
      }

      // Mark as failed
      await _offlineQueueService!.markOperationFailed(operation.id, e.toString());
      return false;
    }
  }

  /// Update comment with conflict resolution
  Future<bool> _updateCommentWithConflictResolution(
    int commentId,
    String commentType,
    String content,
    int localVersion,
    String userId,
  ) async {
    if (_interactionService == null) return false;

    try {
      // First, try to get the current server state
      final currentServerData = await _fetchCurrentCommentData(commentId, commentType);

      if (currentServerData == null) {
        // Comment doesn't exist on server
        return false;
      }

      final serverVersion = currentServerData['version'] as int? ?? 1;

      // Check for version conflict
      if (serverVersion > localVersion) {
        // There's a conflict - create a conflict record
        if (_conflictResolutionService != null) {
          final localData = {
            'comment_id': commentId,
            'comment_type': commentType,
            'content': content,
            'version': localVersion,
          };

          await _conflictResolutionService!.detectConflict(
            commentType: commentType,
            commentId: commentId,
            localData: localData,
            serverData: currentServerData,
            userId: userId,
          );
        }
        return false; // Don't proceed with update
      }

      // No conflict, proceed with update
      if (commentType == 'kata_comment') {
        await _interactionService!.updateKataComment(
          commentId: commentId,
          content: content,
          version: localVersion + 1,
        );
      } else if (commentType == 'ohyo_comment') {
        await _interactionService!.updateOhyoComment(
          commentId: commentId,
          content: content,
          version: localVersion + 1,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error updating comment with conflict resolution: $e');
      return false;
    }
  }

  /// Fetch current comment data from server
  Future<Map<String, dynamic>?> _fetchCurrentCommentData(int commentId, String commentType) async {
    try {
      final tableName = commentType == 'kata_comment' ? 'kata_comments' : 'ohyo_comments';

      final response = await _supabase
          .from(tableName)
          .select('*')
          .eq('id', commentId)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error fetching current comment data: $e');
      return null;
    }
  }

  /// Get pending items count (including comment operations)
  int getPendingItemsCount() {
    // This is now handled by the offline sync notifier
    // Return 0 as the actual count is tracked in the notifier
    return 0;
  }

  /// Force sync all pending operations (for manual sync)
  Future<void> forceSyncPendingOperations(Ref ref) async {
    final networkState = ref.read(networkProvider);
    if (!networkState.isConnected) return;

    try {
      await syncCommentOperations(ref);
    } catch (e) {
      debugPrint('Force sync failed: $e');
    }
  }
}

/// Offline sync notifier
class OfflineSyncNotifier extends StateNotifier<OfflineSyncState> {
  final OfflineSyncService _syncService = OfflineSyncService();
  OfflineQueueService? _offlineQueueService;

  void initializeOfflineQueueService(OfflineQueueService queueService) {
    _offlineQueueService = queueService;
    // Listen to operations stream to update pending items count
    _offlineQueueService?.operationsStream.listen((operations) {
      final pendingCount = operations
          .where((op) => op.status == OfflineOperationStatus.pending ||
                         op.status == OfflineOperationStatus.processing)
          .length;
      state = state.copyWith(pendingItems: pendingCount);
    });
  }

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
