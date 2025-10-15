import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/kata_provider.dart';
import '../providers/forum_provider.dart';
import '../providers/interaction_provider.dart';
import '../services/unified_tts_service.dart';

/// Unified TTS Button - One button to rule them all!
/// This button works on ANY page, with ANY content, including popups, forms, and dialogs.
/// It's simple, reliable, and always works.
/// 
/// Features:
/// - Tap: TTS functionality (read screen content)
/// - Long press: Voice commands (speech-to-text)
/// - Visual feedback and animations
/// - Works globally on all screens
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
    this.size = 40.0, // Smaller, more compact default size
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

    // Use dark green background like the kata detail TTS button
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        (isSpeaking 
          ? Colors.green.shade600  // Slightly lighter green when speaking
          : Colors.green.shade700);  // Dark green background like kata detail screen
    
    final effectiveForegroundColor = widget.foregroundColor ?? 
        (isSpeaking 
          ? Colors.white  // White icon when speaking
          : (isEnabled 
            ? Colors.white  // White icon like kata detail screen
            : Colors.grey.shade400));  // Light grey when disabled

    Widget button = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSpeaking ? _pulseAnimation.value : 1.0,
          child: Container(
            width: widget.size ?? 40.0, // Smaller, more compact size
            height: widget.size ?? 40.0,
            decoration: BoxDecoration(
              color: effectiveBackgroundColor,
              borderRadius: BorderRadius.circular(8), // Rounded corners like the previous design
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),  // More prominent shadow like kata detail
                  blurRadius: isSpeaking ? 8 : 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () => _handleTTSAction(context, ref),
                child: InkWell(
                  onTap: () => _handleTTSAction(context, ref),
                  borderRadius: BorderRadius.circular(8),
                  child: Icon(
                    isSpeaking 
                      ? Icons.volume_up 
                      : (isEnabled 
                          ? (isHighContrast ? Icons.headset_mic : Icons.headphones)
                          : (isHighContrast ? Icons.headset_mic_outlined : Icons.headphones_outlined)),
                    color: effectiveForegroundColor,
                    size: (widget.size ?? 40.0) * 0.5, // Proportionally smaller icon
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (widget.showLabel) {
      button = Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          button,
          const SizedBox(height: 8),
          Flexible(
            child: Text(
              isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak + Stem' : 'Spraak uit'),
              style: TextStyle(
                fontSize: 12,
                color: isSpeaking 
                  ? Colors.green.shade600 
                  : (isEnabled 
                    ? Colors.green.shade700  // Match button background color
                    : Colors.grey.shade600),
                fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      color: Colors.transparent, // Ensure no background color
      child: button,
    );
  }

  Future<void> _handleTTSAction(BuildContext context, WidgetRef ref) async {
    // Check if widget is still mounted before using ref
    if (!mounted) {
      debugPrint('UnifiedTTS: Widget disposed, skipping TTS action');
      return;
    }
    
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
      // Use comprehensive screen reading from TTS service
      debugPrint('UnifiedTTS: Starting comprehensive screen reading');
      
      // Provide feedback - use safe method that works in any context
      if (context.mounted) {
        _showSafeFeedback(context, 'Scannen en voorlezen van alle inhoud...');
      }
      
      if (mounted && context.mounted) {
        // Find the proper screen context instead of using the button's context
        final screenContext = _findScreenContext(context);
        if (screenContext != null && screenContext.mounted) {
          await UnifiedTTSService.readCurrentScreen(screenContext, ref);
        } else {
          // Fallback to simple content reading when no valid screen context found
          debugPrint('UnifiedTTS: No valid screen context found, using simple content reading');
          await _readSimpleScreenContent(context, ref);
        }
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
      if (mounted && context.mounted) {
        // Find the proper screen context instead of using the button's context
        final screenContext = _findScreenContext(context);
        if (screenContext != null && screenContext.mounted) {
          await UnifiedTTSService.readCurrentScreen(screenContext, ref);
        } else {
          // Fallback to simple content reading when no valid screen context found
          debugPrint('UnifiedTTS: No valid screen context found, using simple content reading');
          await _readSimpleScreenContent(context, ref);
        }
      }
    }
  }


  /// Find the proper screen context by traversing up the widget tree
  /// to find the Scaffold or main screen content context
  BuildContext? _findScreenContext(BuildContext context) {
    try {
      // Check if context is still mounted before traversing
      if (!context.mounted) {
        debugPrint('UnifiedTTS: Context no longer mounted, cannot find screen context');
        return null;
      }
      
      debugPrint('UnifiedTTS: Finding screen context from ${context.widget.runtimeType}');
      
      // First, try to find a Scaffold context using safe method
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        debugPrint('UnifiedTTS: Found Scaffold widget, looking for its context');
        // Find the context that contains the Scaffold using safe traversal
        BuildContext? scaffoldContext;
        try {
          context.visitAncestorElements((element) {
            // Check if element is still active before accessing
            if (!element.mounted) {
              debugPrint('UnifiedTTS: Element no longer mounted during traversal');
              return false; // Stop searching
            }
            
            if (element.widget is Scaffold) {
              scaffoldContext = element;
              debugPrint('UnifiedTTS: Found Scaffold context: ${element.widget.runtimeType}');
              return false; // Stop searching
            }
            return true; // Continue searching
          });
        } catch (e) {
          debugPrint('UnifiedTTS: Error during Scaffold context traversal: $e');
        }
        
        if (scaffoldContext != null && scaffoldContext!.mounted) {
          debugPrint('UnifiedTTS: Using Scaffold context for text extraction');
          return scaffoldContext;
        }
      } else {
        debugPrint('UnifiedTTS: No Scaffold found in widget tree');
      }
      
      // If no Scaffold found, try to find the main screen context
      // Look for common screen widgets like StatefulWidget or StatelessWidget
      debugPrint('UnifiedTTS: Looking for main screen context...');
      BuildContext? screenContext;
      try {
        context.visitAncestorElements((element) {
          // Check if element is still active before accessing
          if (!element.mounted) {
            debugPrint('UnifiedTTS: Element no longer mounted during screen context traversal');
            return false; // Stop searching
          }
          
          final widget = element.widget;
          debugPrint('UnifiedTTS: Checking ancestor element: ${widget.runtimeType}');
          // Look for common screen widget types
          if (widget is StatefulWidget || widget is StatelessWidget) {
            // Skip the TTS button and overlay widgets
            if (widget.runtimeType.toString().contains('TTS') || 
                widget.runtimeType.toString().contains('Overlay')) {
              debugPrint('UnifiedTTS: Skipping TTS/Overlay widget: ${widget.runtimeType}');
              return true; // Continue searching
            }
            screenContext = element;
            debugPrint('UnifiedTTS: Found potential screen context: ${widget.runtimeType}');
            return false; // Stop searching
          }
          return true; // Continue searching
        });
      } catch (e) {
        debugPrint('UnifiedTTS: Error during screen context traversal: $e');
      }
      
      if (screenContext != null && screenContext!.mounted) {
        debugPrint('UnifiedTTS: Using screen context for text extraction: ${screenContext!.widget.runtimeType}');
        return screenContext;
      } else {
        debugPrint('UnifiedTTS: No suitable screen context found');
      }
      
      // Fallback: try to find any context that's not the TTS button
      BuildContext? fallbackContext;
      try {
        context.visitAncestorElements((element) {
          // Check if element is still active before accessing
          if (!element.mounted) {
            debugPrint('UnifiedTTS: Element no longer mounted during fallback traversal');
            return false; // Stop searching
          }
          
          final widget = element.widget;
          if (!widget.runtimeType.toString().contains('TTS') && 
              !widget.runtimeType.toString().contains('Overlay') &&
              !widget.runtimeType.toString().contains('AnimatedBuilder')) {
            fallbackContext = element;
            return false; // Stop searching
          }
          return true; // Continue searching
        });
      } catch (e) {
        debugPrint('UnifiedTTS: Error during fallback context traversal: $e');
      }
      
      if (fallbackContext != null && fallbackContext!.mounted) {
        debugPrint('UnifiedTTS: Using fallback context for text extraction: ${fallbackContext!.widget.runtimeType}');
        return fallbackContext;
      }
      
      debugPrint('UnifiedTTS: Could not find proper screen context, will use original context');
      return context.mounted ? context : null;
    } catch (e) {
      debugPrint('UnifiedTTS: Error finding screen context: $e');
      return context.mounted ? context : null; // Fallback to original context if still mounted
    }
  }

  /// Simple screen content reading with reliable fallback
  Future<void> _readSimpleScreenContent(BuildContext context, WidgetRef ref) async {
    // Check if widget is still mounted before using ref
    if (!mounted) {
      debugPrint('UnifiedTTS: Widget disposed, skipping simple screen content reading');
      return;
    }
    
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
        // Try to get more specific content based on current screen
        final route = ModalRoute.of(context);
        if (route?.settings.name != null) {
          final routeName = route!.settings.name!;
          final pageDescription = _getPageDescription(routeName);
          if (pageDescription.isNotEmpty) {
            content = pageDescription;
          } else {
            content = 'Welkom bij de Karate app. Gebruik de navigatie om door de app te bewegen.';
          }
        } else {
          content = 'Welkom bij de Karate app. Gebruik de navigatie om door de app te bewegen.';
        }
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
              // Read full description for favorites
              content += 'Beschrijving: ${kata.description}. ';
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
              // Read full content for favorites
              content += 'Inhoud: ${post.content}. ';
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

/// Helper function to easily add unified TTS to any screen
/// Note: This function is kept for backward compatibility
/// TTS is now globally available through main.dart
Widget withUnifiedTTS({
  required Widget child,
  bool enabled = true,
  EdgeInsets? margin,
  double? size = 40.0,
  Color? backgroundColor,
  Color? foregroundColor,
  bool showLabel = false,
}) {
  // Since TTS is now globally available, just return the child
  // This function is kept for backward compatibility
  return child;
}
