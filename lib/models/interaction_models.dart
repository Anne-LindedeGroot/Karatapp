
// Model for kata comments (separate from forum comments)
class KataComment {
  final int id;
  final int kataId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;

  const KataComment({
    required this.id,
    required this.kataId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory KataComment.fromJson(Map<String, dynamic> json) {
    return KataComment(
      id: json['id'] as int,
      kataId: json['kata_id'] as int,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kata_id': kataId,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Model for likes (can be used for both katas and forum posts)
class Like {
  final int id;
  final String userId;
  final String userName;
  final int? kataId;
  final int? forumPostId;
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.userId,
    required this.userName,
    this.kataId,
    this.forumPostId,
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    // Handle both old format (kata_id/forum_post_id) and new format (target_type/target_id)
    int? kataId;
    int? forumPostId;
    
    if (json.containsKey('target_type') && json.containsKey('target_id')) {
      // New format using target_type and target_id
      final targetType = json['target_type'] as String?;
      final targetId = json['target_id'] as int?;
      
      if (targetType == 'kata') {
        kataId = targetId;
      } else if (targetType == 'forum_post') {
        forumPostId = targetId;
      }
    } else {
      // Old format using direct kata_id/forum_post_id
      kataId = json['kata_id'] as int?;
      forumPostId = json['forum_post_id'] as int?;
    }

    return Like(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown User',
      kataId: kataId,
      forumPostId: forumPostId,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'kata_id': kataId,
      'forum_post_id': forumPostId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Model for favorites (can be used for both katas and forum posts)
class Favorite {
  final int id;
  final String userId;
  final int? kataId;
  final int? forumPostId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    this.kataId,
    this.forumPostId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    // Handle both old format (kata_id/forum_post_id) and new format (target_type/target_id)
    int? kataId;
    int? forumPostId;
    
    if (json.containsKey('target_type') && json.containsKey('target_id')) {
      // New format using target_type and target_id
      final targetType = json['target_type'] as String?;
      final targetId = json['target_id'] as int?;
      
      if (targetType == 'kata') {
        kataId = targetId;
      } else if (targetType == 'forum_post') {
        forumPostId = targetId;
      }
    } else {
      // Old format using direct kata_id/forum_post_id
      kataId = json['kata_id'] as int?;
      forumPostId = json['forum_post_id'] as int?;
    }

    return Favorite(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      kataId: kataId,
      forumPostId: forumPostId,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kata_id': kataId,
      'forum_post_id': forumPostId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// State models for managing interactions
class KataInteractionState {
  final List<KataComment> comments;
  final List<Like> likes;
  final List<Favorite> favorites;
  final bool isLoading;
  final String? error;
  final bool isLiked;
  final bool isFavorited;
  final int likeCount;
  final int commentCount;

  const KataInteractionState({
    this.comments = const [],
    this.likes = const [],
    this.favorites = const [],
    this.isLoading = false,
    this.error,
    this.isLiked = false,
    this.isFavorited = false,
    this.likeCount = 0,
    this.commentCount = 0,
  });

  KataInteractionState copyWith({
    List<KataComment>? comments,
    List<Like>? likes,
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
    bool? isLiked,
    bool? isFavorited,
    int? likeCount,
    int? commentCount,
  }) {
    return KataInteractionState(
      comments: comments ?? this.comments,
      likes: likes ?? this.likes,
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
    );
  }
}

class ForumInteractionState {
  final List<Like> likes;
  final List<Favorite> favorites;
  final bool isLoading;
  final String? error;
  final bool isLiked;
  final bool isFavorited;
  final int likeCount;

  const ForumInteractionState({
    this.likes = const [],
    this.favorites = const [],
    this.isLoading = false,
    this.error,
    this.isLiked = false,
    this.isFavorited = false,
    this.likeCount = 0,
  });

  ForumInteractionState copyWith({
    List<Like>? likes,
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
    bool? isLiked,
    bool? isFavorited,
    int? likeCount,
  }) {
    return ForumInteractionState(
      likes: likes ?? this.likes,
      favorites: favorites ?? this.favorites,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLiked: isLiked ?? this.isLiked,
      isFavorited: isFavorited ?? this.isFavorited,
      likeCount: likeCount ?? this.likeCount,
    );
  }
}
