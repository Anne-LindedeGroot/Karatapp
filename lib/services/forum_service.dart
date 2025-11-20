import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forum_models.dart';

class ForumService {
  final SupabaseClient _client = Supabase.instance.client;

  // Check if user is the app host using the user_roles table
  Future<bool> isAppHost([String? userId]) async {
    try {
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        return false;
      }
      
      final checkUserId = userId ?? currentUser.id;
      
      final response = await _client
          .from('user_roles')
          .select('role')
          .eq('user_id', checkUserId)
          .eq('role', 'host')
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }


  // Grant host role to a user (only existing hosts can do this)
  Future<bool> grantHostRole(String userEmail) async {
    try {
      final result = await _client.rpc('grant_host_role', params: {
        'target_user_email': userEmail,
      });
      return result == true;
    } catch (e) {
      throw Exception('Failed to grant host role: $e');
    }
  }

  // Revoke host role from a user (only existing hosts can do this)
  Future<bool> revokeHostRole(String userEmail) async {
    try {
      final result = await _client.rpc('revoke_host_role', params: {
        'target_user_email': userEmail,
      });
      return result == true;
    } catch (e) {
      throw Exception('Failed to revoke host role: $e');
    }
  }

  // Get all users with their roles
  Future<List<Map<String, dynamic>>> getUsersWithRoles() async {
    try {
      final response = await _client
          .from('user_roles')
          .select('user_id, role, granted_at, auth.users!inner(email)')
          .order('granted_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to load users with roles: $e');
    }
  }

  // Get all forum posts with optional filtering
  Future<List<ForumPost>> getPosts({
    ForumCategory? category,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('forum_posts')
          .select('*');

      // Apply category filter at database level
      if (category != null) {
        query = query.eq('category', category.name);
      }

      // Apply search filter at database level
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,content.ilike.%$searchQuery%,author_name.ilike.%$searchQuery%');
      }

      // Apply ordering and pagination
      final response = await query
          .order('is_pinned', ascending: false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      final posts = List<Map<String, dynamic>>.from(response);
      
      return posts.map((postData) => ForumPost.fromJson(postData)).toList();
    } catch (e) {
      throw Exception('Failed to load forum posts: $e');
    }
  }

