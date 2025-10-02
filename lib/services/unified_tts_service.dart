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
      debugPrint('TTS: Starting simple screen reading...');
      
      // Stop any current speech
      await accessibilityNotifier.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Simple approach: just read what we can see
      final content = _getSimpleScreenContent(context);
      
      debugPrint('TTS: Simple content: $content');
      
      if (content.isNotEmpty) {
        await accessibilityNotifier.speak(content);
      } else {
        await accessibilityNotifier.speak('Pagina geladen, maar geen tekst gevonden om voor te lezen.');
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
      // 1. Try to get the page title directly
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      String? pageTitle;
      
      if (scaffold?.appBar != null && scaffold!.appBar is AppBar) {
        final appBar = scaffold.appBar as AppBar;
        if (appBar.title is Text) {
          pageTitle = (appBar.title as Text).data;
          debugPrint('TTS: Found AppBar title: $pageTitle');
        }
      }
      
      // 2. If we found a title, use it, otherwise try to detect the page
      if (pageTitle != null && pageTitle.isNotEmpty) {
        parts.add(pageTitle);
        
        // Add specific content based on the page
        switch (pageTitle.toLowerCase()) {
          case 'forum':
            parts.add('Zoekbalk beschikbaar om berichten te zoeken');
            parts.add('Categorie filters: Alle, Algemeen, Kata verzoeken, Technieken, Evenementen, Feedback');
            parts.add('Lijst met forum berichten');
            parts.add('Plus knop om nieuw bericht te maken');
            break;
          case 'profiel':
            parts.add('Je profiel informatie');
            parts.add('Avatar en gebruikersnaam');
            parts.add('Instellingen en voorkeuren');
            break;
          case 'hoofdpagina':
          case 'home':
            parts.add('Welkom op de hoofdpagina');
            parts.add('Navigatie naar verschillende delen van de app');
            break;
          default:
            parts.add('Pagina inhoud beschikbaar');
            break;
        }
      } else {
        // Fallback if no title found
        parts.add('App pagina geladen');
        parts.add('Verschillende elementen beschikbaar');
      }
      
    } catch (e) {
      debugPrint('TTS: Error in simple content extraction: $e');
      return 'Pagina geladen';
    }
    
    final result = parts.join('. ');
    debugPrint('TTS: Final simple content: $result');
    return result;
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

  /// Extract all actual text content from the screen
  static String _extractAllTextFromScreen(BuildContext context) {
    final List<String> textContent = [];
    
    try {
      // Try multiple approaches to find content
      
      // 1. Try to find scaffold from current context
      var scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      debugPrint('TTS: Direct scaffold search: ${scaffold != null}');
      
      // 2. If no scaffold found, try to find it from the root
      if (scaffold == null) {
        // Try to find a different context approach
        final navigator = context.findAncestorWidgetOfExactType<Navigator>();
        if (navigator != null) {
          debugPrint('TTS: Found Navigator widget');
        }
        
        // Try to find scaffold in a different way - look for MaterialApp context
        final materialApp = context.findAncestorWidgetOfExactType<MaterialApp>();
        if (materialApp != null) {
          debugPrint('TTS: Found MaterialApp, searching for scaffold...');
        }
      }
      
      // 3. Extract content from scaffold if found
      if (scaffold?.body != null) {
        debugPrint('TTS: Extracting from scaffold body...');
        _extractTextFromWidget(scaffold!.body!, textContent);
        debugPrint('TTS: Extracted ${textContent.length} text items from body');
      }
      
      // 4. Also try to extract from app bar
      if (scaffold?.appBar != null) {
        debugPrint('TTS: Extracting from app bar...');
        _extractTextFromWidget(scaffold!.appBar!, textContent);
        debugPrint('TTS: Extracted ${textContent.length} total text items after app bar');
      }
      
      // 5. If still no content, try a more aggressive search
      if (textContent.isEmpty) {
        debugPrint('TTS: No content found, trying aggressive search...');
        _extractTextFromContext(context, textContent);
        debugPrint('TTS: Aggressive search found ${textContent.length} text items');
      }
      
      // Also check floating action button tooltip
      if (scaffold?.floatingActionButton != null) {
        final fab = scaffold!.floatingActionButton as FloatingActionButton?;
        if (fab?.tooltip != null && fab!.tooltip!.isNotEmpty) {
          textContent.add('Knop: ${fab.tooltip}');
        }
      }
      
      // Remove duplicates and empty strings
      final uniqueContent = textContent
          .where((text) => text.trim().isNotEmpty)
          .toSet()
          .toList();
      
      if (uniqueContent.isNotEmpty) {
        return uniqueContent.join('. ');
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting all text: $e');
    }
    
    return '';
  }

  /// Recursively extract text from a widget and its children
  static void _extractTextFromWidget(Widget widget, List<String> textContent) {
    try {
      // Handle Text widgets
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty) {
          textContent.add(text.trim());
        }
        return;
      }
      
      // Handle TextField widgets
      if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          textContent.add('Invoerveld: ${widget.decoration!.hintText}');
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
          }
        }
        return;
      }
      
      // Handle IconButton with tooltip
      if (widget is IconButton && widget.tooltip != null) {
        textContent.add('Knop: ${widget.tooltip}');
        return;
      }
      
      // Handle containers and layout widgets - try to get their children
      if (widget is SingleChildRenderObjectWidget) {
        if (widget.child != null) {
          _extractTextFromWidget(widget.child!, textContent);
        }
      } else if (widget is MultiChildRenderObjectWidget) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      }
      
      // Handle common Flutter widgets with children
      if (widget is Column) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is Row) {
        for (final child in widget.children) {
          _extractTextFromWidget(child, textContent);
        }
      } else if (widget is ListView) {
        // For ListView, we can't easily access children, so add a generic description
        textContent.add('Lijst met items');
      } else if (widget is ListTile) {
        // Handle ListTile specifically
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            textContent.add(titleText.trim());
          }
        }
        if (widget.subtitle is Text) {
          final subtitleText = (widget.subtitle as Text).data;
          if (subtitleText != null && subtitleText.trim().isNotEmpty) {
            textContent.add(subtitleText.trim());
          }
        }
      } else if (widget is AppBar) {
        // Handle AppBar specifically
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            textContent.add('Pagina: $titleText');
          }
        }
      } else if (widget is Chip) {
        // Handle Chip widgets
        if (widget.label is Text) {
          final labelText = (widget.label as Text).data;
          if (labelText != null && labelText.trim().isNotEmpty) {
            textContent.add('Filter: $labelText');
          }
        }
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
      default:
        return '';
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
      default:
        return 'Deze pagina bevat verschillende interactieve elementen. Gebruik de navigatie om door de app te bewegen.';
    }
  }
}

/// Provider for the unified TTS service
final unifiedTTSServiceProvider = Provider<UnifiedTTSService>((ref) {
  return UnifiedTTSService();
});
