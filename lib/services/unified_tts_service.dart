import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

/// Simple TTS Service - Just reads screens out loud!
/// This service provides a simple, reliable way to read any screen content.
class UnifiedTTSService {
  static final UnifiedTTSService _instance = UnifiedTTSService._internal();
  factory UnifiedTTSService() => _instance;
  UnifiedTTSService._internal();

  /// Read the current screen content out loud
  static Future<void> readCurrentScreen(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Starting screen reading...');
      
      // Stop any current speech
      await accessibilityNotifier.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Try multiple approaches to get content
      String content = _getSimpleScreenContent(context);
      
      // If simple approach didn't work, try more comprehensive extraction
      if (content.isEmpty || content == 'Pagina geladen' || content.length < 10) {
        debugPrint('TTS: Simple approach failed or insufficient, trying comprehensive extraction...');
        content = _extractScreenContent(context);
      }
      
      debugPrint('TTS: Final content to speak: $content');
      debugPrint('TTS: Content length: ${content.length}');
      
      if (content.isNotEmpty && content != 'Pagina geladen' && content.length > 5) {
        await accessibilityNotifier.speak(content);
      } else {
        // Provide helpful fallback based on current route
        debugPrint('TTS: Using fallback content due to insufficient extracted content');
        final fallbackContent = _getFallbackContentForCurrentRoute(context);
        debugPrint('TTS: Fallback content: $fallbackContent');
        await accessibilityNotifier.speak(fallbackContent);
      }
      
    } catch (e) {
      debugPrint('TTS Error: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de pagina.');
    }
  }

  /// Get simple screen content - just read what's actually there
  static String _getSimpleScreenContent(BuildContext context) {
    final parts = <String>[];
    
    try {
      // 1. First, try to extract actual content from the screen
      final actualContent = _extractAllTextFromScreen(context);
      debugPrint('TTS: Extracted actual content: $actualContent');
      
      if (actualContent.isNotEmpty && actualContent != 'Pagina geladen') {
        // We found real content, use it!
        return actualContent;
      }
      
      // 2. If no actual content found, try to get the page title
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      String? pageTitle;
      
      if (scaffold?.appBar != null && scaffold!.appBar is AppBar) {
        final appBar = scaffold.appBar as AppBar;
        if (appBar.title is Text) {
          final textWidget = appBar.title as Text;
          pageTitle = textWidget.data ?? textWidget.textSpan?.toPlainText();
          debugPrint('TTS: Found AppBar title: $pageTitle');
        }
      }
      
      // 3. If we found a title, announce it and try to find more content
      if (pageTitle != null && pageTitle.isNotEmpty) {
        parts.add('Pagina: $pageTitle');
        
        // Try one more time to get content from the body
        if (scaffold?.body != null) {
          final List<String> bodyContent = [];
          _extractTextFromWidget(scaffold!.body!, bodyContent);
          if (bodyContent.isNotEmpty) {
            // Filter out generic/empty content
            final meaningfulContent = bodyContent
                .where((text) => text.trim().isNotEmpty && 
                               !text.contains('Pagina geladen') &&
                               text.length > 3)
                .toList();
            if (meaningfulContent.isNotEmpty) {
              parts.addAll(meaningfulContent);
            }
          }
        }
      } else {
        // Try to get route information if no title found
        final routeInfo = _getPageInfo(context);
        if (routeInfo != 'Onbekende pagina') {
          parts.add('Pagina: $routeInfo');
        } else {
          parts.add('Karate app pagina');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error in simple content extraction: $e');
      return 'Fout bij het lezen van de pagina';
    }
    
    final result = parts.join('. ');
    debugPrint('TTS: Final simple content: $result');
    return result.isNotEmpty ? result : 'Pagina geladen';
  }

  /// Extract content from the current screen - reads actual content
  static String _extractScreenContent(BuildContext context) {
    final StringBuffer content = StringBuffer();
    
    try {
      // Check for dialogs first
      final dialogContent = _extractDialogContent(context);
      if (dialogContent.isNotEmpty) {
        return dialogContent;
      }
      
      // Get page name
      final pageName = _getPageInfo(context);
      content.write('$pageName. ');
      
      // Extract actual text content from the screen
      final screenText = _extractAllTextFromScreen(context);
      if (screenText.isNotEmpty) {
        content.write(screenText);
      } else {
        // Provide more helpful fallback based on page type
        final fallbackContent = _generateFallbackContent(pageName);
        content.write(fallbackContent);
      }
      
    } catch (e) {
      debugPrint('TTS: Error in content extraction: $e');
      content.write('Fout bij het lezen van de pagina inhoud.');
    }
    
    return content.toString().trim();
  }

  /// Extract content from dialogs and popups
  static String _extractDialogContent(BuildContext context) {
    try {
      // Check for dialogs
      final dialog = context.findAncestorWidgetOfExactType<Dialog>() ?? 
                     context.findAncestorWidgetOfExactType<AlertDialog>();
      
      if (dialog != null) {
        return 'Dialog geopend met verschillende opties';
      }
      
      // Check for bottom sheets
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        return 'Onderste menu geopend';
      }
      
      // Check for snack bars
      final snackBar = context.findAncestorWidgetOfExactType<SnackBar>();
      if (snackBar != null) {
        return 'Melding getoond';
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting dialog content: $e');
    }
    
    return '';
  }

  /// Extract all actual text content from the screen using element tree traversal
  static String _extractAllTextFromScreen(BuildContext context) {
    final List<String> textContent = [];
    
    try {
      debugPrint('TTS: Starting element tree text extraction...');
      
      // Use element tree traversal to find actual rendered content
      _extractTextFromElementTree(context, textContent);
      
      debugPrint('TTS: Element tree extraction found ${textContent.length} text items');
      
      // If element tree didn't find much, try widget-based extraction as fallback
      if (textContent.length < 3) {
        debugPrint('TTS: Element tree found little content, trying widget extraction...');
        
        // Try to find scaffold from current context
        var scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        debugPrint('TTS: Direct scaffold search: ${scaffold != null}');
        
        // Extract content from scaffold if found
        if (scaffold?.body != null) {
          debugPrint('TTS: Extracting from scaffold body...');
          _extractTextFromWidget(scaffold!.body!, textContent);
          debugPrint('TTS: Extracted ${textContent.length} text items from body');
        }
        
        // Also try to extract from app bar
        if (scaffold?.appBar != null) {
          debugPrint('TTS: Extracting from app bar...');
          final beforeAppBarCount = textContent.length;
          _extractTextFromWidget(scaffold!.appBar!, textContent);
          debugPrint('TTS: Added ${textContent.length - beforeAppBarCount} items from app bar');
        }
        
        // Extract from drawer if present
        if (scaffold?.drawer != null) {
          debugPrint('TTS: Extracting from drawer...');
          final beforeDrawerCount = textContent.length;
          _extractTextFromWidget(scaffold!.drawer!, textContent);
          debugPrint('TTS: Added ${textContent.length - beforeDrawerCount} items from drawer');
        }
        
        // Extract from bottom navigation bar if present
        if (scaffold?.bottomNavigationBar != null) {
          debugPrint('TTS: Extracting from bottom navigation bar...');
          final beforeBottomNavCount = textContent.length;
          _extractTextFromWidget(scaffold!.bottomNavigationBar!, textContent);
          debugPrint('TTS: Added ${textContent.length - beforeBottomNavCount} items from bottom nav');
        }
        
        // Also check floating action button tooltip
        if (scaffold?.floatingActionButton != null) {
          final fab = scaffold!.floatingActionButton as FloatingActionButton?;
          if (fab?.tooltip != null && fab!.tooltip!.isNotEmpty) {
            textContent.add('Zwevende knop: ${fab.tooltip}');
          }
        }
      }
      
      // Remove duplicates, empty strings, and filter out meaningless content
      final uniqueContent = textContent
          .where((text) => text.trim().isNotEmpty && 
                          text.trim() != 'Pagina geladen' &&
                          text.length > 2 &&
                          !text.toLowerCase().contains('loading') &&
                          !text.toLowerCase().contains('laden'))
          .toSet()
          .toList();
      
      debugPrint('TTS: Final unique content count: ${uniqueContent.length}');
      if (uniqueContent.isNotEmpty) {
        debugPrint('TTS: Final content preview: ${uniqueContent.take(5).join(", ")}...');
        return uniqueContent.join('. ');
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting all text: $e');
    }
    
    debugPrint('TTS: No content extracted, returning empty string');
    return '';
  }

  /// Recursively extract text from a widget and its children
  static void _extractTextFromWidget(Widget widget, List<String> textContent) {
    try {
      // Handle Text widgets
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
          textContent.add(text.trim());
        }
        return;
      }
      
      // Handle TextField widgets
      if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          textContent.add('Invoerveld: ${widget.decoration!.hintText}');
        }
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add('Ingevoerde tekst: ${widget.controller!.text}');
        }
        return;
      }
      
      // Handle buttons with text
      if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        // Try to extract text from button child
        if (widget is ButtonStyleButton) {
          if (widget.child is Text) {
            final text = (widget.child as Text).data;
            if (text != null && text.trim().isNotEmpty) {
              textContent.add('Knop: $text');
            }
          } else if (widget.child != null) {
            // Try to extract text from other child widgets
            _extractTextFromWidget(widget.child!, textContent);
          }
        }
        return;
      }
      
      // Handle IconButton with tooltip
      if (widget is IconButton && widget.tooltip != null) {
        textContent.add('Knop: ${widget.tooltip}');
        return;
      }
      
      // Handle FloatingActionButton
      if (widget is FloatingActionButton) {
        if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
          textContent.add('Zwevende knop: ${widget.tooltip}');
        }
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
        return;
      }
      
      // Handle ListTile specifically (before other widgets)
      if (widget is ListTile) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            textContent.add(titleText.trim());
          }
        } else if (widget.title != null) {
          _extractTextFromWidget(widget.title!, textContent);
        }
        
        if (widget.subtitle is Text) {
          final subtitleText = (widget.subtitle as Text).data;
          if (subtitleText != null && subtitleText.trim().isNotEmpty) {
            textContent.add(subtitleText.trim());
          }
        } else if (widget.subtitle != null) {
          _extractTextFromWidget(widget.subtitle!, textContent);
        }
        
        if (widget.leading != null) {
          _extractTextFromWidget(widget.leading!, textContent);
        }
        if (widget.trailing != null) {
          _extractTextFromWidget(widget.trailing!, textContent);
        }
        return;
      }
      
      // Handle AppBar specifically
      if (widget is AppBar) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            textContent.add('Pagina: $titleText');
          }
        } else if (widget.title != null) {
          _extractTextFromWidget(widget.title!, textContent);
        }
        
        // Extract from actions
        if (widget.actions != null) {
          for (final action in widget.actions!) {
            _extractTextFromWidget(action, textContent);
          }
        }
        return;
      }
      
      // Handle Chip widgets
      if (widget is Chip) {
        if (widget.label is Text) {
          final labelText = (widget.label as Text).data;
          if (labelText != null && labelText.trim().isNotEmpty) {
            textContent.add('Filter: $labelText');
          }
        } else {
          _extractTextFromWidget(widget.label, textContent);
        }
        return;
      }
      
      // Handle common layout widgets with children
      if (widget is Column) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is Row) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is Stack) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is Wrap) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is ListView) {
        // For ListView, we can't easily access children, so add a generic description
        textContent.add('Lijst met items');
      } else if (widget is GridView) {
        textContent.add('Raster met items');
      } else if (widget is Card) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Container) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Padding) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Center) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Align) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Expanded) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is Flexible) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is SizedBox) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      }
      
      // Handle containers and layout widgets - try to get their children
      else if (widget is SingleChildRenderObjectWidget) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is MultiChildRenderObjectWidget) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting text from widget ${widget.runtimeType}: $e');
    }
  }


  /// Get basic page information
  static String _getPageInfo(BuildContext context) {
    try {
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      debugPrint('TTS: Scaffold found: ${scaffold != null}');
      debugPrint('TTS: AppBar found: ${scaffold?.appBar != null}');
      
      if (scaffold?.appBar != null) {
        final appBar = scaffold!.appBar;
        debugPrint('TTS: AppBar type: ${appBar.runtimeType}');
        debugPrint('TTS: AppBar is AppBar: ${appBar is AppBar}');
        
        if (appBar is AppBar) {
          debugPrint('TTS: AppBar title: ${appBar.title}');
          debugPrint('TTS: AppBar title type: ${appBar.title?.runtimeType}');
          
          String? title;
          if (appBar.title is Text) {
            final textWidget = appBar.title as Text;
            title = textWidget.data;
            debugPrint('TTS: Text widget data: $title');
            debugPrint('TTS: Text widget textSpan: ${textWidget.textSpan}');
            
            // If data is null, try textSpan
            if (title == null && textWidget.textSpan != null) {
              title = textWidget.textSpan!.toPlainText();
              debugPrint('TTS: Extracted from textSpan: $title');
            }
          } else if (appBar.title is Widget) {
            // Try to extract text from other widget types
            final List<String> titleContent = [];
            _extractTextFromWidget(appBar.title!, titleContent);
            title = titleContent.isNotEmpty ? titleContent.first : null;
            debugPrint('TTS: Extracted title from widget: $title');
          }
          
          if (title != null && title.isNotEmpty) {
            debugPrint('TTS: Returning page title: $title');
            return title;
          } else {
            debugPrint('TTS: Title is null or empty, title was: $title');
          }
        }
      }
      
      // Try to identify page by route
      try {
        final modalRoute = ModalRoute.of(context);
        debugPrint('TTS: ModalRoute found: ${modalRoute != null}');
        debugPrint('TTS: Route settings: ${modalRoute?.settings}');
        debugPrint('TTS: Route name: ${modalRoute?.settings.name}');
        
        if (modalRoute?.settings.name != null) {
          final routeName = modalRoute!.settings.name!;
          debugPrint('TTS: Processing route name: $routeName');
          final pageDescription = _getRouteDescription(routeName);
          debugPrint('TTS: Route description: $pageDescription');
          if (pageDescription.isNotEmpty) {
            debugPrint('TTS: Returning route-based page name: $pageDescription');
            return pageDescription;
          }
        }
      } catch (e) {
        debugPrint('TTS: Error getting route info: $e');
      }
      
    } catch (e) {
      debugPrint('TTS: Error getting page info: $e');
    }
    
    debugPrint('TTS: Falling back to unknown page');
    return 'Onbekende pagina'; // Unknown page
  }

  /// Get a description for common routes
  static String _getRouteDescription(String routeName) {
    switch (routeName.toLowerCase()) {
      case '/':
      case '/home':
        return 'Hoofdpagina';
      case '/profile':
        return 'Profiel';
      case '/forum':
        return 'Forum';
      case '/favorites':
      case '/favourites':
        return 'Favorieten';
      case '/user-management':
        return 'Gebruikersbeheer';
      case '/kata-form':
        return 'Kata formulier';
      case '/avatar-selection':
        return 'Avatar selectie';
      case '/create-forum-post':
        return 'Nieuw forum bericht maken';
      case '/forum-post-detail':
        return 'Forum bericht details';
      case '/accessibility-settings':
        return 'Toegankelijkheidsinstellingen';
      case '/test-tts':
        return 'TTS Test';
      default:
        return '';
    }
  }

  /// Extract text from the actual rendered element tree
  static void _extractTextFromElementTree(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting element tree traversal from ${context.widget.runtimeType}');
      
      // Visit all child elements in the tree
      context.visitChildElements((element) {
        try {
          _extractTextFromElement(element, textContent);
        } catch (e) {
          debugPrint('TTS: Error extracting from element: $e');
        }
      });
      
      debugPrint('TTS: Element tree traversal completed, found ${textContent.length} items');
    } catch (e) {
      debugPrint('TTS: Error in element tree extraction: $e');
    }
  }

  /// Extract text from a specific element and its children
  static void _extractTextFromElement(Element element, List<String> textContent) {
    try {
      final widget = element.widget;
      
      // Handle different widget types that contain text
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
          textContent.add(text.trim());
          debugPrint('TTS: Found Text widget: "${text.trim()}"');
        }
      } else if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
          textContent.add(text.trim());
          debugPrint('TTS: Found RichText widget: "${text.trim()}"');
        }
      } else if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          textContent.add('Invoerveld: ${widget.decoration!.hintText}');
          debugPrint('TTS: Found TextField hint: "${widget.decoration!.hintText}"');
        }
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add('Ingevoerde tekst: ${widget.controller!.text}');
          debugPrint('TTS: Found TextField content: "${widget.controller!.text}"');
        }
      } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton && widget.child is Text) {
          final text = (widget.child as Text).data;
          if (text != null && text.trim().isNotEmpty) {
            textContent.add('Knop: $text');
            debugPrint('TTS: Found Button: "$text"');
          }
        }
      } else if (widget is IconButton && widget.tooltip != null) {
        textContent.add('Knop: ${widget.tooltip}');
        debugPrint('TTS: Found IconButton tooltip: "${widget.tooltip}"');
      } else if (widget is FloatingActionButton && widget.tooltip != null) {
        textContent.add('Zwevende knop: ${widget.tooltip}');
        debugPrint('TTS: Found FAB tooltip: "${widget.tooltip}"');
      } else if (widget is ListTile) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            textContent.add(titleText.trim());
            debugPrint('TTS: Found ListTile title: "$titleText"');
          }
        }
        if (widget.subtitle is Text) {
          final subtitleText = (widget.subtitle as Text).data;
          if (subtitleText != null && subtitleText.trim().isNotEmpty) {
            textContent.add(subtitleText.trim());
            debugPrint('TTS: Found ListTile subtitle: "$subtitleText"');
          }
        }
      } else if (widget is Chip && widget.label is Text) {
        final labelText = (widget.label as Text).data;
        if (labelText != null && labelText.trim().isNotEmpty) {
          textContent.add('Filter: $labelText');
          debugPrint('TTS: Found Chip: "$labelText"');
        }
      } else if (widget is AppBar && widget.title is Text) {
        final titleText = (widget.title as Text).data;
        if (titleText != null && titleText.trim().isNotEmpty) {
          textContent.add('Pagina: $titleText');
          debugPrint('TTS: Found AppBar title: "$titleText"');
        }
      }
      
      // Check for Semantics widgets which often contain accessibility labels
      if (widget is Semantics && widget.properties.label != null) {
        final label = widget.properties.label!;
        if (label.trim().isNotEmpty && label.trim() != 'Pagina geladen') {
          textContent.add(label.trim());
          debugPrint('TTS: Found Semantics label: "$label"');
        }
      }
      
      // Recursively visit child elements
      element.visitChildren((childElement) {
        _extractTextFromElement(childElement, textContent);
      });
      
    } catch (e) {
      debugPrint('TTS: Error extracting from element ${element.widget.runtimeType}: $e');
    }
  }

  /// Aggressive text extraction from context when normal methods fail
  static void _extractTextFromContext(BuildContext context, List<String> textContent) {
    try {
      // Try to visit the widget tree more aggressively
      context.visitChildElements((element) {
        try {
          final widget = element.widget;
          _extractTextFromWidget(widget, textContent);
          
          // Recursively visit children
          _extractTextFromContext(element, textContent);
        } catch (e) {
          debugPrint('TTS: Error in aggressive extraction: $e');
        }
      });
    } catch (e) {
      debugPrint('TTS: Error in context extraction: $e');
    }
  }

  /// Generate helpful fallback content based on page type
  static String _generateFallbackContent(String pageName) {
    switch (pageName.toLowerCase()) {
      case 'forum':
        return 'Dit is de forum pagina waar je berichten kunt lezen en schrijven. Gebruik de zoekbalk om berichten te vinden, of maak een nieuw bericht met de plus knop.';
      case 'hoofdpagina':
        return 'Dit is de hoofdpagina van de app. Hier vind je verschillende opties om te navigeren naar andere delen van de app.';
      case 'profiel':
        return 'Dit is je profiel pagina waar je je persoonlijke informatie kunt bekijken en bewerken.';
      case 'favorieten':
        return 'Dit is je favorieten pagina waar je je opgeslagen items kunt bekijken.';
      case 'gebruikersbeheer':
        return 'Dit is de gebruikersbeheer pagina waar je gebruikers kunt beheren.';
      case 'nieuw forum bericht maken':
        return 'Dit is de pagina om een nieuw forum bericht te maken. Je kunt hier een titel en inhoud invoeren voor je bericht.';
      case 'forum bericht details':
        return 'Dit is de detail pagina van een forum bericht waar je het volledige bericht kunt lezen en reageren.';
      case 'toegankelijkheidsinstellingen':
        return 'Dit is de toegankelijkheidsinstellingen pagina waar je spraak, lettergrootte en andere toegankelijkheidsopties kunt aanpassen.';
      case 'tts test':
        return 'Dit is de TTS test pagina om de spraakfunctionaliteit te testen.';
      case 'kata formulier':
        return 'Dit is het kata formulier waar je nieuwe kata technieken kunt toevoegen.';
      case 'avatar selectie':
        return 'Dit is de avatar selectie pagina waar je je profiel avatar kunt kiezen.';
      default:
        return 'Deze pagina bevat verschillende interactieve elementen. Gebruik de navigatie om door de app te bewegen.';
    }
  }

  /// Get fallback content based on current route
  static String _getFallbackContentForCurrentRoute(BuildContext context) {
    try {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute?.settings.name != null) {
        final routeName = modalRoute!.settings.name!;
        final pageDescription = _getRouteDescription(routeName);
        if (pageDescription.isNotEmpty) {
          return _generateFallbackContent(pageDescription);
        }
      }
    } catch (e) {
      debugPrint('TTS: Error getting route for fallback: $e');
    }
    
    return 'Karate app pagina geladen. Gebruik de navigatie knoppen om door de app te bewegen. Er zijn verschillende functies beschikbaar zoals het forum, profiel en favorieten.';
  }
}

/// Provider for the unified TTS service
final unifiedTTSServiceProvider = Provider<UnifiedTTSService>((ref) {
  return UnifiedTTSService();
});
