import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kata_model.dart';
import '../models/forum_models.dart';
import '../providers/interaction_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';
import '../widgets/collapsible_kata_card.dart';
import '../widgets/connection_error_widget.dart';
import '../widgets/skeleton_kata_card.dart';
import '../widgets/skeleton_forum_post.dart';
import '../core/navigation/app_router.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavorites() async {
    // Invalidate the providers to refresh data
    ref.invalidate(userFavoriteKatasProvider);
    ref.invalidate(userFavoriteForumPostsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final kataState = ref.watch(kataNotifierProvider);
    final forumState = ref.watch(forumNotifierProvider);
    final favoriteKatasAsync = ref.watch(userFavoriteKatasProvider);
    final favoriteForumPostsAsync = ref.watch(userFavoriteForumPostsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Favorites'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBackOrHome(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.sports_martial_arts),
              text: favoriteKatasAsync.when(
                data: (favoriteKataIds) {
                  final favoriteKatas = kataState.katas
                      .where((kata) => favoriteKataIds.contains(kata.id))
                      .toList();
                  return 'Katas (${favoriteKatas.length})';
                },
                loading: () => 'Katas (...)',
                error: (_, __) => 'Katas (0)',
              ),
            ),
            Tab(
              icon: const Icon(Icons.forum),
              text: favoriteForumPostsAsync.when(
                data: (favoriteForumPostIds) {
                  final favoriteForumPosts = forumState.posts
                      .where((post) => favoriteForumPostIds.contains(post.id))
                      .toList();
                  return 'Forum Posts (${favoriteForumPosts.length})';
                },
                loading: () => 'Forum Posts (...)',
                error: (_, __) => 'Forum Posts (0)',
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFavorites,
            tooltip: 'Refresh favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection error widget
          const ConnectionErrorWidget(),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Favorite Katas Tab
                favoriteKatasAsync.when(
                  data: (favoriteKataIds) {
                    final favoriteKatas = kataState.katas
                        .where((kata) => favoriteKataIds.contains(kata.id))
                        .toList();
                    return _buildFavoriteKatasTab(favoriteKatas, false);
                  },
                  loading: () => _buildFavoriteKatasTab([], true),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading favorites: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshFavorites,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Favorite Forum Posts Tab
                favoriteForumPostsAsync.when(
                  data: (favoriteForumPostIds) {
                    final favoriteForumPosts = forumState.posts
                        .where((post) => favoriteForumPostIds.contains(post.id))
                        .toList();
                    return _buildFavoriteForumPostsTab(favoriteForumPosts, false);
                  },
                  loading: () => _buildFavoriteForumPostsTab([], true),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error loading favorites: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshFavorites,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteKatasTab(List<Kata> favoriteKatas, bool isLoading) {
    if (isLoading) {
      return const SkeletonKataList(itemCount: 3);
    }

    if (favoriteKatas.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorite katas yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any kata to add it to your favorites',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0),
        itemCount: favoriteKatas.length,
        itemBuilder: (context, index) {
          final kata = favoriteKatas[index];
          return CollapsibleKataCard(
            kata: kata,
            onDelete: () {}, // Empty callback instead of null
          );
        },
      ),
    );
  }

  Widget _buildFavoriteForumPostsTab(List<ForumPost> favoriteForumPosts, bool isLoading) {
    if (isLoading) {
      return const SkeletonForumList(itemCount: 3);
    }

    if (favoriteForumPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favorite forum posts yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any forum post to add it to your favorites',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFavorites,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80.0),
        itemCount: favoriteForumPosts.length,
        itemBuilder: (context, index) {
          final post = favoriteForumPosts[index];
          return _buildForumPostCard(post);
        },
      ),
    );
  }

  Widget _buildForumPostCard(ForumPost post) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/forum_post_detail',
            arguments: post.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with category and pin status
              Row(
                children: [
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
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (post.isPinned) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.push_pin,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ],
                  if (post.isLocked) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.lock,
                      size: 16,
                      color: Colors.red,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    _formatDate(post.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Content preview
              Text(
                post.content,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Footer with author and stats
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundImage: post.authorAvatar != null
                        ? NetworkImage(post.authorAvatar!)
                        : null,
                    child: post.authorAvatar == null
                        ? Text(
                            post.authorName.isNotEmpty
                                ? post.authorName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 10),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.authorName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (post.commentCount > 0) ...[
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
                        fontSize: 12,
                      ),
                    ),
                  ],
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
}
