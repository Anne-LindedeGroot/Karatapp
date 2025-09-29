import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';
import '../providers/interaction_provider.dart';

/// Context-aware TTS Service that reads content based on current page context
class ContextAwareTTSService {
  static final ContextAwareTTSService _instance = ContextAwareTTSService._internal();
  factory ContextAwareTTSService() => _instance;
  ContextAwareTTSService._internal();

  static OverlayEntry? _currentHighlightOverlay;
  static OverlayEntry? _currentCursorOverlay;
  static bool _isReading = false;
  static String _currentText = '';
  static int _currentWordIndex = 0;
  static List<String> _currentWords = [];
  static TTSPageType? _currentPageType;

  /// Check if currently reading
  static bool get isReading => _isReading;

  /// Get current page type being read
  static TTSPageType? get currentPageType => _currentPageType;

  /// Read content based on page type with proper context awareness
  static Future<void> readPageContent(
    BuildContext context, 
    WidgetRef ref, 
    TTSPageType pageType, {
    String? customContent,
    String? pageTitle,
    List<String>? comments,
  }) async {
    if (_isReading) {
      await stopReading(context, ref);
      return;
    }

    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      // Wait longer for TTS to initialize properly
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      _isReading = true;
      _currentPageType = pageType;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      if (!context.mounted) return;
      
      switch (pageType) {
        case TTSPageType.home:
          await _readHomePage(context, ref, accessibilityNotifier);
          break;
        case TTSPageType.forum:
          await _readForumPage(context, ref, accessibilityNotifier);
          break;
        case TTSPageType.favorites:
          await _readFavoritesPage(context, ref, accessibilityNotifier);
          break;
        case TTSPageType.forumPostDetail:
          if (pageTitle != null && customContent != null) {
            await _readForumPostDetail(
              context, 
              ref, 
              accessibilityNotifier,
              pageTitle, 
              customContent, 
              comments ?? []
            );
          }
          break;
        case TTSPageType.custom:
          if (customContent != null) {
            await _readCustomContent(
              context, 
              ref, 
              accessibilityNotifier,
              customContent, 
              pageTitle: pageTitle
            );
          }
          break;
      }
      
    } catch (e) {
      debugPrint('Error reading page content: $e');
    } finally {
      _isReading = false;
      _currentPageType = null;
      _removeAllOverlays();
    }
  }

  /// Read home page content with kata information
  static Future<void> _readHomePage(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    if (!context.mounted || !_isReading) return;
    
    // Page introduction
    await _speakWithCursor(
      context, 
      'Welkom op de hoofdpagina van Karatapp. Hier kun je alle kata\'s bekijken en zoeken.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.page
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read kata information
    final kataState = ref.read(kataNotifierProvider);
    final katas = kataState.filteredKatas;
    
    if (katas.isEmpty) {
      await _speakWithCursor(
        context,
        'Er zijn momenteel geen kata\'s beschikbaar.',
        accessibilityNotifier,
        highlightType: TTSHighlightType.noContent
      );
      return;
    }
    
    await _speakWithCursor(
      context,
      'Er ${katas.length == 1 ? 'is' : 'zijn'} ${katas.length} kata${katas.length == 1 ? '' : '\'s'} beschikbaar.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.contentCount
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read first few katas
    final kataSummary = katas.take(3).map((kata) => 
      '${kata.name} uit de ${kata.style} stijl'
    ).join(', ');
    
    await _speakWithCursor(
      context,
      'De eerste kata\'s zijn: $kataSummary.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.content
    );
  }

  /// Read favorites page content with kata and forum post information
  static Future<void> _readFavoritesPage(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    if (!context.mounted || !_isReading) return;
    
    // Page introduction
    await _speakWithCursor(
      context, 
      'Welkom op de favorieten pagina. Hier kun je al je favoriete kata\'s en forumberichten bekijken.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.page
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Get favorites data
    final kataState = ref.read(kataNotifierProvider);
    final forumState = ref.read(forumNotifierProvider);
    
    try {
      // Get favorite kata IDs
      final favoriteKataIds = await ref.read(interactionServiceProvider).getUserFavoriteKatas();
      final favoriteKatas = kataState.katas
          .where((kata) => favoriteKataIds.contains(kata.id))
          .toList();
          
      // Get favorite forum post IDs
      final favoriteForumPostIds = await ref.read(interactionServiceProvider).getUserFavoriteForumPosts();
      final favoriteForumPosts = forumState.posts
          .where((post) => favoriteForumPostIds.contains(post.id))
          .toList();
      
      if (!context.mounted || !_isReading) return;
      
      // Read favorite katas section
      if (favoriteKatas.isEmpty) {
        await _speakWithCursor(
          context,
          'Je hebt geen favoriete kata\'s.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.noContent
        );
      } else {
        await _speakWithCursor(
          context,
          'Je hebt ${favoriteKatas.length} favoriete kata${favoriteKatas.length == 1 ? '' : '\'s'}. Ik lees ze nu voor.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.contentCount
        );
        
        if (!context.mounted || !_isReading) return;
        
        // Read each kata
        for (int i = 0; i < favoriteKatas.length && _isReading; i++) {
          final kata = favoriteKatas[i];
          
          await _speakWithCursor(
            context,
            'Kata ${i + 1}: ${kata.name} uit de ${kata.style} stijl. ${kata.description}',
            accessibilityNotifier,
            highlightType: TTSHighlightType.kataTitle,
            itemIndex: i
          );
          
          if (i < favoriteKatas.length - 1 && _isReading && context.mounted) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        }
      }
      
      if (!context.mounted || !_isReading) return;
      
      // Short pause between sections
      await Future.delayed(const Duration(milliseconds: 1000));
      
      if (!context.mounted || !_isReading) return;
      
      // Read favorite forum posts section
      if (favoriteForumPosts.isEmpty) {
        await _speakWithCursor(
          context,
          'Je hebt geen favoriete forumberichten.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.noContent
        );
      } else {
        await _speakWithCursor(
          context,
          'Je hebt ${favoriteForumPosts.length} favoriet${favoriteForumPosts.length == 1 ? '' : 'e'} forumbericht${favoriteForumPosts.length == 1 ? '' : 'en'}. Ik lees ze nu voor.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.contentCount
        );
        
        if (!context.mounted || !_isReading) return;
        
        // Read each forum post
        for (int i = 0; i < favoriteForumPosts.length && _isReading; i++) {
          final post = favoriteForumPosts[i];
          
          await _speakWithCursor(
            context,
            'Forumbericht ${i + 1}: ${post.title} door ${post.authorName}. Categorie: ${post.category.displayName}. ${post.content}',
            accessibilityNotifier,
            highlightType: TTSHighlightType.postTitle,
            itemIndex: i
          );
          
          if (post.commentCount > 0) {
            await _speakWithCursor(
              context,
              '${post.commentCount} reactie${post.commentCount == 1 ? '' : 's'}.',
              accessibilityNotifier,
              highlightType: TTSHighlightType.postContent,
              itemIndex: i
            );
          }
          
          if (i < favoriteForumPosts.length - 1 && _isReading && context.mounted) {
            await Future.delayed(const Duration(milliseconds: 800));
          }
        }
      }
      
      if (_isReading && context.mounted) {
        await _speakWithCursor(
          context,
          'Klaar met het voorlezen van al je favorieten.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.content
        );
      }
      
    } catch (e) {
      debugPrint('Error reading favorites: $e');
      if (_isReading && context.mounted) {
        await _speakWithCursor(
          context,
          'Fout bij het ophalen van favorieten.',
          accessibilityNotifier,
          highlightType: TTSHighlightType.noContent
        );
      }
    }
  }

  /// Read forum page content with post information
  static Future<void> _readForumPage(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    if (!context.mounted || !_isReading) return;
    
    // Page introduction
    await _speakWithCursor(
      context, 
      'Welkom op het forum. Hier kun je berichten lezen en discussies voeren met andere karateka\'s.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.page
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read forum posts information
    final posts = ref.read(forumPostsProvider);
    
    if (posts.isEmpty) {
      await _speakWithCursor(
        context,
        'Er zijn momenteel geen berichten in het forum.',
        accessibilityNotifier,
        highlightType: TTSHighlightType.noContent
      );
      return;
    }
    
    await _speakWithCursor(
      context,
      'Er ${posts.length == 1 ? 'is' : 'zijn'} ${posts.length} bericht${posts.length == 1 ? '' : 'en'} in het forum.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.contentCount
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read categories available
    final categories = posts.map((post) => post.category.displayName).toSet().toList();
    if (categories.isNotEmpty) {
      await _speakWithCursor(
        context,
        'Beschikbare categorieën zijn: ${categories.join(', ')}.',
        accessibilityNotifier,
        highlightType: TTSHighlightType.categoryFilter
      );
    }
    
    if (!context.mounted || !_isReading) return;
    
    // Read recent posts
    final recentPosts = posts.take(3).map((post) => 
      '${post.title} door ${post.authorName}'
    ).join(', ');
    
    await _speakWithCursor(
      context,
      'Recente berichten zijn: $recentPosts.',
      accessibilityNotifier,
      highlightType: TTSHighlightType.content
    );
  }

  /// Read forum post detail with comments
  static Future<void> _readForumPostDetail(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier,
    String postTitle, 
    String postContent, 
    List<String> comments
  ) async {
    if (!context.mounted || !_isReading) return;
    
    // Read post title
    await _speakWithCursor(
      context,
      'Bericht: $postTitle',
      accessibilityNotifier,
      highlightType: TTSHighlightType.postTitle
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read post content
    await _speakWithCursor(
      context,
      postContent,
      accessibilityNotifier,
      highlightType: TTSHighlightType.postContent
    );
    
    if (!context.mounted || !_isReading) return;
    
    // Read comments if available
    if (comments.isNotEmpty) {
      await _speakWithCursor(
        context,
        'Er ${comments.length == 1 ? 'is' : 'zijn'} ${comments.length} reactie${comments.length == 1 ? '' : 's'} op dit bericht.',
        accessibilityNotifier,
        highlightType: TTSHighlightType.commentsHeader
      );
      
      for (int i = 0; i < comments.length && _isReading; i++) {
        if (!context.mounted || !_isReading) return;
        
        await _speakWithCursor(
          context,
          'Reactie ${i + 1}: ${comments[i]}',
          accessibilityNotifier,
          highlightType: TTSHighlightType.comment,
          itemIndex: i
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }
  }

  /// Read custom content
  static Future<void> _readCustomContent(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier,
    String content, {
    String? pageTitle
  }) async {
    if (!context.mounted || !_isReading) return;
    
    if (pageTitle != null) {
      await _speakWithCursor(
        context,
        pageTitle,
        accessibilityNotifier,
        highlightType: TTSHighlightType.pageTitle
      );
      
      if (!context.mounted || !_isReading) return;
    }
    
    await _speakWithCursor(
      context,
      content,
      accessibilityNotifier,
      highlightType: TTSHighlightType.content
    );
  }

  /// Stop reading and remove all overlays
  static Future<void> stopReading(BuildContext context, WidgetRef ref) async {
    _isReading = false;
    _currentPageType = null;
    _removeAllOverlays();
    
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.stopSpeaking();
  }

  /// Speak text without highlighting
  static Future<void> _speakWithCursor(
    BuildContext context,
    String text,
    AccessibilityNotifier accessibilityNotifier,
    {required TTSHighlightType highlightType, int? itemIndex}
  ) async {
    if (!_isReading || !context.mounted) return;
    
    try {
      // Just speak the text directly without highlighting
      await accessibilityNotifier.speak(text);
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  /// Remove all overlays (simplified - no highlighting)
  static void _removeAllOverlays() {
    // No overlays to remove since highlighting is disabled
  }
}

/// Types of elements that can be highlighted during TTS
enum TTSHighlightType {
  page,
  pageTitle,
  appBar,
  searchBar,
  categoryFilter,
  contentCount,
  noContent,
  content,
  kataTitle,
  kataStyle,
  kataDescription,
  postTitle,
  postCategory,
  postAuthor,
  postContent,
  commentsHeader,
  comment,
}

/// Widget that shows visual highlighting during TTS
class TTSHighlightWidget extends StatefulWidget {
  final TTSHighlightType highlightType;
  final int? itemIndex;

  const TTSHighlightWidget({
    super.key,
    required this.highlightType,
    this.itemIndex,
  });

  @override
  State<TTSHighlightWidget> createState() => _TTSHighlightWidgetState();
}

class _TTSHighlightWidgetState extends State<TTSHighlightWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return CustomPaint(
            painter: TTSHighlightPainter(
              highlightType: widget.highlightType,
              itemIndex: widget.itemIndex,
              animationValue: _pulseAnimation.value,
            ),
          );
        },
      ),
    );
  }
}

/// Widget that shows word cursor during TTS
class TTSWordCursorWidget extends StatefulWidget {
  final int wordIndex;
  final int totalWords;

  const TTSWordCursorWidget({
    super.key,
    required this.wordIndex,
    required this.totalWords,
  });

  @override
  State<TTSWordCursorWidget> createState() => _TTSWordCursorWidgetState();
}

class _TTSWordCursorWidgetState extends State<TTSWordCursorWidget>
    with TickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _blinkAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _blinkController,
      curve: Curves.easeInOut,
    ));
    
    _blinkController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 50,
      right: 20,
      child: AnimatedBuilder(
        animation: _blinkAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.9 * _blinkAnimation.value),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.blue.withValues(alpha: _blinkAnimation.value),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.record_voice_over,
                  color: Colors.white.withValues(alpha: _blinkAnimation.value),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.wordIndex + 1}/${widget.totalWords}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: _blinkAnimation.value),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for drawing highlights
