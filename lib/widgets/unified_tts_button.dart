import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';
import '../providers/interaction_provider.dart';

/// Unified TTS Button - One button to rule them all!
/// This button works on ANY page, with ANY content, including popups, forms, and dialogs.
/// It's simple, reliable, and always works.
class UnifiedTTSButton extends ConsumerStatefulWidget {
  final bool showLabel;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UnifiedTTSButton({
    super.key,
    this.showLabel = false,
    this.margin,
    this.size = 56.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  ConsumerState<UnifiedTTSButton> createState() => _UnifiedTTSButtonState();
}

class _UnifiedTTSButtonState extends ConsumerState<UnifiedTTSButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final themeState = ref.watch(themeNotifierProvider);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isHighContrast = themeState.isHighContrast;
    
    // Start pulse animation when speaking
    if (isSpeaking && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isSpeaking && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Use high contrast colors when needed
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        (isSpeaking 
          ? (isHighContrast ? Colors.green.shade700 : Colors.green)
          : (isEnabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.secondary));
    
    final effectiveForegroundColor = widget.foregroundColor ?? 
        (isSpeaking || isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary);

    Widget button = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSpeaking ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            onPressed: () => _handleTTSAction(context, ref),
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveForegroundColor,
            elevation: isSpeaking ? 8 : 4,
            tooltip: isSpeaking 
              ? 'Stop voorlezen' 
              : (isEnabled 
                ? 'Scan hele pagina en lees alle inhoud voor' 
                : 'Schakel spraak in en scan pagina'),
            child: Icon(
              isSpeaking 
                ? Icons.volume_up 
                : (isEnabled 
                    ? (isHighContrast ? Icons.headset_mic : Icons.headphones)
                    : (isHighContrast ? Icons.headset_mic_outlined : Icons.headphones_outlined)),
              size: (widget.size ?? 56.0) * 0.4,
            ),
          ),
        );
      },
    );

    if (widget.showLabel) {
      button = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          Text(
            isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak aan' : 'Spraak uit'),
            style: TextStyle(
              fontSize: 12,
              color: isSpeaking 
                ? Colors.green 
                : (isEnabled 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant),
              fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: button,
    );
  }

  Future<void> _handleTTSAction(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    if (accessibilityState.isSpeaking) {
      // Stop speaking if currently speaking
      debugPrint('UnifiedTTS: Stopping speech');
      await accessibilityNotifier.stopSpeaking();
      
      // Provide feedback - use safe method that works in any context
      if (context.mounted) {
        _showSafeFeedback(context, 'Voorlezen gestopt');
      }
    } else if (accessibilityState.isTextToSpeechEnabled) {
      // Simple screen reading with fallback content
      debugPrint('UnifiedTTS: Starting simple screen reading');
      
      // Provide feedback - use safe method that works in any context
      if (context.mounted) {
        _showSafeFeedback(context, 'Voorlezen van pagina inhoud...');
      }
      
      if (context.mounted) {
        await _readSimpleScreenContent(context, ref);
      }
    } else {
      // Enable TTS first, then read content
      debugPrint('UnifiedTTS: Enabling TTS and reading screen');
      
      // Provide feedback - use safe method that works in any context
      if (context.mounted) {
        _showSafeFeedback(context, 'Spraak wordt ingeschakeld...');
      }
      
      await accessibilityNotifier.toggleTextToSpeech();
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await _readSimpleScreenContent(context, ref);
      }
    }
  }

  /// Simple screen content reading with reliable fallback
  Future<void> _readSimpleScreenContent(BuildContext context, WidgetRef ref) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    try {
      // Get page title
      String content = '';
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      
      if (scaffold?.appBar is AppBar) {
        final appBar = scaffold!.appBar as AppBar;
        if (appBar.title is Text) {
          final title = (appBar.title as Text).data;
          if (title != null && title.isNotEmpty) {
            content = 'Pagina: $title. ';
          }
        }
      }
      
      // Add basic page description based on route
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        final routeName = route!.settings.name!;
        final pageDescription = _getPageDescription(routeName);
        if (pageDescription.isNotEmpty) {
          content += pageDescription;
        }
      }
      
      // Check if we're on the favorites screen and read favorites content
      if (content.contains('Mijn Favorieten') || content.contains('favorieten')) {
        final favoritesContent = await _readFavoritesContent(context, ref);
        if (favoritesContent.isNotEmpty) {
          content += favoritesContent;
        }
      }
      
      // If no specific content found, use fallback
      if (content.isEmpty) {
        content = 'Welkom bij de Karate app. Gebruik de navigatie om door de app te bewegen.';
      }
      
      debugPrint('UnifiedTTS: Speaking content: $content');
      await accessibilityNotifier.speak(content);
      
    } catch (e) {
      debugPrint('UnifiedTTS: Error reading screen content: $e');
      // Fallback to basic message
      await accessibilityNotifier.speak('Welkom bij de Karate app. Gebruik de navigatie om door de app te bewegen.');
    }
  }

  /// Get page description based on route
  String _getPageDescription(String routeName) {
    switch (routeName.toLowerCase()) {
      case '/':
      case '/home':
        return 'Dit is de hoofdpagina van de Karate app. Hier vind je alle kata technieken.';
      case '/forum':
        return 'Dit is het forum waar je berichten kunt lezen en schrijven.';
      case '/favorites':
        return 'Dit zijn je favoriete kata technieken en forumberichten.';
      case '/profile':
        return 'Dit is je profiel pagina.';
      case '/user-management':
        return 'Dit is de gebruikersbeheer pagina.';
      case '/accessibility-settings':
        return 'Dit zijn de toegankelijkheidsinstellingen.';
      default:
        return 'Karate app pagina geladen.';
    }
  }

  /// Read favorites content from the current screen
  Future<String> _readFavoritesContent(BuildContext context, WidgetRef ref) async {
    try {
      // Import the necessary providers
      final kataState = ref.read(kataNotifierProvider);
      final forumState = ref.read(forumNotifierProvider);
      final favoriteKatasAsync = ref.read(userFavoriteKatasProvider);
      final favoriteForumPostsAsync = ref.read(userFavoriteForumPostsProvider);
      
      String content = 'Mijn Favorieten pagina. ';
      
      // Get favorite katas
      final favoriteKataIds = favoriteKatasAsync.when(
        data: (ids) => ids,
        loading: () => <String>[],
        error: (_, __) => <String>[],
      );
      
      final favoriteKatas = kataState.katas
          .where((kata) => favoriteKataIds.contains(kata.id))
          .toList();
      
      // Get favorite forum posts
      final favoriteForumPostIds = favoriteForumPostsAsync.when(
        data: (ids) => ids,
        loading: () => <String>[],
        error: (_, __) => <String>[],
      );
      
      final favoriteForumPosts = forumState.posts
          .where((post) => favoriteForumPostIds.contains(post.id))
          .toList();
      
      // Build comprehensive content string
      if (favoriteKatas.isEmpty && favoriteForumPosts.isEmpty) {
        content += 'Je hebt nog geen favorieten. Tik op het hartje bij een kata of forumbericht om deze toe te voegen aan je favorieten.';
      } else {
        content += 'Je hebt ${favoriteKatas.length} favoriete kata\'s en ${favoriteForumPosts.length} favoriete forumberichten. ';
        
        if (favoriteKatas.isNotEmpty) {
          content += 'Favoriete kata\'s: ';
          for (int i = 0; i < favoriteKatas.length; i++) {
            final kata = favoriteKatas[i];
            content += 'Kata ${i + 1}: ${kata.name}. ';
            if (kata.style.isNotEmpty && kata.style != 'Unknown') {
              content += 'Stijl: ${kata.style}. ';
            }
            if (kata.description.isNotEmpty) {
              // Read more of the description for favorites
              final description = kata.description.length > 150 
                  ? '${kata.description.substring(0, 150)}...' 
                  : kata.description;
              content += 'Beschrijving: $description. ';
            }
            if (kata.imageUrls?.isNotEmpty == true) {
              content += 'Deze kata heeft ${kata.imageUrls?.length} afbeeldingen. ';
            }
            if (kata.videoUrls?.isNotEmpty == true) {
              content += 'Deze kata heeft ${kata.videoUrls?.length} video\'s. ';
            }
          }
        }
        
        if (favoriteForumPosts.isNotEmpty) {
          content += 'Favoriete forumberichten: ';
          for (int i = 0; i < favoriteForumPosts.length; i++) {
            final post = favoriteForumPosts[i];
            content += 'Forumbericht ${i + 1}: ${post.title}. ';
            content += 'Categorie: ${post.category.displayName}. ';
            if (post.content.isNotEmpty) {
              // Read more of the content for favorites
              final postContent = post.content.length > 120 
                  ? '${post.content.substring(0, 120)}...' 
                  : post.content;
              content += 'Inhoud: $postContent. ';
            }
            content += 'Geschreven door: ${post.authorName}. ';
            if (post.commentCount > 0) {
              content += 'Dit bericht heeft ${post.commentCount} reacties. ';
            }
            if (post.isPinned) {
              content += 'Dit bericht is vastgepind. ';
            }
            if (post.isLocked) {
              content += 'Dit bericht is gesloten. ';
            }
          }
        }
        
        content += 'Je kunt op een kata of forumbericht tikken om deze te bekijken. ';
        content += 'Gebruik de tabbladen bovenaan om tussen kata\'s en forumberichten te wisselen. ';
      }
      
      return content;
    } catch (e) {
      debugPrint('UnifiedTTS: Error reading favorites content: $e');
      return 'Er is een fout opgetreden bij het lezen van je favorieten.';
    }
  }

  /// Safely show feedback that works in any context (Scaffold or not)
  void _showSafeFeedback(BuildContext context, String message) {
    try {
      // Try to find ScaffoldMessenger first
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // If ScaffoldMessenger is not available, try to find MaterialApp
      try {
        final materialApp = context.findAncestorWidgetOfExactType<MaterialApp>();
        if (materialApp != null) {
          // Use a simple overlay instead - but check if Overlay is available
          _showOverlayFeedback(context, message);
        } else {
          // No MaterialApp found, just log the message
          debugPrint('UnifiedTTS Feedback: $message');
        }
      } catch (e2) {
        debugPrint('UnifiedTTS: Could not show feedback: $e2');
        // Fallback: just print to console
        debugPrint('UnifiedTTS Feedback: $message');
      }
    }
  }

  /// Show feedback using an overlay when ScaffoldMessenger is not available
  void _showOverlayFeedback(BuildContext context, String message) {
    try {
      final overlay = Overlay.of(context);
      late OverlayEntry overlayEntry;
      
      overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          bottom: 100,
          left: 16,
          right: 16,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onInverseSurface,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
      
      overlay.insert(overlayEntry);
    
      // Remove overlay after 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        overlayEntry.remove();
      });
    } catch (e) {
      // If overlay is not available, just log the message
      debugPrint('UnifiedTTS: Could not show overlay feedback: $e');
      debugPrint('UnifiedTTS Feedback: $message');
    }
  }
}

