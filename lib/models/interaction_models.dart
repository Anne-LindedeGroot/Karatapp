
// Model for ohyo comments
class OhyoComment {
  final int id;
  final int ohyoId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? parentCommentId; // For nested replies
  final int version; // For conflict resolution
  final bool hasConflict; // Indicates if this comment has unresolved conflicts
  final String? conflictReason; // Reason for conflict (e.g., "concurrent_edit", "deleted_by_another_user")

  const OhyoComment({
    required this.id,
    required this.ohyoId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
    this.version = 1,
    this.hasConflict = false,
    this.conflictReason,
  });

  factory OhyoComment.fromJson(Map<String, dynamic> json) {
    return OhyoComment(
      id: json['id'] as int,
      ohyoId: json['ohyo_id'] as int,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      parentCommentId: json['parent_comment_id'] as int?,
      version: json['version'] as int? ?? 1,
      hasConflict: json['has_conflict'] as bool? ?? false,
      conflictReason: json['conflict_reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ohyo_id': ohyoId,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent_comment_id': parentCommentId,
      'version': version,
      'has_conflict': hasConflict,
      'conflict_reason': conflictReason,
    };
  }
}

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
  final int? parentCommentId; // For nested replies
  final int version; // For conflict resolution
  final bool hasConflict; // Indicates if this comment has unresolved conflicts
  final String? conflictReason; // Reason for conflict (e.g., "concurrent_edit", "deleted_by_another_user")

  const KataComment({
    required this.id,
    required this.kataId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
    this.version = 1,
    this.hasConflict = false,
    this.conflictReason,
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
      parentCommentId: json['parent_comment_id'] as int?,
      version: json['version'] as int? ?? 1,
      hasConflict: json['has_conflict'] as bool? ?? false,
      conflictReason: json['conflict_reason'] as String?,
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
      'parent_comment_id': parentCommentId,
      'version': version,
      'has_conflict': hasConflict,
      'conflict_reason': conflictReason,
    };
  }
}

// Model for likes (can be used for katas, forum posts, ohyos, and comments)
class Like {
  final int id;
  final String userId;
  final String userName;
  final String targetType; // 'kata', 'forum_post', 'ohyo', 'kata_comment', 'forum_comment', 'ohyo_comment'
  final int targetId;
  final bool isDislike; // New field to distinguish likes from dislikes
  final DateTime createdAt;

  const Like({
    required this.id,
    required this.userId,
    required this.userName,
    required this.targetType,
    required this.targetId,
    this.isDislike = false, // Default to like for backward compatibility
    required this.createdAt,
  });

