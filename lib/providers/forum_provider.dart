import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../models/interaction_models.dart';
import '../services/forum_service.dart';
import '../services/offline_forum_service.dart';
import '../services/offline_queue_service.dart';
import '../core/storage/local_storage.dart' as app_storage;
import 'error_boundary_provider.dart';
import 'offline_services_provider.dart';
import 'auth_provider.dart';

// Provider for the ForumService instance
final forumServiceProvider = Provider<ForumService>((ref) {
  return ForumService();
});

// Provider for offline forum service
final offlineForumServiceProvider = Provider<OfflineForumService>((ref) {
  throw UnimplementedError('OfflineForumService must be provided by a parent provider');
});

// StateNotifier for forum management
class ForumNotifier extends StateNotifier<ForumState> {
  final ForumService _forumService;
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;
  OfflineForumService? _offlineForumService;
  OfflineQueueService? _offlineQueueService;

  ForumNotifier(this._forumService, this._errorBoundary, this._ref) : super(const ForumState()) {
    loadPosts();
  }

  void initializeOfflineService(OfflineForumService offlineForumService) {
    _offlineForumService = offlineForumService;
  }

  void initializeOfflineQueueService(OfflineQueueService offlineQueueService) {
    _offlineQueueService = offlineQueueService;
  }