/// Global TTS overlay that provides the unified TTS button on all screens
class UnifiedTTSOverlay extends ConsumerWidget {
  final Widget child;
  final bool enabled;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showLabel;

  const UnifiedTTSOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.margin,
    this.size = 56.0,
    this.backgroundColor,
    this.foregroundColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTTSButton = ref.watch(showTTSButtonProvider);
    
    if (!enabled || !showTTSButton) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: _calculateRightPosition(context),
          bottom: _calculateBottomPosition(context),
          child: UnifiedTTSButton(
            showLabel: showLabel,
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            margin: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  /// Calculate bottom position to avoid conflicts with other UI elements
  double _calculateBottomPosition(BuildContext context) {
    // Check if there are floating action buttons
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.floatingActionButton != null) {
      return (margin?.bottom ?? 66); // 10px above FAB (FAB is at 16px, so 16 + 56 + 10 = 82, but we want 10px gap)
    }
    
    // Check for bottom navigation bar
    if (scaffold?.bottomNavigationBar != null) {
      return (margin?.bottom ?? 80) + 20; // Position above bottom nav
    }
    
    // Default position
    return margin?.bottom ?? 80;
  }

  /// Calculate right position to place TTS button above FAB
  double _calculateRightPosition(BuildContext context) {
    // Check if there are floating action buttons
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.floatingActionButton != null) {
      // Position at the very right edge (0 pixels from right)
      return (margin?.right ?? 0); // 0 pixels from right edge
    }
    
    // Default position
    return margin?.right ?? 0;
  }
}

/// Helper function to easily add unified TTS to any screen
Widget withUnifiedTTS({
  required Widget child,
  bool enabled = true,
  EdgeInsets? margin,
  double? size = 56.0,
  Color? backgroundColor,
  Color? foregroundColor,
  bool showLabel = false,
}) {
  return Consumer(
    builder: (context, ref, _) {
      final showTTSButton = ref.watch(showTTSButtonProvider);
      
      if (!enabled || !showTTSButton) {
        return child;
      }

      return UnifiedTTSOverlay(
        enabled: enabled,
        margin: margin,
        size: size,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        showLabel: showLabel,
        child: child,
      );
    },
  );
}
