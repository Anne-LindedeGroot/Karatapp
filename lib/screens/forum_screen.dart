import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/forum_models.dart';
import '../providers/forum_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/permission_provider.dart';
import '../providers/interaction_provider.dart';
import '../widgets/avatar_widget.dart';
import '../widgets/skeleton_forum_post.dart';
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
    ref.read(forumNotifierProvider.notifier).filterByCategory(category);
  }

  Future<void> _deletePost(ForumPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${post.title}"?'),
        content: const Text(
          'This will permanently delete the post and all its comments. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
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

  Future<void> _togglePinPost(ForumPost post) async {
    try {
      await ref.read(forumNotifierProvider.notifier).togglePinPost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              post.isPinned 
                ? 'Post unpinned successfully' 
                : 'Post pinned successfully'
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
                ? 'Post unlocked successfully' 
                : 'Post locked successfully'
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
    final selectedCategory = ref.watch(forumSelectedCategoryProvider);
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildCategoryChip(null, 'All', selectedCategory),
          const SizedBox(width: 8),
          ...ForumCategory.values.map((category) => 
            _buildCategoryChip(category, category.displayName, selectedCategory)
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(ForumCategory? category, String label, ForumCategory? selectedCategory) {
    final isSelected = category == selectedCategory;
    
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _filterByCategory(selected ? category : null);
        },
        selectedColor: Colors.blue.withValues(alpha: 0.2),
        checkmarkColor: Colors.blue,
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ForumPostDetailScreen(postId: post.id),
            ),
          );
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
                  Container(
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
                  const Spacer(),
                  // Pin indicator
                  if (post.isPinned)
                    const Icon(Icons.push_pin, color: Colors.orange, size: 16),
                  // Lock indicator
                  if (post.isLocked)
                    const Icon(Icons.lock, color: Colors.red, size: 16),
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
                              Text(post.isPinned ? 'Unpin' : 'Pin'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'lock',
                          child: Row(
                            children: [
                              Icon(post.isLocked ? Icons.lock_open : Icons.lock),
                              const SizedBox(width: 8),
                              Text(post.isLocked ? 'Unlock' : 'Lock'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                post.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              
              // Footer with author and stats
              Row(
                children: [
                  // Author avatar and name
                  AvatarWidget(
                    customAvatarUrl: post.authorAvatar,
                    userName: post.authorName,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _formatDate(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Interaction buttons
                  Row(
                    children: [
                      // Like button
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
                            child: Row(
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
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      
                      // Favorite button
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
                                        isFavorited ? 'Removed from favorites' : 'Added to favorites'
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
                            child: Icon(
                              isFavorited ? Icons.bookmark : Icons.bookmark_border,
                              size: 16,
                              color: isFavorited ? Colors.teal : Colors.grey[600],
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      
                      // Comment count
                      Row(
                        children: [
                          Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
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
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
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
        title: const Text('Community Forum'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBackOrHome(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPosts,
          ),
        ],
      ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: const InputDecoration(
                  hintText: 'Search posts...',
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
                margin: const EdgeInsets.all(16),
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
                      child: const Text('Dismiss'),
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
                                'No posts found',
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
        ),
      ),
    );
  }
}
