import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interaction_models.dart';
import 'role_service.dart';

class InteractionService {
  final SupabaseClient _client = Supabase.instance.client;
  final RoleService _roleService = RoleService();

  // KATA COMMENTS
  
  // Get comments for a specific kata
  Future<List<KataComment>> getKataComments(int kataId) async {
    try {
      final response = await _client
          .from('kata_comments')
          .select('*')
          .eq('kata_id', kataId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((comment) => KataComment.fromJson(comment))
          .toList();
    } catch (e) {
      throw Exception('Failed to load kata comments: $e');
    }
  }

  // Add a comment to a kata
  Future<KataComment> addKataComment({
    required int kataId,
    required String content,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = user.userMetadata?['avatar_url'] as String?;

      final commentData = {
        'kata_id': kataId,
        'content': content,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('kata_comments')
          .insert(commentData)
          .select()
          .single();

      return KataComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add kata comment: $e');
    }
  }

  // Update a kata comment (author, mediator, or host can do this)
  Future<KataComment> updateKataComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get comment details and check permissions
      final existingComment = await _client
          .from('kata_comments')
          .select('author_id, kata_id')
          .eq('id', commentId)
          .single();

      // Check if user is the comment author
      bool canEdit = existingComment['author_id'] == user.id;

      // If not the author, check if user is a mediator or host using RoleService
      if (!canEdit) {
        try {
          final userRole = await _roleService.getCurrentUserRole();
          canEdit = userRole == UserRole.mediator || userRole == UserRole.host;
        } catch (e) {
          // If role check fails, fall back to author-only permission
          canEdit = false;
        }
      }

      if (!canEdit) {
        throw Exception('You do not have permission to edit this comment');
      }

      final response = await _client
          .from('kata_comments')
          .update({
            'content': content,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId)
          .select()
          .single();

      return KataComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update kata comment: $e');
    }
  }

  // Delete a kata comment (author, mediator, or host can do this)
  Future<void> deleteKataComment(int commentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get comment details and check permissions
      final existingComment = await _client
          .from('kata_comments')
          .select('author_id, kata_id')
          .eq('id', commentId)
          .single();

      // Check if user is the comment author
      bool canDelete = existingComment['author_id'] == user.id;

      // If not the author, check if user is a mediator or host using RoleService
      if (!canDelete) {
        try {
          final userRole = await _roleService.getCurrentUserRole();
          canDelete = userRole == UserRole.mediator || userRole == UserRole.host;
        } catch (e) {
          // If role check fails, fall back to author-only permission
          canDelete = false;
        }
      }

      if (!canDelete) {
        throw Exception('You do not have permission to delete this comment');
      }

      await _client
          .from('kata_comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete kata comment: $e');
    }
  }

  // LIKES

