import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/accessibility_provider.dart';
import '../screens/splash_screen.dart';
import 'context_aware_page_tts_service.dart';
import 'global_text_extractor.dart';

/// Universal TTS Service that provides comprehensive text-to-speech functionality
class UniversalTTSService {
  static final UniversalTTSService _instance = UniversalTTSService._internal();
  factory UniversalTTSService() => _instance;
  UniversalTTSService._internal();

  /// Speak any widget's content by extracting all text
  static Future<void> speakWidget(Widget widget, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final textContent = _extractAllTextFromWidget(widget);
    if (textContent.isNotEmpty) {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(textContent);
    }
  }

  /// Speak a screen's content with context
  static Future<void> speakScreen(String screenName, String content, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final fullContent = 'Je bent nu op $screenName. $content';
    await accessibilityNotifier.speak(fullContent);
  }

  /// Speak form content with field descriptions
  static Future<void> speakForm(String formTitle, List<String> fieldDescriptions, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    String formContent = 'Formulier: $formTitle. ';
    formContent += 'Dit formulier heeft ${fieldDescriptions.length} velden. ';
    
    for (int i = 0; i < fieldDescriptions.length; i++) {
      formContent += 'Veld ${i + 1}: ${fieldDescriptions[i]}. ';
    }
    
    await accessibilityNotifier.speak(formContent);
  }

  /// Speak list content
  static Future<void> speakList(String listTitle, List<String> items, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    String listContent = '$listTitle. ';
    listContent += 'Deze lijst heeft ${items.length} items. ';
    
    for (int i = 0; i < items.length && i < 10; i++) { // Limit to first 10 items
      listContent += 'Item ${i + 1}: ${items[i]}. ';
    }
    
    if (items.length > 10) {
      listContent += 'En ${items.length - 10} meer items.';
    }
    
    await accessibilityNotifier.speak(listContent);
  }

  /// Extract text from any widget recursively
  static String _extractAllTextFromWidget(Widget widget) {
    final extractor = _WidgetTextExtractor();
    return extractor.extractText(widget);
  }

  /// Enhanced text extraction that includes semantic information
  static String extractTextWithSemantics(BuildContext context) {
    final StringBuffer text = StringBuffer();
    
    try {
      // Extract from AppBar
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.appBar != null) {
        final appBar = scaffold!.appBar!;
        if (appBar is AppBar && appBar.title is Text) {
          final title = (appBar.title as Text).data;
          if (title != null && title.isNotEmpty) {
            text.write('Pagina: $title. ');
          }
        }
      }
      
      // Extract from the entire widget tree
      final element = context as Element;
      _extractTextFromElementTree(element, text);
      
      // If we didn't get much text, try the comprehensive widget extractor
      if (text.toString().trim().length < 50) {
        try {
          if (scaffold?.body != null) {
            final extractor = _WidgetTextExtractor();
            final bodyText = extractor.extractText(scaffold!.body!);
            if (bodyText.isNotEmpty) {
              text.write(bodyText);
            }
          }
        } catch (e) {
          debugPrint('Error in comprehensive widget extraction: $e');
        }
      }
      
    } catch (e) {
      debugPrint('Error extracting text with semantics: $e');
    }
    