  // Get a specific post with its comments
  Future<ForumPost> getPostWithComments(int postId) async {
    try {
      // Get the specific post
      final postResponse = await _client
          .from('forum_posts')
          .select('*')
          .eq('id', postId)
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      // Get comments for this post
      final commentsResponse = await _client
          .from('forum_comments')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: true);

      final postComments = List<Map<String, dynamic>>.from(commentsResponse)
          .map((comment) => ForumComment.fromJson(comment))
          .toList();

      return ForumPost.fromJson(postResponse).copyWith(comments: postComments);
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  // Create a new forum post
  Future<ForumPost> createPost({
    required String title,
    required String content,
    required ForumCategory category,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = user.userMetadata?['avatar_url'] as String?;

      final postData = {
        'title': title,
        'content': content,
        'category': category.name,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_pinned': false,
        'is_locked': false,
      };

      final response = await _client
          .from('forum_posts')
          .insert(postData)
          .select()
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      final responseData = Map<String, dynamic>.from(response);
      responseData['comment_count'] = 0;

      return ForumPost.fromJson(responseData);
    } catch (e) {
      throw Exception('Failed to create post: $e');
    }
  }

  // Update a forum post (only author or host can do this)
  Future<ForumPost> updatePost({
    required int postId,
    required String title,
    required String content,
    ForumCategory? category,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user can edit this post
      final allPosts = await _client
          .from('forum_posts')
          .select('author_id, id');
      
      final posts = List<Map<String, dynamic>>.from(allPosts);
      final existingPostList = posts.where((post) => post['id'] == postId).toList();
      
      if (existingPostList.isEmpty) {
        throw Exception('Post not found');
      }
      
      final existingPost = existingPostList.first;
      final isAuthor = existingPost['author_id'] == user.id;
      final isHost = await isAppHost(user.id);

      if (!isAuthor && !isHost) {
        throw Exception('You do not have permission to edit this post');
      }

      final updateData = {
        'title': title,
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (category != null) {
        updateData['category'] = category.name;
      }

      final response = await _client
          .from('forum_posts')
          .update(updateData)
          .eq('id', postId)
          .select()
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      return ForumPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update post: $e');
    }
  }

  // Delete a forum post (only author or host can do this)
  Future<void> deletePost(int postId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user can delete this post
      final allPosts = await _client
          .from('forum_posts')
          .select('author_id, id');
      
      final posts = List<Map<String, dynamic>>.from(allPosts);
      final existingPostList = posts.where((post) => post['id'] == postId).toList();
      
      if (existingPostList.isEmpty) {
        throw Exception('Post not found');
      }
      
      final existingPost = existingPostList.first;
      final isAuthor = existingPost['author_id'] == user.id;
      final isHost = await isAppHost(user.id);

      if (!isAuthor && !isHost) {
        throw Exception('You do not have permission to delete this post');
      }

      // Delete comments first (due to foreign key constraints)
      await _client
          .from('forum_comments')
          .delete()
          .eq('post_id', postId)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      // Then delete the post
      await _client
          .from('forum_posts')
          .delete()
          .eq('id', postId)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Add a comment to a post
  Future<ForumComment> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }


      // Check if post exists and is not locked (more efficient query)
      final postResponse = await _client
          .from('forum_posts')
          .select('is_locked')
          .eq('id', postId)
          .maybeSingle();
      
      if (postResponse == null) {
        throw Exception('Post not found');
      }
      
      if (postResponse['is_locked'] as bool? ?? false) {
        throw Exception('This post is locked and cannot receive new comments');
      }

      // Get user name from metadata or email, with better fallback
      String userName;
      if (user.userMetadata?['full_name'] != null && user.userMetadata!['full_name'].toString().isNotEmpty) {
        userName = user.userMetadata!['full_name'].toString();
      } else if (user.email != null && user.email!.isNotEmpty) {
        userName = user.email!.split('@')[0]; // Use part before @ as username
      } else {
        userName = 'Anonymous User';
      }

      final userAvatar = user.userMetadata?['avatar_url'] as String?;

      final commentData = {
        'post_id': postId,
        'content': content.trim(),
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
      };

      // Only add parent_comment_id if it's not null
      if (parentCommentId != null) {
        commentData['parent_comment_id'] = parentCommentId;
      }

      final response = await _client
          .from('forum_comments')
          .insert(commentData)
          .select()
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      return ForumComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  // Get a specific post without comments
  Future<ForumPost> getPost(int postId) async {
    try {
      final response = await _client
          .from('forum_posts')
          .select('*')
          .eq('id', postId)
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      return ForumPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  // Get comments for a specific post with pagination
  Future<List<ForumComment>> getCommentsPaginated({
    required int postId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('forum_comments')
          .select('*')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      final comments = List<Map<String, dynamic>>.from(response)
          .map((comment) => ForumComment.fromJson(comment))
          .toList();

      return comments;
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  // Get comments for a specific post (legacy method - loads all)
  Future<List<ForumComment>> getComments(int postId) async {
    try {
      final response = await _client
          .from('forum_comments')
          .select('*')
          .order('created_at', ascending: true);

      final allComments = List<Map<String, dynamic>>.from(response);
      final postComments = allComments
          .where((comment) => comment['post_id'] == postId)
          .map((comment) => ForumComment.fromJson(comment))
          .toList();

      return postComments;
    } catch (e) {
      throw Exception('Failed to load comments: $e');
    }
  }

  // Helper method to recursively get all child comment IDs
  Future<List<int>> _getAllChildCommentIds(int parentCommentId) async {
    final childComments = await _client
        .from('forum_comments')
        .select('id')
        .eq('parent_comment_id', parentCommentId);

    final directChildren = List<Map<String, dynamic>>.from(childComments);
    final allChildIds = <int>[];

    for (final child in directChildren) {
      final childId = child['id'] as int;
      allChildIds.add(childId);
      // Recursively get children of this child
      final grandChildren = await _getAllChildCommentIds(childId);
      allChildIds.addAll(grandChildren);
    }

    return allChildIds;
  }

  // Delete a forum comment (only author, post author, or host can do this)
  Future<void> deleteComment(int commentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the comment and post details to check permissions
      final allComments = await _client
          .from('forum_comments')
          .select('author_id, post_id, id');

      final comments = List<Map<String, dynamic>>.from(allComments);
      final commentList = comments.where((comment) => comment['id'] == commentId).toList();

      if (commentList.isEmpty) {
        throw Exception('Comment not found');
      }

      final comment = commentList.first;
      final isCommentAuthor = comment['author_id'] == user.id;

      // Get the post to check if user is post author
      final allPosts = await _client
          .from('forum_posts')
          .select('author_id, id');

      final posts = List<Map<String, dynamic>>.from(allPosts);
      final postList = posts.where((post) => post['id'] == comment['post_id']).toList();

      final isPostAuthor = postList.isNotEmpty && postList.first['author_id'] == user.id;
      final isHost = await isAppHost(user.id);

      if (!isCommentAuthor && !isPostAuthor && !isHost) {
        throw Exception('You do not have permission to delete this comment');
      }

      // Get all child comment IDs recursively
      final childCommentIds = await _getAllChildCommentIds(commentId);

      // Delete all child comments first (in reverse order to handle dependencies)
      for (final childId in childCommentIds.reversed) {
        await _client
            .from('forum_comments')
            .delete()
            .eq('id', childId)
            .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));
      }

      // Finally delete the parent comment
      await _client
          .from('forum_comments')
          .delete()
          .eq('id', commentId)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Update a forum comment (only author can do this)
  Future<ForumComment> updateComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user can edit this comment (only comment author)
      final allComments = await _client
          .from('forum_comments')
          .select('author_id, id');
      
      final comments = List<Map<String, dynamic>>.from(allComments);
      final existingCommentList = comments.where((comment) => comment['id'] == commentId).toList();
      
      if (existingCommentList.isEmpty) {
        throw Exception('Comment not found');
      }
      
      final existingComment = existingCommentList.first;
      final isAuthor = existingComment['author_id'] == user.id;

      if (!isAuthor) {
        throw Exception('You can only edit your own comments');
      }

      final updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('forum_comments')
          .update(updateData)
          .eq('id', commentId)
          .select()
          .single()
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      return ForumComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  // Pin/unpin a post (only host can do this)
  Future<ForumPost> togglePinPost(int postId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!(await isAppHost(user.id))) {
        throw Exception('Only the app host can pin/unpin posts');
      }

      // Get current pin status
      final allPosts = await _client
          .from('forum_posts')
          .select('is_pinned, id');
      
      final posts = List<Map<String, dynamic>>.from(allPosts);
      final currentPostList = posts.where((post) => post['id'] == postId).toList();
      
      if (currentPostList.isEmpty) {
        throw Exception('Post not found');
      }
      
      final currentPost = currentPostList.first;
      final newPinStatus = !(currentPost['is_pinned'] as bool? ?? false);

      final response = await _client
          .from('forum_posts')
          .update({
            'is_pinned': newPinStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId)
          .select()
          .single();

      return ForumPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle pin status: $e');
    }
  }

  // Lock/unlock a post (only host can do this)
  Future<ForumPost> toggleLockPost(int postId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      if (!(await isAppHost(user.id))) {
        throw Exception('Only the app host can lock/unlock posts');
      }

      // Get current lock status
      final allPosts = await _client
          .from('forum_posts')
          .select('is_locked, id');
      
      final posts = List<Map<String, dynamic>>.from(allPosts);
      final currentPostList = posts.where((post) => post['id'] == postId).toList();
      
      if (currentPostList.isEmpty) {
        throw Exception('Post not found');
      }
      
      final currentPost = currentPostList.first;
      final newLockStatus = !(currentPost['is_locked'] as bool? ?? false);

      final response = await _client
          .from('forum_posts')
          .update({
            'is_locked': newLockStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', postId)
          .select()
          .single();

      return ForumPost.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle lock status: $e');
    }
  }
}
