import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';

/// Comprehensive TTS Service with text cursor tracking and page reading
class ComprehensiveTTSService {
  static final ComprehensiveTTSService _instance = ComprehensiveTTSService._internal();
  factory ComprehensiveTTSService() => _instance;
  ComprehensiveTTSService._internal();

  static OverlayEntry? _currentHighlightOverlay;
  static OverlayEntry? _currentCursorOverlay;
  static bool _isReading = false;
  static String _currentText = '';
  static int _currentWordIndex = 0;
  static List<String> _currentWords = [];

  /// Read entire home page with visual highlighting and cursor tracking
  static Future<void> readHomePage(BuildContext context, WidgetRef ref) async {
    if (_isReading) {
      await stopReading(context, ref);
      return;
    }

    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _isReading = true;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      if (!context.mounted) return;
      
      // Start with page introduction
      await _speakWithCursor(
        context, 
        'Je bent op de hoofdpagina van Karatapp waar je alle kata\'s kunt bekijken en zoeken',
        accessibilityNotifier,
        highlightType: TTSHighlightType.page
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read AppBar
      await _speakWithCursor(
        context,
        'Karatapp hoofdmenu',
        accessibilityNotifier,
        highlightType: TTSHighlightType.appBar
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read search bar
      await _speakWithCursor(
        context,
        'Zoek kata\'s invoerveld',
        accessibilityNotifier,
        highlightType: TTSHighlightType.searchBar
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read kata cards sequentially
      await _readKataCardsSequentially(context, ref, accessibilityNotifier);
      
    } catch (e) {
      debugPrint('Error reading home page: $e');
    } finally {
      _isReading = false;
      _removeAllOverlays();
    }
  }

  /// Read entire forum page with visual highlighting and cursor tracking
  static Future<void> readForumPage(BuildContext context, WidgetRef ref) async {
    if (_isReading) {
      await stopReading(context, ref);
      return;
    }

    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _isReading = true;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      if (!context.mounted) return;
      
      // Start with page introduction
      await _speakWithCursor(
        context, 
        'Je bent op het forum waar je berichten kunt lezen en discussies kunt voeren',
        accessibilityNotifier,
        highlightType: TTSHighlightType.page
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read AppBar
      await _speakWithCursor(
        context,
        'Forum hoofdmenu',
        accessibilityNotifier,
        highlightType: TTSHighlightType.appBar
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read search bar
      await _speakWithCursor(
        context,
        'Zoek berichten invoerveld',
        accessibilityNotifier,
        highlightType: TTSHighlightType.searchBar
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read category filters
      await _speakWithCursor(
        context,
        'Categorie filters: Alle, Algemeen, Kata Verzoeken, Technieken, Evenementen, Feedback',
        accessibilityNotifier,
        highlightType: TTSHighlightType.categoryFilter
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read forum posts sequentially
      await _readForumPostsSequentially(context, ref, accessibilityNotifier);
      
    } catch (e) {
      debugPrint('Error reading forum page: $e');
    } finally {
      _isReading = false;
      _removeAllOverlays();
    }
  }

  /// Read forum post detail with comments
  static Future<void> readForumPostDetail(BuildContext context, WidgetRef ref, String postTitle, String postContent, List<String> comments) async {
    if (_isReading) {
      await stopReading(context, ref);
      return;
    }

    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _isReading = true;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      if (!context.mounted) return;
      
      // Read post title
      await _speakWithCursor(
        context,
        'Bericht titel: $postTitle',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postTitle
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read post content
      await _speakWithCursor(
        context,
        'Bericht inhoud: $postContent',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postContent
      );
      
      if (!context.mounted || !_isReading) return;
      
      // Read comments
      if (comments.isNotEmpty) {
        await _speakWithCursor(
          context,
          'Reacties: ${comments.length} reactie${comments.length == 1 ? '' : 's'}',
          accessibilityNotifier,
          highlightType: TTSHighlightType.commentsHeader
        );
        
        for (int i = 0; i < comments.length; i++) {
          if (!context.mounted || !_isReading) return;
          
          await _speakWithCursor(
            context,
            'Reactie ${i + 1}: ${comments[i]}',
            accessibilityNotifier,
            highlightType: TTSHighlightType.comment,
            itemIndex: i
          );
          
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
      
    } catch (e) {
      debugPrint('Error reading forum post detail: $e');
    } finally {
      _isReading = false;
      _removeAllOverlays();
    }
  }

  /// Read any page content with cursor tracking
  static Future<void> readPageContent(BuildContext context, WidgetRef ref, String content, {String? pageTitle}) async {
    if (_isReading) {
      await stopReading(context, ref);
      return;
    }

    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      _isReading = true;
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      if (!context.mounted) return;
      
      if (pageTitle != null) {
        await _speakWithCursor(
          context,
          'Pagina: $pageTitle',
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
      
    } catch (e) {
      debugPrint('Error reading page content: $e');
    } finally {
      _isReading = false;
      _removeAllOverlays();
    }
  }

  /// Stop reading and remove all overlays
  static Future<void> stopReading(BuildContext context, WidgetRef ref) async {
    _isReading = false;
    _removeAllOverlays();
    
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.stopSpeaking();
  }

  /// Check if currently reading
  static bool get isReading => _isReading;

  /// Read kata cards one by one with highlighting
  static Future<void> _readKataCardsSequentially(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    final kataState = ref.read(kataNotifierProvider);
    final katas = kataState.filteredKatas;
    
    if (katas.isEmpty) {
      await _speakWithCursor(
        context,
        'Geen kata\'s gevonden',
        accessibilityNotifier,
        highlightType: TTSHighlightType.noContent
      );
      return;
    }
    
    await _speakWithCursor(
      context,
      '${katas.length} kata${katas.length == 1 ? '' : '\'s'} gevonden',
      accessibilityNotifier,
      highlightType: TTSHighlightType.contentCount
    );
    
    for (int i = 0; i < katas.length && _isReading; i++) {
      final kata = katas[i];
      
      if (!context.mounted || !_isReading) return;
      
      await _speakWithCursor(
        context,
        'Kata ${i + 1}: ${kata.name}',
        accessibilityNotifier,
        highlightType: TTSHighlightType.kataTitle,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted || !_isReading) return;
      
      await _speakWithCursor(
        context,
        'Stijl: ${kata.style}',
        accessibilityNotifier,
        highlightType: TTSHighlightType.kataStyle,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted || !_isReading) return;
      
      if (kata.description.isNotEmpty) {
        await _speakWithCursor(
          context,
          'Beschrijving: ${kata.description}',
          accessibilityNotifier,
          highlightType: TTSHighlightType.kataDescription,
          itemIndex: i
        );
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Read forum posts one by one with highlighting
  static Future<void> _readForumPostsSequentially(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    final posts = ref.read(forumPostsProvider);
    
    if (posts.isEmpty) {
      await _speakWithCursor(
        context,
        'Geen berichten gevonden',
        accessibilityNotifier,
        highlightType: TTSHighlightType.noContent
      );
      return;
    }
    
    await _speakWithCursor(
      context,
      '${posts.length} bericht${posts.length == 1 ? '' : 'en'} gevonden',
      accessibilityNotifier,
      highlightType: TTSHighlightType.contentCount
    );
    
    for (int i = 0; i < posts.length && _isReading; i++) {
      final post = posts[i];
      
      if (!context.mounted || !_isReading) return;
      
      await _speakWithCursor(
        context,
        'Bericht ${i + 1}: ${post.title}',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postTitle,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted || !_isReading) return;
      
      await _speakWithCursor(
        context,
        'Categorie: ${post.category.displayName}',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postCategory,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted || !_isReading) return;
      
      await _speakWithCursor(
        context,
        'Auteur: ${post.authorName}',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postAuthor,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      if (!context.mounted || !_isReading) return;
      
      // Read first few sentences of content
      final contentPreview = post.content.length > 100 
          ? '${post.content.substring(0, 100)}...' 
          : post.content;
      
      await _speakWithCursor(
        context,
        'Inhoud: $contentPreview',
        accessibilityNotifier,
        highlightType: TTSHighlightType.postContent,
        itemIndex: i
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  /// Speak text with visual highlighting that appears during TTS and disappears when done
  static Future<void> _speakWithCursor(
    BuildContext context,
    String text,
    AccessibilityNotifier accessibilityNotifier,
    {required TTSHighlightType highlightType, int? itemIndex}
  ) async {
    if (!_isReading || !context.mounted) return;
    
    // Show highlight for the section being read
    _showHighlight(context, highlightType, itemIndex);
    
    try {
      // Start speaking
      await accessibilityNotifier.speak(text);
    } finally {
      // Always remove highlights after speaking (whether completed or interrupted)
      if (context.mounted) {
        _removeHighlight();
      }
    }
  }

  /// Show visual highlight on the element being read
  static void _showHighlight(BuildContext context, TTSHighlightType type, int? itemIndex) {
    _removeHighlight();
    
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => TTSHighlightWidget(
        highlightType: type,
        itemIndex: itemIndex,
      ),
    );
    
    overlay.insert(overlayEntry);
    _currentHighlightOverlay = overlayEntry;
  }


  /// Remove visual highlight
  static void _removeHighlight() {
    _currentHighlightOverlay?.remove();
    _currentHighlightOverlay = null;
  }

  /// Remove word cursor
  static void _removeWordCursor() {
    _currentCursorOverlay?.remove();
    _currentCursorOverlay = null;
  }

  /// Remove all overlays
  static void _removeAllOverlays() {
    _removeHighlight();
    _removeWordCursor();
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
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
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
      ..color = Colors.blue.withValues(alpha: 0.3 * animationValue)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8 * animationValue)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

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
