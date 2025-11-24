import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../models/interaction_models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/enhanced_accessible_text.dart';
import '../providers/permission_provider.dart';
import '../providers/interaction_provider.dart';
import '../widgets/avatar_widget.dart';
import '../services/unified_tts_service.dart';
import '../widgets/threaded_comment_widget.dart';
import '../utils/comment_threading_utils.dart';

class EditPostResult {
  final bool shouldSave;
  final ForumCategory selectedCategory;

  const EditPostResult({
    required this.shouldSave,
    required this.selectedCategory,
  });
}

class ForumPostDetailScreen extends ConsumerStatefulWidget {
  final int postId;

  const ForumPostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<ForumPostDetailScreen> createState() =>
      _ForumPostDetailScreenState();
}

class _ForumPostDetailScreenState extends ConsumerState<ForumPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _isSubmittingComment = false;
  ForumPost? _post;
  bool _isLoading = true;
  ForumComment? _replyingToComment;
  bool _isOfflineMode = false;

  // Pagination state
  List<ForumComment> _comments = [];
  bool _isLoadingMore = false;
  bool _hasMoreComments = true;
  int _currentOffset = 0;
  static const int _commentsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMoreComments) {
      _loadMoreComments();
    }
  }

  Future<void> _loadPost() async {
    try {
      // Load post without comments first
      final post = await ref
          .read(forumNotifierProvider.notifier)
          .getPost(widget.postId);

      // Check if we're in offline mode (forum posts list is offline)
      final isForumOffline = ref.read(forumOfflineModeProvider);

      setState(() {
        _post = post;
        _isLoading = false;
        _comments = [];
        _currentOffset = 0;
        _hasMoreComments = true;
        _isOfflineMode = isForumOffline;
      });

      // Automatically read the forum post content when loaded
      if (mounted) {
        await _readForumPostContent(post);
      }

      // Load first page of comments
      await _loadMoreComments();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isOfflineMode = true; // Assume offline if loading fails
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij laden bericht: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reloadComments() async {
    setState(() {
      _comments = [];
      _currentOffset = 0;
      _hasMoreComments = true;
    });
    await _loadMoreComments();
  }

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newComments = await ref
          .read(forumNotifierProvider.notifier)
          .getCommentsPaginated(
            postId: widget.postId,
            limit: _commentsPerPage,
            offset: _currentOffset,
          );

      setState(() {
        _comments.addAll(newComments);
        _currentOffset += newComments.length;
        _hasMoreComments = newComments.length == _commentsPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingMore = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij laden van meer reacties: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleReply(ForumComment comment) {
    _startReplyToComment(comment);
  }


  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
      return;
    }

    // Check if we're in offline mode
    if (_isOfflineMode) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je kunt geen reacties plaatsen in offline modus'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Check if user is authenticated
    final currentUser = ref.read(authUserProvider);
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je moet ingelogd zijn om te reageren'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSubmittingComment = true;
    });

    try {
      await ref
          .read(forumNotifierProvider.notifier)
          .addComment(
            postId: widget.postId,
            content: _commentController.text.trim(),
          );

      _commentController.clear();
      _commentFocusNode.unfocus();

      // Reload the post to get updated comments
      await _loadPost();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reactie succesvol toegevoegd!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij toevoegen reactie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmittingComment = false;
        });
      }
    }
  }

  void _startReplyToComment(ForumComment comment) {
    setState(() {
      _replyingToComment = comment;
    });
    // Focus on the comment input
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentFocusNode.requestFocus();
    });
  }

  Color _getCategoryColor(ForumCategory category) {
    switch (category) {
      case ForumCategory.general:
        return Colors.blue;
      case ForumCategory.kataRequests:
        return Colors.green;
      case ForumCategory.techniques:
        return Colors.orange;
      case ForumCategory.events:
        return Colors.purple;
      case ForumCategory.feedback:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d geleden';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}u geleden';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m geleden';
    } else {
      return 'Zojuist';
    }
  }

  /// Read a forum comment using TTS
  Future<void> _readForumComment(ForumComment comment) async {
    try {
      await UnifiedTTSService.readText(
        context,
        ref,
        '${comment.authorName}: ${comment.content}',
      );
    } catch (e) {
      debugPrint('Error reading forum comment: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Er was een probleem bij het voorlezen van de reactie.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle comment tap - either resolve conflicts or read comment
  Future<void> _handleCommentTap(ForumComment comment, CommentInteractionState commentState, WidgetRef ref) async {
    // If there's a conflict, show conflict resolution dialog
    if (commentState.conflict != null && !commentState.conflict!.resolved) {
      // For now, just show a message - we can add conflict resolution later
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Er is een conflict met deze reactie')),
        );
      }
      return;
    }

    // Otherwise, read the comment using TTS
    await _readForumComment(comment);
  }

  /// Read the entire forum post content using TTS
  Future<void> _readForumPostContent(ForumPost post) async {
    try {
      final content = StringBuffer();
      content.write('Forum bericht: ${post.title}. ');
      content.write('Categorie: ${post.category.displayName}. ');
      
      if (post.content.isNotEmpty) {
        content.write('Inhoud: ${post.content}. ');
      }
      
      content.write('Geschreven door: ${post.authorName}. ');
      
      if (post.commentCount > 0) {
        content.write('Dit bericht heeft ${post.commentCount} reacties. ');
      }
      
      if (post.isPinned) {
        content.write('Dit bericht is vastgepind. ');
      }
      
      if (post.isLocked) {
        content.write('Dit bericht is gesloten. ');
      }
      
      content.write('Gepost ${_formatDate(post.createdAt)}. ');
      
      await UnifiedTTSService.readText(context, ref, content.toString());
    } catch (e) {
      debugPrint('Error reading forum post content: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Er was een probleem bij het voorlezen van het bericht.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildPostHeader(ForumPost post) {
    final currentUser = ref.watch(authUserProvider);
    final canModerateAsync = ref.watch(canModerateProvider);
    final canModerateRole = canModerateAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );
    final canModerate =
        canModerateRole ||
        (currentUser != null && post.authorId == currentUser.id);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category and status indicators
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(post.category),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          post.category.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (post.isPinned)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.push_pin,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'VASTGEMAAKT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (post.isLocked)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, color: Colors.white, size: 12),
                              SizedBox(width: 4),
                              Text(
                                'VERGRENDELD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (canModerate)
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    // Handle moderation actions
                    try {
                      switch (value) {
                        case 'edit':
                          _showEditPostDialog(post);
                          break;
                        case 'pin':
                          await ref
                              .read(forumNotifierProvider.notifier)
                              .togglePinPost(post.id);
                          await _loadPost(); // Reload to get updated status
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  post.isPinned
                                      ? 'Bericht losgemaakt'
                                      : 'Bericht vastgemaakt',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          break;
                        case 'lock':
                          await ref
                              .read(forumNotifierProvider.notifier)
                              .toggleLockPost(post.id);
                          await _loadPost(); // Reload to get updated status
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  post.isLocked
                                      ? 'Bericht ontgrendeld'
                                      : 'Bericht vergrendeld',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          break;
                        case 'delete':
                          _showDeleteConfirmation(post);
                          break;
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => [
                    // Edit option - show for post author and hosts
                    PopupMenuItem(
                      value: 'edit',
                      child: const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Bewerk'),
                        ],
                      ),
                    ),
                    // Pin/Lock options - show for all moderators but only hosts can actually use them
                    PopupMenuItem(
                      value: 'pin',
                      child: Row(
                        children: [
                          Icon(
                            post.isPinned
                                ? Icons.push_pin_outlined
                                : Icons.push_pin,
                          ),
                          const SizedBox(width: 8),
                          Text(post.isPinned ? 'Losmaken' : 'Vastmaken'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'lock',
                      child: Row(
                        children: [
                          Icon(post.isLocked ? Icons.lock_open : Icons.lock),
                          const SizedBox(width: 8),
                          Text(post.isLocked ? 'Ontgrendel' : 'Vergrendel'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: const Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            'Verwijder',
                            style: TextStyle(color: Colors.red),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            post.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Author info
          Row(
            children: [
              AvatarWidget(
                customAvatarUrl: post.authorAvatar,
                userName: post.authorName,
                size: 36,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                      ),
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      overflow: TextOverflow.visible,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Interaction buttons
          Consumer(
            builder: (context, ref, child) {
              final forumInteraction = ref.watch(
                forumInteractionProvider(post.id),
              );
              final isLiked = forumInteraction.isLiked;
              final likeCount = forumInteraction.likeCount;
              final isFavorited = forumInteraction.isFavorited;
              final isLoading = forumInteraction.isLoading;

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Like button
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(
                                      forumInteractionProvider(
                                        post.id,
                                      ).notifier,
                                    )
                                    .toggleLike();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isLiked
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isLiked ? Colors.red : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: 16,
                              color: isLiked ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                color: isLiked ? Colors.red : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Favorite button
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              try {
                                await ref
                                    .read(
                                      forumInteractionProvider(
                                        post.id,
                                      ).notifier,
                                    )
                                    .toggleFavorite();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isFavorited
                                            ? 'Verwijderd uit favorieten'
                                            : 'Toegevoegd aan favorieten',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isFavorited
                              ? Colors.teal.shade400.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFavorited
                                ? Colors.teal.shade400
                                : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isFavorited
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              size: 16,
                              color: isFavorited
                                  ? Colors.teal.shade400
                                  : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFavorited ? 'Opgeslagen' : 'Opslaan',
                              style: TextStyle(
                                color: isFavorited
                                    ? Colors.teal.shade400
                                    : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Comment count display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.comment,
                            size: 16,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostContent(ForumPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Text(
        post.content,
        style: const TextStyle(fontSize: 16, height: 1.6),
      ),
    );
  }

  Widget _buildCommentSection(ForumPost post) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            border: Border(
              top: BorderSide(color: Theme.of(context).colorScheme.outline),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.comment,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${_comments.length} Reactie${_comments.length != 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),

        // Comments list
        Expanded(
          child: Consumer(
            builder: (context, ref, child) {
              // Organize comments into threaded structure
              final threadedComments = CommentThreadingUtils.organizeForumComments(_comments);

              return Container(
                constraints: const BoxConstraints(maxHeight: 600),
                child: ListView.builder(
                  controller: _scrollController,
                  shrinkWrap: true,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  itemCount: threadedComments.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index == threadedComments.length) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(),
                      );
                    }

                    final threadedComment = threadedComments[index];
                    return ThreadedCommentWidget<ForumComment>(
                      threadedComment: threadedComment,
                      isCommentAuthor: (comment) => comment.authorId == ref.watch(authUserProvider)?.id,
                      canDeleteComment: () {
                          final currentUser = ref.watch(authUserProvider);
                          final canModerateAsync = ref.watch(canModerateProvider);
                          final isCommentAuthor = threadedComment.comment.authorId == currentUser?.id;
                          final isPostAuthor = _post!.authorId == currentUser?.id;
                          final canModerate = canModerateAsync.when(
                            data: (value) => value,
                            loading: () => false,
                            error: (_, __) => false,
                          );
                          return isCommentAuthor || isPostAuthor || canModerate;
                        },
                        getCommentState: (commentId) => ref.watch(forumCommentInteractionProvider(commentId)),
                        onCommentTap: _handleCommentTap,
                        onEditComment: (comment, ref) => _showEditCommentDialog(comment),
                        onDeleteComment: (comment, ref) => _showDeleteCommentConfirmation(comment),
                        onReply: (comment) => _handleReply(comment),
                        onToggleLike: (commentId) => ref.read(forumCommentInteractionProvider(commentId).notifier).toggleLike(),
                        onToggleDislike: (commentId) => ref.read(forumCommentInteractionProvider(commentId).notifier).toggleDislike(),
                        getCommentId: (comment) => comment.id,
                        getAuthorName: (comment) => comment.authorName,
                        getAuthorAvatar: (comment) => comment.authorAvatar,
                        getContent: (comment) => comment.content,
                        getCreatedAt: (comment) => comment.createdAt,
                        showReplyButton: true,
                        maxDepth: 5,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Future<void> _showDeleteConfirmation(ForumPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Verwijder "${post.title}"?'),
        content: const Text(
          'Dit zal het bericht en alle reacties permanent verwijderen. Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijder'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(forumNotifierProvider.notifier).deletePost(post.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Post "${post.title}" deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteCommentConfirmation(ForumComment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactie Verwijderen?'),
        content: const Text(
          'Dit zal de reactie permanent verwijderen. Dit kan niet ongedaan worden gemaakt.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijder'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(forumNotifierProvider.notifier)
            .deleteComment(comment.id);

        // Reload comments to get updated list
        await _reloadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting comment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditPostDialog(ForumPost post) async {
    final titleController = TextEditingController(text: post.title);
    final contentController = TextEditingController(text: post.content);
    ForumCategory selectedCategory = post.category;

    final result = await Navigator.push<EditPostResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditPostScreen(
          post: post,
          titleController: titleController,
          contentController: contentController,
          selectedCategory: selectedCategory,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result?.shouldSave == true) {
      try {
        await ref
            .read(forumNotifierProvider.notifier)
            .updatePost(
              postId: post.id,
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              category: result!.selectedCategory,
            );

        // Reload the post to get updated data
        await _loadPost();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating post: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showEditCommentDialog(ForumComment comment) async {
    final contentController = TextEditingController(text: comment.content);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditCommentScreen(
          comment: comment,
          contentController: contentController,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      try {
        await ref
            .read(forumNotifierProvider.notifier)
            .updateComment(
              commentId: comment.id,
              content: contentController.text.trim(),
            );

        // Reload comments to get updated list
        await _reloadComments();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comment updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating comment: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post Not Found')),
        body: const Center(
          child: Text(
            'Post not found or failed to load',
            style: TextStyle(fontSize: 18),
          ),
        ),
      );
    }

    return Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
          actions: [
            if (_isOfflineMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Offline',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                  _isOfflineMode = false;
                });
                await _loadPost();
              },
              tooltip: 'Vernieuwen',
            ),
          ],
        ),
      body: SafeArea(
        child: Column(
          children: [
            // Main content
            Expanded(
              child: NestedScrollView(
                headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPostHeader(_post!),
                          _buildPostContent(_post!),
                          // Add some padding before comments section
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ];
                },
                body: Column(
                  children: [
                    Expanded(
                      child: _buildCommentSection(_post!),
                    ),
                    // Add extra space when comment input is visible to ensure content is not hidden
                    if (!_post!.isLocked)
                      SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 120),
                  ],
                ),
              ),
            ),

            // Fixed comment input at bottom (if not locked)
            if (!_post!.isLocked)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.2),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isOfflineMode)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text(
                                'Offline: reacties kunnen niet worden geplaatst',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: EnhancedAccessibleTextField(
                              controller: _commentController,
                              focusNode: _commentFocusNode,
                              decoration: InputDecoration(
                                hintText: _isOfflineMode
                                    ? 'Offline - reacties kunnen niet worden geplaatst'
                                    : _replyingToComment != null
                                        ? 'Reageer op ${_replyingToComment!.authorName}...'
                                        : 'Schrijf een reactie...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.all(Radius.circular(25)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                filled: _isOfflineMode,
                                fillColor: _isOfflineMode
                                    ? Colors.grey.withValues(alpha: 0.1)
                                    : null,
                              ),
                              maxLines: null,
                              maxLength: 1000,
                              textInputAction: TextInputAction.send,
                              onSubmitted: _isOfflineMode ? null : (_) => _submitComment(),
                              customTTSLabel: 'Reactie invoerveld',
                              enabled: !_isOfflineMode,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: _isOfflineMode
                                  ? Colors.grey
                                  : Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: (_isSubmittingComment || _isOfflineMode)
                                  ? null
                                  : _submitComment,
                              icon: _isSubmittingComment
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.send, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class EditCommentDialog extends ConsumerStatefulWidget {
  final ForumComment comment;
  final TextEditingController contentController;

  const EditCommentDialog({
    super.key,
    required this.comment,
    required this.contentController,
  });

  @override
  ConsumerState<EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends ConsumerState<EditCommentDialog> {
  @override
  void initState() {
    super.initState();
    // Automatically speak the dialog content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakDialogContent();
    });
  }

  Future<void> _speakDialogContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    // Only speak if TTS is enabled
    if (accessibilityState.isTextToSpeechEnabled && mounted) {
      final content = _buildDialogContentText();
      await accessibilityNotifier.speak(content);
    }
  }

  String _buildDialogContentText() {
    final List<String> contentParts = [];

    contentParts.add('Forum reactie bewerken');
    contentParts.add('Dialoog geopend voor het bewerken van een forum reactie');

    contentParts.add('Reactie bewerken invoerveld: Bewerk de inhoud van je reactie');
    if (widget.contentController.text.isNotEmpty) {
      contentParts.add('Huidige reactie: ${widget.contentController.text.substring(0, min(100, widget.contentController.text.length))}');
      if (widget.contentController.text.length > 100) {
        contentParts.add('en nog ${widget.contentController.text.length - 100} karakters');
      }
    }

    contentParts.add('Gebruik de Annuleren knop om te annuleren');
    contentParts.add('Gebruik de Opslaan knop om de wijzigingen op te slaan');

    return contentParts.join('. ');
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reactie Bewerken'),
      content: SizedBox(
        width: double.maxFinite,
        child: EnhancedAccessibleTextField(
          controller: widget.contentController,
          decoration: const InputDecoration(
            labelText: 'Reactie',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          maxLines: 6,
          maxLength: 1000,
          autofocus: true,
          customTTSLabel: 'Reactie bewerken invoerveld',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuleren'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Opslaan'),
        ),
      ],
    );
  }
}

class EditCommentScreen extends ConsumerStatefulWidget {
  final ForumComment comment;
  final TextEditingController contentController;

  const EditCommentScreen({
    super.key,
    required this.comment,
    required this.contentController,
  });

  @override
  ConsumerState<EditCommentScreen> createState() => _EditCommentScreenState();
}

class _EditCommentScreenState extends ConsumerState<EditCommentScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  Future<void> _speakScreenContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    // Only speak if TTS is enabled
    if (accessibilityState.isTextToSpeechEnabled && mounted) {
      final content = _buildScreenContentText();
      await accessibilityNotifier.speak(content);
    }
  }

  String _buildScreenContentText() {
    final List<String> contentParts = [];

    contentParts.add('Forum reactie bewerken');
    contentParts.add('Scherm geopend voor het bewerken van een forum reactie');

    contentParts.add('Reactie bewerken invoerveld: Bewerk de inhoud van je reactie');
    if (widget.contentController.text.isNotEmpty) {
      contentParts.add('Huidige reactie: ${widget.contentController.text.substring(0, min(100, widget.contentController.text.length))}');
      if (widget.contentController.text.length > 100) {
        contentParts.add('en nog ${widget.contentController.text.length - 100} karakters');
      }
    }

    contentParts.add('Gebruik de Annuleren knop om te annuleren');
    contentParts.add('Gebruik de Opslaan knop om de wijzigingen op te slaan');

    return contentParts.join('. ');
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactie Bewerken'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnhancedAccessibleTextField(
                      controller: widget.contentController,
                      decoration: const InputDecoration(
                        labelText: 'Reactie',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      maxLength: 1000,
                      autofocus: true,
                      customTTSLabel: 'Reactie bewerken invoerveld',
                    ),
                    const SizedBox(height: 24), // Extra space before buttons
                  ],
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annuleren', overflow: TextOverflow.visible),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Opslaan', overflow: TextOverflow.visible),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EditPostScreen extends ConsumerStatefulWidget {
  final ForumPost post;
  final TextEditingController titleController;
  final TextEditingController contentController;
  final ForumCategory selectedCategory;

  const EditPostScreen({
    super.key,
    required this.post,
    required this.titleController,
    required this.contentController,
    required this.selectedCategory,
  });

  @override
  ConsumerState<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends ConsumerState<EditPostScreen> {
  late ForumCategory _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  Future<void> _speakScreenContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    // Only speak if TTS is enabled
    if (accessibilityState.isTextToSpeechEnabled && mounted) {
      final content = _buildScreenContentText();
      await accessibilityNotifier.speak(content);
    }
  }

  String _buildScreenContentText() {
    final List<String> contentParts = [];

    contentParts.add('Forum bericht bewerken');
    contentParts.add('Scherm geopend voor het bewerken van een forum bericht');

    contentParts.add('Huidige titel: ${widget.titleController.text}');
    contentParts.add('Titel invoerveld: Bewerk de titel van je bericht');

    contentParts.add('Categorie dropdown: Selecteer een categorie');
    contentParts.add('Momenteel geselecteerd: ${_selectedCategory.displayName}');
    contentParts.add('Beschikbare categorieën zijn: Algemeen, Kata Verzoeken, Technieken, Evenementen, en Feedback');

    contentParts.add('Inhoud invoerveld: Bewerk de inhoud van je bericht');
    if (widget.contentController.text.isNotEmpty) {
      contentParts.add('Huidige inhoud: ${widget.contentController.text.substring(0, min(100, widget.contentController.text.length))}');
      if (widget.contentController.text.length > 100) {
        contentParts.add('en nog ${widget.contentController.text.length - 100} karakters');
      }
    }

    contentParts.add('Gebruik de Annuleren knop om te annuleren');
    contentParts.add('Gebruik de Opslaan knop om de wijzigingen op te slaan');

    return contentParts.join('. ');
  }

  int min(int a, int b) => a < b ? a : b;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bericht Bewerken'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, const EditPostResult(shouldSave: false, selectedCategory: ForumCategory.general)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnhancedAccessibleTextField(
                      controller: widget.titleController,
                      decoration: const InputDecoration(
                        labelText: 'Titel',
                        border: OutlineInputBorder(),
                      ),
                      maxLength: 200,
                      customTTSLabel: 'Titel invoerveld',
                    ),
                    const SizedBox(height: 16),
                    Consumer(
                      builder: (context, ref, child) {
                        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
                        final baseStyle = const TextStyle(fontSize: 14, height: 1.2);
                        final accessibleStyle = accessibilityNotifier.getAccessibleTextStyle(baseStyle);

                        return DropdownButtonFormField<ForumCategory>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categorie',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          isExpanded: true,
                          style: accessibleStyle,
                          items: ForumCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Text(
                                  category.displayName,
                                  style: accessibleStyle,
                                  softWrap: true,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    EnhancedAccessibleTextField(
                      controller: widget.contentController,
                      decoration: const InputDecoration(
                        labelText: 'Inhoud',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 8,
                      maxLength: 5000,
                      customTTSLabel: 'Inhoud invoerveld',
                    ),
                    const SizedBox(height: 24), // Extra space before buttons
                  ],
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, const EditPostResult(shouldSave: false, selectedCategory: ForumCategory.general)),
                      child: const Text('Annuleren', overflow: TextOverflow.visible),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, EditPostResult(shouldSave: true, selectedCategory: _selectedCategory)),
                      child: const Text('Opslaan', overflow: TextOverflow.visible),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class ReplyForumCommentScreen extends ConsumerStatefulWidget {
  final int forumPostId;
  final ForumComment originalComment;

  const ReplyForumCommentScreen({
    super.key,
    required this.forumPostId,
    required this.originalComment,
  });

  @override
  ConsumerState<ReplyForumCommentScreen> createState() => _ReplyForumCommentScreenState();
}

class _ReplyForumCommentScreenState extends ConsumerState<ReplyForumCommentScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  Future<void> _speakScreenContent() async {
    // TTS implementation for reply screen
    // This is a placeholder for future accessibility enhancement
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reageren op reactie'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Original comment preview
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDark ? theme.colorScheme.surfaceContainerHighest : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? theme.colorScheme.outline : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Original author name and reply icon
                          Row(
                            children: [
                              const Icon(Icons.reply, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Text(
                                widget.originalComment.authorName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Original comment content
                          Text(
                            widget.originalComment.content,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Reply input
                    EnhancedAccessibleTextField(
                      controller: _replyController,
                      decoration: InputDecoration(
                        labelText: 'Jouw reactie',
                        hintText: 'Schrijf hier je reactie...',
                        border: const OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 6,
                      maxLength: 500,
                      autofocus: true,
                      customTTSLabel: 'Reactie invoerveld',
                    ),
                  ],
                ),
              ),
            ),
            // Fixed buttons at bottom
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annuleren'),
                  ),
                  const SizedBox(width: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final isSubmitting = ref.watch(forumNotifierProvider).isLoading;

                      return ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          if (_replyController.text.trim().isNotEmpty) {
                            try {
                              await ref.read(forumNotifierProvider.notifier)
                                  .addComment(
                                    postId: widget.forumPostId,
                                    content: _replyController.text.trim(),
                                    parentCommentId: widget.originalComment.id,
                                  );
                              if (context.mounted) {
                                Navigator.pop(context, true);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Fout bij toevoegen reactie: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        child: isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Reageren'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
