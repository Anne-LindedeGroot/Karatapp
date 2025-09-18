
enum ForumCategory {
  general('General Discussion'),
  kataRequests('Kata Requests'),
  techniques('Techniques & Tips'),
  events('Events & Announcements'),
  feedback('App Feedback');

  const ForumCategory(this.displayName);
  final String displayName;
}

class ForumPost {
  final int id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final ForumCategory category;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final bool isLocked;
  final int commentCount;
  final List<ForumComment> comments;

  const ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.isLocked = false,
    this.commentCount = 0,
    this.comments = const [],
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      category: ForumCategory.values.firstWhere(
        (cat) => cat.name == json['category'],
        orElse: () => ForumCategory.general,
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isPinned: json['is_pinned'] as bool? ?? false,
      isLocked: json['is_locked'] as bool? ?? false,
      commentCount: json['comment_count'] as int? ?? 0,
      comments: (json['comments'] as List<dynamic>?)
              ?.map((comment) => ForumComment.fromJson(comment))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'category': category.name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_pinned': isPinned,
      'is_locked': isLocked,
      'comment_count': commentCount,
    };
  }

  ForumPost copyWith({
    int? id,
    String? title,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    ForumCategory? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
    bool? isLocked,
    int? commentCount,
    List<ForumComment>? comments,
  }) {
    return ForumPost(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      commentCount: commentCount ?? this.commentCount,
      comments: comments ?? this.comments,
    );
  }
}

class ForumComment {
  final int id;
  final int postId;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? parentCommentId; // For nested replies

  const ForumComment({
    required this.id,
    required this.postId,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    required this.updatedAt,
    this.parentCommentId,
  });

  factory ForumComment.fromJson(Map<String, dynamic> json) {
    return ForumComment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      content: json['content'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String,
      authorAvatar: json['author_avatar'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      parentCommentId: json['parent_comment_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'post_id': postId,
      'content': content,
      'author_id': authorId,
      'author_name': authorName,
      'author_avatar': authorAvatar,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'parent_comment_id': parentCommentId,
    };
  }

  ForumComment copyWith({
    int? id,
    int? postId,
    String? content,
    String? authorId,
    String? authorName,
    String? authorAvatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? parentCommentId,
  }) {
    return ForumComment(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      content: content ?? this.content,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      parentCommentId: parentCommentId ?? this.parentCommentId,
    );
  }
}

class ForumState {
  final List<ForumPost> posts;
  final List<ForumPost> filteredPosts;
  final ForumPost? selectedPost;
  final bool isLoading;
  final String? error;
  final ForumCategory? selectedCategory;
  final String searchQuery;

  const ForumState({
    this.posts = const [],
    this.filteredPosts = const [],
    this.selectedPost,
    this.isLoading = false,
    this.error,
    this.selectedCategory,
    this.searchQuery = '',
  });

  ForumState copyWith({
    List<ForumPost>? posts,
    List<ForumPost>? filteredPosts,
    ForumPost? selectedPost,
    bool? isLoading,
    String? error,
    ForumCategory? selectedCategory,
    String? searchQuery,
  }) {
    return ForumState(
      posts: posts ?? this.posts,
      filteredPosts: filteredPosts ?? this.filteredPosts,
      selectedPost: selectedPost ?? this.selectedPost,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
