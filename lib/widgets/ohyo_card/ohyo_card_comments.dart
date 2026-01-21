import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/ohyo_model.dart';
import '../../models/interaction_models.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/role_provider.dart';
import '../../providers/network_provider.dart';
import '../enhanced_accessible_text.dart';
import '../../services/unified_tts_service.dart';
import '../conflict_resolution_dialog.dart';
import '../threaded_comment_widget.dart';
import '../../utils/comment_threading_utils.dart';

class OhyoCardComments extends ConsumerStatefulWidget {
  final Ohyo ohyo;
  final List<OhyoComment> comments;
  final bool isLoading;
  final VoidCallback onCollapse;

  const OhyoCardComments({
    super.key,
    required this.ohyo,
    required this.comments,
    required this.isLoading,
    required this.onCollapse,
  });

  @override
  ConsumerState<OhyoCardComments> createState() => _OhyoCardCommentsState();
}

class _OhyoCardCommentsState extends ConsumerState<OhyoCardComments> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pagination state
  List<OhyoComment> _comments = [];
  bool _isLoadingMore = false;
  bool _hasMoreComments = true;
  int _currentOffset = 0;
  static const int _commentsPerPage = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _comments = List.from(widget.comments);
    _currentOffset = widget.comments.length;
    _hasMoreComments = widget.comments.length == _commentsPerPage;
  }

  @override
  void dispose() {
    _commentController.dispose();
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

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final newComments = await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier)
          .getCommentsPaginated(
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

  void _handleReply(OhyoComment comment) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ReplyOhyoCommentScreen(
          ohyoId: widget.ohyo.id,
          originalComment: comment,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      // Comment was successfully added, refresh will happen automatically
      // through the provider
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? theme.colorScheme.outline : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with collapse button
          Row(
            children: [
              const Icon(Icons.comment, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Reacties (${_comments.length})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onCollapse,
                icon: const Icon(Icons.expand_less, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Sluit reacties',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Comments list
          Consumer(
            builder: (context, ref, child) {
              final networkState = ref.watch(networkProvider);

              if (widget.isLoading && networkState.isConnected) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (widget.isLoading && !networkState.isConnected) {
                // Show offline message when loading but offline
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.wifi_off,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Reacties laden mislukt',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Reacties worden geladen wanneer je weer online bent',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final networkNotifier = ref.read(networkProvider.notifier);
                              await networkNotifier.retry();
                              // Retry loading comments after network check
                              final updatedNetworkState = ref.read(networkProvider);
                              if (updatedNetworkState.isConnected) {
                                await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier).loadOhyoInteractions();
                              }
                            },
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text(
                              'Opnieuw proberen',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              minimumSize: const Size(0, 32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              } else if (widget.comments.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Nog geen reacties. Wees de eerste om te reageren!',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              } else {
                // Organize comments into threaded structure
                final threadedComments = CommentThreadingUtils.organizeOhyoComments(_comments);

                return Container(
                  constraints: const BoxConstraints(maxHeight: 400),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    cacheExtent: 600,
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
                      return ThreadedCommentWidget<OhyoComment>(
                        threadedComment: threadedComment,
                        isCommentAuthor: (comment) => comment.authorId == ref.watch(authUserProvider)?.id,
                        canDeleteComment: () {
                          final currentUser = ref.watch(authUserProvider);
                          final isModeratorAsync = ref.watch(isCurrentUserModeratorProvider);
                          final isCommentAuthor = threadedComment.comment.authorId == currentUser?.id;
                          final canDelete = isCommentAuthor || isModeratorAsync.when(
                            data: (isModerator) => isModerator,
                            loading: () => false,
                            error: (error, stackTrace) => false,
                          );
                          return canDelete;
                        },
                        getCommentState: (commentId) => ref.watch(ohyoCommentInteractionProvider(commentId)),
                        onCommentTap: _handleCommentTap,
                        onEditComment: _showEditOhyoCommentDialog,
                        onDeleteComment: _showDeleteOhyoCommentConfirmation,
                        onReply: _handleReply,
                        onToggleLike: (commentId) => ref.read(ohyoCommentInteractionProvider(commentId).notifier).toggleLike(),
                        onToggleDislike: (commentId) => ref.read(ohyoCommentInteractionProvider(commentId).notifier).toggleDislike(),
                        getCommentId: (comment) => comment.id,
                        getAuthorId: (comment) => comment.authorId,
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
              }
            },
          ),

          const SizedBox(height: 12),

          // Add comment section
          _buildAddCommentSection(),
        ],
      ),
    );
  }


  Widget _buildAddCommentSection() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? theme.colorScheme.outline : Colors.grey.shade300),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8.0),
          bottomRight: Radius.circular(8.0),
        ),
      ),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Consumer(
            builder: (context, ref, child) {
              return EnhancedAccessibleTextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  hintText: 'Voeg een reactie toe...',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.all(8),
                ),
                maxLines: 2,
                minLines: 1,
                maxLength: 500,
                customTTSLabel: 'Reactie invoerveld',
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final isSubmitting = ref.watch(ohyoInteractionProvider(widget.ohyo.id)).isLoading;

                  return ElevatedButton(
                    onPressed: isSubmitting ? null : () async {
                      if (_commentController.text.trim().isNotEmpty) {
                        try {
                          await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier)
                              .addComment(_commentController.text.trim());
                          _commentController.clear();
                          if (mounted && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Reactie succesvol toegevoegd!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted && context.mounted) {
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
                      : const Text('Plaats'),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleCommentTap(OhyoComment comment, CommentInteractionState commentState, WidgetRef ref) async {
    // If there's a conflict, show conflict resolution dialog
    if (commentState.conflict != null && !commentState.conflict!.resolved) {
      await showConflictResolutionDialog(context, commentState.conflict!);
      return;
    }

    // Otherwise, read the comment using TTS
    await _readOhyoComment(comment, ref);
  }

  /// Read an ohyo comment using TTS
  Future<void> _readOhyoComment(OhyoComment comment, WidgetRef ref) async {
    try {
      // Build the comment text to speak
      final commentText = 'Reactie van ${comment.authorName}: ${comment.content}';

      // Use the UnifiedTTSService to speak the comment
      await UnifiedTTSService.readText(context, ref, commentText);
    } catch (e) {
      debugPrint('Error reading ohyo comment: $e');
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

  Future<void> _showEditOhyoCommentDialog(OhyoComment comment, WidgetRef ref) async {
    final contentController = TextEditingController(text: comment.content);

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditOhyoCommentScreen(
          comment: comment,
          contentController: contentController,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == true) {
      try {
        await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier)
            .updateComment(
              commentId: comment.id,
              content: contentController.text.trim(),
            );
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reactie bijgewerkt!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij bijwerken reactie: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteOhyoCommentConfirmation(OhyoComment comment, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reactie verwijderen'),
        content: const Text('Weet je zeker dat je deze reactie wilt verwijderen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuleren'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwijderen', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier)
            .deleteComment(comment.id);
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reactie verwijderd!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fout bij verwijderen reactie: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

class EditOhyoCommentScreen extends ConsumerStatefulWidget {
  final OhyoComment comment;
  final TextEditingController contentController;

  const EditOhyoCommentScreen({
    super.key,
    required this.comment,
    required this.contentController,
  });

  @override
  ConsumerState<EditOhyoCommentScreen> createState() => _EditOhyoCommentScreenState();
}

class _EditOhyoCommentScreenState extends ConsumerState<EditOhyoCommentScreen> {
  @override
  void initState() {
    super.initState();
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  Future<void> _speakScreenContent() async {
    // TTS implementation for ohyo comment editing screen
    // This is a placeholder for future accessibility enhancement
  }

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
                      maxLines: 6,
                      maxLength: 500,
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

class ReplyOhyoCommentScreen extends ConsumerStatefulWidget {
  final int ohyoId;
  final OhyoComment originalComment;

  const ReplyOhyoCommentScreen({
    super.key,
    required this.ohyoId,
    required this.originalComment,
  });

  @override
  ConsumerState<ReplyOhyoCommentScreen> createState() => _ReplyOhyoCommentScreenState();
}

class _ReplyOhyoCommentScreenState extends ConsumerState<ReplyOhyoCommentScreen> {
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
                      final isSubmitting = ref.watch(ohyoInteractionProvider(widget.ohyoId)).isLoading;

                      return ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                            if (_replyController.text.trim().isNotEmpty) {
                              try {
                                await ref.read(ohyoInteractionProvider(widget.ohyoId).notifier)
                                    .addComment(
                                      _replyController.text.trim(),
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
