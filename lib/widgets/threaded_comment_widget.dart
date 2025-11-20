import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/interaction_models.dart';
import '../utils/comment_threading_utils.dart';
import 'avatar_widget.dart';

/// Generic threaded comment widget that can display nested comments
/// Supports ForumComment, KataComment, and OhyoComment
class ThreadedCommentWidget<T> extends StatefulWidget {
  final ThreadedComment<T> threadedComment;
  final bool Function(T) isCommentAuthor;
  final bool Function() canDeleteComment;
  final CommentInteractionState Function(int) getCommentState;
  final void Function(T, CommentInteractionState, WidgetRef) onCommentTap;
  final void Function(T, WidgetRef) onEditComment;
  final void Function(T, WidgetRef) onDeleteComment;
  final void Function(T) onReply;
  final void Function(int) onToggleLike;
  final void Function(int) onToggleDislike;
  final int Function(T) getCommentId;
  final String Function(T) getAuthorName;
  final String? Function(T) getAuthorAvatar;
  final String Function(T) getContent;
  final DateTime Function(T) getCreatedAt;
  final bool showReplyButton;
  final int maxDepth;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;

  const ThreadedCommentWidget({
    super.key,
    required this.threadedComment,
    required this.isCommentAuthor,
    required this.canDeleteComment,
    required this.getCommentState,
    required this.onCommentTap,
    required this.onEditComment,
    required this.onDeleteComment,
    required this.onReply,
    required this.onToggleLike,
    required this.onToggleDislike,
    required this.getCommentId,
    required this.getAuthorName,
    required this.getAuthorAvatar,
    required this.getContent,
    required this.getCreatedAt,
    this.showReplyButton = true,
    this.maxDepth = 5,
    this.isCollapsed = false,
    this.onToggleCollapse,
  });

  @override
  State<ThreadedCommentWidget<T>> createState() => _ThreadedCommentWidgetState<T>();
}

