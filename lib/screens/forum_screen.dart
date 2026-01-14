import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/accessibility_provider.dart';
import '../providers/network_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/skeleton_forum_post.dart';
import '../widgets/responsive_layout.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/app_router.dart';
import 'forum_post_detail_screen.dart';
import 'create_forum_post_screen.dart';
import '../widgets/enhanced_accessible_text.dart';

class ForumScreen extends ConsumerStatefulWidget {
  const ForumScreen({super.key});

  @override
  ConsumerState<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends ConsumerState<ForumScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int? _selectedPostId;
  ForumCategory? _localSelectedCategory; // Local state for category selection

  @override
  void initState() {
    super.initState();
    // Initialize local state with provider state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerCategory = ref.read(forumSelectedCategoryProvider);
      final providerSearchQuery = ref.read(forumSearchQueryProvider);
      if (mounted) {
        setState(() {
          _localSelectedCategory = providerCategory;
        });
        // Synchronize search controller with provider state
        _searchController.text = providerSearchQuery;
        // Re-apply search if there was a previous search query
        if (providerSearchQuery.isNotEmpty) {
          _filterPosts(providerSearchQuery);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _refreshPosts() async {
    await ref.read(forumNotifierProvider.notifier).refreshPosts();
  }

  void _filterPosts(String query) {
    ref.read(forumNotifierProvider.notifier).searchPosts(query);
  }

  void _filterByCategory(ForumCategory? category) {
    setState(() {
      _localSelectedCategory = category;
    });
    ref.read(forumNotifierProvider.notifier).filterByCategory(category);
  }

  Future<void> _speakForumPostContent(ForumPost post) async {
    try {
      final accessibilityState = ref.read(accessibilityNotifierProvider);
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      // Only speak if TTS is enabled
      if (!accessibilityState.isTextToSpeechEnabled) {
        // Silent: TTS status not logged
        return;
      }

      // Build comprehensive content for TTS
      final content = StringBuffer();
      content.write('Forum Post: ${post.title}. ');
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

      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking forum post content: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _deletePost(ForumPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ResponsiveDialog(
        title: 'Verwijder "${post.title}"?',
        child: const Text(
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
            child: const Text('Verwijderen'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(forumNotifierProvider.notifier).deletePost(post.id);
        if (mounted) {
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
              content: Text('Fout bij verwijderen bericht: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _togglePinPost(ForumPost post) async {
    try {
      await ref.read(forumNotifierProvider.notifier).togglePinPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              post.isPinned 
                ? 'Bericht losgemaakt' 
                : 'Bericht vastgemaakt'
            ),
            backgroundColor: Colors.green,
          ),
        );
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
  }

  Future<void> _toggleLockPost(ForumPost post) async {
    try {
      await ref.read(forumNotifierProvider.notifier).toggleLockPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              post.isLocked 
                ? 'Bericht ontgrendeld' 
                : 'Bericht vergrendeld'
            ),
            backgroundColor: Colors.green,
          ),
        );
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
  }

  Widget _buildCategoryFilter() {
    // Use local state instead of provider state for immediate UI updates
    final selectedCategory = _localSelectedCategory;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Always use horizontal scroll to ensure all categories are visible
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCategoryButton(
                    category: null,
                    label: 'Alle Berichten',
                    isSelected: selectedCategory == null,
                    onTap: () => _filterByCategory(null),
                  ),
                  const SizedBox(width: 8),
                  ...ForumCategory.values.map((category) =>
                    _buildCategoryButton(
                      category: category,
                      label: category.displayName,
                      isSelected: selectedCategory == category,
                      onTap: () => _filterByCategory(category),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Add some padding at the bottom for better spacing
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required ForumCategory? category,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(
        label: isSelected ? '$label (geselecteerd)' : label,
        button: true,
        selected: isSelected,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: BoxConstraints(
                minWidth: context.responsiveValue(mobile: 90, tablet: 100, desktop: 110),
                minHeight: context.responsiveValue(mobile: 44, tablet: 48, desktop: 52),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: context.responsiveValue(mobile: 12, tablet: 16, desktop: 20),
                vertical: context.responsiveValue(mobile: 10, tablet: 12, desktop: 14),
              ),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected
                    ? null
                    : Colors.grey[800]?.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF4CAF50)
                      : Colors.grey[600]!.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.6),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                    spreadRadius: 2,
                  ),
                ] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Always reserve space for check icon to maintain consistent sizing
                  SizedBox(
                    width: 20, // Fixed width for icon space
                    child: isSelected ? Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: const Color(0xFF4CAF50),
                      ),
                    ) : null,
                  ),
                  if (isSelected) const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : Colors.grey[300],
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: context.responsiveValue(mobile: 12, tablet: 13, desktop: 14),
                        shadows: isSelected ? [
                          Shadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                          ),
                        ] : null,
                      ),
                      overflow: TextOverflow.visible,
                      maxLines: 2, // Allow up to 2 lines for longer category names
                      softWrap: true,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(ForumPost post) {
    final currentUser = ref.watch(authUserProvider);
    final canModerateAsync = ref.watch(canModerateProvider);
    final canModerateRole = canModerateAsync.when(
      data: (value) => value,
      loading: () => false,
      error: (error, stackTrace) => false,
    );
    final canModerate = canModerateRole || (currentUser != null && post.authorId == currentUser.id);
    final isSelected = context.isDesktop && _selectedPostId == post.id;
    final accessibilityState = ref.watch(accessibilityNotifierProvider);

    return Semantics(
      label: 'Forum bericht: ${post.title}, categorie: ${post.category.displayName}, door ${post.authorName}',
      button: true,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 20, // Prevent overflow on any screen
        ),
        child: Card(
          margin: EdgeInsets.symmetric(
            horizontal: context.responsiveValue(mobile: 10.0, tablet: 8.0, desktop: 6.0),
            vertical: context.responsiveValue(mobile: 6.0, tablet: 4.0, desktop: 3.0),
          ),
          elevation: isSelected ? 8 : 2,
          color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected
              ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
              : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              _speakForumPostContent(post);
              if (context.isDesktop) {
                // Master-detail mode: select post for detail view
                setState(() {
                  _selectedPostId = post.id;
                });
              } else {
                // Mobile mode: navigate to detail screen (works offline with cached posts)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ForumPostDetailScreen(postId: post.id),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and actions
                Row(
                  children: [
                    // Category badge
                    Semantics(
                      label: 'Categorie: ${post.category.displayName}',
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: post.category == ForumCategory.events
                              ? (accessibilityState.fontSize == AccessibilityFontSize.extraLarge || accessibilityState.isDyslexiaFriendly ? 240 : 200)
                              : (post.category.displayName.length > 15 ? 140 : 120),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                              vertical: post.category == ForumCategory.events
                                ? (accessibilityState.fontSize == AccessibilityFontSize.extraLarge || accessibilityState.isDyslexiaFriendly ? 9 : 7)
                                : (post.category.displayName.length > 20 ? 6 : 5),
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(post.category),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            post.category == ForumCategory.events
                                ? 'Evenementen\n&\nAankondigingen'
                                : post.category.displayName,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: post.category == ForumCategory.events && (accessibilityState.fontSize == AccessibilityFontSize.extraLarge || accessibilityState.isDyslexiaFriendly)
                                  ? 14
                                  : 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: post.category == ForumCategory.events ? 3 : (post.category.displayName.length > 15 ? 2 : 1),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Pin indicator
                  if (post.isPinned)
                    Semantics(
                      label: 'Vastgemaakt bericht',
                      child: const Icon(Icons.push_pin, color: Colors.orange, size: 16),
                    ),
                  // Lock indicator
                  if (post.isLocked)
                    Semantics(
                      label: 'Vergrendeld bericht',
                      child: const Icon(Icons.lock, color: Colors.red, size: 16),
                    ),
                  // Actions menu
                  if (canModerate)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'pin':
                            _togglePinPost(post);
                            break;
                          case 'lock':
                            _toggleLockPost(post);
                            break;
                          case 'delete':
                            _deletePost(post);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'pin',
                          child: Row(
                            children: [
                              Icon(post.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
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
                              Text(post.isLocked ? 'Ontgrendelen' : 'Vergrendelen'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Verwijderen',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Semantics(
                label: 'Bericht titel: ${post.title}',
                child: Text(
                  post.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  maxLines: 3,
                ),
              ),
              const SizedBox(height: 10),
              
              // Content preview
              Semantics(
                label: 'Bericht inhoud: ${post.content}',
                child: Text(
                  post.content,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Footer with author and stats - redesigned for better spacing
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author info row
                  Row(
                        children: [
                          Semantics(
                            label: 'Auteur avatar voor ${post.authorName}',
                            child: AvatarWidget(
                          customAvatarUrl: post.authorAvatar,
                              userName: post.authorName,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Semantics(
                                  label: 'Auteur: ${post.authorName}',
                                  child: Text(
                                    post.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 2),
                            Semantics(
                              label: 'Geplaatst op: ${_formatDate(post.createdAt)}',
                              child: Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Interaction buttons row - responsive layout to prevent overflow
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final availableWidth = constraints.maxWidth;
                      const buttonSpacing = 8.0;
                      const estimatedButtonWidth = 85.0; // Estimated width per button (increased for safety)
                      const viewTextWidth = 105.0; // Estimated width for "Bekijk bericht" (increased for safety)

                      // Calculate how many buttons we can fit with a small buffer
                      final maxButtons = ((availableWidth - viewTextWidth - buttonSpacing * 2 - 10) / (estimatedButtonWidth + buttonSpacing)).floor();
                      final showAllButtons = maxButtons >= 3;

                      if (showAllButtons) {
                        return Row(
                          children: [
                            // Like button
                            Consumer(
                              builder: (context, ref, child) {
                                final forumInteraction = ref.watch(forumInteractionProvider(post.id));
                                final isLiked = forumInteraction.isLiked;
                                final likeCount = forumInteraction.likeCount;
                                final isLoading = forumInteraction.isLoading;
                                final isConnected = ref.watch(isConnectedProvider);

                                return GestureDetector(
                                  onTap: (isLoading || !isConnected) ? null : () async {
                                    try {
                                      await ref.read(forumInteractionProvider(post.id).notifier).toggleLike();
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !isConnected
                                        ? Colors.grey.withValues(alpha: 0.05)
                                        : isLiked
                                          ? Colors.red.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: !isConnected
                                          ? Colors.grey.withValues(alpha: 0.2)
                                          : isLiked ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 14,
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
                                              : isLiked ? Colors.red : Colors.grey[700],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // Favorite button
                            Consumer(
                              builder: (context, ref, child) {
                                final forumInteraction = ref.watch(forumInteractionProvider(post.id));
                                final isFavorited = forumInteraction.isFavorited;
                                final isLoading = forumInteraction.isLoading;
                                final isConnected = ref.watch(isConnectedProvider);

                                return GestureDetector(
                                  onTap: (isLoading || !isConnected) ? null : () async {
                                    try {
                                      await ref.read(forumInteractionProvider(post.id).notifier).toggleFavorite();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isFavorited ? 'Verwijderd uit favorieten' : 'Toegevoegd aan favorieten'
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
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: !isConnected
                                        ? Colors.grey.withValues(alpha: 0.05)
                                        : isFavorited
                                          ? Colors.teal.withValues(alpha: 0.1)
                                          : Colors.grey.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: !isConnected
                                          ? Colors.grey.withValues(alpha: 0.2)
                                          : isFavorited ? Colors.teal.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Icon(
                                      isFavorited ? Icons.bookmark : Icons.bookmark_border,
                                      size: 14,
                                      color: !isConnected
                                        ? Colors.grey[400]
                                        : isFavorited ? Colors.teal : Colors.grey[600],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 8),

                            // Comment count
                            Consumer(
                              builder: (context, ref, child) {
                                final textScaler = MediaQuery.of(context).textScaler;
                                final scaleFactor = textScaler.scale(1.0);

                              // Check if dyslexia font is enabled
                              final isDyslexiaFriendly = ref.watch(accessibilityNotifierProvider).isDyslexiaFriendly;
                              final dyslexiaAdjustment = isDyslexiaFriendly ? 1.1 : 1.0;

                                final scaledPadding = 10 * scaleFactor.clamp(1.0, 2.0) * dyslexiaAdjustment;
                                final scaledIconSize = (14 * scaleFactor).clamp(14.0, 20.0);
                                final scaledFontSize = (12 * scaleFactor).clamp(12.0, 18.0) * dyslexiaAdjustment;

                                return Container(
                                  constraints: BoxConstraints(
                                    minWidth: 50 * scaleFactor.clamp(1.0, 1.8),
                                    minHeight: 32 + (scaleFactor - 1) * 8,
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: scaledPadding,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                        size: scaledIconSize,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                      SizedBox(width: 4 * scaleFactor.clamp(1.0, 1.2)),
                                      Text(
                                        '${post.commentCount}',
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontSize: scaledFontSize,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            const Spacer(),

                            // View text
                            Text(
                              'Bekijk bericht',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        );
                      } else {
                        // Compact layout - show only essential buttons
                        return Row(
                          children: [
                            // Like button only
                            Consumer(
                              builder: (context, ref, child) {
                                final forumInteraction = ref.watch(forumInteractionProvider(post.id));
                                final isLiked = forumInteraction.isLiked;
                                final likeCount = forumInteraction.likeCount;
                                final isLoading = forumInteraction.isLoading;

                                return GestureDetector(
                                  onTap: isLoading ? null : () async {
                                    try {
                                      await ref.read(forumInteractionProvider(post.id).notifier).toggleLike();
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
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLiked
                                        ? Colors.red.withValues(alpha: 0.1)
                                        : Colors.grey.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isLiked ? Colors.red.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 12,
                                          color: isLiked ? Colors.red : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          '$likeCount',
                                          style: TextStyle(
                                            color: isLiked ? Colors.red : Colors.grey[700],
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const Spacer(),

                            // Comment count and view text combined
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.comment_outlined, size: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                const SizedBox(width: 2),
                                Text(
                                  '${post.commentCount}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Bekijk',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
        ),
      );
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



  /// Get appropriate icon for font size
  IconData _getFontSizeIcon(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return Icons.text_decrease;
      case AccessibilityFontSize.normal:
        return Icons.text_fields;
      case AccessibilityFontSize.large:
        return Icons.text_increase;
      case AccessibilityFontSize.extraLarge:
        return Icons.format_size;
    }
  }

  Widget _buildForumList(List<ForumPost> posts, bool isLoading, String? error) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: EdgeInsets.all(context.responsiveValue(mobile: 16.0, tablet: 12.0, desktop: 8.0)),
          child: SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 56, // Minimum height for single line
                maxHeight: 120, // Maximum height for 3 lines
              ),
              child: EnhancedAccessibleTextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                maxLines: 3, // Allow multiple lines to show full text
                minLines: 1, // Start with single line
                decoration: InputDecoration(
                  hintText: 'Zoek berichten...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: context.responsiveValue(mobile: 20.0, tablet: 22.0, desktop: 24.0),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(context.responsiveValue(mobile: 25.0, tablet: 28.0, desktop: 30.0))),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onChanged: _filterPosts,
                customTTSLabel: 'Zoek berichten invoerveld',
              ),
            ),
          ),
        ),
        
        // Category filter
        _buildCategoryFilter(),
        const SizedBox(height: 8),
        
        // Error display
        if (error != null)
          Container(
            margin: EdgeInsets.all(context.responsiveValue(mobile: 16.0, tablet: 12.0, desktop: 8.0)),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Fout: $error',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(forumNotifierProvider.notifier).clearError();
                  },
                  child: const Text('Sluiten'),
                ),
              ],
            ),
          ),
        
        // Posts list
        Expanded(
          child: isLoading
              ? const SkeletonForumList(itemCount: 5)
              : RefreshIndicator(
                  onRefresh: _refreshPosts,
                  child: posts.isEmpty
                      ? const Center(
                          child: Text(
                            'Geen berichten gevonden',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.only(
                            left: context.responsiveValue(mobile: 8.0, tablet: 6.0, desktop: 4.0),
                            right: context.responsiveValue(mobile: 8.0, tablet: 6.0, desktop: 4.0),
                            bottom: 16.0,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            return _buildPostCard(posts[index]);
                          },
                        ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailView() {
    if (_selectedPostId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.forum, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Selecteer een bericht om de details te bekijken',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // For now, show a simple placeholder. In a full implementation,
    // you would create an embedded version of the detail screen
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Post Details',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text(
            'Post ID: $_selectedPostId',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          const Text(
            'This is a placeholder for the embedded post detail view. '
            'In a full implementation, this would show the complete post content, '
            'comments, and interaction options.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(forumPostsProvider);
    final isLoading = ref.watch(forumLoadingProvider);
    final error = ref.watch(forumErrorProvider);

    return GestureDetector(
      onTap: () {
        _searchFocusNode.unfocus();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, child) {
            final accessibilityState = ref.watch(accessibilityNotifierProvider);
            final isExtraLarge = accessibilityState.fontSize == AccessibilityFontSize.extraLarge;
            final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
            
            // For dyslexia + extra large: keep Forum text large (don't reduce)
            // For other cases: use default or larger sizes
            double? fontSize;
            if (isDyslexiaFriendly && isExtraLarge) {
              // Keep it large even with dyslexia + extra large
              fontSize = 22.0; // Large font size
            } else if (isExtraLarge) {
              fontSize = 24.0; // Extra large for regular font
            } else if (accessibilityState.fontSize == AccessibilityFontSize.large) {
              fontSize = 22.0; // Large size
            } else {
              fontSize = null; // Use default
            }
            
            return Flexible(
              child: Text(
                'Forum',
                style: TextStyle(
                  fontSize: fontSize,
                ),
                overflow: TextOverflow.visible, // Show full word, no dots
                maxLines: 1,
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
              onPressed: () => context.goBackOrHome(),
        ),
        actions: [
          // Status indicators (moved from title to actions)
          Consumer(
            builder: (context, ref, child) {
              final isConnected = ref.watch(isConnectedProvider);
              final pendingOperations = ref.watch(forumPendingOperationsProvider);
              final hasPendingOperations = pendingOperations > 0;
              final accessibilityState = ref.watch(accessibilityNotifierProvider);
              final isExtraLarge = accessibilityState.fontSize == AccessibilityFontSize.extraLarge;
              final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
              final shouldReduceSize = isExtraLarge && isDyslexiaFriendly;
              
              // Reduce sizes when both extra large and dyslexia are on
              final scaleFactor = shouldReduceSize ? 0.55 : 0.75;
              final iconSize = (10 * scaleFactor).clamp(7.0, 10.0);
              final fontSize = (9 * scaleFactor).clamp(8.0, 9.0);
              final padding = EdgeInsets.symmetric(
                horizontal: (3 * scaleFactor).clamp(2.0, 3.0),
                vertical: (1 * scaleFactor).clamp(0.5, 1.0),
              );

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isConnected) ...[
                    Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off, size: iconSize, color: Colors.orange),
                          SizedBox(width: 2 * scaleFactor),
                          Text(
                            'Offline',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (hasPendingOperations) ...[
                    SizedBox(width: !isConnected ? 2 : 0),
                    Container(
                      padding: padding,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.sync, size: iconSize, color: Colors.blue),
                          SizedBox(width: 2 * scaleFactor),
                          Text(
                            '$pendingOperations',
                            style: TextStyle(
                              fontSize: fontSize,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          // Accessibility quick actions in app bar
          Consumer(
            builder: (context, ref, child) {
              final accessibilityState = ref.watch(accessibilityNotifierProvider);
              final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
              final isExtraLarge = accessibilityState.fontSize == AccessibilityFontSize.extraLarge;
              final isDyslexiaFriendly = accessibilityState.isDyslexiaFriendly;
              final shouldReduceSize = isExtraLarge && isDyslexiaFriendly;
              
              // Reduce icon sizes when both extra large and dyslexia are on
              final iconSize = shouldReduceSize ? 20.0 : 24.0;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Combined accessibility settings popup
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.text_fields,
                      size: iconSize,
                      color: (accessibilityState.fontSize != AccessibilityFontSize.normal ||
                             accessibilityState.isDyslexiaFriendly)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Tekst instellingen',
                    padding: EdgeInsets.zero,
                    iconSize: iconSize,
                    constraints: BoxConstraints(
                      minWidth: shouldReduceSize
                          ? 280
                          : (accessibilityState.fontSize == AccessibilityFontSize.extraLarge ||
                             accessibilityState.isDyslexiaFriendly
                              ? 320
                              : 280),
                    ),
                    itemBuilder: (context) => [
                      // Font size section
                      PopupMenuItem<String>(
                        enabled: false,
                        child: Text(
                          'Lettergrootte',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ...AccessibilityFontSize.values.map((fontSize) {
                        final isSelected = accessibilityState.fontSize == fontSize;
                        return PopupMenuItem<String>(
                          value: 'font_${fontSize.name}',
                          child: Row(
                            children: [
                              Icon(
                                _getFontSizeIcon(fontSize),
                                size: 20,
                                color: isSelected ? Theme.of(context).colorScheme.primary : null,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                fontSize == AccessibilityFontSize.small ? 'Klein' :
                                fontSize == AccessibilityFontSize.normal ? 'Normaal' :
                                fontSize == AccessibilityFontSize.large ? 'Groot' : 'Extra Groot',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        );
                      }),
                      const PopupMenuDivider(),
                      // Dyslexia toggle
                      PopupMenuItem<String>(
                        value: 'toggle_dyslexia',
                        child: Row(
                          children: [
                            Icon(
                              accessibilityState.isDyslexiaFriendly
                                  ? Icons.format_line_spacing
                                  : Icons.format_line_spacing_outlined,
                              size: 18,
                              color: accessibilityState.isDyslexiaFriendly
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'dyslexie\nvriendelijk',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.visible,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 0.7,
                              child: Switch(
                                value: accessibilityState.isDyslexiaFriendly,
                                onChanged: (value) {
                                  accessibilityNotifier.toggleDyslexiaFriendly();
                                  Navigator.pop(context);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (String value) {
                      if (value.startsWith('font_')) {
                        final fontSizeName = value.substring(5);
                        final fontSize = AccessibilityFontSize.values.firstWhere(
                          (size) => size.name == fontSizeName,
                        );
                        accessibilityNotifier.setFontSize(fontSize);
                      } else if (value == 'toggle_dyslexia') {
                        accessibilityNotifier.toggleDyslexiaFriendly();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
        body: SafeArea(
          child: ResponsiveLayout(
            mobile: _buildForumList(posts, isLoading, error),
            tablet: _buildForumList(posts, isLoading, error),
            desktop: Row(
              children: [
                // Forum posts list (left side)
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    child: _buildForumList(posts, isLoading, error),
                  ),
                ),
                // Post detail view (right side)
                Expanded(
                  flex: 3,
                  child: Container(
                    color: Theme.of(context).colorScheme.surface,
                    child: _buildDetailView(),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: Consumer(
          builder: (context, ref, child) {
            final isConnected = ref.watch(isConnectedProvider);
            return FloatingActionButton(
              heroTag: "forum_fab",
              onPressed: isConnected ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateForumPostScreen(),
                  ),
                );
              } : null,
              backgroundColor: isConnected ? null : Colors.grey,
              child: Icon(
                isConnected ? Icons.add : Icons.cloud_off,
                color: isConnected ? null : Colors.white70,
              ),
              tooltip: isConnected ? 'Nieuw bericht maken' : 'Niet beschikbaar offline',
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
