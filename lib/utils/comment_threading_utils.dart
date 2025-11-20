import '../models/forum_models.dart';
import '../models/interaction_models.dart';

/// Represents a threaded comment with its replies
class ThreadedComment<T> {
  final T comment;
  final List<ThreadedComment<T>> replies;
  final int depth; // Nesting level (0 = top level)

  const ThreadedComment({
    required this.comment,
    required this.replies,
    required this.depth,
  });

  /// Get total number of comments in this thread (including this one)
  int get totalComments => 1 + replies.fold(0, (sum, reply) => sum + reply.totalComments);

  /// Get direct reply count (not including nested replies)
  int get directReplyCount => replies.length;
}

/// Utility class for organizing comments into threaded/nested structure
class CommentThreadingUtils {

  /// Organize forum comments into threaded structure
  static List<ThreadedComment<ForumComment>> organizeForumComments(List<ForumComment> comments) {
    return _organizeComments(
      comments,
      (comment) => comment.id,
      (comment) => comment.parentCommentId,
      (comment) => comment.createdAt,
    );
  }

  /// Organize kata comments into threaded structure
  static List<ThreadedComment<KataComment>> organizeKataComments(List<KataComment> comments) {
    return _organizeComments(
      comments,
      (comment) => comment.id,
      (comment) => comment.parentCommentId,
      (comment) => comment.createdAt,
    );
  }

  /// Organize ohyo comments into threaded structure
  static List<ThreadedComment<OhyoComment>> organizeOhyoComments(List<OhyoComment> comments) {
    return _organizeComments(
      comments,
      (comment) => comment.id,
      (comment) => comment.parentCommentId,
      (comment) => comment.createdAt,
    );
  }

  /// Generic method to organize comments into threaded structure
  static List<ThreadedComment<T>> _organizeComments<T>(
    List<T> comments,
    int Function(T) getId,
    int? Function(T) getParentId,
    DateTime Function(T) getCreatedAt,
  ) {
    // Create maps for efficient lookup
    final commentMap = <int, T>{};
    final childrenMap = <int?, List<T>>{};

    // Populate maps
    for (final comment in comments) {
      final id = getId(comment);
      final parentId = getParentId(comment);

      commentMap[id] = comment;
      childrenMap.putIfAbsent(parentId, () => []).add(comment);
    }

    // Build threaded structure starting from top-level comments (parentId == null)
    return _buildThreadedComments<T>(
      childrenMap[null] ?? [],
      childrenMap,
      getId,
      getParentId,
      getCreatedAt,
      0,
    );
  }

  /// Recursively build threaded comment structure
  static List<ThreadedComment<T>> _buildThreadedComments<T>(
    List<T> comments,
    Map<int?, List<T>> childrenMap,
    int Function(T) getId,
    int? Function(T) getParentId,
    DateTime Function(T) getCreatedAt,
    int depth,
  ) {
    final threadedComments = <ThreadedComment<T>>[];

    // Sort comments by creation date for consistent ordering
    comments.sort((a, b) {
      final dateA = getCreatedAt(a);
      final dateB = getCreatedAt(b);
      return dateA.compareTo(dateB);
    });

    for (final comment in comments) {
      final id = getId(comment);
      final replies = _buildThreadedComments<T>(
        childrenMap[id] ?? [],
        childrenMap,
        getId,
        getParentId,
        getCreatedAt,
        depth + 1,
      );

      threadedComments.add(ThreadedComment<T>(
        comment: comment,
        replies: replies,
        depth: depth,
      ));
    }

    return threadedComments;
  }

  /// Get all comment IDs in a thread (including the root comment)
  static List<int> getThreadCommentIds<T>(ThreadedComment<T> threadedComment) {
    final ids = <int>[];

    void collectIds(ThreadedComment<T> comment) {
      // This assumes T has an id field - we'll need to pass a getter
      ids.add(0); // Placeholder - will be fixed when used
      for (final reply in comment.replies) {
        collectIds(reply);
      }
    }

    collectIds(threadedComment);
    return ids;
  }

  /// Find a specific comment in the threaded structure
  static ThreadedComment<T>? findCommentInThreads<T>(
    List<ThreadedComment<T>> threads,
    int Function(T) getId,
    int targetId,
  ) {
    for (final thread in threads) {
      final result = _findCommentRecursive(thread, getId, targetId);
      if (result != null) return result;
    }
    return null;
  }

  static ThreadedComment<T>? _findCommentRecursive<T>(
    ThreadedComment<T> threadedComment,
    int Function(T) getId,
    int targetId,
  ) {
    if (getId(threadedComment.comment) == targetId) {
      return threadedComment;
    }

    for (final reply in threadedComment.replies) {
      final result = _findCommentRecursive(reply, getId, targetId);
      if (result != null) return result;
    }

    return null;
  }

  /// Get the parent comment ID for a given comment ID from a flat list
  static int? getParentCommentId<T>(
    List<T> comments,
    int Function(T) getId,
    int? Function(T) getParentId,
    int commentId,
  ) {
    final comment = comments.firstWhere(
      (c) => getId(c) == commentId,
      orElse: () => null as T,
    );

    if (comment == null) return null;
    return getParentId(comment);
  }

  /// Check if a comment has replies
  static bool hasReplies<T>(
    List<T> allComments,
    int Function(T) getId,
    int? Function(T) getParentId,
    int commentId,
  ) {
    return allComments.any((comment) => getParentId(comment) == commentId);
  }

  /// Get reply count for a comment
  static int getReplyCount<T>(
    List<T> allComments,
    int Function(T) getId,
    int? Function(T) getParentId,
    int commentId,
  ) {
    return allComments.where((comment) => getParentId(comment) == commentId).length;
  }

  /// Get the thread root comment ID for any comment in the thread
  static int getThreadRootId<T>(
    List<T> allComments,
    int Function(T) getId,
    int? Function(T) getParentId,
    int commentId,
  ) {
    int currentId = commentId;
    int? parentId;

    do {
      parentId = getParentCommentId(allComments, getId, getParentId, currentId);
      if (parentId != null) {
        currentId = parentId;
      }
    } while (parentId != null);

    return currentId;
  }

  /// Get all comments in a thread (including nested replies)
  static List<T> getThreadComments<T>(
    List<T> allComments,
    int Function(T) getId,
    int? Function(T) getParentId,
    int rootCommentId,
  ) {
    final threadComments = <T>[];
    final processedIds = <int>{};

    void collectThreadComments(int commentId) {
      if (processedIds.contains(commentId)) return;
      processedIds.add(commentId);

      final comment = allComments.firstWhere(
        (c) => getId(c) == commentId,
        orElse: () => null as T,
      );

      if (comment != null) {
        threadComments.add(comment);

        // Find all direct replies and recursively collect their threads
        final replies = allComments.where((c) => getParentId(c) == commentId);
        for (final reply in replies) {
          collectThreadComments(getId(reply));
        }
      }
    }

    collectThreadComments(rootCommentId);
    return threadComments;
  }
}