    return text.toString().trim();
  }

  /// Extract text from element tree with better coverage
  static void _extractTextFromElementTree(Element element, StringBuffer text) {
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
      
      // Check for buttons and interactive elements
      if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        final child = (widget as dynamic).child;
        if (child is Text) {
          text.write('Knop: ${child.data}. ');
        } else if (child is Row) {
          // Extract text from button with icon and text
          for (final buttonChild in child.children) {
            if (buttonChild is Text) {
              text.write('Knop: ${buttonChild.data}. ');
            }
          }
        }
      }
      
      // Check for list tiles
      if (widget is ListTile) {
        if (widget.title is Text) {
          text.write('${(widget.title as Text).data}. ');
        }
        if (widget.subtitle is Text) {
          text.write('${(widget.subtitle as Text).data}. ');
        }
      }
      
      // Check for form fields
      if (widget is TextField) {
        if (widget.decoration?.labelText != null) {
          text.write('${widget.decoration!.labelText} invoerveld. ');
        }
        if (widget.controller?.text.isNotEmpty == true) {
          text.write('Huidige waarde: ${widget.controller!.text}. ');
        }
      }
      
      // Note: TextFormField doesn't expose decoration as a property,
      // so we cannot access its labelText directly via reflection
      
      // Check for switches and checkboxes
      if (widget is Switch) {
        text.write('Schakelaar: ${widget.value ? 'aan' : 'uit'}. ');
      }
      
      if (widget is Checkbox) {
        text.write('Checkbox: ${widget.value == true ? 'aangevinkt' : 'niet aangevinkt'}. ');
      }
      
      // Check for chips
      if (widget is Chip || widget is ActionChip || widget is FilterChip || widget is ChoiceChip) {
        final label = (widget as dynamic).label;
        if (label is Text) {
          text.write('Chip: ${label.data}. ');
        }
      }
      
      // Check for cards and containers with text
      if (widget is Card || widget is Container) {
        final child = (widget as dynamic).child;
        if (child is Widget) {
          _extractTextFromElementTree(child as Element, text);
        }
      }
      
      // Traverse children
      element.visitChildren((child) => _extractTextFromElementTree(child, text));
      
    } catch (e) {
      // Skip problematic elements
    }
  }

  /// Public method to extract text from any widget
  static String extractAllTextFromWidget(Widget widget) {
    return _extractAllTextFromWidget(widget);
  }

  /// Check if we're actually on the splash screen by examining the widget tree
  static bool _isActuallyOnSplashScreen(BuildContext context) {
    try {
      // Look for SplashScreen widget in the widget tree
      final splashScreen = context.findAncestorWidgetOfExactType<SplashScreen>();
      if (splashScreen != null) {
        debugPrint('TTS: Found SplashScreen widget in tree');
        return true;
      }
      
      // Check for splash screen specific content
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        // Look for splash screen specific elements
        final body = scaffold.body;
        if (body != null) {
          // Check if the body contains splash screen specific content
          final textWidgets = _findTextWidgets(body);
          for (final text in textWidgets) {
            if (text.contains('Karatapp') && text.contains('Jouw Karate Reis')) {
              debugPrint('TTS: Found splash screen content in body');
              return true;
            }
          }
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error checking splash screen: $e');
      return false;
    }
  }

  /// Helper method to find text widgets in a widget tree
  static List<String> _findTextWidgets(Widget widget) {
    final List<String> texts = [];
    
    if (widget is Text) {
      texts.add(widget.data ?? '');
    } else if (widget is RichText) {
      // Extract text from RichText
      widget.text.visitChildren((span) {
        if (span is TextSpan && span.text != null) {
          texts.add(span.text!);
        }
        return true;
      });
    } else if (widget is Container) {
      if (widget.child != null) {
        texts.addAll(_findTextWidgets(widget.child!));
      }
    } else if (widget is Column || widget is Row) {
      if (widget is Column) {
        for (final child in widget.children) {
          texts.addAll(_findTextWidgets(child));
        }
      } else if (widget is Row) {
        for (final child in widget.children) {
          texts.addAll(_findTextWidgets(child));
        }
      }
    }
    
    return texts;
  }

  /// Get the current route using GoRouter
  static String _getCurrentRoute(BuildContext context) {
    try {
      // First try GoRouter
      try {
        final router = GoRouter.of(context);
        final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();
        debugPrint('TTS: Current route detected: $currentLocation');
        return currentLocation;
      } catch (goRouterError) {
        debugPrint('GoRouter not available: $goRouterError');
      }
      
      // Fallback to ModalRoute
      final modalRoute = ModalRoute.of(context);
      if (modalRoute != null && modalRoute.settings.name != null) {
        final routeName = modalRoute.settings.name!;
        debugPrint('TTS: ModalRoute name detected: $routeName');
        return routeName;
      }
      
      // If we're on the splash screen but the app has already navigated away,
      // try to detect the actual current screen
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        // Try to determine the actual screen based on the AppBar title or content
        final appBar = scaffold.appBar;
        if (appBar != null && appBar is AppBar && appBar.title is Text) {
          final title = (appBar.title as Text).data ?? '';
          debugPrint('TTS: AppBar title detected: $title');
          
          // Map common titles to routes
          switch (title.toLowerCase()) {
            case 'home':
            case 'karatapp':
              return '/home';
            case 'profiel':
            case 'profile':
              return '/profile';
            case 'forum':
              return '/forum';
            case 'favorieten':
            case 'favorites':
              return '/favorites';
            case 'gebruikersbeheer':
            case 'user management':
              return '/user-management';
            case 'avatar selectie':
            case 'avatar selection':
              return '/avatar-selection';
            case 'toegankelijkheid demo':
            case 'accessibility demo':
              return '/accessibility-demo';
          }
        }
      }
      
      debugPrint('TTS: No route detected, defaulting to /home');
      return '/home'; // Default to home instead of splash
    } catch (e) {
      debugPrint('Error getting current route: $e');
      return '/home'; // Default to home instead of splash
    }
  }

  /// Get screen-specific content descriptions
  static String getScreenDescription(String routeName) {
    switch (routeName) {
      case '/':
        return 'de hoofdpagina waar je alle kata\'s kunt bekijken en zoeken'; // Treat splash as home
      case '/home':
        return 'de hoofdpagina waar je alle kata\'s kunt bekijken en zoeken';
      case '/profile':
        return 'je profiel pagina waar je je gegevens kunt bewerken';
      case '/favorites':
        return 'je favorieten pagina met opgeslagen kata\'s';
      case '/forum':
        return 'het community forum voor discussies';
      case '/forum/create':
        return 'de pagina om een nieuw forum bericht aan te maken';
      case '/forum/post':
        return 'het forum bericht detail scherm';
      case '/kata/edit':
        return 'de pagina om een kata te bewerken';
      case '/avatar-selection':
        return 'de avatar selectie pagina';
      case '/user-management':
        return 'de gebruikersbeheer pagina';
      case '/accessibility-demo':
        return 'de toegankelijkheids demo pagina';
      case '/login':
        return 'de inlog pagina';
      case '/signup':
        return 'de registratie pagina';
      default:
        // Check if it's a dynamic route
        if (routeName.startsWith('/forum/post/')) {
          return 'het forum bericht detail scherm';
        } else if (routeName.startsWith('/kata/edit/')) {
          return 'de pagina om een kata te bewerken';
        }
        return 'een pagina in de app';
    }
  }

  /// Read the entire page content - like reading an article
  static Future<void> readEntirePage(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      // Enable TTS first
      await ref.read(accessibilityNotifierProvider.notifier).setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    try {
      // Check if context is still mounted before using it
      if (!context.mounted) return;
      
      // Get the current route for context using GoRouter
      final currentRoute = _getCurrentRoute(context);
      
      // Skip TTS if we're actually on the splash screen (not just route detection issue)
      if (currentRoute == '/' && _isActuallyOnSplashScreen(context)) {
        debugPrint('TTS: Skipping - actually on splash screen');
        return;
      }
      
      // Check for dialogs and popups first
      final dialogContent = _extractDialogContent(context);
      if (dialogContent.isNotEmpty) {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Popup venster. $dialogContent');
        return;
      }
      
      // Check for open menus
      final menuContent = _extractMenuContent(context);
      if (menuContent.isNotEmpty) {
        final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
        await accessibilityNotifier.speak('Menu. $menuContent');
        return;
      }
      
      // Extract all text content from the entire page
      final pageContent = _extractEntirePageContent(context, currentRoute);
      
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(pageContent);
    } catch (e) {
      debugPrint('Error reading entire page: $e');
    }
  }

  /// Extract all text content from the entire page
  static String _extractEntirePageContent(BuildContext context, String routeName) {
    final StringBuffer content = StringBuffer();
    
    // Start with page introduction
    content.write('${getScreenDescription(routeName)}. ');
    
    // Use context-aware extraction for specific pages
    if (routeName == '/forum') {
      final forumContent = ContextAwarePageTTSService.extractForumPostsContent(context);
      if (forumContent.isNotEmpty) {
        content.write(forumContent);
        return content.toString();
      }
    } else if (routeName.startsWith('/forum/post/')) {
      final postContent = ContextAwarePageTTSService.extractForumPostDetailContent(context);
      if (postContent.isNotEmpty) {
        content.write(postContent);
        return content.toString();
      }
    } else if (routeName == '/forum/create') {
      // Use global text extractor for form content
      final formContent = GlobalTextExtractor.extractTextFromContext(context);
      if (formContent.isNotEmpty) {
        content.write('Forum post creation form. $formContent');
        return content.toString();
      }
    }
    
    try {
      // Find the Scaffold and extract all content
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        
        // Extract AppBar content
        if (scaffold.appBar != null) {
          content.write('App balk: ');
          final appBarText = _extractAllTextFromWidget(scaffold.appBar!);
          if (appBarText.isNotEmpty) {
            content.write('$appBarText. ');
          }
        }
        
        // Extract main body content
        if (scaffold.body != null) {
          content.write('Hoofdinhoud: ');
          final bodyText = _extractAllTextFromWidget(scaffold.body!);
          if (bodyText.isNotEmpty) {
            content.write('$bodyText. ');
          }
        }
        
        // Extract drawer content if present
        if (scaffold.drawer != null) {
          content.write('Menu: ');
          final drawerText = _extractAllTextFromWidget(scaffold.drawer!);
          if (drawerText.isNotEmpty) {
            content.write('$drawerText. ');
          }
        }
        
        // Extract floating action button
        if (scaffold.floatingActionButton != null) {
          content.write('Actie knop: ');
          final fabText = _extractAllTextFromWidget(scaffold.floatingActionButton!);
          if (fabText.isNotEmpty) {
            content.write('$fabText. ');
          }
        }
        
        // Extract bottom navigation
        if (scaffold.bottomNavigationBar != null) {
          content.write('Onderste navigatie: ');
          final bottomNavText = _extractAllTextFromWidget(scaffold.bottomNavigationBar!);
          if (bottomNavText.isNotEmpty) {
            content.write('$bottomNavText. ');
          }
        }
        
        // Extract persistent footer buttons
        if (scaffold.persistentFooterButtons != null) {
          content.write('Voettekst knoppen: ');
          for (final button in scaffold.persistentFooterButtons!) {
            final buttonText = _extractAllTextFromWidget(button);
            if (buttonText.isNotEmpty) {
              content.write('$buttonText. ');
            }
          }
        }
        
        // Extract bottom sheet if present
        if (scaffold.bottomSheet != null) {
          content.write('Onderste blad: ');
          final bottomSheetText = _extractAllTextFromWidget(scaffold.bottomSheet!);
          if (bottomSheetText.isNotEmpty) {
            content.write('$bottomSheetText. ');
          }
        }
        
      } else {
        // Fallback: try to extract from the current widget
        final widget = context.widget;
        final widgetText = _extractAllTextFromWidget(widget);
        if (widgetText.isNotEmpty) {
          content.write('Pagina inhoud: $widgetText. ');
        }
      }
      
      // Also check for any overlays or floating elements
      final overlayContent = _extractOverlayContent(context);
      if (overlayContent.isNotEmpty) {
        content.write('Overlay: $overlayContent. ');
      }
      
      // If still no content found, try alternative extraction methods
      if (content.toString().trim().isEmpty || content.toString().trim() == '${getScreenDescription(routeName)}. ') {
        final alternativeText = _extractAlternativePageContent(context);
        if (alternativeText.isNotEmpty) {
          content.write(alternativeText);
        }
      }
      
    } catch (e) {
      debugPrint('Error extracting page content: $e');
      content.write('Er was een probleem bij het lezen van de pagina inhoud. ');
    }
    
    final result = content.toString();
    
    // If we still have no meaningful content, provide a helpful fallback
    if (result.trim().isEmpty || result.trim() == '${getScreenDescription(routeName)}. ') {
      return 'Deze pagina bevat verschillende elementen en knoppen. Gebruik de navigatie om door de app te bewegen. Tik op elementen om interactie te hebben.';
    }
    
    return result;
  }

  /// Extract content from overlays and floating elements
  static String _extractOverlayContent(BuildContext context) {
    try {
      // Check for any floating elements
      final overlay = Overlay.of(context);
      if (overlay != null) {
        // This is a simplified approach - in practice, accessing overlay entries
        // requires more complex state management
        return '';
      }
      
      // Check for any floating widgets in the current context
      final floatingWidgets = <Widget>[];
      
      // Look for common floating elements
      final element = context as Element;
      _findFloatingElements(element, floatingWidgets);
      
      if (floatingWidgets.isNotEmpty) {
        final StringBuffer overlayText = StringBuffer();
        for (final widget in floatingWidgets) {
          final widgetText = _extractAllTextFromWidget(widget);
          if (widgetText.isNotEmpty) {
            overlayText.write('$widgetText. ');
          }
        }
        return overlayText.toString();
      }
      
    } catch (e) {
      debugPrint('Error extracting overlay content: $e');
    }
    
    return '';
  }

  /// Find floating elements in the widget tree
  static void _findFloatingElements(Element element, List<Widget> floatingWidgets) {
    try {
      final widget = element.widget;
      
      // Check for common floating widget types
      if (widget is FloatingActionButton ||
          widget is Tooltip ||
          widget is SnackBar ||
          widget is Dialog ||
          widget is AlertDialog ||
          widget is SimpleDialog ||
          widget is BottomSheet) {
        floatingWidgets.add(widget);
      }
      
      // Traverse children
      element.visitChildren((child) => _findFloatingElements(child, floatingWidgets));
      
    } catch (e) {
      // Skip problematic elements
    }
  }

  /// Extract text from the current page using element traversal
  static String extractCurrentPageText(BuildContext context) {
    try {
      // Try to find the main content widget
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        return _extractAllTextFromWidget(scaffold!.body!);
      }
      
      // Fallback to extracting from the entire context
      final widget = context.widget;
      return _extractAllTextFromWidget(widget);
    } catch (e) {
      debugPrint('Error extracting current page text: $e');
      return 'Kon de pagina tekst niet lezen.';
    }
  }

  /// Alternative page content extraction using element traversal
  static String _extractAlternativePageContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    try {
      // Try to extract from the entire element tree
      final element = context as Element;
      _extractTextFromElementTree(element, content);
      
      // If still no content, try to find any text widgets in the widget tree
      if (content.toString().trim().isEmpty) {
        _extractTextFromWidgetTree(context, content);
      }
      
      // Try to extract from any visible text widgets using a more comprehensive approach
      if (content.toString().trim().isEmpty) {
        _extractFromVisibleWidgets(context, content);
      }
      
      // If still no content, provide generic page description
      if (content.toString().trim().isEmpty) {
        content.write('Deze pagina bevat verschillende elementen en knoppen. ');
        content.write('Gebruik de navigatie om door de app te bewegen. ');
        content.write('Tik op elementen om interactie te hebben. ');
      }
      
    } catch (e) {
      debugPrint('Error in alternative page content extraction: $e');
      content.write('Deze pagina is geladen. ');
    }
    
    return content.toString();
  }

  /// Extract text from visible widgets using a more comprehensive approach
  static void _extractFromVisibleWidgets(BuildContext context, StringBuffer content) {
    try {
      // Get the current widget and try to extract text from it
      final widget = context.widget;
      
      // Try to find any text in the widget tree
      if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          content.write('$data. ');
        }
      } else if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          content.write('$plainText. ');
        }
      }
      
      // Try to find scaffold and extract from it
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        // Extract from body
        if (scaffold.body != null) {
          final bodyText = _extractAllTextFromWidget(scaffold.body!);
          if (bodyText.isNotEmpty) {
            content.write('$bodyText. ');
          }
        }
        
        // Extract from app bar
        if (scaffold.appBar != null) {
          final appBarText = _extractAllTextFromWidget(scaffold.appBar!);
          if (appBarText.isNotEmpty) {
            content.write('$appBarText. ');
          }
        }
      }
      
      // Try to extract from any Column, Row, or other layout widgets
      _extractFromLayoutWidgets(context, content);
      
    } catch (e) {
      debugPrint('Error extracting from visible widgets: $e');
    }
  }

  /// Extract text from layout widgets
  static void _extractFromLayoutWidgets(BuildContext context, StringBuffer content) {
    try {
      final element = context as Element;
      _traverseLayoutElements(element, content);
    } catch (e) {
      debugPrint('Error extracting from layout widgets: $e');
    }
  }

  /// Traverse layout elements to find text
  static void _traverseLayoutElements(Element element, StringBuffer content) {
    try {
      final widget = element.widget;
      
      // Check for common layout widgets that might contain text
      if (widget is Column || widget is Row || widget is Wrap || widget is Stack) {
        // These widgets have children, so we need to traverse them
        element.visitChildren((child) => _traverseLayoutElements(child, content));
      } else if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          content.write('$data. ');
        }
      } else if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          content.write('$plainText. ');
        }
      } else if (widget is ListTile) {
        if (widget.title is Text) {
          content.write('${(widget.title as Text).data}. ');
        }
        if (widget.subtitle is Text) {
          content.write('${(widget.subtitle as Text).data}. ');
        }
      } else if (widget is Card) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Container) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Padding) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Center) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Align) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Expanded) {
        _traverseLayoutElements(element, content);
      } else if (widget is Flexible) {
        _traverseLayoutElements(element, content);
      } else if (widget is SizedBox) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is SingleChildScrollView) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is SafeArea) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Material) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is InkWell) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is GestureDetector) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is DefaultTextStyle) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Theme) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is MediaQuery) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Directionality) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Localizations) {
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Semantics) {
        // Extract semantic label
        if (widget.properties.label != null && widget.properties.label!.trim().isNotEmpty) {
          content.write('${widget.properties.label}. ');
        }
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else if (widget is Tooltip) {
        if (widget.message != null && widget.message!.trim().isNotEmpty) {
          content.write('${widget.message}. ');
        }
        if (widget.child != null) {
          _traverseLayoutElements(element, content);
        }
      } else {
        // For other widgets, try to traverse children
        element.visitChildren((child) => _traverseLayoutElements(child, content));
      }
      
    } catch (e) {
      // Skip problematic elements
    }
  }

  /// Extract text from widget tree using a different approach
  static void _extractTextFromWidgetTree(BuildContext context, StringBuffer content) {
    try {
      // Get the current widget and try to extract text from it
      final widget = context.widget;
      
      // Try to find any text in the widget tree
      if (widget is Text) {
        final data = widget.data;
        if (data != null && data.trim().isNotEmpty) {
          content.write('$data. ');
        }
      } else if (widget is RichText) {
        final plainText = widget.text.toPlainText();
        if (plainText.trim().isNotEmpty) {
          content.write('$plainText. ');
        }
      }
      
      // Try to find scaffold and extract from it
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        // Extract from body
        if (scaffold.body != null) {
          final bodyText = _extractAllTextFromWidget(scaffold.body!);
          if (bodyText.isNotEmpty) {
            content.write('$bodyText. ');
          }
        }
        
        // Extract from app bar
        if (scaffold.appBar != null) {
          final appBarText = _extractAllTextFromWidget(scaffold.appBar!);
          if (appBarText.isNotEmpty) {
            content.write('$appBarText. ');
          }
        }
      }
      
    } catch (e) {
      debugPrint('Error extracting text from widget tree: $e');
    }
  }

  /// Extract content from dialogs and popups
  static String _extractDialogContent(BuildContext context) {
    try {
      // Check for various dialog types
      final dialog = context.findAncestorWidgetOfExactType<Dialog>() ?? 
                     context.findAncestorWidgetOfExactType<AlertDialog>() ??
                     context.findAncestorWidgetOfExactType<SimpleDialog>() ??
                     context.findAncestorWidgetOfExactType<BottomSheet>();
      
      if (dialog != null) {
        return _extractAllTextFromWidget(dialog);
      }
      
      // Check for popup menus
      final popupMenu = context.findAncestorWidgetOfExactType<PopupMenuButton>();
      if (popupMenu != null) {
        return 'Popup menu beschikbaar';
      }
      
      // Check for snackbars
      final snackBar = context.findAncestorWidgetOfExactType<SnackBar>();
      if (snackBar != null) {
        return 'Melding: ${snackBar.content}';
      }
      
    } catch (e) {
      debugPrint('Error extracting dialog content: $e');
    }
    
    return '';
  }

  /// Extract content from open menus
  static String _extractMenuContent(BuildContext context) {
    try {
      // Check for open drawer
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold != null) {
        final scaffoldState = Scaffold.maybeOf(context);
        if (scaffoldState != null) {
          if (scaffoldState.isDrawerOpen) {
            return _extractAllTextFromWidget(scaffold.drawer ?? Container());
          }
          if (scaffoldState.isEndDrawerOpen) {
            return _extractAllTextFromWidget(scaffold.endDrawer ?? Container());
          }
        }
      }
      
      // Check for navigation drawer
      final navigationDrawer = context.findAncestorWidgetOfExactType<NavigationDrawer>();
      if (navigationDrawer != null) {
        return _extractAllTextFromWidget(navigationDrawer);
      }
      
      // Check for bottom navigation
      final bottomNav = context.findAncestorWidgetOfExactType<BottomNavigationBar>();
      if (bottomNav != null) {
        return _extractAllTextFromWidget(bottomNav);
      }
      
    } catch (e) {
      debugPrint('Error extracting menu content: $e');
    }
    
    return '';
  }

  /// Get common UI element descriptions
  static String getElementDescription(String elementType, String? text) {
    switch (elementType) {
      case 'button':
        return '${text ?? 'Knop'} knop';
      case 'textfield':
        return '${text ?? 'Tekst'} invoerveld';
      case 'dropdown':
        return '${text ?? 'Keuze'} dropdown menu';
      case 'checkbox':
        return '${text ?? 'Optie'} checkbox';
      case 'radio':
        return '${text ?? 'Keuze'} radio knop';
      case 'link':
        return '${text ?? 'Link'} link';
      case 'image':
        return '${text ?? 'Afbeelding'} afbeelding';
      case 'video':
        return '${text ?? 'Video'} video';
      default:
        return text ?? 'Element';
    }
  }
}

