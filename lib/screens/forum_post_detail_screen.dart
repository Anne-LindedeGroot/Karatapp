import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/interaction_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/global_tts_overlay.dart';

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
  bool _isSubmittingComment = false;
  ForumPost? _post;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final post = await ref
          .read(forumNotifierProvider.notifier)
          .getPostWithComments(widget.postId);
      setState(() {
        _post = post;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) {
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
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(post.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      overflow: TextOverflow.ellipsis,
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
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
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
                '${post.comments.length} Reactie${post.comments.length != 1 ? 's' : ''}',
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
        ...post.comments.map((comment) => _buildCommentCard(comment)),

        // Add some bottom padding to ensure content is not hidden behind navigation
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildCommentCard(ForumComment comment) {
    final currentUser = ref.watch(authUserProvider);
    final canModerateAsync = ref.watch(canModerateProvider);
    final canModerateRole = canModerateAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (_, __) => false,
    );

    // User can edit/delete if they are:
    // 1. The comment author
    // 2. The post author (forum creator)
    // 3. A moderator (host or mediator)
    final canEditComment =
        currentUser != null &&
        (comment.authorId == currentUser.id || // Comment author
            _post!.authorId == currentUser.id || // Post author (forum creator)
            canModerateRole // Moderator (host or mediator)
            );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Comment header
          Row(
            children: [
              AvatarWidget(
                customAvatarUrl: comment.authorAvatar,
                userName: comment.authorName,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.authorName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(comment.createdAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              // Edit/Delete menu for comments
              if (canEditComment)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _showEditCommentDialog(comment);
                        break;
                      case 'delete':
                        _showDeleteCommentConfirmation(comment);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    // Only show edit for comment author
                    if (comment.authorId == currentUser.id)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue, size: 16),
                            SizedBox(width: 8),
                            Text('Bewerk'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text('Verwijder', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  icon: Icon(
                    Icons.more_vert,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Comment content
          Text(
            comment.content,
            style: const TextStyle(
              fontSize: 15, 
              height: 1.5,
              color: Color(0xFF2C2C2C),
            ),
          ),
        ],
      ),
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

        // Reload the post to get updated comments
        await _loadPost();

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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.05, // Reduced to 5% padding for more space
            vertical: 40,
          ),
          child: Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height - 120,
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width - 40, // Ensure maximum width
            ),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Bericht Bewerken',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context, false),
                            icon: const Icon(Icons.close),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: 'Titel',
                                border: OutlineInputBorder(),
                              ),
                              maxLength: 200,
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<ForumCategory>(
                              initialValue: selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categorie',
                                border: OutlineInputBorder(),
                              ),
                              isExpanded: true, // This prevents overflow by expanding the dropdown
                              items: ForumCategory.values.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(
                                    category.displayName,
                                    overflow: TextOverflow.ellipsis, // Handle long text gracefully
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedCategory = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: contentController,
                              decoration: const InputDecoration(
                                labelText: 'Inhoud',
                                border: OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              maxLines: 8,
                              maxLength: 5000,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Divider(height: 1),

                    // Actions
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Annuleren'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Opslaan'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          ),
        ),
      ),
    );

    if (result == true) {
      try {
        await ref
            .read(forumNotifierProvider.notifier)
            .updatePost(
              postId: post.id,
              title: titleController.text.trim(),
              content: contentController.text.trim(),
              category: selectedCategory,
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

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactie Bewerken'),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: contentController,
            decoration: const InputDecoration(
              labelText: 'Reactie',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 6,
            maxLength: 1000,
            autofocus: true,
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

        // Reload the post to get updated comments
        await _loadPost();

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

    return GlobalTTSOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Forum Post'),
        ),
      body: Column(
        children: [
          // Main content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPostHeader(_post!),
                  _buildPostContent(_post!),
                  _buildCommentSection(_post!),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.shadow.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocusNode,
                          decoration: InputDecoration(
                            hintText: 'Schrijf een reactie...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          maxLength: 1000,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _submitComment(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _isSubmittingComment
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
                ),
              ),
            ),
        ],
      ),
    ),
    );
  }
}