class TTSHighlightPainter extends CustomPainter {
  final TTSHighlightType highlightType;
  final int? itemIndex;
  final double animationValue;

  TTSHighlightPainter({
    required this.highlightType,
    this.itemIndex,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.2 * animationValue)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    Rect highlightRect;

    switch (highlightType) {
      case TTSHighlightType.page:
      case TTSHighlightType.pageTitle:
        highlightRect = Rect.fromLTWH(0, 0, size.width, size.height);
        break;
        
      case TTSHighlightType.appBar:
        highlightRect = Rect.fromLTWH(0, 0, size.width, 80);
        break;
        
      case TTSHighlightType.searchBar:
        highlightRect = Rect.fromLTWH(16, 90, size.width - 32, 60);
        break;
        
      case TTSHighlightType.categoryFilter:
        highlightRect = Rect.fromLTWH(16, 160, size.width - 32, 50);
        break;
        
      case TTSHighlightType.contentCount:
      case TTSHighlightType.noContent:
        highlightRect = Rect.fromLTWH(16, 220, size.width - 32, 40);
        break;
        
      case TTSHighlightType.content:
        highlightRect = Rect.fromLTWH(16, 270, size.width - 32, size.height - 350);
        break;
        
      case TTSHighlightType.kataTitle:
      case TTSHighlightType.kataStyle:
      case TTSHighlightType.kataDescription:
      case TTSHighlightType.postTitle:
      case TTSHighlightType.postCategory:
      case TTSHighlightType.postAuthor:
      case TTSHighlightType.postContent:
        final cardTop = 270 + (itemIndex ?? 0) * 200.0;
        highlightRect = Rect.fromLTWH(16, cardTop, size.width - 32, 180);
        break;
        
      case TTSHighlightType.commentsHeader:
        highlightRect = Rect.fromLTWH(16, size.height * 0.6, size.width - 32, 40);
        break;
        
      case TTSHighlightType.comment:
        final commentTop = size.height * 0.65 + (itemIndex ?? 0) * 80.0;
        highlightRect = Rect.fromLTWH(16, commentTop, size.width - 32, 70);
        break;
    }

    // Draw highlight background
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      paint,
    );

    // Draw highlight border
    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(8)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Page types for TTS context awareness
enum TTSPageType {
  home,
  forum,
  favorites,
  forumPostDetail,
  custom,
}
