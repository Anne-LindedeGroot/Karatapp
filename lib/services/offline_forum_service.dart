import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/forum_models.dart';

class OfflineForumService {
  static const String _forumPostsKey = 'cached_forum_posts';
  static const String _lastUpdatedKey = 'forum_posts_last_updated';
  static const String _individualPostsKey = 'cached_individual_posts';
  static const String _postCommentsKey = 'cached_post_comments';
  static const Duration _cacheValidityDuration = Duration(hours: 24); // Cache for 24 hours

  final SharedPreferences _prefs;

  OfflineForumService(this._prefs);

  /// Cache forum posts locally
  Future<void> cacheForumPosts(List<ForumPost> posts) async {
    try {
      final postMaps = posts.map((post) => post.toJson()).toList();
      final jsonString = jsonEncode(postMaps);
      await _prefs.setString(_forumPostsKey, jsonString);
      await _prefs.setString(_lastUpdatedKey, DateTime.now().toIso8601String());
    } catch (e) {
      throw Exception('Failed to cache forum posts: $e');
    }
  }

  /// Get cached forum posts
  Future<List<ForumPost>?> getCachedForumPosts() async {
    try {
      final jsonString = _prefs.getString(_forumPostsKey);
      if (jsonString == null) return null;

      final postMaps = jsonDecode(jsonString) as List<dynamic>;
      return postMaps.map((map) => ForumPost.fromJson(map as Map<String, dynamic>)).toList();
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

  /// Clear all cached forum data (posts list, individual posts, and comments)
  Future<void> clearCache() async {
    await _prefs.remove(_forumPostsKey);
    await _prefs.remove(_lastUpdatedKey);
    await _prefs.remove(_individualPostsKey);
    await _prefs.remove(_postCommentsKey);
  }

  /// Get cached forum posts if valid, otherwise return null
  Future<List<ForumPost>?> getValidCachedForumPosts() async {
    if (!isCacheValid()) {
      await clearCache(); // Clear expired cache
      return null;
    }
    return getCachedForumPosts();
  }

  /// Cache an individual forum post
  Future<void> cacheIndividualPost(ForumPost post) async {
    try {
      final individualPosts = await getCachedIndividualPosts() ?? {};
      individualPosts[post.id.toString()] = {
        'post': post.toJson(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(individualPosts);
      await _prefs.setString(_individualPostsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache individual post: $e');
    }
  }

  /// Get cached individual posts
  Future<Map<String, dynamic>?> getCachedIndividualPosts() async {
    try {
      final jsonString = _prefs.getString(_individualPostsKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get a cached individual post by ID
  Future<ForumPost?> getCachedIndividualPost(int postId, {bool allowExpired = false}) async {
    try {
      final individualPosts = await getCachedIndividualPosts();
      if (individualPosts == null) return null;

      final postData = individualPosts[postId.toString()];
      if (postData == null) return null;

      final cachedAt = DateTime.parse(postData['cached_at']);
      final now = DateTime.now();
      final difference = now.difference(cachedAt);

      // Check if individual post cache is still valid
      if (!allowExpired && difference >= _cacheValidityDuration) {
        return null; // Cache expired
      }

      return ForumPost.fromJson(postData['post']);
    } catch (e) {
      return null;
    }
  }

  /// Cache comments for a specific post
  Future<void> cachePostComments(int postId, List<ForumComment> comments) async {
    try {
      final allPostComments = await _getCachedPostCommentsMap() ?? {};
      allPostComments[postId.toString()] = {
        'comments': comments.map((comment) => comment.toJson()).toList(),
        'cached_at': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(allPostComments);
      await _prefs.setString(_postCommentsKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache post comments: $e');
    }
  }

  /// Get cached post comments map (internal method)
  Future<Map<String, dynamic>?> _getCachedPostCommentsMap() async {
    try {
      final jsonString = _prefs.getString(_postCommentsKey);
      if (jsonString == null) return null;

      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get cached comments for a specific post
  Future<List<ForumComment>?> getCachedPostComments(int postId, {int? limit, int? offset, bool allowExpired = false}) async {
    try {
      final allPostComments = await _getCachedPostCommentsMap();
      if (allPostComments == null) return null;

      final postCommentsData = allPostComments[postId.toString()];
      if (postCommentsData == null) return null;

      final cachedAt = DateTime.parse(postCommentsData['cached_at']);
      final now = DateTime.now();
      final difference = now.difference(cachedAt);

      // Check if comments cache is still valid
      if (!allowExpired && difference >= _cacheValidityDuration) {
        return null; // Cache expired
      }

      final comments = (postCommentsData['comments'] as List<dynamic>)
          .map((commentJson) => ForumComment.fromJson(commentJson))
          .toList();

      // Apply pagination if specified
      if (offset != null || limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = limit != null ? startIndex + limit : comments.length;
        return comments.sublist(
          startIndex.clamp(0, comments.length),
          endIndex.clamp(0, comments.length),
        );
      }

      return comments;
    } catch (e) {
      return null;
    }
  }
}
