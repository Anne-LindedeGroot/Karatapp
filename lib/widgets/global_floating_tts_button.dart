import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';
import '../services/global_text_extractor.dart';
import '../services/universal_tts_service.dart';
import '../services/context_aware_page_tts_service.dart';

/// Global floating TTS button that reads all text content from the current screen
class GlobalFloatingTTSButton extends ConsumerStatefulWidget {
  final bool showLabel;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? tooltip;

  const GlobalFloatingTTSButton({
    super.key,
    this.showLabel = false,
    this.margin,
    this.size = 56.0,
    this.backgroundColor,
    this.foregroundColor,
    this.tooltip,
  });

  @override
  ConsumerState<GlobalFloatingTTSButton> createState() => _GlobalFloatingTTSButtonState();
}

class _GlobalFloatingTTSButtonState extends ConsumerState<GlobalFloatingTTSButton>
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
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
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
            onPressed: () => _handleTTSAction(context, ref, accessibilityNotifier),
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveForegroundColor,
            // Remove tooltip to avoid overlay issues
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


  Future<void> _handleTTSAction(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    
    if (accessibilityState.isSpeaking) {
      // Stop speaking if currently speaking
      await accessibilityNotifier.stopSpeaking();
    } else if (accessibilityState.isTextToSpeechEnabled) {
      // Read all text from current screen
      await _readAllScreenText(context, ref, accessibilityNotifier);
    } else {
      // Enable TTS first, then read content
      await accessibilityNotifier.toggleTextToSpeech();
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await _readAllScreenText(context, ref, accessibilityNotifier);
      }
    }
  }

  Future<void> _readAllScreenText(
    BuildContext context, 
    WidgetRef ref, 
    AccessibilityNotifier accessibilityNotifier
  ) async {
    try {
      // Get current route for context
      final currentRoute = _getCurrentRoute(context);
      final screenName = _getCurrentScreenName(context);
      
      debugPrint('TTS DEBUG: Reading content for route: $currentRoute, screen name: $screenName');
      
      // Special handling for splash screen - only if we're actually on the splash screen
      if (currentRoute == '/' || currentRoute == '/splash') {
        // Check if we're actually on the splash screen by looking for splash screen content
        final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        if (scaffold != null) {
          final bodyText = GlobalTextExtractor.extractTextFromWidget(scaffold.body ?? Container());
          if (bodyText.contains('Karatapp') && bodyText.contains('Jouw Karate Reis')) {
            // We're actually on the splash screen
            await accessibilityNotifier.speak('Welkom bij Karatapp. Jouw Karate Reis. De app wordt geladen. Even geduld.');
            return;
          }
        }
        // If we're not actually on the splash screen, continue with normal text extraction
      }
      
      // First check if we're in a dialog/popup
      final dialogContext = _detectDialogContext(context);
      if (dialogContext != null) {
        await _readDialogContent(context, ref, dialogContext);
        return;
      }

      // Check if menu is open and read menu content
      if (_isMenuOpen(context)) {
        await ContextAwarePageTTSService.readMenuContent(context, ref);
        return;
      }

      // Check for specific page contexts and use context-aware reading
      final pageContext = _detectPageContext(context);
      if (pageContext != null) {
        await _readPageContent(context, ref, pageContext);
        return;
      }

      // Use the enhanced UniversalTTSService for comprehensive text extraction
      String allText = UniversalTTSService.extractCurrentPageText(context);
      
      if (allText.isNotEmpty) {
        await accessibilityNotifier.speak(allText);
      } else {
        // Final fallback with helpful message
        await accessibilityNotifier.speak('Je bent nu op $screenName. Deze pagina bevat verschillende elementen en knoppen. Gebruik de navigatie om door de app te bewegen. Tik op elementen om interactie te hebben.');
      }
    } catch (e) {
      debugPrint('Error reading entire page: $e');
      
      // Final fallback with helpful message
      try {
        final screenName = _getCurrentScreenName(context);
        await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de scherm inhoud. Je bent nu op $screenName. Deze pagina bevat verschillende elementen en knoppen. Gebruik de navigatie om door de app te bewegen.');
      } catch (fallbackError) {
        debugPrint('Error in final fallback: $fallbackError');
        await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de scherm inhoud. Deze pagina bevat verschillende elementen en knoppen. Gebruik de navigatie om door de app te bewegen.');
      }
    }
  }


  /// Detect if we're in a dialog/popup context
  String? _detectDialogContext(BuildContext context) {
    try {
      // Check for various dialog types
      final dialog = context.findAncestorWidgetOfExactType<Dialog>() ?? 
                     context.findAncestorWidgetOfExactType<AlertDialog>() ??
                     context.findAncestorWidgetOfExactType<SimpleDialog>();
      
      if (dialog != null) {
        // Try to determine dialog type by content
        final dialogText = GlobalTextExtractor.extractTextFromWidget(dialog);
        
        if (dialogText.toLowerCase().contains('uitloggen') || 
            dialogText.toLowerCase().contains('logout')) {
          return 'logout_popup';
        } else if (dialogText.toLowerCase().contains('verwijder') || 
                   dialogText.toLowerCase().contains('delete')) {
          return 'delete_popup';
        } else if (dialogText.toLowerCase().contains('afbeeldingen') || 
                   dialogText.toLowerCase().contains('opruimen')) {
          return 'clean_images_popup';
        } else if (dialogText.toLowerCase().contains('beschrijving') || 
                   dialogText.toLowerCase().contains('description')) {
          return 'kata_form_description_dialog';
        }
      }
    } catch (e) {
      debugPrint('Error detecting dialog context: $e');
    }
    
    return null;
  }

  /// Detect the current page context
  String? _detectPageContext(BuildContext context) {
    try {
      // First try GoRouter
      try {
        final router = GoRouter.of(context);
        final routeName = router.routerDelegate.currentConfiguration.uri.toString();
        debugPrint('TTS DEBUG: GoRouter route detected: $routeName');
        final pageContext = _getPageContextFromRoute(routeName);
        if (pageContext != null) {
          debugPrint('TTS DEBUG: Page context found via GoRouter: $pageContext');
          return pageContext;
        }
      } catch (goRouterError) {
        debugPrint('GoRouter not available: $goRouterError');
      }
      
      // Fallback to ModalRoute
      try {
        final route = ModalRoute.of(context);
        if (route != null && route.settings.name != null) {
          final routeName = route.settings.name!;
          debugPrint('TTS DEBUG: ModalRoute detected: $routeName');
          final pageContext = _getPageContextFromRoute(routeName);
          if (pageContext != null) {
            debugPrint('TTS DEBUG: Page context found via ModalRoute: $pageContext');
            return pageContext;
          }
        }
      } catch (fallbackError) {
        debugPrint('Error in fallback page context detection: $fallbackError');
      }
      
      // Fallback: try to detect by widget type and content
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        final appBar = scaffold.appBar;
        if (appBar != null) {
          final appBarText = GlobalTextExtractor.extractTextFromWidget(appBar);
          debugPrint('TTS DEBUG: AppBar text detected: $appBarText');
          
          if (appBarText.toLowerCase().contains('forum')) {
            debugPrint('TTS DEBUG: Detected forum context from AppBar');
            return 'forum_home';
          } else if (appBarText.toLowerCase().contains('profiel')) {
            debugPrint('TTS DEBUG: Detected profile context from AppBar');
            return 'profile';
          } else if (appBarText.toLowerCase().contains('favorieten')) {
            debugPrint('TTS DEBUG: Detected favorites context from AppBar');
            return 'favorites';
          }
        }
        
        // Try to detect by body content
        if (scaffold.body != null) {
          final bodyText = GlobalTextExtractor.extractTextFromWidget(scaffold.body!);
          debugPrint('TTS DEBUG: Body text detected: ${bodyText.substring(0, bodyText.length > 100 ? 100 : bodyText.length)}...');
          
          if (bodyText.toLowerCase().contains('gebruikersprofiel') || 
              bodyText.toLowerCase().contains('e-mail adres') ||
              bodyText.toLowerCase().contains('volledige naam')) {
            debugPrint('TTS DEBUG: Detected profile context from body content');
            return 'profile';
          } else if (bodyText.toLowerCase().contains('favoriete') || 
                     bodyText.toLowerCase().contains('katas') ||
                     bodyText.toLowerCase().contains('forum berichten')) {
            debugPrint('TTS DEBUG: Detected favorites context from body content');
            return 'favorites';
          } else if (bodyText.toLowerCase().contains('forum berichten') ||
                     bodyText.toLowerCase().contains('nieuw bericht maken')) {
            debugPrint('TTS DEBUG: Detected forum context from body content');
            return 'forum_home';
          }
        }
      }
    } catch (e) {
      debugPrint('Error detecting page context: $e');
    }
    
    debugPrint('TTS DEBUG: No page context detected, will use fallback');
    return null;
  }

  String? _getPageContextFromRoute(String routeName) {
    switch (routeName) {
      case '/':
        return 'app_bar_and_home';
      case '/home':
        return 'app_bar_and_home';
      case '/profile':
        return 'profile';
      case '/favorites':
        return 'favorites';
      case '/forum':
        return 'forum_home';
      case '/forum/create':
        return 'forum_post_form';
      case '/kata/edit':
        return 'kata_form';
      case '/user-management':
        return 'user_management';
      default:
        // Check if it's a dynamic route
        if (routeName.startsWith('/forum/post/')) {
          return 'forum_post_detail';
        } else if (routeName.startsWith('/kata/edit/')) {
          return 'kata_form';
        }
        return null;
    }
  }

  /// Check if a menu/drawer is currently open
  bool _isMenuOpen(BuildContext context) {
    try {
      // Check for open drawer
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState != null) {
          return scaffoldState.isDrawerOpen || scaffoldState.isEndDrawerOpen;
        }
      }
      
      // Check for popup menu by looking for PopupMenuButton in the widget tree
      // This is a simplified check - in practice, popup menu state is harder to detect
      final popupMenu = context.findAncestorWidgetOfExactType<PopupMenuButton>();
      if (popupMenu != null) {
        // For now, we'll assume popup menus are not open when this check runs
        // In a real implementation, you'd need to track popup menu state
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking menu state: $e');
      return false;
    }
  }

  /// Read dialog content using context-aware service
  Future<void> _readDialogContent(BuildContext context, WidgetRef ref, String dialogContext) async {
    try {
      switch (dialogContext) {
        case 'logout_popup':
          await ContextAwarePageTTSService.readLogoutPopup(context, ref);
          break;
        case 'delete_popup':
          await ContextAwarePageTTSService.readDeletePopup(context, ref);
          break;
        case 'clean_images_popup':
          await ContextAwarePageTTSService.readCleanImagesPopup(context, ref);
          break;
        case 'kata_form_description_dialog':
          await ContextAwarePageTTSService.readKataFormDescriptionDialog(context, ref);
          break;
        default:
          // Fallback for unknown dialog types
          final dialogText = GlobalTextExtractor.extractTextFromContext(context);
          final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
          await accessibilityNotifier.speak('Popup venster. $dialogText');
      }
    } catch (e) {
      debugPrint('Error reading dialog content: $e');
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de popup inhoud.');
    }
  }

  /// Read page content using context-aware service
  Future<void> _readPageContent(BuildContext context, WidgetRef ref, String pageContext) async {
    try {
      switch (pageContext) {
        case 'profile':
          await ContextAwarePageTTSService.readProfileScreen(context, ref);
          break;
        case 'kata_form':
          final isEdit = ModalRoute.of(context)?.settings.name == '/edit-kata';
          await ContextAwarePageTTSService.readKataForm(context, ref, isEdit: isEdit);
          break;
        case 'favorites':
          await ContextAwarePageTTSService.readFavoritesScreen(context, ref, 'katas');
          break;
        case 'forum_home':
          await ContextAwarePageTTSService.readForumHomePage(context, ref);
          break;
        case 'forum_post_form':
          await ContextAwarePageTTSService.readForumPostForm(context, ref);
          break;
        case 'forum_post_detail':
          await ContextAwarePageTTSService.readForumPostDetail(context, ref);
          break;
        case 'user_management':
          await ContextAwarePageTTSService.readUserManagementScreen(context, ref);
          break;
        case 'app_bar_and_home':
          await ContextAwarePageTTSService.readAppBarAndHomePage(context, ref);
          break;
        default:
          // Fallback to general text extraction with comprehensive reading
          final allText = GlobalTextExtractor.extractTextFromContext(context);
          final screenName = _getCurrentScreenName(context);
          final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
          
          // Use more comprehensive text extraction for fallback
          String comprehensiveText = allText;
          if (comprehensiveText.isEmpty) {
            try {
              comprehensiveText = UniversalTTSService.extractTextWithSemantics(context);
            } catch (e) {
              debugPrint('Error in comprehensive text extraction: $e');
            }
          }
          
          await accessibilityNotifier.speak('Je bent nu op $screenName. $comprehensiveText');
      }
    } catch (e) {
      debugPrint('Error reading page content: $e');
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de pagina inhoud.');
    }
  }

  /// Get the current route using GoRouter
  String _getCurrentRoute(BuildContext context) {
    try {
      // First try GoRouter
      try {
        final router = GoRouter.of(context);
        return router.routerDelegate.currentConfiguration.uri.toString();
      } catch (goRouterError) {
        debugPrint('GoRouter not available: $goRouterError');
      }
      
      // Fallback to ModalRoute
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null && modalRoute.settings.name != null) {
        return modalRoute.settings.name!;
      }
      
      // Final fallback
      return '/home';
    } catch (e) {
      debugPrint('Error getting current route: $e');
      return '/home';
    }
  }

  String _getCurrentScreenName(BuildContext context) {
    try {
      // First try GoRouter
      try {
        final router = GoRouter.of(context);
        final routeName = router.routerDelegate.currentConfiguration.uri.toString();
        debugPrint('TTS DEBUG: Current route name: $routeName');
        return _getScreenNameFromRoute(routeName);
      } catch (goRouterError) {
        debugPrint('GoRouter not available: $goRouterError');
      }
      
      // Fallback to ModalRoute
      try {
        final route = ModalRoute.of(context);
        if (route != null && route.settings.name != null) {
          final routeName = route.settings.name!;
          debugPrint('TTS DEBUG: ModalRoute name: $routeName');
          return _getScreenNameFromRoute(routeName);
        }
      } catch (fallbackError) {
        debugPrint('Error in fallback screen name detection: $fallbackError');
      }
      
      // Final fallback
      debugPrint('TTS DEBUG: No route detected, returning "dit scherm"');
      return 'dit scherm';
    } catch (e) {
      debugPrint('TTS DEBUG: Error getting screen name: $e');
      return 'dit scherm';
    }
  }

  String _getScreenNameFromRoute(String routeName) {
    switch (routeName) {
      case '/':
        return 'de hoofdpagina';
      case '/home':
        return 'de hoofdpagina';
      case '/profile':
        return 'het profiel scherm';
      case '/favorites':
        return 'de favorieten pagina';
      case '/forum':
        return 'het forum';
      case '/forum/create':
        return 'het forum bericht aanmaken scherm';
      case '/kata/edit':
        return 'het kata bewerken scherm';
      case '/avatar-selection':
        return 'de avatar selectie pagina';
      case '/user-management':
        return 'het gebruikersbeheer scherm';
      case '/accessibility-demo':
        return 'de toegankelijkheidsinstellingen';
      case '/login':
        return 'de inlog pagina';
      case '/signup':
        return 'de registratie pagina';
      default:
        // Check if it's a dynamic route
        if (routeName.startsWith('/forum/post/')) {
          return 'het forum bericht detail scherm';
        } else if (routeName.startsWith('/kata/edit/')) {
          return 'het kata bewerken scherm';
        }
        debugPrint('TTS DEBUG: Unknown route, returning "dit scherm"');
        return 'dit scherm';
    }
  }

  /// Alternative text extraction method using semantic labels and accessibility
  String _extractAlternativeText(BuildContext context) {
    final StringBuffer text = StringBuffer();
    
    try {
      // Try to extract from AppBar title
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.appBar != null) {
        final appBar = scaffold!.appBar!;
        if (appBar is AppBar && appBar.title is Text) {
          final title = (appBar.title as Text).data;
          if (title != null && title.isNotEmpty) {
            text.write('Pagina titel: $title. ');
          }
        }
      }
      
      // Try to extract from any visible text widgets
      final element = context as Element;
      _extractTextFromElement(element, text);
      
      // If still no text, provide a generic description
      if (text.toString().trim().isEmpty) {
        text.write('Deze pagina bevat verschillende elementen en knoppen. ');
        text.write('Gebruik de navigatie om door de app te bewegen. ');
        text.write('Tik op elementen om interactie te hebben. ');
      }
      
    } catch (e) {
      debugPrint('Error in alternative text extraction: $e');
      text.write('Deze pagina is geladen. ');
    }
    
    return text.toString().trim();
  }

  /// Extract text from element tree
  void _extractTextFromElement(Element element, StringBuffer text) {
    try {
      final widget = element.widget;
      
      // Check for Text widgets
      if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          text.write('$data. ');
        }
      }
      
      // Check for RichText widgets
      if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          text.write('$plainText. ');
        }
      }
      
      // Check for semantic labels
      if (widget is Semantics) {
        final label = widget.properties.label;
        if (label != null && label.trim().isNotEmpty) {
          text.write('$label. ');
        }
      }
      
      // Traverse children
      element.visitChildren((child) => _extractTextFromElement(child, text));
      
    } catch (e) {
      // Skip problematic elements
    }
  }

  /// Enhanced text extraction that tries multiple methods
  Future<String> _extractAllVisibleText(BuildContext context) async {
    final StringBuffer allText = StringBuffer();
    
    try {
      // Method 1: Universal TTS service with enhanced extraction
      try {
        final universalText = UniversalTTSService.extractTextWithSemantics(context);
        if (universalText.isNotEmpty) {
          allText.write(universalText);
          debugPrint('TTS DEBUG: UniversalTTSService result: "${universalText}" (${universalText.length} characters)');
        }
      } catch (e) {
        debugPrint('TTS DEBUG: UniversalTTSService error: $e');
      }
      
      // Method 2: Global text extractor if first failed or empty
      if (allText.toString().trim().isEmpty) {
        try {
          final globalText = GlobalTextExtractor.extractTextFromContext(context);
          if (globalText.isNotEmpty) {
            allText.write(globalText);
            debugPrint('TTS DEBUG: GlobalTextExtractor result: "${globalText}" (${globalText.length} characters)');
          }
        } catch (e) {
          debugPrint('TTS DEBUG: GlobalTextExtractor error: $e');
        }
      }
      
      // Method 3: Alternative extraction
      if (allText.toString().trim().isEmpty) {
        try {
          final alternativeText = _extractAlternativeText(context);
          if (alternativeText.isNotEmpty) {
            allText.write(alternativeText);
            debugPrint('TTS DEBUG: Alternative extraction result: "${alternativeText}" (${alternativeText.length} characters)');
          }
        } catch (e) {
          debugPrint('TTS DEBUG: Alternative extraction error: $e');
        }
      }
      
      // Method 4: Direct widget tree traversal
      if (allText.toString().trim().isEmpty) {
        try {
          final directText = _extractDirectWidgetText(context);
          if (directText.isNotEmpty) {
            allText.write(directText);
            debugPrint('TTS DEBUG: Direct widget extraction result: "${directText}" (${directText.length} characters)');
          }
        } catch (e) {
          debugPrint('TTS DEBUG: Direct widget extraction error: $e');
        }
      }
      
      // Method 5: Enhanced widget extraction
      if (allText.toString().trim().isEmpty) {
        try {
          final enhancedText = UniversalTTSService.extractAllTextFromWidget(context.widget);
          if (enhancedText.isNotEmpty) {
            allText.write(enhancedText);
            debugPrint('TTS DEBUG: Enhanced widget extraction result: "${enhancedText}" (${enhancedText.length} characters)');
          }
        } catch (e) {
          debugPrint('TTS DEBUG: Enhanced widget extraction error: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Error in enhanced text extraction: $e');
    }
    
    return allText.toString().trim();
  }

  /// Direct widget text extraction method
  String _extractDirectWidgetText(BuildContext context) {
    final StringBuffer text = StringBuffer();
    
    try {
      // Get the current widget and traverse its tree
      final element = context as Element;
      _traverseWidgetTree(element, text);
      
      // Also try to get text from the scaffold if available
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        _extractFromScaffoldDirect(scaffold, text);
      }
      
    } catch (e) {
      debugPrint('Error in direct widget text extraction: $e');
    }
    
    return text.toString().trim();
  }

  /// Traverse widget tree directly
  void _traverseWidgetTree(Element element, StringBuffer text) {
    try {
      final widget = element.widget;
      
      // Handle different widget types
      if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          text.write('$data. ');
        }
      } else if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          text.write('$plainText. ');
        }
      } else if (widget is TextField || widget is TextFormField) {
        text.write('Invoerveld beschikbaar. ');
      } else if (widget is ElevatedButton || widget is OutlinedButton || widget is TextButton) {
        text.write('Knop beschikbaar. ');
      } else if (widget is IconButton) {
        text.write('Knop met icoon. ');
      } else if (widget is ListTile) {
        text.write('Lijst item. ');
      } else if (widget is Card) {
        text.write('Kaart element. ');
      }
      
      // Traverse children
      element.visitChildren((child) => _traverseWidgetTree(child, text));
      
    } catch (e) {
      // Skip problematic elements
    }
  }

  /// Extract text directly from scaffold
  void _extractFromScaffoldDirect(Scaffold scaffold, StringBuffer text) {
    try {
      // Extract AppBar text
      if (scaffold.appBar != null) {
        final appBar = scaffold.appBar!;
        if (appBar is AppBar && appBar.title is Text) {
          final title = (appBar.title as Text).data;
          if (title != null && title.isNotEmpty) {
            text.write('Pagina titel: $title. ');
          }
        }
      }
      
      // Extract body text
      if (scaffold.body != null) {
        _extractFromWidgetDirect(scaffold.body!, text);
      }
      
      // Extract floating action button
      if (scaffold.floatingActionButton != null) {
        text.write('Actie knop beschikbaar. ');
      }
      
      // Extract bottom navigation
      if (scaffold.bottomNavigationBar != null) {
        text.write('Navigatie balk beschikbaar. ');
      }
      
    } catch (e) {
      debugPrint('Error extracting from scaffold: $e');
    }
  }

  /// Extract text from widget directly
  void _extractFromWidgetDirect(Widget widget, StringBuffer text) {
    try {
      if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          text.write('$data. ');
        }
      } else if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          text.write('$plainText. ');
        }
      } else if (widget is Column) {
        text.write('Kolom met elementen. ');
      } else if (widget is Row) {
        text.write('Rij met elementen. ');
      } else if (widget is ListView) {
        text.write('Lijst weergave. ');
      } else if (widget is GridView) {
        text.write('Raster weergave. ');
      } else if (widget is SingleChildScrollView) {
        text.write('Scrollbare inhoud. ');
      } else if (widget is Container) {
        text.write('Container element. ');
      } else if (widget is Padding) {
        text.write('Element met opvulling. ');
      } else if (widget is Center) {
        text.write('Gecentreerd element. ');
      }
      
    } catch (e) {
      debugPrint('Error extracting from widget: $e');
    }
  }
}

