import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/forum_models.dart';

class ForumService {
  final SupabaseClient _client = Supabase.instance.client;
  static const List<String> _forumImagesBucketCandidates = [
    'FORUM_IMAGES',
    'forum_images',
  ];
  static const List<String> _forumFilesBucketCandidates = [
    'FORUM_FILES',
    'forum_files',
  ];
  static const int _signedUrlExpirySeconds = 31536000; // 1 year
  String? _resolvedForumImagesBucket;
  String? _resolvedForumFilesBucket;

  // Helper function to get user avatar from metadata
  // Returns avatar URL for custom avatars, or avatar ID for preset avatars
  String? _getUserAvatarFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    
    final avatarType = metadata['avatar_type'] as String?;
    
    // For custom avatars, return the URL
    if (avatarType == 'custom') {
      return metadata['avatar_url'] as String?;
    }
    
    // For preset avatars, return the ID (check both avatar_id and preset_avatar_id for compatibility)
    if (avatarType == 'preset' || avatarType == null) {
      return metadata['avatar_id'] as String? ?? 
             metadata['preset_avatar_id'] as String?;
    }
    
    // Fallback: check if avatar_url exists (for backward compatibility)
    return metadata['avatar_url'] as String?;
  }

  Future<String> _resolveForumImagesBucket() async {
    if (_resolvedForumImagesBucket != null) {
      return _resolvedForumImagesBucket!;
    }
    for (final bucket in _forumImagesBucketCandidates) {
      try {
        await _client.storage.getBucket(bucket);
        _resolvedForumImagesBucket = bucket;
        return bucket;
      } catch (_) {}
    }
    throw Exception(
      'Storage bucket for forum images not found or not accessible.',
    );
  }

  Future<String?> _tryResolveForumImagesBucket() async {
    try {
      return await _resolveForumImagesBucket();
    } catch (_) {
      return null;
    }
  }

  String _getFileExtension(File file) {
    final path = file.path;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }

  String? _extractStoragePathFromUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        return null;
      }
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  String? _extractBucketFromUrl(String url) {
    try {
      final segments = Uri.parse(url).pathSegments;
      final publicIndex = segments.indexOf('public');
      if (publicIndex != -1 && publicIndex + 1 < segments.length) {
        return segments[publicIndex + 1];
      }
      final signIndex = segments.indexOf('sign');
      if (signIndex != -1 && signIndex + 1 < segments.length) {
        return segments[signIndex + 1];
      }
    } catch (_) {}
    return null;
  }

  Future<String> _maybeSignUrl(String url, String bucket) async {
    final isHttpUrl = url.startsWith('http://') || url.startsWith('https://');
    if (!isHttpUrl) {
      try {
        return await _client.storage.from(bucket).createSignedUrl(
              url,
              _signedUrlExpirySeconds,
            );
      } catch (_) {
        return url;
      }
    }
    if (!url.contains('/storage/v1/object/')) {
      return url;
    }

    final resolvedBucket = _extractBucketFromUrl(url) ?? bucket;
    final path = _extractStoragePathFromUrl(url, resolvedBucket);
    if (path == null || path.isEmpty) return url;
    try {
      return await _client.storage.from(resolvedBucket).createSignedUrl(
            path,
            _signedUrlExpirySeconds,
          );
    } catch (_) {
      return url;
    }
  }

  Future<List<String>> _ensureSignedUrls(List<String> urls, String bucket) async {
    if (urls.isEmpty) return urls;
    return Future.wait(urls.map((url) => _maybeSignUrl(url, bucket)));
  }

  Future<List<String>> _uploadForumImages({
    required String folder,
    required String prefix,
    required int id,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.isEmpty) return [];
    final bucket = await _resolveForumImagesBucket();

    final uploadedUrls = <String>[];
    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (!await file.exists()) continue;
      final extension = _getFileExtension(file);
      final fileName =
          '${prefix}_${id}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      final filePath = '$folder/$fileName';
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;

      await _client.storage.from(bucket).uploadBinary(filePath, bytes);
      String url;
      try {
        url = await _client.storage
            .from(bucket)
            .createSignedUrl(filePath, _signedUrlExpirySeconds);
      } catch (_) {
        url = _client.storage.from(bucket).getPublicUrl(filePath);
      }
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<void> _deleteForumImages(List<String> urls) async {
    if (urls.isEmpty) return;
    final bucket = await _resolveForumImagesBucket();
    final paths = urls
        .map((url) => _extractStoragePathFromUrl(url, bucket))
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup only
    }
  }

  Future<String> _resolveForumFilesBucket() async {
    if (_resolvedForumFilesBucket != null) {
      return _resolvedForumFilesBucket!;
    }
    for (final bucket in _forumFilesBucketCandidates) {
      try {
        await _client.storage.getBucket(bucket);
        _resolvedForumFilesBucket = bucket;
        return bucket;
      } catch (_) {}
    }
    throw Exception(
      'Storage bucket for forum files not found or not accessible.',
    );
  }

  Future<String?> _tryResolveForumFilesBucket() async {
    try {
      return await _resolveForumFilesBucket();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _uploadForumFiles({
    required String folder,
    required String prefix,
    required int id,
    required List<File> files,
  }) async {
    if (files.isEmpty) return [];
    final bucket = await _resolveForumFilesBucket();

    final uploadedUrls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (!await file.exists()) continue;
      final extension = _getFileExtension(file);
      final fileName =
          '${prefix}_${id}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      final filePath = '$folder/$fileName';
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;

      await _client.storage.from(bucket).uploadBinary(filePath, bytes);
      String url;
      try {
        url = await _client.storage
            .from(bucket)
            .createSignedUrl(filePath, _signedUrlExpirySeconds);
      } catch (_) {
        url = _client.storage.from(bucket).getPublicUrl(filePath);
      }
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<void> _deleteForumFiles(List<String> urls) async {
    if (urls.isEmpty) return;
    final bucket = await _resolveForumFilesBucket();
    final paths = urls
        .map((url) => _extractStoragePathFromUrl(url, bucket))
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup only
    }
  }

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

      final imagesBucket = await _tryResolveForumImagesBucket();
      final filesBucket = await _tryResolveForumFilesBucket();
      final mappedPosts = await Future.wait(posts.map((postData) async {
        final post = ForumPost.fromJson(postData);
        final imageUrls = imagesBucket == null
            ? post.imageUrls
            : await _ensureSignedUrls(post.imageUrls, imagesBucket);
        final fileUrls = filesBucket == null
            ? post.fileUrls
            : await _ensureSignedUrls(post.fileUrls, filesBucket);
        return post.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
      }));

      return mappedPosts;
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

      final imagesBucket = await _tryResolveForumImagesBucket();
      final filesBucket = await _tryResolveForumFilesBucket();
      final postComments = await Future.wait(
        List<Map<String, dynamic>>.from(commentsResponse).map((comment) async {
          final parsed = ForumComment.fromJson(comment);
          final imageUrls = imagesBucket == null
              ? parsed.imageUrls
              : await _ensureSignedUrls(parsed.imageUrls, imagesBucket);
          final fileUrls = filesBucket == null
              ? parsed.fileUrls
              : await _ensureSignedUrls(parsed.fileUrls, filesBucket);
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

      final post = ForumPost.fromJson(postResponse);
      final postImageUrls = imagesBucket == null
          ? post.imageUrls
          : await _ensureSignedUrls(post.imageUrls, imagesBucket);
      final postFileUrls = filesBucket == null
          ? post.fileUrls
          : await _ensureSignedUrls(post.fileUrls, filesBucket);

      return post.copyWith(
        comments: postComments,
        imageUrls: postImageUrls,
        fileUrls: postFileUrls,
      );
    } catch (e) {
      throw Exception('Failed to load post: $e');
    }
  }

  // Create a new forum post
  Future<ForumPost> createPost({
    required String title,
    required String content,
    required ForumCategory category,
    List<String> imageUrls = const [],
    List<String> fileUrls = const [],
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = _getUserAvatarFromMetadata(user.userMetadata);

      final postData = {
        'title': title,
        'content': content,
        'category': category.name,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
        if (fileUrls.isNotEmpty) 'file_urls': fileUrls,
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

  Future<List<String>> uploadForumPostImages({
    required int postId,
    required List<File> imageFiles,
  }) async {
    return _uploadForumImages(
      folder: 'posts/$postId',
      prefix: 'post',
      id: postId,
      imageFiles: imageFiles,
    );
  }

  Future<List<String>> uploadForumPostFiles({
    required int postId,
    required List<File> files,
  }) async {
    return _uploadForumFiles(
      folder: 'posts/$postId',
      prefix: 'post',
      id: postId,
      files: files,
    );
  }

  Future<List<String>> uploadForumCommentImages({
    required int commentId,
    required List<File> imageFiles,
  }) async {
    return _uploadForumImages(
      folder: 'comments/$commentId',
      prefix: 'comment',
      id: commentId,
      imageFiles: imageFiles,
    );
  }

  Future<List<String>> uploadForumCommentFiles({
    required int commentId,
    required List<File> files,
  }) async {
    return _uploadForumFiles(
      folder: 'comments/$commentId',
      prefix: 'comment',
      id: commentId,
      files: files,
    );
  }

  Future<ForumPost> updatePostImages({
    required int postId,
    required List<String> imageUrls,
  }) async {
    final response = await _client
        .from('forum_posts')
        .update({
          'image_urls': imageUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select()
        .single();
    return ForumPost.fromJson(response);
  }

  Future<ForumPost> updatePostFiles({
    required int postId,
    required List<String> fileUrls,
  }) async {
    final response = await _client
        .from('forum_posts')
        .update({
          'file_urls': fileUrls,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', postId)
        .select()
        .single();
    return ForumPost.fromJson(response);
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

      // Best-effort: collect image URLs for post + comments before delete
      final postMediaResponse = await _client
          .from('forum_posts')
          .select('image_urls, file_urls')
          .eq('id', postId)
          .maybeSingle();
      final postImageUrls =
          (postMediaResponse?['image_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];
      final postFileUrls =
          (postMediaResponse?['file_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

      final commentMediaResponse = await _client
          .from('forum_comments')
          .select('image_urls, file_urls')
          .eq('post_id', postId);
      final commentImageUrls = List<Map<String, dynamic>>.from(commentMediaResponse)
          .expand((row) => (row['image_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              const <String>[])
          .toList();
      final commentFileUrls = List<Map<String, dynamic>>.from(commentMediaResponse)
          .expand((row) => (row['file_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
              const <String>[])
          .toList();

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

      // Clean up images after deleting the records
      await _deleteForumImages([...postImageUrls, ...commentImageUrls]);
      await _deleteForumFiles([...postFileUrls, ...commentFileUrls]);
    } catch (e) {
      throw Exception('Failed to delete post: $e');
    }
  }

  // Add a comment to a post
  Future<ForumComment> addComment({
    required int postId,
    required String content,
    int? parentCommentId,
    List<String> imageUrls = const [],
    List<String> fileUrls = const [],
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

      final userAvatar = _getUserAvatarFromMetadata(user.userMetadata);

      final commentData = {
        'post_id': postId,
        'content': content.trim(),
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
        if (fileUrls.isNotEmpty) 'file_urls': fileUrls,
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

      final imagesBucket = await _tryResolveForumImagesBucket();
      final filesBucket = await _tryResolveForumFilesBucket();
      final comments = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((comment) async {
          final parsed = ForumComment.fromJson(comment);
          final imageUrls = imagesBucket == null
              ? parsed.imageUrls
              : await _ensureSignedUrls(parsed.imageUrls, imagesBucket);
          final fileUrls = filesBucket == null
              ? parsed.fileUrls
              : await _ensureSignedUrls(parsed.fileUrls, filesBucket);
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

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
      final imagesBucket = await _tryResolveForumImagesBucket();
      final filesBucket = await _tryResolveForumFilesBucket();
      final postComments = await Future.wait(
        allComments
            .where((comment) => comment['post_id'] == postId)
            .map((comment) async {
          final parsed = ForumComment.fromJson(comment);
          final imageUrls = imagesBucket == null
              ? parsed.imageUrls
              : await _ensureSignedUrls(parsed.imageUrls, imagesBucket);
          final fileUrls = filesBucket == null
              ? parsed.fileUrls
              : await _ensureSignedUrls(parsed.fileUrls, filesBucket);
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

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
          .select('author_id, post_id, id, image_urls, file_urls');

      final comments = List<Map<String, dynamic>>.from(allComments);
      final commentList = comments.where((comment) => comment['id'] == commentId).toList();

      if (commentList.isEmpty) {
        throw Exception('Comment not found');
      }

      final comment = commentList.first;
      final isCommentAuthor = comment['author_id'] == user.id;
      final commentImageUrls =
          (comment['image_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];
      final commentFileUrls =
          (comment['file_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              <String>[];

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

      // Clean up images after deleting
      await _deleteForumImages(commentImageUrls);
      await _deleteForumFiles(commentFileUrls);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // Update a forum comment (only author can do this)
  Future<ForumComment> updateComment({
    required int commentId,
    required String content,
    List<String>? imageUrls,
    List<String>? fileUrls,
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

      final Map<String, dynamic> updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      if (fileUrls != null) {
        updateData['file_urls'] = fileUrls;
      }

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