  // Get likes for a kata
  Future<List<Like>> getKataLikes(int kataId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load kata likes: $e');
    }
  }

  // Get likes for a forum post
  Future<List<Like>> getForumPostLikes(int forumPostId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load forum post likes: $e');
    }
  }

  // Toggle like for a kata
  Future<bool> toggleKataLike(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already liked this kata
      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike - remove the like
        await _client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);
        return false; // Not liked anymore
      } else {
        // Like - add the like
        await _client
            .from('likes')
            .insert({
              'user_id': user.id,
              'target_type': 'kata',
              'target_id': kataId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now liked
      }
    } catch (e) {
      throw Exception('Failed to toggle kata like: $e');
    }
  }

  // Toggle like for a forum post
  Future<bool> toggleForumPostLike(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already liked this forum post
      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike - remove the like
        await _client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);
        return false; // Not liked anymore
      } else {
        // Like - add the like
        await _client
            .from('likes')
            .insert({
              'user_id': user.id,
              'target_type': 'forum_post',
              'target_id': forumPostId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now liked
      }
    } catch (e) {
      throw Exception('Failed to toggle forum post like: $e');
    }
  }

  // Check if user liked a kata
  Future<bool> isKataLiked(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // Check if user liked a forum post
  Future<bool> isForumPostLiked(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // FAVORITES

  // Get favorites for a kata
  Future<List<Favorite>> getKataFavorites(int kataId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load kata favorites: $e');
    }
  }

  // Get favorites for a forum post
  Future<List<Favorite>> getForumPostFavorites(int forumPostId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load forum post favorites: $e');
    }
  }

  // Toggle favorite for a kata
  Future<bool> toggleKataFavorite(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already favorited this kata
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite - remove the favorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false; // Not favorited anymore
      } else {
        // Favorite - add the favorite
        await _client
            .from('favorites')
            .insert({
              'user_id': user.id,
              'target_type': 'kata',
              'target_id': kataId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now favorited
      }
    } catch (e) {
      throw Exception('Failed to toggle kata favorite: $e');
    }
  }

  // Toggle favorite for a forum post
  Future<bool> toggleForumPostFavorite(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already favorited this forum post
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite - remove the favorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false; // Not favorited anymore
      } else {
        // Favorite - add the favorite
        await _client
            .from('favorites')
            .insert({
              'user_id': user.id,
              'target_type': 'forum_post',
              'target_id': forumPostId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now favorited
      }
    } catch (e) {
      throw Exception('Failed to toggle forum post favorite: $e');
    }
  }

  // Check if user favorited a kata
  Future<bool> isKataFavorited(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingFavorite != null;
    } catch (e) {
      return false;
    }
  }

  // Check if user favorited a forum post
  Future<bool> isForumPostFavorited(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingFavorite != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's favorite katas
  Future<List<int>> getUserFavoriteKatas() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'kata');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get user's favorite forum posts
  Future<List<int>> getUserFavoriteForumPosts() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'forum_post');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // OHYO COMMENTS

  // Get comments for a specific ohyo
  Future<List<OhyoComment>> getOhyoComments(int ohyoId) async {
    try {
      final response = await _client
          .from('ohyo_comments')
          .select('*')
          .eq('ohyo_id', ohyoId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((comment) => OhyoComment.fromJson(comment))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ohyo comments: $e');
    }
  }

  // Add a comment to an ohyo
  Future<OhyoComment> addOhyoComment({
    required int ohyoId,
    required String content,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = user.userMetadata?['avatar_url'] as String?;

      final commentData = {
        'ohyo_id': ohyoId,
        'content': content,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('ohyo_comments')
          .insert(commentData)
          .select()
          .single();

      return OhyoComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add ohyo comment: $e');
    }
  }

  // Update an ohyo comment
  Future<OhyoComment> updateOhyoComment({
    required int commentId,
    required String content,
  }) async {
    try {
      final updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('ohyo_comments')
          .update(updateData)
          .eq('id', commentId)
          .select()
          .single();

      return OhyoComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ohyo comment: $e');
    }
  }

  // Delete an ohyo comment
  Future<void> deleteOhyoComment(int commentId) async {
    try {
      await _client
          .from('ohyo_comments')
          .delete()
          .eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete ohyo comment: $e');
    }
  }

  // OHYO LIKES

  // Get likes for a specific ohyo
  Future<List<Like>> getOhyoLikes(int ohyoId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ohyo likes: $e');
    }
  }

  // Check if current user liked an ohyo
  Future<bool> isOhyoLiked(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle like on an ohyo
  Future<bool> toggleOhyoLike(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already liked
      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);
        return false;
      } else {
        // Like
        final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
        final likeData = {
          'user_id': user.id,
          'user_name': userName,
          'target_type': 'ohyo',
          'target_id': ohyoId,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _client
            .from('likes')
            .insert(likeData);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle ohyo like: $e');
    }
  }

  // OHYO FAVORITES

  // Get favorites for a specific ohyo
  Future<List<Favorite>> getOhyoFavorites(int ohyoId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ohyo favorites: $e');
    }
  }

  // Check if current user favorited an ohyo
  Future<bool> isOhyoFavorited(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite on an ohyo
  Future<bool> toggleOhyoFavorite(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favorited
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false;
      } else {
        // Favorite
        final favoriteData = {
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': ohyoId,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _client
            .from('favorites')
            .insert(favoriteData);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle ohyo favorite: $e');
    }
  }

  // Get user's favorite ohyos
  Future<List<int>> getUserFavoriteOhyos() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
