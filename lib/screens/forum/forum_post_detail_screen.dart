import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/forum_models.dart';
import '../../models/interaction_models.dart';
import '../../providers/forum_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accessibility_provider.dart';
import '../../widgets/enhanced_accessible_text.dart';
import '../../providers/permission_provider.dart';
import '../../providers/interaction_provider.dart';
import '../../providers/network_provider.dart';
import '../../widgets/avatar_widget.dart';
import '../../services/unified_tts_service.dart';
import '../../widgets/threaded_comment_widget.dart';
import '../../utils/comment_threading_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/image_utils.dart';
import '../../widgets/media_source_bottom_sheet.dart';
import '../../widgets/image_gallery.dart';
import '../../services/offline_media_cache_service.dart';

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
  final List<File> _selectedCommentImages = [];
  final List<File> _selectedCommentFiles = [];

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

      setState(() {
        _post = post;
        _isLoading = false;
        _comments = [];
        _currentOffset = 0;
        _hasMoreComments = true;
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

  Future<void> _pickCommentImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _selectedCommentImages.addAll(images);
    });
  }

  Future<void> _captureCommentImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _selectedCommentImages.add(image);
    });
  }

  void _removeCommentImage(File image) {
    setState(() {
      _selectedCommentImages.remove(image);
    });
  }

  void _showCommentImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureCommentImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickCommentImagesFromGallery();
          },
        );
      },
    );
  }

  Future<void> _pickCommentFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _selectedCommentFiles.addAll(files);
    });
  }

  void _removeCommentFile(File file) {
    setState(() {
      _selectedCommentFiles.remove(file);
    });
  }

  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty) {
        return uri.pathSegments.last;
      }
    } catch (_) {}
    return url;
  }

  Future<void> _openAttachment(String url) async {
    final isConnected = ref.read(isConnectedProvider);
    String openUrl = url;
    if (!isConnected) {
      final cachedPath = OfflineMediaCacheService.getCachedFilePath(url, false);
      if (cachedPath != null) {
        openUrl = Uri.file(cachedPath).toString();
      }
    }
    final uri = Uri.parse(openUrl);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }


  Future<void> _submitComment() async {
    final trimmedContent = _commentController.text.trim();
    final hasAttachments =
        _selectedCommentImages.isNotEmpty || _selectedCommentFiles.isNotEmpty;
    if (trimmedContent.isEmpty && !hasAttachments) {
      return;
    }

    // Check if we're online
    final isConnected = ref.read(isConnectedProvider);
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Je kunt geen reacties plaatsen zonder internetverbinding'),
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
      await ref.read(forumNotifierProvider.notifier).addComment(
            postId: widget.postId,
            content: trimmedContent,
            parentCommentId: _replyingToComment?.id,
            imageFiles: _selectedCommentImages,
            fileFiles: _selectedCommentFiles,
          );

      _commentController.clear();
      _selectedCommentImages.clear();
      _selectedCommentFiles.clear();
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

  Color _getCategoryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
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
      error: (error, stackTrace) => false,
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
        mainAxisSize: MainAxisSize.min,
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
                          style: TextStyle(
                            color: _getCategoryTextColor(context),
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
                  tooltip: 'Menu tonen',
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
          Consumer(
            builder: (context, ref, child) {
              // Check if this is a fake account (sensei, student) that should always show initials
              final authorNameLower = post.authorName.toLowerCase();
              final isFakeAccount = authorNameLower.contains('sensei') || 
                                   authorNameLower.contains('student');
              
              // Get current user to check if this post is by current user
              final currentUser = ref.watch(authUserProvider);
              // Only treat as current user if it's NOT a fake account
              final isCurrentUser = !isFakeAccount && 
                                   currentUser?.id == post.authorId;
              
              String? avatarUrlToShow;
              String? avatarIdToShow;
              
              // Always show initials for fake accounts (sensei, student)
              if (isFakeAccount) {
                avatarIdToShow = null;
                avatarUrlToShow = null;
              } else if (isCurrentUser && currentUser != null) {
                // For current user (Anne-Linde de Groot), get avatar from their profile metadata
                final metadata = currentUser.userMetadata ?? {};
                final avatarType = metadata['avatar_type'] as String?;
                
                if (avatarType == 'custom') {
                  avatarUrlToShow = metadata['avatar_url'] as String? ?? 
                                   metadata['custom_avatar_url'] as String?;
                  avatarIdToShow = null;
                } else if (avatarType == 'preset') {
                  // Only use preset avatar if explicitly set
                  avatarIdToShow = metadata['preset_avatar_id'] as String? ?? 
                                 metadata['avatar_id'] as String?;
                  avatarUrlToShow = null;
                } else {
                  // If avatar_type is null or not set, don't use any preset avatar
                  // This will fall back to initials
                  avatarIdToShow = null;
                  avatarUrlToShow = null;
                }
              } else {
                // For other real users (verified accounts), use stored avatar from post
                // If they have an avatar set, show it; otherwise show initials
                if (post.authorAvatar != null && post.authorAvatar!.isNotEmpty) {
                  final isUrl = post.authorAvatar!.startsWith('http://') || 
                              post.authorAvatar!.startsWith('https://') ||
                              post.authorAvatar!.startsWith('file://') ||
                              post.authorAvatar!.startsWith('/');
                  
                  if (isUrl) {
                    avatarUrlToShow = post.authorAvatar;
                    avatarIdToShow = null;
                  } else {
                    // It's an avatar ID
                    avatarIdToShow = post.authorAvatar;
                    avatarUrlToShow = null;
                  }
                } else {
                  // No avatar stored - show initials
                  avatarIdToShow = null;
                  avatarUrlToShow = null;
                }
              }
              
              return Row(
            children: [
              AvatarWidget(
                    customAvatarUrl: avatarUrlToShow,
                    avatarId: avatarIdToShow,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ],
              );
            },
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
              final isConnected = ref.watch(isConnectedProvider);

              // Get text scale factor for accessibility
              final textScaler = MediaQuery.of(context).textScaler;
              final scaleFactor = textScaler.scale(1.0); // Get the scale factor

              // Check if dyslexia font is enabled to adjust scaling
              final isDyslexiaFriendly = ref.watch(accessibilityNotifierProvider).isDyslexiaFriendly;

              // Dyslexia fonts need more space due to wider character spacing
              final dyslexiaAdjustment = isDyslexiaFriendly ? 1.1 : 1.0;

              final scaledPadding = 12 * scaleFactor.clamp(1.0, 2.0) * dyslexiaAdjustment;
              final scaledFontSize = (12 * scaleFactor).clamp(12.0, 20.0) * dyslexiaAdjustment;
              final scaledIconSize = (16 * scaleFactor).clamp(16.0, 24.0);

              return ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: 44,
                  maxHeight: double.infinity, // Allow flexible height
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(vertical: 4), // Add vertical padding for flexibility
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                    // Like button
                    GestureDetector(
                      onTap: (isLoading || !isConnected)
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
                        constraints: BoxConstraints(
                          minWidth: 60 * scaleFactor.clamp(1.0, 1.8),
                          minHeight: 32 + (scaleFactor - 1) * 8,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: scaledPadding,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !isConnected
                              ? Colors.grey.withValues(alpha: 0.05)
                              : isLiked
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isConnected
                                ? Colors.grey.withValues(alpha: 0.2)
                                : isLiked ? Colors.red : Colors.grey,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              size: scaledIconSize,
                              color: !isConnected
                                  ? Colors.grey[400]
                                  : isLiked ? Colors.red : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$likeCount',
                              style: TextStyle(
                                color: !isConnected
                                    ? Colors.grey[400]
                                    : isLiked ? Colors.red : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: scaledFontSize,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scaleFactor.clamp(1.0, 1.2)),

                    // Favorite button
                    GestureDetector(
                      onTap: (isLoading || !isConnected)
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
                        constraints: BoxConstraints(
                          minWidth: 60 * scaleFactor.clamp(1.0, 1.8),
                          minHeight: 32 + (scaleFactor - 1) * 8,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: scaledPadding,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: !isConnected
                              ? Colors.grey.withValues(alpha: 0.05)
                              : isFavorited
                                  ? Colors.teal.shade400.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: !isConnected
                                ? Colors.grey.withValues(alpha: 0.2)
                                : isFavorited
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
                              size: scaledIconSize,
                              color: !isConnected
                                  ? Colors.grey[400]
                                  : isFavorited
                                      ? Colors.teal.shade400
                                      : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFavorited ? 'Opgeslagen' : 'Opslaan',
                              style: TextStyle(
                                color: !isConnected
                                    ? Colors.grey[400]
                                    : isFavorited
                                        ? Colors.teal.shade400
                                        : Colors.grey[600],
                                fontWeight: FontWeight.w500,
                                fontSize: scaledFontSize,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 8 * scaleFactor.clamp(1.0, 1.2)),

                    // Comment count display
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: scaledPadding,
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
                            size: scaledIconSize,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                              fontSize: scaledFontSize,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPostImageThumbnail(String url) {
    final isLocalFile = url.startsWith('/') || url.startsWith('file://');
    if (isLocalFile) {
      final file = url.startsWith('file://') ? File.fromUri(Uri.parse(url)) : File(url);
      return Image.file(
        file,
        width: 90,
        height: 90,
        fit: BoxFit.cover,
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      memCacheWidth: 180,
      memCacheHeight: 180,
      placeholder: (context, _) => Container(
        width: 90,
        height: 90,
        color: Colors.grey.withValues(alpha: 0.1),
      ),
      errorWidget: (context, _, _) => Container(
        width: 90,
        height: 90,
        color: Colors.grey.withValues(alpha: 0.1),
        child: const Icon(Icons.broken_image, size: 18),
      ),
    );
  }

  Widget _buildPostImagePreview(List<String> imageUrls) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(imageUrls.length, (index) {
        final url = imageUrls[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ImageGallery(
                  imageUrls: imageUrls,
                  initialIndex: index,
                  title: 'Afbeeldingen',
                ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildPostImageThumbnail(url),
          ),
        );
      }),
    );
  }

  Widget _buildFileAttachments(List<String> fileUrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fileUrls.map((url) {
        final fileName = _extractFileName(url);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(
            fileName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.open_in_new, size: 18),
          onTap: () => _openAttachment(url),
        );
      }).toList(),
    );
  }

  Widget _buildPostContent(ForumPost post) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            post.content,
            style: const TextStyle(fontSize: 16, height: 1.6),
          ),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildPostImagePreview(post.imageUrls),
          ],
          if (post.fileUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildFileAttachments(post.fileUrls),
          ],
        ],
      ),
    );
  }

  Widget _buildCommentSection(ForumPost post) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + (_post!.isLocked ? 0 : 90)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // Comments header
        Consumer(
          builder: (context, ref, child) {
            final textScaler = MediaQuery.of(context).textScaler;
            final scaleFactor = textScaler.scale(1.0);

            // Check if dyslexia font is enabled
            final isDyslexiaFriendly = ref.watch(accessibilityNotifierProvider).isDyslexiaFriendly;
            final dyslexiaAdjustment = isDyslexiaFriendly ? 1.1 : 1.0;

            final scaledFontSize = (18 * scaleFactor).clamp(18.0, 28.0) * dyslexiaAdjustment;
            final scaledIconSize = (24 * scaleFactor).clamp(24.0, 32.0); // Default icon size is 24
            final scaledPadding = 16 * scaleFactor.clamp(1.0, 1.5);

            return Container(
              padding: EdgeInsets.all(scaledPadding),
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
                    size: scaledIconSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8 * scaleFactor.clamp(1.0, 1.2)),
                  Expanded(
                    child: Text(
                      '${_comments.length} Reactie${_comments.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: scaledFontSize,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            );
          },
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
                  cacheExtent: context.isMobile ? 600 : 800,
                  itemCount: threadedComments.length + (_isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Show loading indicator at the end
                    if (index == threadedComments.length) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        child: const CircularProgressIndicator(),
                      );
                    }

                    final threadedComment = threadedComments[index];
                    return ThreadedCommentWidget<ForumComment>(
                      threadedComment: threadedComment,
                      isCommentAuthor: (comment) => comment.authorId == ref.watch(authUserProvider)?.id,
                      getAuthorId: (comment) => comment.authorId,
                      canDeleteComment: () {
                          final currentUser = ref.watch(authUserProvider);
                          final canModerateAsync = ref.watch(canModerateProvider);
                          final isCommentAuthor = threadedComment.comment.authorId == currentUser?.id;
                          final isPostAuthor = _post!.authorId == currentUser?.id;
                          final canModerate = canModerateAsync.when(
                            data: (value) => value,
                            loading: () => false,
                            error: (error, stackTrace) => false,
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
                        getImageUrls: (comment) => comment.imageUrls,
                        getFileUrls: (comment) => comment.fileUrls,
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
              content: Text('Bericht "${post.title}" succesvol verwijderd'),
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
              content: Text('Reactie succesvol verwijderd'),
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
              content: Text('Bericht succesvol bijgewerkt'),
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
              content: Text('Reactie succesvol bijgewerkt'),
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
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Terug',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                final isConnected = ref.watch(isConnectedProvider);
                final pendingOperations = ref.watch(forumPendingOperationsProvider);
                final hasPendingOperations = pendingOperations > 0;
                return Row(
                  children: [
                    if (!isConnected)
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
                    if (hasPendingOperations)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.sync, size: 16, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text(
                              '$pendingOperations',
                              style: const TextStyle(
                                color: Colors.blue,
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
                        });
                        await _loadPost();
                      },
                      tooltip: 'Vernieuwen',
                    ),
                  ],
                );
              },
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
                body: _buildCommentSection(_post!),
              ),
            ),

            // Fixed comment input at bottom (if not locked)
            if (!_post!.isLocked)
              Consumer(
                builder: (context, ref, child) {
                  final isConnected = ref.watch(isConnectedProvider);
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.90),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isConnected)
                            Container(
                              width: double.infinity,
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
                                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Offline: reacties kunnen niet worden geplaatst',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: isConnected ? _showCommentImageSourceSheet : null,
                                icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                                label: const Text('Afbeelding'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCommentImages.isEmpty
                                      ? 'Geen afbeeldingen geselecteerd'
                                      : '${_selectedCommentImages.length} afbeelding(en) geselecteerd',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCommentImages.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _selectedCommentImages.map((image) {
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
                                      onTap: () => _removeCommentImage(image),
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
                                onPressed: isConnected ? _pickCommentFiles : null,
                                icon: const Icon(Icons.attach_file, size: 18),
                                label: const Text('Bestand'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedCommentFiles.isEmpty
                                      ? 'Geen bestanden geselecteerd'
                                      : '${_selectedCommentFiles.length} bestand(en) geselecteerd',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          if (_selectedCommentFiles.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Column(
                              children: _selectedCommentFiles.map((file) {
                                final fileName = file.path.split('/').last;
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () => _removeCommentFile(file),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                          Row(
                            children: [
                              Expanded(
                                child: EnhancedAccessibleTextField(
                                  controller: _commentController,
                                  focusNode: _commentFocusNode,
                                  decoration: InputDecoration(
                                    hintText: !isConnected
                                        ? 'Offline'
                                        : _replyingToComment != null
                                            ? 'Reageer op ${_replyingToComment!.authorName}...'
                                            : 'Schrijf een reactie...',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    filled: true,
                                    fillColor: !isConnected
                                        ? Colors.grey.withValues(alpha: 0.1)
                                        : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                                    counterText: "",
                                  ),
                                  maxLines: 5,
                                  minLines: 1,
                                  maxLength: 1000,
                                  textInputAction: TextInputAction.newline,
                                  onSubmitted: !isConnected ? null : (_) => _submitComment(),
                                  customTTSLabel: 'Reactie invoerveld',
                                  enabled: isConnected,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: (_isSubmittingComment || !isConnected)
                                    ? null
                                    : _submitComment,
                                icon: _isSubmittingComment
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Icon(
                                        Icons.send,
                                        color: !isConnected
                                          ? Colors.grey
                                          : Theme.of(context).colorScheme.primary
                                      ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
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
                      child: const Text('Annuleren', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Opslaan', overflow: TextOverflow.ellipsis),
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
                        final textColor = Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black;

                        return DropdownButtonFormField<ForumCategory>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Categorie',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          ),
                          isExpanded: true,
                          style: accessibleStyle.copyWith(color: textColor),
                          items: ForumCategory.values.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Container(
                                constraints: const BoxConstraints(minHeight: 48),
                                child: Text(
                                  category.displayName,
                                  style: accessibleStyle.copyWith(color: textColor),
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
                      child: const Text('Annuleren', overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 100),
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, EditPostResult(shouldSave: true, selectedCategory: _selectedCategory)),
                      child: const Text('Opslaan', overflow: TextOverflow.ellipsis),
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
  final List<File> _selectedReplyImages = [];
  final List<File> _selectedReplyFiles = [];

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

  Future<void> _pickReplyImagesFromGallery() async {
    final images = await ImageUtils.pickMultipleImagesFromGallery();
    if (images.isEmpty) return;
    setState(() {
      _selectedReplyImages.addAll(images);
    });
  }

  Future<void> _captureReplyImageWithCamera() async {
    final image = await ImageUtils.captureImageWithCamera(context: context);
    if (image == null) return;
    setState(() {
      _selectedReplyImages.add(image);
    });
  }

  void _removeReplyImage(File image) {
    setState(() {
      _selectedReplyImages.remove(image);
    });
  }

  void _showReplyImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return MediaSourceBottomSheet(
          title: 'Afbeelding toevoegen',
          onCameraSelected: () async {
            Navigator.pop(context);
            await _captureReplyImageWithCamera();
          },
          onGallerySelected: () async {
            Navigator.pop(context);
            await _pickReplyImagesFromGallery();
          },
        );
      },
    );
  }

  Future<void> _pickReplyFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );
    if (result == null || result.files.isEmpty) return;
    final files = result.files
        .where((file) => file.path != null)
        .map((file) => File(file.path!))
        .toList();
    if (files.isEmpty) return;
    setState(() {
      _selectedReplyFiles.addAll(files);
    });
  }

  void _removeReplyFile(File file) {
    setState(() {
      _selectedReplyFiles.remove(file);
    });
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
                          onPressed: _showReplyImageSourceSheet,
                          icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                          label: const Text('Afbeelding'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedReplyImages.isEmpty
                                ? 'Geen afbeeldingen geselecteerd'
                                : '${_selectedReplyImages.length} afbeelding(en) geselecteerd',
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
                    if (_selectedReplyImages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedReplyImages.map((image) {
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
                                onTap: () => _removeReplyImage(image),
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
                          onPressed: _pickReplyFiles,
                          icon: const Icon(Icons.attach_file, size: 18),
                          label: const Text('Bestand'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _selectedReplyFiles.isEmpty
                                ? 'Geen bestanden geselecteerd'
                                : '${_selectedReplyFiles.length} bestand(en) geselecteerd',
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
                    if (_selectedReplyFiles.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Column(
                        children: _selectedReplyFiles.map((file) {
                          final fileName = file.path.split('/').last;
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.description_outlined),
                            title: Text(
                              fileName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => _removeReplyFile(file),
                            ),
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
                      final isSubmitting = ref.watch(forumNotifierProvider).isLoading;

                      return ElevatedButton(
                        onPressed: isSubmitting ? null : () async {
                          final trimmedContent = _replyController.text.trim();
                          final hasAttachments =
                              _selectedReplyImages.isNotEmpty || _selectedReplyFiles.isNotEmpty;
                          if (trimmedContent.isEmpty && !hasAttachments) {
                            return;
                          }
                          try {
                            await ref.read(forumNotifierProvider.notifier)
                                .addComment(
                                  postId: widget.forumPostId,
                                  content: trimmedContent,
                                  parentCommentId: widget.originalComment.id,
                                  imageFiles: _selectedReplyImages,
                                  fileFiles: _selectedReplyFiles,
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
