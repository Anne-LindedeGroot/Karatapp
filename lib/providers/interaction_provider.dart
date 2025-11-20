import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interaction_models.dart';
import '../services/interaction_service.dart';
import '../services/offline_queue_service.dart';
import '../services/comment_cache_service.dart';
import '../services/conflict_resolution_service.dart';
import 'error_boundary_provider.dart';

// Provider for the InteractionService instance
final interactionServiceProvider = Provider<InteractionService>((ref) {
  return InteractionService();
});

// Providers for offline services
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  throw UnimplementedError('OfflineQueueService must be provided by a parent provider');
});

final commentCacheServiceProvider = Provider<CommentCacheService>((ref) {
  throw UnimplementedError('CommentCacheService must be provided by a parent provider');
});

final conflictResolutionServiceProvider = Provider<ConflictResolutionService>((ref) {
  throw UnimplementedError('ConflictResolutionService must be provided by a parent provider');
});

// StateNotifier for kata interactions
class KataInteractionNotifier extends StateNotifier<KataInteractionState> {
  final InteractionService _interactionService;
  final ErrorBoundaryNotifier _errorBoundary;
  final int kataId;

  KataInteractionNotifier(
    this._interactionService,
    this._errorBoundary,
    this.kataId,
  ) : super(const KataInteractionState()) {
    loadKataInteractions();
  }

  Future<void> loadKataInteractions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load comments, likes, and favorites in parallel
      final results = await Future.wait([
        _interactionService.getKataComments(kataId),
        _interactionService.getKataLikes(kataId),
        _interactionService.isKataLiked(kataId),
        _interactionService.isKataFavorited(kataId),
      ]);

      final comments = results[0] as List<KataComment>;
      final likes = results[1] as List<Like>;
      final isLiked = results[2] as bool;
      final isFavorited = results[3] as bool;