/// Widget text extractor for comprehensive text extraction
class _WidgetTextExtractor {
  final List<String> _texts = [];

  String extractText(Widget widget) {
    _texts.clear();
    _extractFromWidget(widget);
    return _texts.join(' ').trim();
  }

  void _extractFromWidget(Widget widget) {
    // Handle different widget types
    if (widget is Text) {
      if (widget.data != null && widget.data!.trim().isNotEmpty) {
        _texts.add(widget.data!);
      }
    } else if (widget is RichText) {
      _extractFromTextSpan(widget.text);
    } else if (widget is TextField) {
      _extractFromTextField(widget);
    } else if (widget is TextFormField) {
      _extractFromTextFormField(widget);
    } else if (widget is ListTile) {
      _extractFromListTile(widget);
    } else if (widget is AppBar) {
      _extractFromAppBar(widget);
    } else if (widget is ElevatedButton) {
      _extractFromButton(widget.child);
    } else if (widget is TextButton) {
      _extractFromButton(widget.child);
    } else if (widget is OutlinedButton) {
      _extractFromButton(widget.child);
    } else if (widget is FloatingActionButton) {
      _extractFromButton(widget.child);
    } else if (widget is IconButton) {
      // Extract tooltip text from IconButton
      if (widget.tooltip != null && widget.tooltip!.trim().isNotEmpty) {
        _texts.add('${widget.tooltip} knop');
      }
    } else if (widget is Card) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Container) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Padding) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Center) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Align) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is SingleChildScrollView) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is ListView) {
      // ListView children are not directly accessible in this way
      // We'll skip ListView for now as it's built dynamically
    } else if (widget is Column) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Row) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Stack) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Wrap) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Expanded) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Flexible) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is SizedBox) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is RefreshIndicator) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is GestureDetector) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is InkWell) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Material) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is ClipRRect) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is DecoratedBox) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Transform) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Opacity) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is AnimatedBuilder) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Builder) {
      // For Builder widgets, we can't extract at build time
      // but we can try to get the child if it's set
    } else if (widget is Consumer) {
      // For Consumer widgets, we can't extract at build time
      // but we can try to get the child if it's set
    } else if (widget is SafeArea) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Scaffold) {
      // Extract from scaffold parts
      if (widget.appBar != null) {
        _extractFromWidget(widget.appBar!);
      }
      if (widget.body != null) {
        _extractFromWidget(widget.body!);
      }
      if (widget.floatingActionButton != null) {
        _extractFromWidget(widget.floatingActionButton!);
      }
      if (widget.bottomNavigationBar != null) {
        _extractFromWidget(widget.bottomNavigationBar!);
      }
      if (widget.drawer != null) {
        _extractFromWidget(widget.drawer!);
      }
    } else if (widget is DefaultTextStyle) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Theme) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is MediaQuery) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Directionality) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Localizations) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Semantics) {
      // Extract semantic label
      if (widget.properties.label != null && widget.properties.label!.trim().isNotEmpty) {
        _texts.add(widget.properties.label!);
      }
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Tooltip) {
      if (widget.message != null && widget.message!.trim().isNotEmpty) {
        _texts.add(widget.message!);
      }
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Chip) {
      if (widget.label != null) {
        _extractFromWidget(widget.label!);
      }
    } else if (widget is ActionChip) {
      if (widget.label != null) {
        _extractFromWidget(widget.label!);
      }
    } else if (widget is FilterChip) {
      if (widget.label != null) {
        _extractFromWidget(widget.label!);
      }
    } else if (widget is ChoiceChip) {
      if (widget.label != null) {
        _extractFromWidget(widget.label!);
      }
    } else if (widget is InputChip) {
      if (widget.label != null) {
        _extractFromWidget(widget.label!);
      }
    } else if (widget is Switch) {
      _texts.add('Schakelaar: ${widget.value ? 'aan' : 'uit'}');
    } else if (widget is Checkbox) {
      _texts.add('Checkbox: ${widget.value == true ? 'aangevinkt' : 'niet aangevinkt'}');
    } else if (widget is Radio) {
      _texts.add('Radio knop: ${widget.value == true ? 'geselecteerd' : 'niet geselecteerd'}');
    } else if (widget is Slider) {
      _texts.add('Schuifregelaar: waarde ${widget.value}');
    } else if (widget is DropdownButton) {
      _texts.add('Dropdown menu');
    } else if (widget is ExpansionTile) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.subtitle != null) {
        _extractFromWidget(widget.subtitle!);
      }
    } else if (widget is CheckboxListTile) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.subtitle != null) {
        _extractFromWidget(widget.subtitle!);
      }
    } else if (widget is RadioListTile) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.subtitle != null) {
        _extractFromWidget(widget.subtitle!);
      }
    } else if (widget is SwitchListTile) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.subtitle != null) {
        _extractFromWidget(widget.subtitle!);
      }
    } else if (widget is BottomNavigationBar) {
      for (final item in widget.items) {
        if (item.label != null && item.label!.trim().isNotEmpty) {
          _texts.add('Tab: ${item.label}');
        }
      }
    } else if (widget is Drawer) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Dialog) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is AlertDialog) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.content != null) {
        _extractFromWidget(widget.content!);
      }
    } else if (widget is SimpleDialog) {
      if (widget.title != null) {
        _extractFromWidget(widget.title!);
      }
      if (widget.children != null) {
        for (final child in widget.children!) {
          _extractFromWidget(child);
        }
      }
    } else if (widget is SnackBar) {
      _texts.add(widget.content.toString());
    } else if (widget is LinearProgressIndicator) {
      _texts.add('Voortgangsbalk');
    } else if (widget is CircularProgressIndicator) {
      _texts.add('Laden');
    } else if (widget is Dismissible) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Draggable) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is IndexedStack) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is AnimatedSwitcher) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is AnimatedCrossFade) {
      if (widget.firstChild != null) {
        _extractFromWidget(widget.firstChild!);
      }
      if (widget.secondChild != null) {
        _extractFromWidget(widget.secondChild!);
      }
    } else if (widget is Hero) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is FadeTransition) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is ScaleTransition) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is RotationTransition) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is SlideTransition) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is Positioned) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is GridView) {
      // GridView children are not directly accessible
    } else if (widget is PageView) {
      // PageView children are not directly accessible
    } else if (widget is TabBarView) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is DefaultTabController) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is ReorderableListView) {
      // ReorderableListView children are not directly accessible
    } else if (widget is ReorderableList) {
      // ReorderableList children are not directly accessible
    } else if (widget is DragTarget) {
      // DragTarget doesn't have a direct child property
    } else if (widget is NavigationDrawer) {
      // NavigationDrawer doesn't have direct child access
    } else if (widget is PopupMenuButton) {
      if (widget.tooltip != null && widget.tooltip!.trim().isNotEmpty) {
        _texts.add('${widget.tooltip} menu');
      }
    } else if (widget is DataTable) {
      for (final row in widget.rows) {
        for (final cell in row.cells) {
          if (cell.child != null) {
            _extractFromWidget(cell.child!);
          }
        }
      }
    } else if (widget is DataColumn) {
      _extractFromWidget((widget as DataColumn).label);
    } else if (widget is DataRow) {
      for (final cell in (widget as DataRow).cells) {
        if (cell.child != null) {
          _extractFromWidget(cell.child!);
        }
      }
    } else if (widget is DataCell) {
      if ((widget as DataCell).child != null) {
        _extractFromWidget((widget as DataCell).child!);
      }
    } else if (widget is Table) {
      for (final row in (widget as Table).children) {
        if (row is TableRow) {
          for (final child in row.children) {
            _extractFromWidget(child);
          }
        }
      }
    } else if (widget is TableRow) {
      for (final child in (widget as TableRow).children) {
        _extractFromWidget(child);
      }
    } else if (widget is TableCell) {
      _extractFromWidget((widget as TableCell).child);
    } else if (widget is Stepper) {
      for (final step in widget.steps) {
        if (step.title != null) {
          _extractFromWidget(step.title!);
        }
        if (step.subtitle != null) {
          _extractFromWidget(step.subtitle!);
        }
        if (step.content != null) {
          _extractFromWidget(step.content!);
        }
      }
    } else {
      // Try to extract from child if it exists (generic approach)
      try {
        final child = (widget as dynamic).child;
        if (child is Widget) {
          _extractFromWidget(child);
        }
      } catch (e) {
        // Ignore errors when trying to access child
      }
    }
  }

  void _extractFromTextSpan(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null) {
        _texts.add(span.text!);
      }
      if (span.children != null) {
        for (final child in span.children!) {
          _extractFromTextSpan(child);
        }
      }
    }
  }

  void _extractFromTextField(TextField widget) {
    // Add label text
    if (widget.decoration?.labelText != null) {
      _texts.add('${widget.decoration!.labelText} invoerveld');
    }
    // Add current value
    if (widget.controller?.text.isNotEmpty == true) {
      if (widget.obscureText) {
        _texts.add('bevat tekst');
      } else {
        _texts.add('waarde: ${widget.controller!.text}');
      }
    }
    // Add hint text
    if (widget.decoration?.hintText != null) {
      _texts.add('hint: ${widget.decoration!.hintText}');
    }
  }

  void _extractFromTextFormField(TextFormField widget) {
    // Try to extract what we can from TextFormField
    _texts.add('invoerveld');
    
    // Note: TextFormField's controller and decoration are not directly accessible
    // in this context, but we can provide a generic description
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      _texts.add('waarde: ${widget.initialValue}');
    }
  }

  void _extractFromListTile(ListTile widget) {
    if (widget.title is Text) {
      _texts.add((widget.title as Text).data ?? '');
    }
    if (widget.subtitle is Text) {
      _texts.add((widget.subtitle as Text).data ?? '');
    }
    if (widget.leading != null) {
      _extractFromWidget(widget.leading!);
    }
    if (widget.trailing != null) {
      _extractFromWidget(widget.trailing!);
    }
  }

  void _extractFromAppBar(AppBar widget) {
    if (widget.title is Text) {
      _texts.add((widget.title as Text).data ?? '');
    }
    if (widget.leading != null) {
      _extractFromWidget(widget.leading!);
    }
    if (widget.actions != null) {
      for (final action in widget.actions!) {
        _extractFromWidget(action);
      }
    }
  }

  void _extractFromButton(Widget? child) {
    if (child != null) {
      _extractFromWidget(child);
    }
  }
}

/// Mixin for widgets that want to provide TTS functionality
mixin TTSCapable {
  /// Speak the widget's content
  Future<void> speakContent(Widget widget, WidgetRef ref) async {
    await UniversalTTSService.speakWidget(widget, ref);
  }

  /// Speak custom text
  Future<void> speakText(String text, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.speak(text);
  }

  /// Check if TTS is enabled
  bool isTTSEnabled(WidgetRef ref) {
    return ref.read(accessibilityNotifierProvider).isTextToSpeechEnabled;
  }
}

/// Extension on BuildContext for easy TTS access
extension TTSContext on BuildContext {
  /// Speak text using the current context
  Future<void> speak(String text) async {
    // This would need access to WidgetRef, so it's better to use the service directly
    // or use the mixin in ConsumerWidget classes
  }
}

/// Provider for the universal TTS service
final universalTTSServiceProvider = Provider<UniversalTTSService>((ref) {
  return UniversalTTSService();
});
