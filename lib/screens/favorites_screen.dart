import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/kata_model.dart';
import '../models/forum_models.dart';
import '../models/ohyo_model.dart';
import '../providers/interaction_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';
import '../providers/ohyo_provider.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/collapsible_kata_card.dart';
import '../widgets/collapsible_ohyo_card.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
    ref.invalidate(userFavoriteOhyosProvider);
  }

  Future<void> _speakKataContent(Kata kata, int index) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final skipGeneralInfo = ref.read(skipGeneralInfoInTTSKataProvider);
      
      // Build content for TTS based on settings
      final content = StringBuffer();
      content.write('Kata $index: ${kata.name}. ');
      
      // Always include style (this is important kata information)
      if (kata.style.isNotEmpty && kata.style != 'Unknown') {
        content.write('Stijl: ${kata.style}. ');
      }
      
      // Include description only if not skipping general info
      if (!skipGeneralInfo && kata.description.isNotEmpty) {
        content.write('Beschrijving: ${kata.description}. ');
      }
      
      // Always include media information (this is specific content, not general info)
      if (kata.imageUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.imageUrls?.length} afbeeldingen. ');
      }
      
      if (kata.videoUrls?.isNotEmpty == true) {
        content.write('Deze kata heeft ${kata.videoUrls?.length} video\'s. ');
      }
      
      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking kata content: $e');
    }
  }

  Future<void> _speakForumPostContent(ForumPost post, int index) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

      // Build comprehensive content for TTS
      final content = StringBuffer();
      content.write('Forum Post $index: ${post.title}. ');
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

  Future<void> _speakOhyoContent(Ohyo ohyo, int index) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final skipGeneralInfo = ref.read(skipGeneralInfoInTTSOhyoProvider);

      // Build content for TTS based on settings
      final content = StringBuffer();
      content.write('Ohyo $index: ${ohyo.name}. ');

      // Always include style (this is important ohyo information)
      if (ohyo.style.isNotEmpty && ohyo.style != 'Unknown') {
        content.write('Stijl: ${ohyo.style}. ');
      }

      // Include description only if not skipping general info
      if (!skipGeneralInfo && ohyo.description.isNotEmpty) {
        content.write('Beschrijving: ${ohyo.description}. ');
      }

      // Always include media information (this is specific content, not general info)
      if (ohyo.imageUrls?.isNotEmpty == true) {
        content.write('Deze ohyo heeft ${ohyo.imageUrls?.length} afbeeldingen. ');
      }

      if (ohyo.videoUrls?.isNotEmpty == true) {
        content.write('Deze ohyo heeft ${ohyo.videoUrls?.length} video\'s. ');
      }

      await accessibilityNotifier.speak(content.toString());
    } catch (e) {
      debugPrint('Error speaking ohyo content: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final kataState = ref.watch(kataNotifierProvider);
    final forumState = ref.watch(forumNotifierProvider);
    final ohyoState = ref.watch(ohyoNotifierProvider);
    final favoriteKatasAsync = ref.watch(userFavoriteKatasProvider);
    final favoriteForumPostsAsync = ref.watch(userFavoriteForumPostsProvider);
    final favoriteOhyosAsync = ref.watch(userFavoriteOhyosProvider);

    return Scaffold(
      appBar: AppBar(
        title: Semantics(
          label: 'Mijn Favorieten pagina. Gebruik de tabbladen om tussen favoriete kata\'s, ohyo\'s en forumberichten te wisselen.',
          child: const Text('Mijn Favorieten'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.goBackOrHome(),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          tabs: [
            Tab(
              icon: const Icon(Icons.self_improvement),
              text: favoriteKatasAsync.when(
                data: (favoriteKataIds) {
                  final favoriteKatas = kataState.katas
                      .where((kata) => favoriteKataIds.contains(kata.id))
                      .toList();
                  return 'Kata\'s (${favoriteKatas.length})';
                },
                loading: () => 'Kata\'s (...)',
                error: (_, __) => 'Kata\'s (0)',
              ),
            ),
            Tab(
              icon: const Icon(Icons.sports_martial_arts),
              text: favoriteOhyosAsync.when(
                data: (favoriteOhyoIds) {
                  final favoriteOhyos = ohyoState.ohyos
                      .where((ohyo) => favoriteOhyoIds.contains(ohyo.id))
                      .toList();
                  return 'Ohyo\'s (${favoriteOhyos.length})';
                },
                loading: () => 'Ohyo\'s (...)',
                error: (_, __) => 'Ohyo\'s (0)',
              ),
            ),
            Tab(
              icon: const Icon(Icons.forum),
              text: favoriteForumPostsAsync.when(
                data: (favoriteForumPostIds) {
                  final favoriteForumPosts = forumState.posts
                      .where((post) => favoriteForumPostIds.contains(post.id))
                      .toList();
                  return 'Forumberichten (${favoriteForumPosts.length})';
                },
                loading: () => 'Forumberichten (...)',
                error: (_, __) => 'Forumberichten (0)',
              ),
            ),
          ],
        ),
        actions: [
          // Refresh Button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshFavorites,
            tooltip: 'Favorieten vernieuwen',
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
                        Text('Fout bij laden favorieten: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshFavorites,
                          child: const Text('Opnieuw proberen'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Favorite Ohyos Tab
                favoriteOhyosAsync.when(
                  data: (favoriteOhyoIds) {
                    final favoriteOhyos = ohyoState.ohyos
                        .where((ohyo) => favoriteOhyoIds.contains(ohyo.id))
                        .toList();
                    return _buildFavoriteOhyosTab(favoriteOhyos, false);
                  },
                  loading: () => _buildFavoriteOhyosTab([], true),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Fout bij laden favorieten: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshFavorites,
                          child: const Text('Opnieuw proberen'),
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
                    return _buildFavoriteForumPostsTab(
                      favoriteForumPosts,
                      false,
                    );
                  },
                  loading: () => _buildFavoriteForumPostsTab([], true),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Fout bij laden favorieten: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refreshFavorites,
                          child: const Text('Opnieuw proberen'),
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
          children: [
            const SizedBox(height: 100),
            Semantics(
              label: 'Nog geen favoriete kata\'s. Tik op het hartje bij een kata om deze toe te voegen aan je favorieten.',
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nog geen favoriete kata\'s',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tik op het hartje bij een kata om deze toe te voegen aan je favorieten',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          return _buildKataCard(kata, index + 1);
        },
      ),
    );
  }

  Widget _buildFavoriteForumPostsTab(
    List<ForumPost> favoriteForumPosts,
    bool isLoading,
  ) {
    if (isLoading) {
      return const SkeletonForumList(itemCount: 3);
    }

    if (favoriteForumPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Semantics(
              label: 'Nog geen favoriete forumberichten. Tik op het hartje bij een forumbericht om deze toe te voegen aan je favorieten.',
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nog geen favoriete forumberichten',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tik op het hartje bij een forumbericht om deze toe te voegen aan je favorieten',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
          return _buildForumPostCard(post, index + 1);
        },
      ),
    );
  }

  Widget _buildFavoriteOhyosTab(List<Ohyo> favoriteOhyos, bool isLoading) {
    if (isLoading) {
      return const SkeletonKataList(itemCount: 3);
    }

    if (favoriteOhyos.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshFavorites,
        child: ListView(
          children: [
            const SizedBox(height: 100),
            Semantics(
              label: 'Nog geen favoriete ohyo\'s. Tik op het hartje bij een ohyo om deze toe te voegen aan je favorieten.',
              child: const Center(
                child: Column(
                  children: [
                    Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'Nog geen favoriete ohyo\'s',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tik op het hartje bij een ohyo om deze toe te voegen aan je favorieten',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
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
        itemCount: favoriteOhyos.length,
        itemBuilder: (context, index) {
          final ohyo = favoriteOhyos[index];
          return _buildOhyoCard(ohyo, index + 1);
        },
      ),
    );
  }

  Widget _buildKataCard(Kata kata, int index) {
    return Semantics(
      label: 'Favoriete kata $index van ${kata.name}. ${kata.style.isNotEmpty && kata.style != 'Unknown' ? 'Stijl: ${kata.style}.' : ''} ${kata.description.isNotEmpty ? 'Beschrijving: ${kata.description}.' : ''} ${kata.imageUrls?.isNotEmpty == true ? 'Deze kata heeft ${kata.imageUrls?.length} afbeeldingen.' : ''} ${kata.videoUrls?.isNotEmpty == true ? 'Deze kata heeft ${kata.videoUrls?.length} video\'s.' : ''} Tik om te bekijken.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          onTap: () => _speakKataContent(kata, index),
          child: Column(
            children: [
              // Card header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.self_improvement,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Kata $index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Kata card content - show all information for favorites
              CollapsibleKataCard(
                kata: kata,
                onDelete: () {}, // Empty callback instead of null
                showAllInfo: true, // Show all information in favorites
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForumPostCard(ForumPost post, int index) {
    final semanticLabel = 'Favoriet forumbericht $index: ${post.title}. '
        'Categorie: ${post.category.displayName}. '
        '${post.content.isNotEmpty ? 'Inhoud: ${post.content}.' : ''} '
        'Geschreven door: ${post.authorName}. '
        '${post.commentCount > 0 ? 'Dit bericht heeft ${post.commentCount} reacties.' : ''} '
        '${post.isPinned ? 'Dit bericht is vastgepind.' : ''} '
        '${post.isLocked ? 'Dit bericht is gesloten.' : ''} '
        'Gepost ${_formatDate(post.createdAt)}. '
        'Tik om het volledige bericht te bekijken.';

    return Semantics(
      label: semanticLabel,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Card header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.forum,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Forumbericht $index',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Forum post card content
            InkWell(
              onTap: () {
                _speakForumPostContent(post, index);
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
                        Flexible(
                          child: Container(
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
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ),
                        if (post.isPinned) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.push_pin, size: 14, color: Colors.orange),
                        ],
                        if (post.isLocked) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.lock, size: 14, color: Colors.red),
                        ],
                        const Spacer(),
                        Flexible(
                          child: Text(
                            _formatDate(post.createdAt),
                            style: TextStyle(color: Colors.grey[600], fontSize: 11),
                            overflow: TextOverflow.visible,
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
                      overflow: TextOverflow.visible,
                    ),
                    const SizedBox(height: 8),

                    // Content preview
                    Text(
                      post.content,
                      style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      maxLines: 3,
                      overflow: TextOverflow.visible,
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
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        if (post.commentCount > 0) ...[
                          Icon(Icons.comment, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${post.commentCount}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                        ],
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

  Widget _buildOhyoCard(Ohyo ohyo, int index) {
    return Semantics(
      label: 'Favoriete ohyo $index van ${ohyo.name}. ${ohyo.style.isNotEmpty && ohyo.style != 'Unknown' ? 'Stijl: ${ohyo.style}.' : ''} ${ohyo.description.isNotEmpty ? 'Beschrijving: ${ohyo.description}.' : ''} ${ohyo.imageUrls?.isNotEmpty == true ? 'Deze ohyo heeft ${ohyo.imageUrls?.length} afbeeldingen.' : ''} ${ohyo.videoUrls?.isNotEmpty == true ? 'Deze ohyo heeft ${ohyo.videoUrls?.length} video\'s.' : ''} Tik om te bekijken.',
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: InkWell(
          onTap: () => _speakOhyoContent(ohyo, index),
          child: Column(
            children: [
              // Card header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sports_martial_arts,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ohyo $index',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Ohyo card content - show all information for favorites
              CollapsibleOhyoCard(
                ohyo: ohyo,
                onDelete: () {}, // Empty callback instead of null
                showAllInfo: true, // Show all information in favorites
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
