import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/interaction_provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/skeleton_forum_post.dart';
import '../widgets/responsive_layout.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/app_router.dart';
import 'forum_post_detail_screen.dart';
import 'create_forum_post_screen.dart';

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
      if (mounted) {
        setState(() {
          _localSelectedCategory = providerCategory;
        });
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
    
    // Debug print to track selection state
    print('Category Filter - selectedCategory: $selectedCategory');
    print('Category Filter - "Alle Berichten" isSelected: ${selectedCategory == null}');
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildCategoryButton(
              category: null,
              label: 'Alle Berichten',
              isSelected: selectedCategory == null,
              onTap: () {
                print('Tapping "Alle Berichten" button');
                _filterByCategory(null);
              },
            ),
            const SizedBox(width: 8),
            ...ForumCategory.values.map((category) => 
              _buildCategoryButton(
                category: category,
                label: category.displayName,
                isSelected: selectedCategory == category,
                onTap: () {
                  print('Tapping category button: ${category.displayName}');
                  _filterByCategory(category);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryButton({
    required ForumCategory? category,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    // Debug print for each button
    print('Building button "$label" - isSelected: $isSelected');
    
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                  if (isSelected) ...[
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected 
                          ? Colors.white
                          : Colors.grey[300],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 15,
                      shadows: isSelected ? [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ] : null,
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
      error: (_, __) => false,
    );
    final canModerate = canModerateRole || (currentUser != null && post.authorId == currentUser.id);
    final isSelected = context.isDesktop && _selectedPostId == post.id;

    return Semantics(
      label: 'Forum bericht: ${post.title}, categorie: ${post.category.displayName}, door ${post.authorName}',
      button: true,
      child: Card(
        margin: EdgeInsets.symmetric(
          horizontal: context.responsiveValue(mobile: 16.0, tablet: 12.0, desktop: 8.0),
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
            if (context.isDesktop) {
              // Master-detail mode: select post for detail view
              setState(() {
                _selectedPostId = post.id;
              });
            } else {
              // Mobile mode: navigate to detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ForumPostDetailScreen(postId: post.id),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with category and actions
                Row(
                  children: [
                    // Category badge
                    Semantics(
                      label: 'Categorie: ${post.category.displayName}',
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              Text('Verwijderen', style: TextStyle(color: Colors.red)),
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
                ),
              ),
              const SizedBox(height: 10),
              
              // Content preview
              Semantics(
                label: 'Bericht inhoud: ${post.content}',
                child: Text(
                  post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
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
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Semantics(
                              label: 'Geplaatst op: ${_formatDate(post.createdAt)}',
                              child: Text(
                                _formatDate(post.createdAt),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Interaction buttons row - separated for better spacing
                  Row(
                    children: [
                      // Like button with improved styling
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isLiked 
                                  ? Colors.red.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
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
                                    size: 16,
                                    color: isLiked ? Colors.red : Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$likeCount',
                                    style: TextStyle(
                                      color: isLiked ? Colors.red : Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      
                      // Favorite button with improved styling
                      Consumer(
                        builder: (context, ref, child) {
                          final forumInteraction = ref.watch(forumInteractionProvider(post.id));
                          final isFavorited = forumInteraction.isFavorited;
                          final isLoading = forumInteraction.isLoading;
                          
                          return GestureDetector(
                            onTap: isLoading ? null : () async {
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isFavorited 
                                  ? Colors.teal.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isFavorited ? Colors.teal.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                              ),
                              child: Icon(
                                isFavorited ? Icons.bookmark : Icons.bookmark_border,
                                size: 16,
                                color: isFavorited ? Colors.teal : Colors.grey[600],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      
                      // Comment count with improved styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          children: [
                            Icon(Icons.comment_outlined, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 6),
                            Text(
                              '${post.commentCount}',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // View count or additional info could go here
                      Text(
                        'Bekijk bericht',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            decoration: const InputDecoration(
              hintText: 'Zoek berichten...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
              ),
            ),
            onChanged: _filterPosts,
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
                    'Error: $error',
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
        title: const Text('Forum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBackOrHome(),
        ),
        actions: [
          // Accessibility quick actions in app bar
          Consumer(
            builder: (context, ref, child) {
              final accessibilityState = ref.watch(accessibilityNotifierProvider);
              final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  
                  // Combined accessibility settings popup
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.text_fields,
                      color: (accessibilityState.fontSize != AccessibilityFontSize.normal || 
                             accessibilityState.isDyslexiaFriendly)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    tooltip: 'Tekst instellingen',
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
                              size: 20,
                              color: accessibilityState.isDyslexiaFriendly
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            const Text('Dyslexie vriendelijk'),
                            const Spacer(),
                            Switch(
                              value: accessibilityState.isDyslexiaFriendly,
                              onChanged: (value) {
                                accessibilityNotifier.toggleDyslexiaFriendly();
                                Navigator.pop(context);
                              },
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
                  
                  // Refresh button
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _refreshPosts,
                    tooltip: 'Berichten verversen',
                  ),
                ],
              );
            },
          ),
        ],
      ),
        body: ResponsiveLayout(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateForumPostScreen(),
              ),
            );
          },
          child: const Icon(Icons.add),
          tooltip: 'Nieuw bericht maken',
        ),
      ),
    );
  }
}
