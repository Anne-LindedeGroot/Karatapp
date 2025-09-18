import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interaction_models.dart';
import '../services/interaction_service.dart';
import 'error_boundary_provider.dart';

// Provider for the InteractionService instance
final interactionServiceProvider = Provider<InteractionService>((ref) {
  return InteractionService();
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

  Future<void> addComment(String content) async {
    try {
      final newComment = await _interactionService.addKataComment(
        kataId: kataId,
        content: content,
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

// Provider for forum post interactions (family provider for different posts)
final forumInteractionProvider = StateNotifierProvider.family<ForumInteractionNotifier, ForumInteractionState, int>((ref, forumPostId) {
  final interactionService = ref.watch(interactionServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return ForumInteractionNotifier(interactionService, errorBoundary, forumPostId);
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