      state = state.copyWith(
        comments: comments,
        likes: likes,
        isLiked: isLiked,
        isFavorited: isFavorited,
        likeCount: likes.length,
        commentCount: comments.length,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to load kata interactions: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  Future<void> addComment(String content, {int? parentCommentId}) async {
    try {
      final newComment = await _interactionService.addKataComment(
        kataId: kataId,
        content: content,
        parentCommentId: parentCommentId,
      );

      final updatedComments = [...state.comments, newComment];
      state = state.copyWith(
        comments: updatedComments,
        commentCount: updatedComments.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to add comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _interactionService.deleteKataComment(commentId);

      final updatedComments = state.comments
          .where((comment) => comment.id != commentId)
          .toList();
      state = state.copyWith(
        comments: updatedComments,
        commentCount: updatedComments.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to delete comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final updatedComment = await _interactionService.updateKataComment(
        commentId: commentId,
        content: content,
      );

      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return updatedComment;
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      final errorMessage = 'Failed to update comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleLike() async {
    try {
      final isLiked = await _interactionService.toggleKataLike(kataId);
      
      // Reload likes to get updated count
      final likes = await _interactionService.getKataLikes(kataId);
      
      state = state.copyWith(
        isLiked: isLiked,
        likes: likes,
        likeCount: likes.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to toggle like: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final isFavorited = await _interactionService.toggleKataFavorite(kataId);
      
      state = state.copyWith(isFavorited: isFavorited);
    } catch (e) {
      final errorMessage = 'Failed to toggle favorite: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<List<KataComment>> getCommentsPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _interactionService.getKataCommentsPaginated(
        kataId: kataId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      final errorMessage = 'Failed to load comments: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// StateNotifier for forum post interactions
class ForumInteractionNotifier extends StateNotifier<ForumInteractionState> {
  final InteractionService _interactionService;
  final ErrorBoundaryNotifier _errorBoundary;
  final int forumPostId;

  ForumInteractionNotifier(
    this._interactionService,
    this._errorBoundary,
    this.forumPostId,
  ) : super(const ForumInteractionState()) {
    loadForumInteractions();
  }

  Future<void> loadForumInteractions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load likes and favorites in parallel
      final results = await Future.wait([
        _interactionService.getForumPostLikes(forumPostId),
        _interactionService.isForumPostLiked(forumPostId),
        _interactionService.isForumPostFavorited(forumPostId),
      ]);

      final likes = results[0] as List<Like>;
      final isLiked = results[1] as bool;
      final isFavorited = results[2] as bool;

      state = state.copyWith(
        likes: likes,
        isLiked: isLiked,
        isFavorited: isFavorited,
        likeCount: likes.length,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to load forum interactions: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  Future<void> toggleLike() async {
    try {
      final isLiked = await _interactionService.toggleForumPostLike(forumPostId);
      
      // Reload likes to get updated count
      final likes = await _interactionService.getForumPostLikes(forumPostId);
      
      state = state.copyWith(
        isLiked: isLiked,
        likes: likes,
        likeCount: likes.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to toggle like: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final isFavorited = await _interactionService.toggleForumPostFavorite(forumPostId);
      
      state = state.copyWith(isFavorited: isFavorited);
    } catch (e) {
      final errorMessage = 'Failed to toggle favorite: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider for kata interactions (family provider for different katas)
final kataInteractionProvider = StateNotifierProvider.family<KataInteractionNotifier, KataInteractionState, int>((ref, kataId) {
  final interactionService = ref.watch(interactionServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return KataInteractionNotifier(interactionService, errorBoundary, kataId);
});

// StateNotifier for ohyo interactions
class OhyoInteractionNotifier extends StateNotifier<OhyoInteractionState> {
  final InteractionService _interactionService;
  final ErrorBoundaryNotifier _errorBoundary;
  final int ohyoId;

  OhyoInteractionNotifier(
    this._interactionService,
    this._errorBoundary,
    this.ohyoId,
  ) : super(const OhyoInteractionState()) {
    loadOhyoInteractions();
  }

  Future<void> loadOhyoInteractions() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load comments, likes, and favorites in parallel
      final results = await Future.wait([
        _interactionService.getOhyoComments(ohyoId),
        _interactionService.getOhyoLikes(ohyoId),
        _interactionService.isOhyoLiked(ohyoId),
        _interactionService.isOhyoFavorited(ohyoId),
      ]);

      final comments = results[0] as List<OhyoComment>;
      final likes = results[1] as List<Like>;
      final isLiked = results[2] as bool;
      final isFavorited = results[3] as bool;

      state = state.copyWith(
        comments: comments,
        likes: likes,
        isLiked: isLiked,
        isFavorited: isFavorited,
        likeCount: likes.length,
        commentCount: comments.length,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to load ohyo interactions: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  Future<void> addComment(String content, {int? parentCommentId}) async {
    try {
      final newComment = await _interactionService.addOhyoComment(
        ohyoId: ohyoId,
        content: content,
        parentCommentId: parentCommentId,
      );

      final updatedComments = [...state.comments, newComment];
      state = state.copyWith(
        comments: updatedComments,
        commentCount: updatedComments.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to add comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> deleteComment(int commentId) async {
    try {
      await _interactionService.deleteOhyoComment(commentId);

      final updatedComments = state.comments
          .where((comment) => comment.id != commentId)
          .toList();
      state = state.copyWith(
        comments: updatedComments,
        commentCount: updatedComments.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to delete comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final updatedComment = await _interactionService.updateOhyoComment(
        commentId: commentId,
        content: content,
      );

      final updatedComments = state.comments.map((comment) {
        if (comment.id == commentId) {
          return updatedComment;
        }
        return comment;
      }).toList();

      state = state.copyWith(comments: updatedComments);
    } catch (e) {
      final errorMessage = 'Failed to update comment: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleLike() async {
    try {
      final isLiked = await _interactionService.toggleOhyoLike(ohyoId);

      // Reload likes to get updated count
      final likes = await _interactionService.getOhyoLikes(ohyoId);

      state = state.copyWith(
        isLiked: isLiked,
        likes: likes,
        likeCount: likes.length,
      );
    } catch (e) {
      final errorMessage = 'Failed to toggle like: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleFavorite() async {
    try {
      final isFavorited = await _interactionService.toggleOhyoFavorite(ohyoId);

      state = state.copyWith(isFavorited: isFavorited);
    } catch (e) {
      final errorMessage = 'Failed to toggle favorite: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<List<OhyoComment>> getCommentsPaginated({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await _interactionService.getOhyoCommentsPaginated(
        ohyoId: ohyoId,
        limit: limit,
        offset: offset,
      );
    } catch (e) {
      final errorMessage = 'Failed to load comments: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }
}

// Provider for forum post interactions (family provider for different posts)
final forumInteractionProvider = StateNotifierProvider.family<ForumInteractionNotifier, ForumInteractionState, int>((ref, forumPostId) {
  final interactionService = ref.watch(interactionServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return ForumInteractionNotifier(interactionService, errorBoundary, forumPostId);
});

// Provider for ohyo interactions (family provider for different ohyos)
final ohyoInteractionProvider = StateNotifierProvider.family<OhyoInteractionNotifier, OhyoInteractionState, int>((ref, ohyoId) {
  final interactionService = ref.watch(interactionServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return OhyoInteractionNotifier(interactionService, errorBoundary, ohyoId);
});

// Convenience providers for specific interaction properties
final kataCommentsProvider = Provider.family<List<KataComment>, int>((ref, kataId) {
  return ref.watch(kataInteractionProvider(kataId)).comments;
});

final kataLikeCountProvider = Provider.family<int, int>((ref, kataId) {
  return ref.watch(kataInteractionProvider(kataId)).likeCount;
});

final kataIsLikedProvider = Provider.family<bool, int>((ref, kataId) {
  return ref.watch(kataInteractionProvider(kataId)).isLiked;
});

final kataIsFavoritedProvider = Provider.family<bool, int>((ref, kataId) {
  return ref.watch(kataInteractionProvider(kataId)).isFavorited;
});

final kataCommentCountProvider = Provider.family<int, int>((ref, kataId) {
  return ref.watch(kataInteractionProvider(kataId)).commentCount;
});

final forumPostLikeCountProvider = Provider.family<int, int>((ref, forumPostId) {
  return ref.watch(forumInteractionProvider(forumPostId)).likeCount;
});

final forumPostIsLikedProvider = Provider.family<bool, int>((ref, forumPostId) {
  return ref.watch(forumInteractionProvider(forumPostId)).isLiked;
});

final forumPostIsFavoritedProvider = Provider.family<bool, int>((ref, forumPostId) {
  return ref.watch(forumInteractionProvider(forumPostId)).isFavorited;
});

// Convenience providers for ohyo interactions
final ohyoCommentsProvider = Provider.family<List<OhyoComment>, int>((ref, ohyoId) {
  return ref.watch(ohyoInteractionProvider(ohyoId)).comments;
});

final ohyoLikeCountProvider = Provider.family<int, int>((ref, ohyoId) {
  return ref.watch(ohyoInteractionProvider(ohyoId)).likeCount;
});

final ohyoIsLikedProvider = Provider.family<bool, int>((ref, ohyoId) {
  return ref.watch(ohyoInteractionProvider(ohyoId)).isLiked;
});

final ohyoIsFavoritedProvider = Provider.family<bool, int>((ref, ohyoId) {
  return ref.watch(ohyoInteractionProvider(ohyoId)).isFavorited;
});

final ohyoCommentCountProvider = Provider.family<int, int>((ref, ohyoId) {
  return ref.watch(ohyoInteractionProvider(ohyoId)).commentCount;
});

// Provider for user's favorite katas
final userFavoriteKatasProvider = FutureProvider<List<int>>((ref) async {
  final interactionService = ref.watch(interactionServiceProvider);
  return await interactionService.getUserFavoriteKatas();
});

// Provider for user's favorite forum posts
final userFavoriteForumPostsProvider = FutureProvider<List<int>>((ref) async {
  final interactionService = ref.watch(interactionServiceProvider);
  return await interactionService.getUserFavoriteForumPosts();
});

// Provider for user's favorite ohyos
final userFavoriteOhyosProvider = FutureProvider<List<int>>((ref) async {
  final interactionService = ref.watch(interactionServiceProvider);
  return await interactionService.getUserFavoriteOhyos();
});

// Comment interaction providers

class CommentInteractionNotifier extends StateNotifier<CommentInteractionState> {
  final InteractionService _interactionService;
  final ErrorBoundaryNotifier _errorBoundary;
  final int commentId;
  final String commentType; // 'kata_comment', 'forum_comment', or 'ohyo_comment'

  // Offline services
  OfflineQueueService? _offlineQueueService;
  CommentCacheService? _commentCacheService;
  ConflictResolutionService? _conflictResolutionService;

  CommentInteractionNotifier(
    this._interactionService,
    this._errorBoundary,
    this.commentId,
    this.commentType,
  ) : super(const CommentInteractionState()) {
    loadCommentInteractions();
  }

  void initializeOfflineServices(
    OfflineQueueService queueService,
    CommentCacheService cacheService,
    ConflictResolutionService conflictResolutionService,
  ) {
    _offlineQueueService = queueService;
    _commentCacheService = cacheService;
    _conflictResolutionService = conflictResolutionService;
  }

  Future<void> loadCommentInteractions() async {
    state = state.copyWith(isLoading: true, error: null);

    // Check for unresolved conflicts first
    CommentConflict? conflict;
    if (_conflictResolutionService != null) {
      final conflicts = await _conflictResolutionService!.getUnresolvedConflictsForComment(commentType, commentId);
      if (conflicts.isNotEmpty) {
        conflict = conflicts.first; // Take the most recent conflict
      }
    }

    try {
      // First, try to load from cache for immediate UI feedback
      CachedCommentState? cachedState;
      if (_commentCacheService != null) {
        cachedState = await _commentCacheService!.getCachedCommentState(commentId, commentType);
        if (cachedState != null) {
          state = state.copyWith(
            isLiked: cachedState.isLiked,
            isDisliked: cachedState.isDisliked,
            likeCount: cachedState.likeCount,
            dislikeCount: cachedState.dislikeCount,
            isOffline: true,
            lastSynced: cachedState.lastSynced,
            conflict: conflict,
          );
        }
      }

      // Check for pending operations
      bool hasPendingOperations = false;
      if (_offlineQueueService != null) {
        final pendingOps = await _offlineQueueService!.getPendingOperations();
        hasPendingOperations = pendingOps.any((op) =>
          op.data['comment_id'] == commentId &&
          op.data['comment_type'] == commentType &&
          (op.type == OfflineOperationType.toggleLike || op.type == OfflineOperationType.toggleDislike)
        );
      }

      // Try to load fresh data from server
      try {
        final likes = await _interactionService.getCommentLikes(commentId, commentType);
        final dislikes = await _interactionService.getCommentDislikes(commentId, commentType);
        final isLiked = await _interactionService.isCommentLiked(commentId, commentType);
        final isDisliked = await _interactionService.isCommentDisliked(commentId, commentType);

        // Cache the fresh data
        if (_commentCacheService != null) {
          final freshCachedState = CachedCommentState(
            commentId: commentId,
            commentType: commentType,
            isLiked: isLiked,
            isDisliked: isDisliked,
            likeCount: likes.length,
            dislikeCount: dislikes.length,
            lastSynced: DateTime.now(),
          );
          await _commentCacheService!.cacheCommentState(freshCachedState);
        }

        state = state.copyWith(
          likes: likes,
          dislikes: dislikes,
          isLiked: isLiked,
          isDisliked: isDisliked,
          likeCount: likes.length,
          dislikeCount: dislikes.length,
          isLoading: false,
          error: null,
          isOffline: false,
          hasPendingOperations: hasPendingOperations,
          lastSynced: DateTime.now(),
          conflict: conflict,
        );
      } catch (serverError) {
        // Server request failed, but we have cached data
        state = state.copyWith(
          isLoading: false,
          error: cachedState != null ? null : 'Failed to load comment interactions: ${serverError.toString()}',
          isOffline: true,
          hasPendingOperations: hasPendingOperations,
          conflict: conflict,
        );

        // Only report non-network errors to global error boundary
        if (!_isNetworkError(serverError) && cachedState == null) {
          _errorBoundary.reportNetworkError('Failed to load comment interactions: ${serverError.toString()}');
        }
      }
    } catch (e) {
      final errorMessage = 'Failed to load comment interactions: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
        isOffline: true,
        conflict: conflict,
      );
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  Future<void> toggleLike() async {
    if (state.isLoading) return;

    final wasLiked = state.isLiked;
    final previousLikeCount = state.likeCount;

    // Optimistically update UI
    state = state.copyWith(
      isLiked: !wasLiked,
      likeCount: wasLiked ? previousLikeCount - 1 : previousLikeCount + 1,
    );

    try {
      await _interactionService.toggleCommentLike(commentId, commentType);
      // Reload to get accurate state
      await loadCommentInteractions();
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isLiked: wasLiked,
        likeCount: previousLikeCount,
      );
      final errorMessage = 'Failed to toggle comment like: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> toggleDislike() async {
    if (state.isLoading) return;

    final wasDisliked = state.isDisliked;
    final previousDislikeCount = state.dislikeCount;

    // Optimistically update UI
    state = state.copyWith(
      isDisliked: !wasDisliked,
      dislikeCount: wasDisliked ? previousDislikeCount - 1 : previousDislikeCount + 1,
    );

    try {
      await _interactionService.toggleCommentDislike(commentId, commentType);
      // Reload to get accurate state
      await loadCommentInteractions();
    } catch (e) {
      // Revert on error
      state = state.copyWith(
        isDisliked: wasDisliked,
        dislikeCount: previousDislikeCount,
      );
      final errorMessage = 'Failed to toggle comment dislike: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}
// Provider factories for different comment types
final kataCommentInteractionProvider = StateNotifierProvider.family<CommentInteractionNotifier, CommentInteractionState, int>(
  (ref, commentId) {
    final notifier = CommentInteractionNotifier(
      ref.watch(interactionServiceProvider),
      ref.watch(errorBoundaryProvider.notifier),
      commentId,
      'kata_comment',
    );
    notifier.initializeOfflineServices(
      ref.watch(offlineQueueServiceProvider),
      ref.watch(commentCacheServiceProvider),
      ref.watch(conflictResolutionServiceProvider),
    );
    return notifier;
  },
);
final forumCommentInteractionProvider = StateNotifierProvider.family<CommentInteractionNotifier, CommentInteractionState, int>(
  (ref, commentId) {
    final notifier = CommentInteractionNotifier(
      ref.watch(interactionServiceProvider),
      ref.watch(errorBoundaryProvider.notifier),
      commentId,
      'forum_comment',
    );
    notifier.initializeOfflineServices(
      ref.watch(offlineQueueServiceProvider),
      ref.watch(commentCacheServiceProvider),
      ref.watch(conflictResolutionServiceProvider),
    );
    return notifier;
  },
);
final ohyoCommentInteractionProvider = StateNotifierProvider.family<CommentInteractionNotifier, CommentInteractionState, int>(
  (ref, commentId) {
    final notifier = CommentInteractionNotifier(
      ref.watch(interactionServiceProvider),
      ref.watch(errorBoundaryProvider.notifier),
      commentId,
      'ohyo_comment',
    );
    notifier.initializeOfflineServices(
      ref.watch(offlineQueueServiceProvider),
      ref.watch(commentCacheServiceProvider),
      ref.watch(conflictResolutionServiceProvider),
    );
    return notifier;
  },
);