  /// Check if the device is currently online
  Future<bool> _isOnline() async {
    try {
      // Use a quick network check
      await _forumService.getPosts(limit: 1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> loadPosts({
    ForumCategory? category,
    String? searchQuery,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    List<ForumPost>? cachedPosts;
    bool isOnline = true; // Will be determined by network check

    // First, try to load from cache if available (using Hive storage)
    try {
      final cachedForumPosts = app_storage.LocalStorage.getAllForumPosts();
      debugPrint('📱 Forum provider: Found ${cachedForumPosts.length} cached forum posts in local storage');

      if (cachedForumPosts.isNotEmpty) {
        // Convert CachedForumPost to ForumPost
        cachedPosts = cachedForumPosts.map((cachedPost) {
          debugPrint('📱 Converting cached post: ${cachedPost.title} (ID: ${cachedPost.id})');
          return ForumPost(
            id: int.parse(cachedPost.id),
            title: cachedPost.title,
            content: cachedPost.content,
            authorId: cachedPost.authorId,
            authorName: cachedPost.authorName,
            authorAvatar: null, // Not stored in cached version
            category: ForumCategory.general, // Default category
            createdAt: cachedPost.createdAt,
            updatedAt: cachedPost.lastSynced, // Use lastSynced as updatedAt
            isPinned: false, // Not stored in cached version
            isLocked: false, // Not stored in cached version
            commentCount: cachedPost.commentsCount,
            comments: [], // Comments not cached at post list level
          );
        }).toList();

        // Sort by creation date (newest first)
        cachedPosts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        debugPrint('📱 Forum provider: Successfully loaded ${cachedPosts.length} cached posts');
      } else {
        debugPrint('📱 Forum provider: No cached forum posts found');
      }
    } catch (e) {
      // Ignore cache errors
      debugPrint('❌ Error loading cached forum posts: $e');
    }

    // Check network connectivity
    try {
      debugPrint('📡 Forum provider: Checking network connectivity...');
      await _forumService.getPosts(limit: 1); // Quick connectivity check
      isOnline = true;
      debugPrint('📡 Forum provider: Network check passed - device is online');
    } catch (e) {
      isOnline = false;
      debugPrint('📡 Forum provider: Network check failed - device is offline: $e');
    }

    if (isOnline) {
      // Online mode - try to load fresh data
      try {
        final posts = await _forumService.getPosts(
          category: category,
          searchQuery: searchQuery,
        );

        // Cache the online data to both SharedPreferences and Hive
        if (_offlineForumService != null) {
          await _offlineForumService!.cacheForumPosts(posts);
        }

        // Also cache to Hive storage for consistency
        final cachedPostsToSave = posts.map((post) {
          return app_storage.CachedForumPost(
            id: post.id.toString(),
            title: post.title,
            content: post.content,
            authorId: post.authorId,
            authorName: post.authorName,
            createdAt: post.createdAt,
            lastSynced: DateTime.now(),
            likesCount: 0, // Not available in ForumPost
            commentsCount: post.commentCount,
            needsSync: false,
          );
        }).toList();

        await app_storage.LocalStorage.saveForumPosts(cachedPostsToSave);

        final filteredPosts = _filterPosts(posts, searchQuery ?? state.searchQuery, category ?? state.selectedCategory);

        // Update state with online data
        state = state.copyWith(
          posts: posts,
          filteredPosts: filteredPosts,
          isLoading: false,
          error: null,
          isOfflineMode: false,
        );
      } catch (e) {
        // Online loading failed, fall back to cached data if available
        if (cachedPosts != null && cachedPosts.isNotEmpty) {
          final filteredPosts = _filterPosts(cachedPosts, searchQuery ?? state.searchQuery, category ?? state.selectedCategory);
          state = state.copyWith(
            posts: cachedPosts,
            filteredPosts: filteredPosts,
            isLoading: false,
            error: null,
            isOfflineMode: true,
          );
        } else {
          // No cached data available, show error
          final errorMessage = 'Failed to load forum posts: ${e.toString()}';
          state = state.copyWith(
            isLoading: false,
            error: errorMessage,
            isOfflineMode: false,
          );

          // Report to global error boundary
          _errorBoundary.reportNetworkError(errorMessage);
        }
      }
    } else {
      // Offline mode - use cached data if available
      debugPrint('📱 Forum provider: Offline mode - cachedPosts is ${cachedPosts?.length ?? 0}');
      if (cachedPosts != null && cachedPosts.isNotEmpty) {
        final filteredPosts = _filterPosts(cachedPosts, searchQuery ?? state.searchQuery, category ?? state.selectedCategory);
        debugPrint('📱 Forum provider: Using ${cachedPosts.length} cached posts in offline mode');
        state = state.copyWith(
          posts: cachedPosts,
          filteredPosts: filteredPosts,
          isLoading: false,
          error: null,
          isOfflineMode: true,
        );
      } else {
        // No cached data available
        debugPrint('📱 Forum provider: No cached data available - showing error');
        state = state.copyWith(
          isLoading: false,
          error: 'Geen internetverbinding en geen lokale gegevens beschikbaar',
          isOfflineMode: true,
        );
      }
    }
  }

  Future<void> refreshPosts() async {
    // Force reload from cache first in case new cached data became available
    await loadPosts(
      category: state.selectedCategory,
      searchQuery: state.searchQuery,
    );
  }

  /// Force reload cached posts (useful after comprehensive cache completion)
  Future<void> reloadCachedPosts() async {
    debugPrint('📱 Forum provider: Force reloading cached posts...');
    await loadPosts(
      category: state.selectedCategory,
      searchQuery: state.searchQuery,
    );
  }

  Future<ForumPost> createPost({
    required String title,
    required String content,
    required ForumCategory category,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newPost = await _forumService.createPost(
        title: title,
        content: content,
        category: category,
      );

      // Add the new post to the current list
      final updatedPosts = [newPost, ...state.posts];
      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
        isLoading: false,
        error: null,
      );

      return newPost;
    } catch (e) {
      final errorMessage = 'Failed to create post: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> deletePost(int postId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _forumService.deletePost(postId);

      // Remove the post from the current list
      final updatedPosts = state.posts.where((post) => post.id != postId).toList();
      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to delete post: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<ForumPost> getPost(int postId) async {
    // Check if we're online
    final isOnline = await _isOnline();

    // First, try to load from cache if available
    if (_offlineForumService != null) {
      try {
        final cachedPost = await _offlineForumService!.getCachedIndividualPost(postId);
        if (cachedPost != null) {
          state = state.copyWith(selectedPost: cachedPost);
          // Try to refresh from online in the background if we're online
          if (isOnline) {
            _refreshPostFromOnline(postId);
          }
          return cachedPost;
        }
      } catch (e) {
        // Ignore cache errors, continue with loading
      }
    }

    if (isOnline) {
      // Load from online
      try {
        final post = await _forumService.getPost(postId);

        // Cache the post for offline use
        if (_offlineForumService != null) {
          await _offlineForumService!.cacheIndividualPost(post);
        }

        state = state.copyWith(selectedPost: post);
        return post;
      } catch (e) {
        // If online loading fails and we have cached data, we already returned it above
        // If we don't have cached data, throw the error
        final errorMessage = 'Failed to load post: ${e.toString()}';
        state = state.copyWith(error: errorMessage);

        // Report to global error boundary
        _errorBoundary.reportNetworkError(errorMessage);

        rethrow;
      }
    } else {
      // Offline mode - if we have cached data, we already returned it above
      // If we don't have cached data, throw an error
      throw Exception('Post niet beschikbaar offline - geen lokale gegevens gevonden');
    }
  }

  /// Refresh post from online in the background (used when serving cached post)
  Future<void> _refreshPostFromOnline(int postId) async {
    try {
      final post = await _forumService.getPost(postId);

      // Cache the updated post
      if (_offlineForumService != null) {
        await _offlineForumService!.cacheIndividualPost(post);
      }

      // Update state if we're still showing the same post
      if (state.selectedPost?.id == postId) {
        state = state.copyWith(selectedPost: post);
      }
    } catch (e) {
      // Silently fail background refresh - user already has cached data
    }
  }

  Future<List<ForumComment>> getCommentsPaginated({
    required int postId,
    int limit = 20,
    int offset = 0,
  }) async {
    // Check if we're online
    final isOnline = await _isOnline();

    // First, try to load from cache if available
    if (_offlineForumService != null) {
      try {
        final cachedComments = await _offlineForumService!.getCachedPostComments(
          postId,
          limit: limit,
          offset: offset,
        );
        if (cachedComments != null && cachedComments.isNotEmpty) {
          // Try to refresh from online in the background if we're online
          if (isOnline) {
            _refreshCommentsFromOnline(postId, limit, offset);
          }
          return cachedComments;
        }
      } catch (e) {
        // Ignore cache errors, continue with loading
      }
    }

    if (isOnline) {
      // Load from online
      try {
        final comments = await _forumService.getCommentsPaginated(
          postId: postId,
          limit: limit,
          offset: offset,
        );

        // Cache the comments for offline use (cache all comments, not just the paginated ones)
        if (_offlineForumService != null && offset == 0) {
          try {
            final allComments = await _forumService.getCommentsPaginated(
              postId: postId,
              limit: 1000, // Get a large batch to cache
              offset: 0,
            );
            await _offlineForumService!.cachePostComments(postId, allComments);
          } catch (e) {
            // If we can't get all comments, at least cache what we have
            await _offlineForumService!.cachePostComments(postId, comments);
          }
        }

        return comments;
      } catch (e) {
        // If online loading fails and we have cached data, we already returned it above
        // If we don't have cached data, throw the error
        final errorMessage = 'Failed to load comments: ${e.toString()}';
        state = state.copyWith(error: errorMessage);

        // Report to global error boundary
        _errorBoundary.reportNetworkError(errorMessage);

        rethrow;
      }
    } else {
      // Offline mode - if we have cached data, we already returned it above
      // If we don't have cached data, return empty list (no error, just no comments available offline)
      return [];
    }
  }

  /// Refresh comments from online in the background (used when serving cached comments)
  Future<void> _refreshCommentsFromOnline(int postId, int limit, int offset) async {
    try {
      final comments = await _forumService.getCommentsPaginated(
        postId: postId,
        limit: limit,
        offset: offset,
      );

      // Cache the updated comments
      if (_offlineForumService != null) {
        try {
          final allComments = await _forumService.getCommentsPaginated(
            postId: postId,
            limit: 1000,
            offset: 0,
          );
          await _offlineForumService!.cachePostComments(postId, allComments);
        } catch (e) {
          await _offlineForumService!.cachePostComments(postId, comments);
        }
      }
    } catch (e) {
      // Silently fail background refresh - user already has cached data
    }
  }

  Future<ForumPost> getPostWithComments(int postId) async {
    try {
      final post = await _forumService.getPostWithComments(postId);
      
      state = state.copyWith(selectedPost: post);
      
      return post;
    } catch (e) {
      final errorMessage = 'Failed to load post details: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<ForumComment> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    // Check if we're online
    final isOnline = await _isOnline();

    if (isOnline) {
      // Online mode - try to add comment directly
      try {
        final comment = await _forumService.addComment(
          postId: postId,
          content: content,
          parentCommentId: parentCommentId,
        );

        // If we have the selected post loaded, update its comments
        if (state.selectedPost != null && state.selectedPost!.id == postId) {
          final updatedComments = [...state.selectedPost!.comments, comment];
          final updatedPost = state.selectedPost!.copyWith(
            comments: updatedComments,
            commentCount: updatedComments.length,
          );
          state = state.copyWith(selectedPost: updatedPost);
        }

        // Update the comment count in the posts list
        final updatedPosts = state.posts.map((post) {
          if (post.id == postId) {
            return post.copyWith(commentCount: post.commentCount + 1);
          }
          return post;
        }).toList();

        final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

        state = state.copyWith(
          posts: updatedPosts,
          filteredPosts: filteredPosts,
        );

        return comment;
      } catch (e) {
        final errorMessage = 'Failed to add comment: ${e.toString()}';
        state = state.copyWith(error: errorMessage);

        // Report to global error boundary
        _errorBoundary.reportNetworkError(errorMessage);
        rethrow;
      }
    } else {
      // Offline mode - queue the operation
      if (_offlineQueueService == null) {
        throw Exception('Offline queue service not available');
      }

      // Get current user ID from auth service
      final authService = _ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create a temporary comment for optimistic UI update
      final tempComment = ForumComment(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        postId: postId,
        content: content,
        authorId: userId,
        authorName: authService.currentUser!.userMetadata?['name'] as String? ?? 'Unknown',
        authorAvatar: authService.currentUser!.userMetadata?['avatar_url'] as String?,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        parentCommentId: parentCommentId,
      );

      // Optimistically update UI
      if (state.selectedPost != null && state.selectedPost!.id == postId) {
        final updatedComments = [...state.selectedPost!.comments, tempComment];
        final updatedPost = state.selectedPost!.copyWith(
          comments: updatedComments,
          commentCount: updatedComments.length,
        );
        state = state.copyWith(selectedPost: updatedPost);
      }

      // Update the comment count in the posts list
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return post.copyWith(commentCount: post.commentCount + 1);
        }
        return post;
      }).toList();

      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
      );

      // Queue the operation
      final operation = OfflineOperation(
        id: 'forum_comment_${tempComment.id}',
        type: OfflineOperationType.addForumComment,
        status: OfflineOperationStatus.pending,
        data: {
          'post_id': postId,
          'content': content,
          'parent_comment_id': parentCommentId,
          'temp_comment_id': tempComment.id,
        },
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _offlineQueueService!.addOperation(operation);

      return tempComment;
    }
  }

  Future<ForumPost> togglePinPost(int postId) async {
    try {
      final updatedPost = await _forumService.togglePinPost(postId);

      // Update the post in the current list
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      // Sort posts to put pinned posts at the top
      updatedPosts.sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return b.createdAt.compareTo(a.createdAt);
      });

      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
      );

      return updatedPost;
    } catch (e) {
      final errorMessage = 'Failed to toggle pin status: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<ForumPost> toggleLockPost(int postId) async {
    try {
      final updatedPost = await _forumService.toggleLockPost(postId);

      // Update the post in the current list
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
      );

      // Update selected post if it's the same one
      if (state.selectedPost != null && state.selectedPost!.id == postId) {
        state = state.copyWith(selectedPost: updatedPost);
      }

      return updatedPost;
    } catch (e) {
      final errorMessage = 'Failed to toggle lock status: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> deleteComment(int commentId) async {
    // Check if we're online
    final isOnline = await _isOnline();

    if (isOnline) {
      // Online mode - try to delete comment directly
      try {
        await _forumService.deleteComment(commentId);

        // If we have the selected post loaded, remove the comment from its comments
        if (state.selectedPost != null) {
          final updatedComments = state.selectedPost!.comments
              .where((comment) => comment.id != commentId)
              .toList();
          final updatedPost = state.selectedPost!.copyWith(
            comments: updatedComments,
            commentCount: updatedComments.length,
          );
          state = state.copyWith(selectedPost: updatedPost);

          // Update the comment count in the posts list
          final updatedPosts = state.posts.map((post) {
            if (post.id == state.selectedPost!.id) {
              return post.copyWith(commentCount: updatedComments.length);
            }
            return post;
          }).toList();

          final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

          state = state.copyWith(
            posts: updatedPosts,
            filteredPosts: filteredPosts,
          );
        }
      } catch (e) {
        final errorMessage = 'Failed to delete comment: ${e.toString()}';
        state = state.copyWith(error: errorMessage);

        // Report to global error boundary
        _errorBoundary.reportNetworkError(errorMessage);
        rethrow;
      }
    } else {
      // Offline mode - queue the operation
      if (_offlineQueueService == null) {
        throw Exception('Offline queue service not available');
      }

      // Get current user ID from auth service
      final authService = _ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Optimistically update UI
      if (state.selectedPost != null) {
        final updatedComments = state.selectedPost!.comments
            .where((comment) => comment.id != commentId)
            .toList();
        final updatedPost = state.selectedPost!.copyWith(
          comments: updatedComments,
          commentCount: updatedComments.length,
        );
        state = state.copyWith(selectedPost: updatedPost);

        // Update the comment count in the posts list
        final updatedPosts = state.posts.map((post) {
          if (post.id == state.selectedPost!.id) {
            return post.copyWith(commentCount: updatedComments.length);
          }
          return post;
        }).toList();

        final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

        state = state.copyWith(
          posts: updatedPosts,
          filteredPosts: filteredPosts,
        );
      }

      // Queue the operation
      final operation = OfflineOperation(
        id: 'forum_comment_delete_$commentId',
        type: OfflineOperationType.deleteForumComment,
        status: OfflineOperationStatus.pending,
        data: {
          'comment_id': commentId,
        },
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _offlineQueueService!.addOperation(operation);
    }
  }

  Future<ForumComment> updateComment({
    required int commentId,
    required String content,
  }) async {
    // Check if we're online
    final isOnline = await _isOnline();

    if (isOnline) {
      // Online mode - try to update comment directly
      try {
        final updatedComment = await _forumService.updateComment(
          commentId: commentId,
          content: content,
        );

        // If we have the selected post loaded, update the comment in its comments
        if (state.selectedPost != null) {
          final updatedComments = state.selectedPost!.comments.map((comment) {
            if (comment.id == commentId) {
              return updatedComment;
            }
            return comment;
          }).toList();

          final updatedPost = state.selectedPost!.copyWith(comments: updatedComments);
          state = state.copyWith(selectedPost: updatedPost);
        }

        return updatedComment;
      } catch (e) {
        final errorMessage = 'Failed to update comment: ${e.toString()}';
        state = state.copyWith(error: errorMessage);

        // Report to global error boundary
        _errorBoundary.reportNetworkError(errorMessage);
        rethrow;
      }
    } else {
      // Offline mode - queue the operation
      if (_offlineQueueService == null) {
        throw Exception('Offline queue service not available');
      }

      // Get current user ID from auth service
      final authService = _ref.read(authServiceProvider);
      final userId = authService.currentUser?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Find the existing comment to update
      ForumComment? existingComment;
      if (state.selectedPost != null) {
        existingComment = state.selectedPost!.comments.firstWhere(
          (comment) => comment.id == commentId,
          orElse: () => throw Exception('Comment not found'),
        );
      }

      if (existingComment == null) {
        throw Exception('Comment not found');
      }

      // Create updated comment for optimistic UI update
      final updatedComment = existingComment.copyWith(
        content: content,
        updatedAt: DateTime.now(),
      );

      // Optimistically update UI
      if (state.selectedPost != null) {
        final updatedComments = state.selectedPost!.comments.map((comment) {
          if (comment.id == commentId) {
            return updatedComment;
          }
          return comment;
        }).toList();

        final updatedPost = state.selectedPost!.copyWith(comments: updatedComments);
        state = state.copyWith(selectedPost: updatedPost);
      }

      // Queue the operation
      final operation = OfflineOperation(
        id: 'forum_comment_update_$commentId',
        type: OfflineOperationType.updateForumComment,
        status: OfflineOperationStatus.pending,
        data: {
          'comment_id': commentId,
          'content': content,
        },
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _offlineQueueService!.addOperation(operation);

      return updatedComment;
    }
  }

  Future<ForumPost> updatePost({
    required int postId,
    required String title,
    required String content,
    ForumCategory? category,
  }) async {
    try {
      final updatedPost = await _forumService.updatePost(
        postId: postId,
        title: title,
        content: content,
        category: category,
      );

      // Update the post in the current list
      final updatedPosts = state.posts.map((post) {
        if (post.id == postId) {
          return updatedPost;
        }
        return post;
      }).toList();

      final filteredPosts = _filterPosts(updatedPosts, state.searchQuery, state.selectedCategory);

      state = state.copyWith(
        posts: updatedPosts,
        filteredPosts: filteredPosts,
      );

      // Update selected post if it's the same one
      if (state.selectedPost != null && state.selectedPost!.id == postId) {
        state = state.copyWith(selectedPost: updatedPost);
      }

      return updatedPost;
    } catch (e) {
      final errorMessage = 'Failed to update post: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  void searchPosts(String query) {
    // Store the search query even if posts aren't loaded yet
    state = state.copyWith(searchQuery: query);

    // Only filter if we have posts loaded
    if (state.posts.isNotEmpty) {
      final filteredPosts = _filterPosts(state.posts, query, state.selectedCategory);
      state = state.copyWith(filteredPosts: filteredPosts);
    }
  }

  void filterByCategory(ForumCategory? category) {
    final filteredPosts = _filterPosts(state.posts, state.searchQuery, category);
    state = state.copyWith(
      selectedCategory: category,
      filteredPosts: filteredPosts,
    );
  }

  List<ForumPost> _filterPosts(List<ForumPost> posts, String searchQuery, ForumCategory? category) {
    var filtered = posts;

    // Apply category filter
    if (category != null) {
      filtered = filtered.where((post) => post.category == category).toList();
    }

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final queryLower = searchQuery.toLowerCase();
      filtered = filtered.where((post) {
        final titleMatch = post.title.toLowerCase().contains(queryLower);
        final contentMatch = post.content.toLowerCase().contains(queryLower);
        final authorMatch = post.authorName.toLowerCase().contains(queryLower);
        return titleMatch || contentMatch || authorMatch;
      }).toList();
    }

    // Create a mutable copy before sorting to avoid unmodifiable list error
    final mutableFiltered = List<ForumPost>.from(filtered);

    // Sort: pinned posts first, then by creation date
    mutableFiltered.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return mutableFiltered;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedPost() {
    state = state.copyWith(selectedPost: null);
  }

  // Check if current user is the app host
  Future<bool> isCurrentUserHost() async {
    return await _forumService.isAppHost(); // The service will check the current user
  }
}

// Provider for the ForumNotifier
final forumNotifierProvider = StateNotifierProvider<ForumNotifier, ForumState>((ref) {
  final forumService = ref.watch(forumServiceProvider);
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  final notifier = ForumNotifier(forumService, errorBoundary, ref);

  // Initialize offline services if available (catch errors if not initialized yet)
  try {
    final offlineForumService = ref.watch(offlineForumServiceProvider);
    notifier.initializeOfflineService(offlineForumService);
  } catch (e) {
    // Offline service not available yet, will be initialized later
  }

  try {
    final offlineQueueService = ref.watch(offlineQueueServiceProvider);
    notifier.initializeOfflineQueueService(offlineQueueService);
  } catch (e) {
    // Offline queue service not available yet, will be initialized later
  }

  return notifier;
});

// Convenience providers for specific forum state properties
final forumPostsProvider = Provider<List<ForumPost>>((ref) {
  return ref.watch(forumNotifierProvider).filteredPosts;
});

final forumLoadingProvider = Provider<bool>((ref) {
  return ref.watch(forumNotifierProvider).isLoading;
});

final forumOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(forumNotifierProvider).isOfflineMode;
});

final forumErrorProvider = Provider<String?>((ref) {
  return ref.watch(forumNotifierProvider).error;
});

final forumSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(forumNotifierProvider).searchQuery;
});

final forumSelectedCategoryProvider = Provider<ForumCategory?>((ref) {
  return ref.watch(forumNotifierProvider).selectedCategory;
});

final forumSelectedPostProvider = Provider<ForumPost?>((ref) {
  return ref.watch(forumNotifierProvider).selectedPost;
});

// Provider for forum pending operations count
final forumPendingOperationsProvider = Provider<int>((ref) {
  // This is a simplified version - in a real app you'd want proper stream handling
  // For now, we'll return 0 and let the UI handle the pending operations differently
  return 0;
});

// Family provider for individual post by ID
final forumPostByIdProvider = Provider.family<ForumPost?, int>((ref, postId) {
  final posts = ref.watch(forumNotifierProvider).posts;
  try {
    return posts.firstWhere((post) => post.id == postId);
  } catch (e) {
    return null;
  }
});

// Provider to check if current user is host
final isCurrentUserHostProvider = FutureProvider<bool>((ref) async {
  return await ref.watch(forumNotifierProvider.notifier).isCurrentUserHost();
});