class _ThreadedCommentWidgetState<T> extends State<ThreadedCommentWidget<T>> {
  late bool _isCollapsed;

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.isCollapsed;
  }

  @override
  void didUpdateWidget(ThreadedCommentWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      _isCollapsed = widget.isCollapsed;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Don't show deeply nested comments beyond maxDepth
    if (widget.threadedComment.depth >= widget.maxDepth) {
      return Container(
        margin: EdgeInsets.only(left: min(32.0 * (widget.threadedComment.depth + 1), 160.0)),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Text(
          'Deze thread is te diep genest om weer te geven',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return Column(
      children: [
        // Main comment
        _buildCommentCard(context, isDark),

        // Replies (if not collapsed)
        if (!_isCollapsed && widget.threadedComment.replies.isNotEmpty) ...[
          ...widget.threadedComment.replies.map((reply) => Padding(
                padding: EdgeInsets.only(left: min(32.0 * (widget.threadedComment.depth + 1), 160.0)),
                child: ThreadedCommentWidget<T>(
                  threadedComment: reply,
                  isCommentAuthor: widget.isCommentAuthor,
                  canDeleteComment: widget.canDeleteComment,
                  getCommentState: widget.getCommentState,
                  onCommentTap: widget.onCommentTap,
                  onEditComment: widget.onEditComment,
                  onDeleteComment: widget.onDeleteComment,
                  onReply: widget.onReply,
                  onToggleLike: widget.onToggleLike,
                  onToggleDislike: widget.onToggleDislike,
                  getCommentId: widget.getCommentId,
                  getAuthorName: widget.getAuthorName,
                  getAuthorAvatar: widget.getAuthorAvatar,
                  getContent: widget.getContent,
                  getCreatedAt: widget.getCreatedAt,
                  showReplyButton: widget.showReplyButton,
                  maxDepth: widget.maxDepth,
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildCommentCard(BuildContext context, bool isDark) {
    final comment = widget.threadedComment.comment;
    final commentId = widget.getCommentId(comment);
    final commentState = widget.getCommentState(commentId);

    return Consumer(
      builder: (context, ref, child) {

        final canDelete = widget.canDeleteComment();

        return GestureDetector(
          onTap: () => widget.onCommentTap(comment, commentState, ref),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surfaceContainerHighest : Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: isDark ? Theme.of(context).colorScheme.outline : Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar, name, date, and menu
                Row(
                  children: [
                    AvatarWidget(
                      customAvatarUrl: widget.getAuthorAvatar(comment),
                      userName: widget.getAuthorName(comment),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.getAuthorName(comment),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            _formatDate(widget.getCreatedAt(comment)),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Menu button
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            widget.onEditComment(comment, ref);
                            break;
                          case 'delete':
                            widget.onDeleteComment(comment, ref);
                            break;
                        }
                      },
                      itemBuilder: (context) {
                        List<PopupMenuEntry<String>> items = [];

                        // Edit option if user is the comment author
                        if (widget.isCommentAuthor(comment)) {
                          items.add(
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue, size: 14),
                                  SizedBox(width: 8),
                                  Text('Bewerk', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }

                        // Delete option if user has permission
                        if (canDelete) {
                          items.add(
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 14),
                                  SizedBox(width: 8),
                                  Text('Verwijder', style: TextStyle(color: Colors.red, fontSize: 12)),
                                ],
                              ),
                            ),
                          );
                        }

                        // If no items available, show a disabled "No actions" item
                        if (items.isEmpty) {
                          items.add(
                            const PopupMenuItem(
                              enabled: false,
                              value: 'none',
                              child: Text(
                                'Geen acties beschikbaar',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                          );
                        }

                        return items;
                      },
                      icon: Icon(
                        Icons.more_vert,
                        size: 16,
                        color: isDark ? Theme.of(context).colorScheme.onSurfaceVariant : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Comment content
                Text(
                  widget.getContent(comment),
                  style: const TextStyle(fontSize: 13),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                ),
                const SizedBox(height: 8),
                // Like and dislike buttons and counts
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Like button and count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: commentState.isLoading
                              ? null
                              : () => widget.onToggleLike(commentId),
                          icon: Icon(
                            commentState.isLiked ? Icons.thumb_up : Icons.thumb_up_alt_outlined,
                            size: 16,
                            color: commentState.isLiked ? Colors.green : null,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          tooltip: commentState.isLiked ? 'Unlike comment' : 'Like comment',
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${commentState.likeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: commentState.isLiked ? Colors.green : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Dislike button and count
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: commentState.isLoading
                              ? null
                              : () => widget.onToggleDislike(commentId),
                          icon: Icon(
                            commentState.isDisliked ? Icons.thumb_down : Icons.thumb_down_alt_outlined,
                            size: 16,
                            color: commentState.isDisliked ? Colors.red : null,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 24,
                            minHeight: 24,
                          ),
                          tooltip: commentState.isDisliked ? 'Remove dislike' : 'Dislike comment',
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${commentState.dislikeCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: commentState.isDisliked ? Colors.red : null,
                          ),
                        ),
                      ],
                    ),
                    // Offline/sync/conflict indicator
                    if (commentState.isOffline || commentState.hasPendingOperations || commentState.conflict != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        commentState.conflict != null
                            ? Icons.warning
                            : commentState.isOffline
                                ? Icons.wifi_off
                                : Icons.sync,
                        size: 14,
                        color: commentState.conflict != null ? Colors.orange : Colors.grey,
                      ),
                    ],
                    // Reply toggle button (only show if there are replies)
                    if (widget.threadedComment.replies.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isCollapsed = !_isCollapsed;
                          });
                          widget.onToggleCollapse?.call();
                        },
                        child: Row(
                          children: [
                            Icon(
                              _isCollapsed ? Icons.expand_more : Icons.expand_less,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.threadedComment.totalComments - 1} reactie${widget.threadedComment.totalComments - 1 == 1 ? '' : 's'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (widget.showReplyButton) ...[
                      // Show reply button only if no replies exist yet
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () => widget.onReply(comment),
                        icon: const Icon(
                          Icons.reply,
                          size: 16,
                          color: Colors.blue,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        tooltip: 'Reply to comment',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}j geleden';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}m geleden';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d geleden';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}u geleden';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m geleden';
    } else {
      return 'Nu net';
    }
  }
}