  factory Like.fromJson(Map<String, dynamic> json) {
    return Like(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      userName: json['user_name'] as String? ?? 'Unknown User',
      targetType: json['target_type'] as String,
      targetId: json['target_id'] as int,
      isDislike: json['is_dislike'] as bool? ?? false, // Default to false for backward compatibility
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'target_type': targetType,
      'target_id': targetId,
      'is_dislike': isDislike,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Model for favorites (can be used for katas, forum posts, and ohyos)
class Favorite {
  final int id;
  final String userId;
  final int? kataId;
  final int? forumPostId;
  final int? ohyoId;
  final DateTime createdAt;

  const Favorite({
    required this.id,
    required this.userId,
    this.kataId,
    this.forumPostId,
    this.ohyoId,
    required this.createdAt,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    // Handle both old format (kata_id/forum_post_id) and new format (target_type/target_id)
    int? kataId;
    int? forumPostId;
    int? ohyoId;

    if (json.containsKey('target_type') && json.containsKey('target_id')) {
      // New format using target_type and target_id
      final targetType = json['target_type'] as String?;
      final targetId = json['target_id'] as int?;

      if (targetType == 'kata') {
        kataId = targetId;
      } else if (targetType == 'forum_post') {
        forumPostId = targetId;
      } else if (targetType == 'ohyo') {
        ohyoId = targetId;
      }
    } else {
      // Old format using direct kata_id/forum_post_id/ohyo_id
      kataId = json['kata_id'] as int?;
      forumPostId = json['forum_post_id'] as int?;
      ohyoId = json['ohyo_id'] as int?;
    }

    return Favorite(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      kataId: kataId,
      forumPostId: forumPostId,
      ohyoId: ohyoId,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'kata_id': kataId,
      'forum_post_id': forumPostId,
      'ohyo_id': ohyoId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

// Comment interaction state - supports likes and dislikes for different comment types
class CommentInteractionState {
  final bool isLiked;
  final bool isDisliked;
  final int likeCount;
  final int dislikeCount;
  final List<Like> likes;
  final List<Like> dislikes;
  final bool isLoading;
  final String? error;
  final bool isOffline; // Indicates if the state is from offline cache
  final bool hasPendingOperations; // Indicates if there are pending operations for this comment
  final DateTime? lastSynced; // When this comment was last synced
  final CommentConflict? conflict; // Current conflict for this comment

  const CommentInteractionState({
    this.isLiked = false,
    this.isDisliked = false,
    this.likeCount = 0,
    this.dislikeCount = 0,
    this.likes = const [],
    this.dislikes = const [],
    this.isLoading = false,
    this.error,
    this.isOffline = false,
    this.hasPendingOperations = false,
    this.lastSynced,
    this.conflict,
  });

  CommentInteractionState copyWith({
    bool? isLiked,
    bool? isDisliked,
    int? likeCount,
    int? dislikeCount,
    List<Like>? likes,
    List<Like>? dislikes,
    bool? isLoading,
    String? error,
    bool? isOffline,
    bool? hasPendingOperations,
    DateTime? lastSynced,
    CommentConflict? conflict,
  }) {
    return CommentInteractionState(
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      likes: likes ?? this.likes,
      dislikes: dislikes ?? this.dislikes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isOffline: isOffline ?? this.isOffline,
      hasPendingOperations: hasPendingOperations ?? this.hasPendingOperations,
      lastSynced: lastSynced ?? this.lastSynced,
      conflict: conflict ?? this.conflict,
    );
  }
}

// Offline queue models for storing pending operations

enum OfflineOperationType {
  addComment,
  updateComment,
  deleteComment,
  toggleLike,
  toggleDislike,
}

// Conflict resolution models

enum ConflictType {
  concurrentEdit, // Two users edited the same comment
  deletedByAnother, // Comment was deleted by another user while being edited
  likeDislikeConflict, // Conflicting like/dislike actions
  versionMismatch, // Local version doesn't match server version
}

enum ConflictResolution {
  keepLocal, // Keep local changes
  keepServer, // Keep server changes
  merge, // Merge changes (for edits)
  discard, // Discard conflicting operation
}

enum OfflineOperationStatus {
  pending,
  processing,
  completed,
  failed,
}

class OfflineOperation {
  final String id;
  final OfflineOperationType type;
  final OfflineOperationStatus status;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final DateTime? processedAt;
  final int retryCount;
  final String? error;
  final String? userId;

  const OfflineOperation({
    required this.id,
    required this.type,
    required this.status,
    required this.data,
    required this.createdAt,
    this.processedAt,
    this.retryCount = 0,
    this.error,
    this.userId,
  });

  OfflineOperation copyWith({
    OfflineOperationStatus? status,
    DateTime? processedAt,
    int? retryCount,
    String? error,
  }) {
    return OfflineOperation(
      id: id,
      type: type,
      status: status ?? this.status,
      data: data,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      retryCount: retryCount ?? this.retryCount,
      error: error ?? this.error,
      userId: userId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'status': status.name,
      'data': data,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'retry_count': retryCount,
      'error': error,
      'user_id': userId,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'] as String,
      type: OfflineOperationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      status: OfflineOperationStatus.values.firstWhere(
        (e) => e.name == json['status'],
      ),
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.parse(json['created_at'] as String),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'] as String)
          : null,
      retryCount: json['retry_count'] as int? ?? 0,
      error: json['error'] as String?,
      userId: json['user_id'] as String?,
    );
  }
}

// Model for representing conflicts that need resolution
class CommentConflict {
  final String id;
  final ConflictType type;
  final String commentType; // 'kata_comment', 'ohyo_comment', 'forum_comment'
  final int commentId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> serverData;
  final DateTime detectedAt;
  final String? userId;
  final bool resolved;
  final ConflictResolution? resolution;

  const CommentConflict({
    required this.id,
    required this.type,
    required this.commentType,
    required this.commentId,
    required this.localData,
    required this.serverData,
    required this.detectedAt,
    this.userId,
    this.resolved = false,
    this.resolution,
  });

  CommentConflict copyWith({
    ConflictResolution? resolution,
    bool? resolved,
  }) {
    return CommentConflict(
      id: id,
      type: type,
      commentType: commentType,
      commentId: commentId,
      localData: localData,
      serverData: serverData,
      detectedAt: detectedAt,
      userId: userId,
      resolved: resolved ?? this.resolved,
      resolution: resolution ?? this.resolution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'comment_type': commentType,
      'comment_id': commentId,
      'local_data': localData,
      'server_data': serverData,
      'detected_at': detectedAt.toIso8601String(),
      'user_id': userId,
      'resolved': resolved,
      'resolution': resolution?.name,
    };
  }

  factory CommentConflict.fromJson(Map<String, dynamic> json) {
    return CommentConflict(
      id: json['id'] as String,
      type: ConflictType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      commentType: json['comment_type'] as String,
      commentId: json['comment_id'] as int,
      localData: json['local_data'] as Map<String, dynamic>,
      serverData: json['server_data'] as Map<String, dynamic>,
      detectedAt: DateTime.parse(json['detected_at'] as String),
      userId: json['user_id'] as String?,
      resolved: json['resolved'] as bool? ?? false,
      resolution: json['resolution'] != null
          ? ConflictResolution.values.firstWhere(
              (e) => e.name == json['resolution'],
            )
          : null,
    );
  }
}

// Offline cached comment state
class CachedCommentState {
  final int commentId;
  final String commentType; // 'kata_comment', 'forum_comment', 'ohyo_comment'
  final bool isLiked;
  final bool isDisliked;
  final int likeCount;
  final int dislikeCount;
  final DateTime lastSynced;
  final DateTime? lastUpdated;

  const CachedCommentState({
    required this.commentId,
    required this.commentType,
    required this.isLiked,
    required this.isDisliked,
    required this.likeCount,
    required this.dislikeCount,
    required this.lastSynced,
    this.lastUpdated,
  });

  CachedCommentState copyWith({
    bool? isLiked,
    bool? isDisliked,
    int? likeCount,
    int? dislikeCount,
    DateTime? lastSynced,
    DateTime? lastUpdated,
  }) {
    return CachedCommentState(
      commentId: commentId,
      commentType: commentType,
      isLiked: isLiked ?? this.isLiked,
      isDisliked: isDisliked ?? this.isDisliked,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      lastSynced: lastSynced ?? this.lastSynced,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment_id': commentId,
      'comment_type': commentType,
      'is_liked': isLiked,
      'is_disliked': isDisliked,
      'like_count': likeCount,
      'dislike_count': dislikeCount,
      'last_synced': lastSynced.toIso8601String(),
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }

  factory CachedCommentState.fromJson(Map<String, dynamic> json) {
    return CachedCommentState(
      commentId: json['comment_id'] as int,
      commentType: json['comment_type'] as String,
      isLiked: json['is_liked'] as bool? ?? false,
      isDisliked: json['is_disliked'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      dislikeCount: json['dislike_count'] as int? ?? 0,
      lastSynced: DateTime.parse(json['last_synced'] as String),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
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

class OhyoInteractionState {
  final List<OhyoComment> comments;
  final List<Like> likes;
  final List<Favorite> favorites;
  final bool isLoading;
  final String? error;
  final bool isLiked;
  final bool isFavorited;
  final int likeCount;
  final int commentCount;

  const OhyoInteractionState({
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

  OhyoInteractionState copyWith({
    List<OhyoComment>? comments,
    List<Like>? likes,
    List<Favorite>? favorites,
    bool? isLoading,
    String? error,
    bool? isLiked,
    bool? isFavorited,
    int? likeCount,
    int? commentCount,
  }) {
    return OhyoInteractionState(
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
