import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
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
import '../../utils/image_utils.dart';
import '../media_source_bottom_sheet.dart';

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
  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];

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
  void didUpdateWidget(OhyoCardComments oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ohyo.id != widget.ohyo.id) {
      _comments = List.from(widget.comments);
      _currentOffset = widget.comments.length;
      _hasMoreComments = widget.comments.length == _commentsPerPage;
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _syncCommentsIfNeeded(List<OhyoComment> nextComments) {
    if (!_shouldUpdateComments(nextComments)) return;
    setState(() {
      _comments = List.from(nextComments);
      _currentOffset = nextComments.length;
      _hasMoreComments = nextComments.length >= _commentsPerPage;
    });
  }

  bool _shouldUpdateComments(List<OhyoComment> nextComments) {
    if (nextComments.length != _comments.length) return true;
    for (var i = 0; i < nextComments.length; i++) {
      final next = nextComments[i];
      final current = _comments[i];
      if (next.id != current.id) return true;
      if (next.updatedAt != current.updatedAt) return true;
      if (next.content != current.content) return true;
      if (next.imageUrls.length != current.imageUrls.length) return true;
      if (next.fileUrls.length != current.fileUrls.length) return true;
    }
    return false;
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _selectedImages.add(image);
    });
  }

  void _removeSelectedImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _selectedFiles.addAll(files);
    });
  }

  void _removeSelectedFile(File file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  String _getFileName(File file) {
    final path = file.path.replaceAll('\\', '/');
    final slashIndex = path.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == path.length - 1) {
      return path;
    }
    return path.substring(slashIndex + 1);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickImagesFromGallery();
          },
        );
      },
    );
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
    ref.listen<OhyoInteractionState>(
      ohyoInteractionProvider(widget.ohyo.id),
      (previous, next) {
        if (!mounted) return;
        if (next.comments.isEmpty && _comments.isEmpty) return;
        _syncCommentsIfNeeded(next.comments);
      },
    );

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
                        getImageUrls: (comment) => comment.imageUrls,
                        getFileUrls: (comment) => comment.fileUrls,
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
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _showImageSourceSheet,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                label: const Text('Afbeelding'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedImages.isEmpty
                      ? 'Geen afbeeldingen geselecteerd'
                      : '${_selectedImages.length} afbeelding(en) geselecteerd',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedImages.map((image) {
                return Stack(
                  alignment: Alignment.topRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        image,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    ),
                    InkWell(
                      onTap: () => _removeSelectedImage(image),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _pickFiles,
                icon: const Icon(Icons.attach_file, size: 18),
                label: const Text('Bestand'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedFiles.isEmpty
                      ? 'Geen bestanden geselecteerd'
                      : '${_selectedFiles.length} bestand(en) geselecteerd',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (_selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedFiles.map((file) {
                return Chip(
                  label: Text(
                    _getFileName(file),
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () => _removeSelectedFile(file),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: EnhancedAccessibleTextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: 'Voeg een reactie toe...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
                        : Colors.grey[100],
                    counterText: "",
                  ),
                  maxLines: 1,
                  minLines: 1,
                  maxLength: 500,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) async {
                    final notifier = ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier);
                    final trimmedContent = _commentController.text.trim();
                    final hasImages = _selectedImages.isNotEmpty;
                    final hasFiles = _selectedFiles.isNotEmpty;
                    if (trimmedContent.isEmpty && !hasImages && !hasFiles) {
                      return;
                    }
                    await notifier.addComment(
                      trimmedContent,
                      imageFiles: _selectedImages,
                      fileFiles: _selectedFiles,
                    );
                    _commentController.clear();
                    _selectedImages.clear();
                    _selectedFiles.clear();
                    final latestComments =
                        ref.read(ohyoInteractionProvider(widget.ohyo.id)).comments;
                    if (latestComments.isNotEmpty) {
                      setState(() {
                        _comments = List.from(latestComments);
                        _currentOffset = latestComments.length;
                        _hasMoreComments = latestComments.length >= _commentsPerPage;
                      });
                    }
                  },
                  customTTSLabel: 'Reactie invoerveld',
                ),
              ),
              const SizedBox(width: 8),
              Consumer(
                builder: (context, ref, child) {
                  final isSubmitting = ref.watch(ohyoInteractionProvider(widget.ohyo.id)).isLoading;

                  return IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final trimmedContent = _commentController.text.trim();
                            final hasImages = _selectedImages.isNotEmpty;
                            final hasFiles = _selectedFiles.isNotEmpty;
                            if (trimmedContent.isEmpty && !hasImages && !hasFiles) {
                              return;
                            }
                            try {
                              await ref
                                  .read(ohyoInteractionProvider(widget.ohyo.id).notifier)
                                  .addComment(
                                    trimmedContent,
                                    imageFiles: _selectedImages,
                                    fileFiles: _selectedFiles,
                                  );
                              _commentController.clear();
                              _selectedImages.clear();
                              _selectedFiles.clear();
                              final latestComments =
                                  ref.read(ohyoInteractionProvider(widget.ohyo.id)).comments;
                              if (latestComments.isNotEmpty) {
                                setState(() {
                                  _comments = List.from(latestComments);
                                  _currentOffset = latestComments.length;
                                  _hasMoreComments = latestComments.length >= _commentsPerPage;
                                });
                              }
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
                          },
                    icon: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            Icons.send,
                            color: theme.colorScheme.primary,
                          ),
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

    final result = await Navigator.push<EditOhyoCommentResult>(
      context,
      MaterialPageRoute(
        builder: (context) => EditOhyoCommentScreen(
          comment: comment,
          contentController: contentController,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result?.shouldSave == true) {
      try {
        await ref.read(ohyoInteractionProvider(widget.ohyo.id).notifier)
            .updateComment(
              commentId: comment.id,
              content: result!.content,
              imageUrls: result.keptImageUrls,
              imageFiles: result.newImages,
              fileUrls: result.keptFileUrls,
              fileFiles: result.newFiles,
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

class EditOhyoCommentResult {
  final bool shouldSave;
  final String content;
  final List<String> keptImageUrls;
  final List<File> newImages;
  final List<String> keptFileUrls;
  final List<File> newFiles;

  const EditOhyoCommentResult({
    required this.shouldSave,
    required this.content,
    this.keptImageUrls = const [],
    this.newImages = const [],
    this.keptFileUrls = const [],
    this.newFiles = const [],
  });
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
  final List<File> _newImages = [];
  late List<String> _existingImageUrls;
  final List<File> _newFiles = [];
  late List<String> _existingFileUrls;

  @override
  void initState() {
    super.initState();
    _existingImageUrls = List<String>.from(widget.comment.imageUrls);
    _existingFileUrls = List<String>.from(widget.comment.fileUrls);
    // Automatically speak the screen content when it opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakScreenContent();
    });
  }

  Future<void> _speakScreenContent() async {
    // TTS implementation for ohyo comment editing screen
    // This is a placeholder for future accessibility enhancement
  }

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _newImages.addAll(images);
    });
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _newImages.add(image);
    });
  }

  void _removeNewImage(File image) {
    setState(() {
      _newImages.remove(image);
    });
  }

  void _removeExistingImage(String url) {
    setState(() {
      _existingImageUrls.remove(url);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _newFiles.addAll(files);
    });
  }

  void _removeNewFile(File file) {
    setState(() {
      _newFiles.remove(file);
    });
  }

  void _removeExistingFile(String url) {
    setState(() {
      _existingFileUrls.remove(url);
    });
  }

  String _getFileName(File file) {
    final path = file.path.replaceAll('\\', '/');
    final slashIndex = path.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == path.length - 1) {
      return path;
    }
    return path.substring(slashIndex + 1);
  }

  String _extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        final lastSegment = Uri.decodeComponent(uri.pathSegments.last);
        final separatorIndex = lastSegment.indexOf('__');
        if (separatorIndex != -1 && separatorIndex + 2 < lastSegment.length) {
          return lastSegment.substring(separatorIndex + 2);
        }
        return lastSegment;
      }
    } catch (_) {}
    return 'bestand';
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickImagesFromGallery();
          },
        );
      },
    );
  }

  Widget _buildImageThumbnail(String url) {
    final isLocalFile = url.startsWith('/') || url.startsWith('file://');
    if (isLocalFile) {
      final file = url.startsWith('file://') ? File.fromUri(Uri.parse(url)) : File(url);
      return Image.file(
        file,
        width: 70,
        height: 70,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 70,
      height: 70,
      fit: BoxFit.cover,
      placeholder: (context, _) => Container(
        width: 70,
        height: 70,
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      errorWidget: (context, _, _) => Container(
        width: 70,
        height: 70,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Icon(Icons.broken_image, size: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reactie Bewerken'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(
            context,
            EditOhyoCommentResult(
              shouldSave: false,
              content: widget.contentController.text.trim(),
              keptImageUrls: _existingImageUrls,
              newImages: _newImages,
              keptFileUrls: _existingFileUrls,
              newFiles: _newFiles,
            ),
          ),
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
                    const SizedBox(height: 16),
                    const Text(
                      'Afbeeldingen (optioneel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _showImageSourceSheet,
                      icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                      label: Text(
                        _newImages.isEmpty && _existingImageUrls.isEmpty
                            ? 'Afbeeldingen toevoegen'
                            : 'Meer afbeeldingen toevoegen',
                      ),
                    ),
                    if (_existingImageUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _existingImageUrls.map((url) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildImageThumbnail(url),
                              ),
                              InkWell(
                                onTap: () => _removeExistingImage(url),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    if (_newImages.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _newImages.map((image) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              InkWell(
                                onTap: () => _removeNewImage(image),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text(
                      'Bestanden (optioneel)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickFiles,
                      icon: const Icon(Icons.attach_file, size: 18),
                      label: Text(
                        _newFiles.isEmpty && _existingFileUrls.isEmpty
                            ? 'Bestanden toevoegen'
                            : 'Meer bestanden toevoegen',
                      ),
                    ),
                    if (_existingFileUrls.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _existingFileUrls.map((url) {
                          return Chip(
                            label: Text(
                              _extractFileNameFromUrl(url),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () => _removeExistingFile(url),
                          );
                        }).toList(),
                      ),
                    ],
                    if (_newFiles.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _newFiles.map((file) {
                          return Chip(
                            label: Text(
                              _getFileName(file),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () => _removeNewFile(file),
                          );
                        }).toList(),
                      ),
                    ],
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
                      onPressed: () => Navigator.pop(
                        context,
                        EditOhyoCommentResult(
                          shouldSave: false,
                          content: widget.contentController.text.trim(),
                          keptImageUrls: _existingImageUrls,
                          newImages: _newImages,
                          keptFileUrls: _existingFileUrls,
                          newFiles: _newFiles,
                        ),
                      ),
                      child: const Text('Annuleren', overflow: TextOverflow.visible),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        EditOhyoCommentResult(
                          shouldSave: true,
                          content: widget.contentController.text.trim(),
                          keptImageUrls: _existingImageUrls,
                          newImages: _newImages,
                          keptFileUrls: _existingFileUrls,
                          newFiles: _newFiles,
                        ),
                      ),
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
  final List<File> _selectedImages = [];
  final List<File> _selectedFiles = [];

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

  Future<void> _pickImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  Future<void> _captureImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _selectedImages.add(image);
    });
  }

  void _removeSelectedImage(File image) {
    setState(() {
      _selectedImages.remove(image);
    });
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _selectedFiles.addAll(files);
    });
  }

  void _removeSelectedFile(File file) {
    setState(() {
      _selectedFiles.remove(file);
    });
  }

  String _getFileName(File file) {
    final path = file.path.replaceAll('\\', '/');
    final slashIndex = path.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == path.length - 1) {
      return path;
    }
    return path.substring(slashIndex + 1);
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickImagesFromGallery();
          },
        );
      },
    );
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
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _showImageSourceSheet,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Afbeelding'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedImages.isEmpty
                                ? 'Geen afbeeldingen geselecteerd'
                                : '${_selectedImages.length} afbeelding(en) geselecteerd',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedImages.map((image) {
                          return Stack(
                            alignment: Alignment.topRight,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  image,
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              InkWell(
                                onTap: () => _removeSelectedImage(image),
                                child: Container(
                                  margin: const EdgeInsets.all(4),
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _pickFiles,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Bestand'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedFiles.isEmpty
                                ? 'Geen bestanden geselecteerd'
                                : '${_selectedFiles.length} bestand(en) geselecteerd',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedFiles.map((file) {
                          return Chip(
                            label: Text(
                              _getFileName(file),
                              overflow: TextOverflow.ellipsis,
                            ),
                            onDeleted: () => _removeSelectedFile(file),
                          );
                        }).toList(),
                      ),
                    ],
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
                            final trimmedContent = _replyController.text.trim();
                            final hasImages = _selectedImages.isNotEmpty;
                            final hasFiles = _selectedFiles.isNotEmpty;
                            if (trimmedContent.isEmpty && !hasImages && !hasFiles) {
                              return;
                            }
                            try {
                              await ref.read(ohyoInteractionProvider(widget.ohyoId).notifier)
                                  .addComment(
                                    trimmedContent,
                                    parentCommentId: widget.originalComment.id,
                                    imageFiles: _selectedImages,
                                    fileFiles: _selectedFiles,
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
