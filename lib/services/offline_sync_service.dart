import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/storage/local_storage.dart' as app_storage;
import '../providers/data_usage_provider.dart';
import '../providers/network_provider.dart';
import '../providers/forum_provider.dart';
import 'offline_queue_service.dart';
import 'comment_cache_service.dart';
import 'conflict_resolution_service.dart';
import 'interaction_service.dart';
import 'offline_media_cache_service.dart';
import '../models/interaction_models.dart';
import '../models/forum_models.dart';

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
  comprehensiveCache,
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
  void startBackgroundSync(dynamic ref) {
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
  Future<void> _performBackgroundSync(dynamic ref) async {
    final networkState = ref.read(networkProvider);
    final dataUsageState = ref.read(dataUsageProvider);

    // Only sync if connected and data usage is allowed
    if (!networkState.isConnected || !dataUsageState.shouldAllowDataUsage) {
      return;
    }

    try {
      await syncKatas(ref, background: true);
      await syncOhyos(ref, background: true);
      await syncForumPosts(ref, background: true);
      await syncCommentOperations(ref, background: true);
    } catch (e) {
      debugPrint('Background sync failed: $e');
    }
  }


  /// Sync ohyos from server to local storage
  Future<SyncResult> syncOhyos(dynamic ref, {bool background = false}) async {
    int processed = 0;
    int failed = 0;
    String? error;

    try {
      if (!background) {
        ref.read(offlineSyncProvider.notifier).updateStatus(
          SyncStatus.syncing,
          SyncOperation.katas, // Reuse kata operation for now, can add ohyo operation later
          0.0,
        );
      }

      // Fetch ohyos from server
      final response = await _supabase
          .from('ohyo')
          .select()
          .order('id');

      if (response.isEmpty) {
        return SyncResult(
          operation: SyncOperation.katas, // Reuse kata operation
          success: true,
          itemsProcessed: 0,
          itemsFailed: 0,
          error: null,
          timestamp: DateTime.now(),
        );
      }

      final List<app_storage.CachedOhyo> ohyosToCache = [];

      for (int i = 0; i < response.length; i++) {
        try {
          final ohyoData = response[i];
          final ohyoId = ohyoData['id'];

          // Get like information for this ohyo
          int likeCount = 0;
          bool isLiked = false;
          try {
            final likesResponse = await _supabase
                .from('likes')
                .select('id, user_id')
                .eq('target_type', 'ohyo')
                .eq('target_id', ohyoId);

            likeCount = likesResponse.length;

            // Check if current user liked this ohyo
            final user = _supabase.auth.currentUser;
            if (user != null) {
              isLiked = likesResponse.any((like) => like['user_id'] == user.id);
            }
          } catch (likeError) {
            debugPrint('Error fetching likes for ohyo $ohyoId: $likeError');
          }

          final ohyo = app_storage.CachedOhyo(
            id: ohyoId,
            name: ohyoData['name'],
            description: ohyoData['description'] ?? '',
            createdAt: DateTime.tryParse(ohyoData['created_at'] ?? '') ?? DateTime.now(),
            lastSynced: DateTime.now(),
            imageUrls: List<String>.from(ohyoData['image_urls'] ?? []),
            style: ohyoData['style'] ?? '',
            isFavorite: ohyoData['is_favorite'] ?? false,
            needsSync: false,
            isLiked: isLiked,
            likeCount: likeCount,
          );

          ohyosToCache.add(ohyo);
          processed++;

          // Update progress
          if (!background) {
            final progress = (i + 1) / response.length;
            ref.read(offlineSyncProvider.notifier).updateProgress(progress);
          }
        } catch (e) {
          failed++;
          debugPrint('Error processing ohyo ${response[i]['id']}: $e');
        }
      }

      // Save to local storage
      await app_storage.LocalStorage.saveOhyos(ohyosToCache);

      // Cache media files (images and videos) for offline use
      await _cacheOhyoMedia(ohyosToCache, ref);

      // Record data usage
      final estimatedBytes = response.length * 1024; // ~1KB per ohyo
      ref.read(dataUsageProvider.notifier).recordDataUsage(estimatedBytes, type: 'forum');

      final result = SyncResult(
        operation: SyncOperation.katas, // Reuse kata operation
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
      debugPrint('Error syncing ohyos: $e');

      final result = SyncResult(
        operation: SyncOperation.katas, // Reuse kata operation
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
          final kataId = kataData['id'];

          // Get like information for this kata
          int likeCount = 0;
          bool isLiked = false;
          try {
            final likesResponse = await _supabase
                .from('likes')
                .select('id, user_id')
                .eq('target_type', 'kata')
                .eq('target_id', kataId);

            likeCount = likesResponse.length;

            // Check if current user liked this kata
            final user = _supabase.auth.currentUser;
            if (user != null) {
              isLiked = likesResponse.any((like) => like['user_id'] == user.id);
            }
          } catch (likeError) {
            debugPrint('Error fetching likes for kata $kataId: $likeError');
          }

          final kata = app_storage.CachedKata(
            id: kataId,
            name: kataData['name'],
            description: kataData['description'] ?? '',
            createdAt: DateTime.tryParse(kataData['created_at'] ?? '') ?? DateTime.now(),
            lastSynced: DateTime.now(),
            imageUrls: List<String>.from(kataData['image_urls'] ?? []),
            style: kataData['style'] ?? '',
            isFavorite: kataData['is_favorite'] ?? false,
            needsSync: false,
            isLiked: isLiked,
            likeCount: likeCount,
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

      // Fetch all forum posts for comprehensive offline access
      final response = await _supabase
          .from('forum_posts')
          .select()
          .order('created_at', ascending: false);

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
  Future<void> preloadFavorites(dynamic ref) async {
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

      // Get favorite ohyos
      final favoriteOhyos = app_storage.LocalStorage.getFavoriteOhyos();

      for (final ohyo in favoriteOhyos) {
        try {
          // Cache ohyo videos for offline use
          await _cacheOhyoVideos(ohyo.id, ref);

          // Small delay to avoid overwhelming the network
          await Future.delayed(const Duration(milliseconds: 500));
        } catch (e) {
          debugPrint('Error preloading ohyo ${ohyo.id}: $e');
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
        // Clear old cache for this kata before caching new content
        await OfflineMediaCacheService.clearKataCache(kata.id);

        // Cache images
        if (kata.imageUrls.isNotEmpty) {
          await OfflineMediaCacheService.preCacheMediaFiles(kata.imageUrls, false, ref);
          // Update metadata for offline gallery access with all URLs
          await OfflineMediaCacheService.updateKataMetadata(kata.id, kata.imageUrls);
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

  /// Cache media files for ohyos (images and videos)
  Future<void> _cacheOhyoMedia(List<app_storage.CachedOhyo> ohyos, Ref ref) async {
    try {
      for (final ohyo in ohyos) {
        // Clear old cache for this ohyo before caching new content
        await OfflineMediaCacheService.clearOhyoCache(ohyo.id);

        // Cache images
        if (ohyo.imageUrls.isNotEmpty) {
          await OfflineMediaCacheService.preCacheMediaFiles(ohyo.imageUrls, false, ref);
          // Update metadata for offline gallery access
          for (final url in ohyo.imageUrls) {
            // Extract filename from URL for metadata
            final fileName = _extractFileNameFromUrl(url);
            if (fileName != null) {
              await OfflineMediaCacheService.cacheOhyoImage(ohyo.id, fileName, url, ref);
            }
          }
        }

        // Fetch and cache videos for this ohyo
        await _cacheOhyoVideos(ohyo.id, ref);
      }
      debugPrint('Media caching completed for ${ohyos.length} ohyos');
    } catch (e) {
      debugPrint('Error caching ohyo media: $e');
    }
  }

  Future<void> _cacheOhyoVideos(int ohyoId, Ref ref) async {
    try {
      // Fetch video URLs for this ohyo from the database
      final response = await _supabase
          .from('ohyo')
          .select('video_urls')
          .eq('id', ohyoId)
          .single();

      final videoUrls = List<String>.from(response['video_urls'] ?? []);

      if (videoUrls.isNotEmpty) {
        // Cache video files
        await OfflineMediaCacheService.preCacheMediaFiles(videoUrls, true, ref);
        debugPrint('Cached ${videoUrls.length} videos for ohyo $ohyoId');
      }
    } catch (e) {
      debugPrint('Error caching videos for ohyo $ohyoId: $e');
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

        case OfflineOperationType.addForumComment:
          final content = operation.data['content'] as String;
          final postId = operation.data['post_id'] as int;
          final parentCommentId = operation.data['parent_comment_id'] as int?;

          await _interactionService!.addForumComment(
            postId: postId,
            content: content,
            parentCommentId: parentCommentId,
          );
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

        case OfflineOperationType.toggleKataLike:
          final kataId = operation.data['kata_id'] as int;
          await _interactionService!.executeToggleKataLike(kataId, operation.userId!);
          success = true;
          break;

        case OfflineOperationType.toggleOhyoLike:
          final ohyoId = operation.data['ohyo_id'] as int;
          await _interactionService!.executeToggleOhyoLike(ohyoId, operation.userId!);
          success = true;
          break;

        case OfflineOperationType.toggleDislike:
          final commentId = operation.data['comment_id'] as int;
          final commentType = operation.data['comment_type'] as String;
          await _interactionService!.executeToggleCommentDislike(commentId, commentType, operation.userId!);
          success = true;
          break;

        case OfflineOperationType.updateForumComment:
          final commentId = operation.data['comment_id'] as int;
          final content = operation.data['content'] as String;

          await _interactionService!.updateForumComment(
            commentId: commentId,
            content: content,
          );
          success = true;
          break;

        case OfflineOperationType.deleteForumComment:
          final commentId = operation.data['comment_id'] as int;

          await _interactionService!.deleteForumComment(commentId);
          success = true;
          break;

        case OfflineOperationType.toggleForumLike:
          final forumPostId = operation.data['forum_post_id'] as int;

          await _interactionService!.toggleForumPostLike(forumPostId);
          success = true;
          break;

        case OfflineOperationType.toggleForumFavorite:
          final forumPostId = operation.data['forum_post_id'] as int;

          await _interactionService!.toggleForumPostFavorite(forumPostId);
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

  /// Extract filename from URL for metadata purposes
  String? _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      debugPrint('Error extracting filename from URL $url: $e');
    }
    return null;
  }


  /// Get pending items count (including comment operations)
  int getPendingItemsCount() {
    // This is now handled by the offline sync notifier
    // Return 0 as the actual count is tracked in the notifier
    return 0;
  }




  /// Check if comprehensive cache has been completed
  Future<bool> isComprehensiveCacheCompleted() async {
    return app_storage.LocalStorage.getSetting('comprehensive_cache_completed', defaultValue: false) ?? false;
  }

  /// Mark comprehensive cache as completed
  Future<void> _markComprehensiveCacheCompleted() async {
    await app_storage.LocalStorage.saveSetting('comprehensive_cache_completed', true);
  }

  /// Force sync all pending operations (for manual sync)
  Future<void> forceSyncPendingOperations(dynamic ref) async {
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

  void initializeServices(
    OfflineQueueService queueService,
    CommentCacheService cacheService,
    ConflictResolutionService conflictResolutionService,
    InteractionService interactionService,
  ) {
    _offlineQueueService = queueService;
    _syncService.initializeOfflineServices(
      queueService,
      cacheService,
      conflictResolutionService,
      interactionService,
    );
    
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
    // Create a completely new mutable list
    final currentResults = state.recentResults.toList();
    final newResults = [result, ...currentResults];

    // Keep only last 10 results
    if (newResults.length > 10) {
      newResults.removeRange(10, newResults.length);
    }

    state = state.copyWith(recentResults: newResults);
  }

  /// Start full sync
  Future<void> startFullSync(dynamic ref) async {
    if (state.isSyncing) return;

    try {
      await _syncService.syncKatas(ref);
      await _syncService.syncOhyos(ref);
      await _syncService.syncForumPosts(ref);
    } catch (e) {
      debugPrint('Full sync failed: $e');
    }
  }

  /// Start background sync
  void startBackgroundSync(dynamic ref) {
    _syncService.startBackgroundSync(ref);
    state = state.copyWith(isBackgroundSyncEnabled: true);
  }

  /// Stop background sync
  void stopBackgroundSync() {
    _syncService.stopBackgroundSync();
    state = state.copyWith(isBackgroundSyncEnabled: false);
  }

  /// Preload favorites
  Future<void> preloadFavorites(dynamic ref) async {
    await _syncService.preloadFavorites(ref);
  }

  /// Comprehensive cache - cache everything for offline use
  Future<void> comprehensiveCache(Ref ref) async {
    // Update status to syncing
    state = state.copyWith(
      status: SyncStatus.syncing,
      currentOperation: SyncOperation.comprehensiveCache,
      progress: 0.0,
    );

    try {
      int processed = 0;
      int failed = 0;
      final List<app_storage.CachedKata> katasToCache = [];
      final List<app_storage.CachedOhyo> ohyosToCache = [];

      debugPrint('🚀 Starting comprehensive offline cache...');
      debugPrint('📥 Syncing metadata...');

      // Sync katas
      try {
        final kataResponse = await Supabase.instance.client.from('katas').select().order('id');
        katasToCache.clear(); // Reset in case of retry

        for (final kataData in kataResponse) {
          final kataId = kataData['id'];

          // Get like information for this kata
          int likeCount = 0;
          bool isLiked = false;
          try {
            final likesResponse = await Supabase.instance.client
                .from('likes')
                .select('id, user_id')
                .eq('target_type', 'kata')
                .eq('target_id', kataId);

            likeCount = likesResponse.length;

            // Check if current user liked this kata
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              isLiked = likesResponse.any((like) => like['user_id'] == user.id);
            }
          } catch (likeError) {
            debugPrint('Error fetching likes for kata $kataId: $likeError');
          }

          final kata = app_storage.CachedKata(
            id: kataId,
            name: kataData['name'],
            description: kataData['description'] ?? '',
            createdAt: DateTime.tryParse(kataData['created_at'] ?? '') ?? DateTime.now(),
            lastSynced: DateTime.now(),
            imageUrls: List<String>.from(kataData['image_urls'] ?? []),
            style: kataData['style'] ?? '',
            isFavorite: kataData['is_favorite'] ?? false,
            needsSync: false,
            isLiked: isLiked,
            likeCount: likeCount,
          );
          katasToCache.add(kata);
        }

        await app_storage.LocalStorage.saveKatas(katasToCache);
        processed += katasToCache.length;
        debugPrint('✅ Synced ${katasToCache.length} katas');

        // Verify katas were saved
        final savedKatas = app_storage.LocalStorage.getAllKatas();
        debugPrint('✅ Verified ${savedKatas.length} katas saved to local storage');
      } catch (e) {
        failed++;
        debugPrint('❌ Error syncing katas: $e');
      }

      // Sync ohyos
      try {
        final ohyoResponse = await Supabase.instance.client.from('ohyo').select().order('id');
        ohyosToCache.clear(); // Reset in case of retry

        for (final ohyoData in ohyoResponse) {
          final ohyoId = ohyoData['id'];

          // Get like information for this ohyo
          int likeCount = 0;
          bool isLiked = false;
          try {
            final likesResponse = await Supabase.instance.client
                .from('likes')
                .select('id, user_id')
                .eq('target_type', 'ohyo')
                .eq('target_id', ohyoId);

            likeCount = likesResponse.length;

            // Check if current user liked this ohyo
            final user = Supabase.instance.client.auth.currentUser;
            if (user != null) {
              isLiked = likesResponse.any((like) => like['user_id'] == user.id);
            }
          } catch (likeError) {
            debugPrint('Error fetching likes for ohyo $ohyoId: $likeError');
          }

          final ohyo = app_storage.CachedOhyo(
            id: ohyoId,
            name: ohyoData['name'],
            description: ohyoData['description'] ?? '',
            createdAt: DateTime.tryParse(ohyoData['created_at'] ?? '') ?? DateTime.now(),
            lastSynced: DateTime.now(),
            imageUrls: List<String>.from(ohyoData['image_urls'] ?? []),
            style: ohyoData['style'] ?? '',
            isFavorite: ohyoData['is_favorite'] ?? false,
            needsSync: false,
            isLiked: isLiked,
            likeCount: likeCount,
          );
          ohyosToCache.add(ohyo);
        }

        await app_storage.LocalStorage.saveOhyos(ohyosToCache);

        // Verify ohyos were saved
        final verifiedOhyos = app_storage.LocalStorage.getAllOhyos();
        debugPrint('✅ Verified ${verifiedOhyos.length} ohyos saved to local storage');

        processed += ohyosToCache.length;
        debugPrint('✅ Synced ${ohyosToCache.length} ohyos');

        // Verify ohyos were saved
        final savedOhyos = app_storage.LocalStorage.getAllOhyos();
        debugPrint('✅ Verified ${savedOhyos.length} ohyos saved to local storage');
      } catch (e) {
        failed++;
        debugPrint('❌ Error syncing ohyos: $e');
      }

      // Sync forum posts
      try {
        final forumResponse = await Supabase.instance.client.from('forum_posts').select().order('created_at', ascending: false);
        final List<app_storage.CachedForumPost> postsToCache = [];

        for (final postData in forumResponse) {
          final post = app_storage.CachedForumPost(
            id: postData['id'].toString(),
            title: postData['title'],
            content: postData['content'],
            authorId: postData['author_id'].toString(),
            authorName: postData['author_name'] ?? 'Unknown',
            createdAt: DateTime.parse(postData['created_at']),
            lastSynced: DateTime.now(),
            likesCount: postData['likes'] ?? 0,
            commentsCount: postData['replies'] ?? 0,
            needsSync: false,
          );
          postsToCache.add(post);
        }

        await app_storage.LocalStorage.saveForumPosts(postsToCache);

        // Verify forum posts were saved
        final savedForumPosts = app_storage.LocalStorage.getAllForumPosts();
        debugPrint('✅ Verified ${savedForumPosts.length} forum posts saved to local storage');

        // Also cache individual posts for offline viewing
        await _cacheIndividualForumPosts(postsToCache, ref);
        processed += postsToCache.length;
        debugPrint('✅ Synced ${postsToCache.length} forum posts');

        processed += postsToCache.length;
        debugPrint('✅ Synced ${postsToCache.length} forum posts');
      } catch (e) {
        failed++;
        debugPrint('❌ Error syncing forum posts: $e');
      }

      // Clean up orphaned cache files before caching new content
      debugPrint('🧹 Cleaning up orphaned cache files...');
      await OfflineMediaCacheService.cleanupOrphanedCacheFiles();

      // Cache media for all items
      debugPrint('💾 Starting comprehensive media cache...');
      await _cacheAllMedia(ref, katasToCache, ohyosToCache);

      final result = SyncResult(
        operation: SyncOperation.comprehensiveCache,
        success: failed == 0,
        itemsProcessed: processed,
        itemsFailed: failed,
        error: failed > 0 ? '$failed operations failed' : null,
        timestamp: DateTime.now(),
      );

      // Only mark comprehensive cache as completed if all operations succeeded
      if (failed == 0) {
        await _syncService._markComprehensiveCacheCompleted();

        // Notify forum provider to reload cached posts
        try {
          final forumNotifier = ref.read(forumNotifierProvider.notifier);
          await forumNotifier.reloadCachedPosts();
          debugPrint('✅ Notified forum provider to reload cached posts');
        } catch (e) {
          debugPrint('⚠️ Failed to notify forum provider: $e');
        }
      }

      // Update with results
      final newResults = List<SyncResult>.from(state.recentResults);
      newResults.insert(0, result);
      if (newResults.length > 10) {
        newResults.removeRange(10, newResults.length);
      }

      state = state.copyWith(
        status: SyncStatus.completed,
        currentOperation: null,
        progress: 1.0,
        recentResults: newResults,
        lastSyncTime: DateTime.now(),
      );

      debugPrint('✅ Comprehensive offline cache completed! Processed: $processed, Failed: $failed');
    } catch (e) {
      debugPrint('❌ Comprehensive cache failed: $e');
      state = state.copyWith(
        status: SyncStatus.failed,
        currentOperation: null,
        progress: 0.0,
        lastError: e.toString(),
      );
    }
  }

  /// Cache media for all katas and ohyos (images only - videos work online only)
  Future<void> _cacheAllMedia(dynamic ref, List<app_storage.CachedKata> katasToCache, List<app_storage.CachedOhyo> ohyosToCache) async {
    try {
      debugPrint('📹 Starting image caching for ${katasToCache.length} katas and ${ohyosToCache.length} ohyos...');

      // Cache images for all katas
      for (final kata in katasToCache) {
        debugPrint('📹 Kata ${kata.id}: ${kata.name} with ${kata.imageUrls.length} images');
        if (kata.imageUrls.isNotEmpty) {
          debugPrint('📹 Caching ${kata.imageUrls.length} images for kata ${kata.id}');
          await OfflineMediaCacheService.preCacheMediaFiles(kata.imageUrls, false, ref);
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // Cache images for all ohyos
      for (final ohyo in ohyosToCache) {
        debugPrint('📹 Ohyo ${ohyo.id}: ${ohyo.name} with ${ohyo.imageUrls.length} images');
        if (ohyo.imageUrls.isNotEmpty) {
          debugPrint('📹 Caching ${ohyo.imageUrls.length} images for ohyo ${ohyo.id}');
          await OfflineMediaCacheService.preCacheMediaFiles(ohyo.imageUrls, false, ref);
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }

      debugPrint('✅ Comprehensive image caching completed (videos work online only)');
    } catch (e) {
      debugPrint('❌ Error in comprehensive image cache: $e');
    }
  }


  /// Cache individual forum posts for offline viewing
  Future<void> _cacheIndividualForumPosts(List<app_storage.CachedForumPost> cachedPosts, Ref ref) async {
    try {
      // Get the offline forum service from the ref
      final offlineForumService = ref.read(offlineForumServiceProvider);

      for (final cachedPost in cachedPosts) {
        try {
          // Fetch full post data from server
          final fullPostResponse = await Supabase.instance.client
              .from('forum_posts')
              .select('''
                *,
                forum_post_categories (
                  category
                )
              ''')
              .eq('id', cachedPost.id)
              .single();

          // Convert to ForumPost model
          final categoryString = fullPostResponse['forum_post_categories']?['category'] ?? 'general';
          final category = ForumCategory.values.firstWhere(
            (cat) => cat.name == categoryString,
            orElse: () => ForumCategory.general,
          );

          final forumPost = ForumPost(
            id: fullPostResponse['id'] as int,
            title: fullPostResponse['title'],
            content: fullPostResponse['content'],
            authorId: fullPostResponse['author_id'].toString(),
            authorName: fullPostResponse['author_name'] ?? 'Unknown',
            authorAvatar: null, // Not cached
            category: category,
            createdAt: DateTime.parse(fullPostResponse['created_at']),
            updatedAt: DateTime.parse(fullPostResponse['updated_at'] ?? fullPostResponse['created_at']),
            isPinned: fullPostResponse['is_pinned'] ?? false,
            isLocked: fullPostResponse['is_locked'] ?? false,
            commentCount: fullPostResponse['replies'] ?? 0,
            comments: [], // Comments will be loaded separately when needed
          );

          // Cache the individual post
          await offlineForumService.cacheIndividualPost(forumPost);
          debugPrint('✅ Cached individual forum post: ${forumPost.id} - ${forumPost.title}');
        } catch (e) {
          debugPrint('Error caching individual forum post ${cachedPost.id}: $e');
          // Continue with other posts
        }
      }

      debugPrint('✅ Cached ${cachedPosts.length} individual forum posts');
    } catch (e) {
      debugPrint('❌ Error caching individual forum posts: $e');
    }
  }

  /// Check if comprehensive cache has been completed
  Future<bool> isComprehensiveCacheCompleted() async {
    return await _syncService.isComprehensiveCacheCompleted();
  }

  /// Clean up orphaned cache files
  Future<void> cleanupOrphanedCacheFiles() async {
    await OfflineMediaCacheService.cleanupOrphanedCacheFiles();
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
