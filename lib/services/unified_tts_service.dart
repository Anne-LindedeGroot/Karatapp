import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import 'tts/tts_cache_manager.dart';
import 'tts/tts_screen_detector.dart';
import 'tts/tts_content_extractor.dart';

/// Enhanced TTS Service - Comprehensive screen reading in Dutch!
/// This service provides comprehensive text-to-speech functionality that reads
/// all visible text on screen in natural Dutch pronunciation.
class UnifiedTTSService {
  static final UnifiedTTSService _instance = UnifiedTTSService._internal();
  factory UnifiedTTSService() => _instance;
  UnifiedTTSService._internal();

  // Content caching moved to TTSCacheManager

  /// Read the current screen content out loud in Dutch
  static Future<void> readCurrentScreen(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Starting comprehensive screen reading in Dutch...');
      print('🔊 TTS: Starting comprehensive screen reading in Dutch...');
      
      // Stop any current speech
      await accessibilityNotifier.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if context is still mounted before proceeding
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted, aborting screen reading');
        print('❌ TTS: Context no longer mounted, aborting screen reading');
        return;
      }
      
      // Detect current screen type and extract appropriate content
      final screenType = TTSScreenDetector.detectCurrentScreenType(context);
      debugPrint('TTS: Detected screen type: $screenType');
      print('📱 TTS: Detected screen type: $screenType');
      
      // Check context again before content extraction
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted during content extraction');
        print('❌ TTS: Context no longer mounted during content extraction');
        return;
      }
      
      // Try to get cached content first
      final cacheKey = TTSScreenDetector.generateCacheKey(context, screenType);
      String screenContent = TTSCacheManager.getCachedContent(cacheKey);
      
      if (screenContent.isEmpty) {
        // Extract content if not cached or cache expired
        screenContent = TTSContentExtractor.extractScreenContentByType(context, screenType);
        TTSCacheManager.cacheContent(cacheKey, screenContent);
      } else {
        debugPrint('TTS: Using cached content for $screenType');
        print('💾 TTS: Using cached content for $screenType');
      }
      
      debugPrint('TTS: Extracted content length: ${screenContent.length}');
      debugPrint('TTS: Content preview: ${screenContent.length > 100 ? '${screenContent.substring(0, 100)}...' : screenContent}');
      print('📝 TTS: Extracted content length: ${screenContent.length}');
      print('📄 TTS: Content preview: ${screenContent.length > 100 ? '${screenContent.substring(0, 100)}...' : screenContent}');
      
      if (screenContent.isNotEmpty && screenContent.length > 5) {
        // Process and speak the content with proper Dutch formatting
        final processedContent = _processContentForDutchSpeech(screenContent);
        print('🗣️ TTS: Speaking processed content: ${processedContent.length > 200 ? '${processedContent.substring(0, 200)}...' : processedContent}');
        await accessibilityNotifier.speak(processedContent);
      } else {
        // Provide helpful fallback based on current route
        debugPrint('TTS: Using fallback content due to insufficient extracted content');
        print('⚠️ TTS: Using fallback content due to insufficient extracted content');
        
        // Check context again before fallback
        if (!context.mounted) {
          debugPrint('TTS: Context no longer mounted during fallback');
          print('❌ TTS: Context no longer mounted during fallback');
          return;
        }
        
        final fallbackContent = _getFallbackContentForCurrentRoute(context);
        debugPrint('TTS: Fallback content: $fallbackContent');
        print('🔄 TTS: Fallback content: $fallbackContent');
        await accessibilityNotifier.speak(fallbackContent);
      }
      
    } catch (e) {
      debugPrint('TTS Error: $e');
      print('❌ TTS Error: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de pagina.');
    }
  }

  /// Extract comprehensive content from the current screen
  static String _extractComprehensiveScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      debugPrint('TTS: Starting comprehensive content extraction...');
      
      // 1. Check for overlays, dialogs, and popups first
      final overlayContent = _extractOverlayContent(context);
      if (overlayContent.isNotEmpty) {
        contentParts.add(overlayContent);
        debugPrint('TTS: Found overlay content: $overlayContent');
      }
      
      // 2. Extract page title and navigation
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
        debugPrint('TTS: Found page info: $pageInfo');
      }
      
      // 3. Extract main content using multiple strategies
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
        debugPrint('TTS: Found main content: ${mainContent.length} characters');
      }
      
      // 4. Extract interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
        debugPrint('TTS: Found interactive elements: $interactiveElements');
      }
      
      // 5. Extract form content if present
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
        debugPrint('TTS: Found form content: $formContent');
      }
      
      // Combine all content parts
      final combinedContent = contentParts.join('. ');
      debugPrint('TTS: Combined content length: ${combinedContent.length}');
      
      return combinedContent;
      
    } catch (e) {
      debugPrint('TTS: Error in comprehensive extraction: $e');
      return _getFallbackContentForCurrentRoute(context);
    }
  }

  /// Process content for better Dutch speech pronunciation
  static String _processContentForDutchSpeech(String content) {
    if (content.isEmpty) return content;
    
    // Clean up the content for better speech
    String processed = content;
    
    // Remove excessive whitespace and normalize
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Add pauses for better readability
    processed = processed.replaceAll('. ', '. ');
    processed = processed.replaceAll('! ', '! ');
    processed = processed.replaceAll('? ', '? ');
    
    // Handle common abbreviations and acronyms for better pronunciation
    processed = processed.replaceAll(RegExp(r'\bTTS\b', caseSensitive: false), 'T T S');
    processed = processed.replaceAll(RegExp(r'\bAPI\b', caseSensitive: false), 'A P I');
    processed = processed.replaceAll(RegExp(r'\bURL\b', caseSensitive: false), 'U R L');
    
    // Ensure proper sentence endings
    if (!processed.endsWith('.') && !processed.endsWith('!') && !processed.endsWith('?')) {
      processed += '.';
    }
    
    return processed;
  }

  /// Extract content from overlays, dialogs, and popups
  static String _extractOverlayContent(BuildContext context) {
    final List<String> overlayParts = [];
    
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _extractOverlayContent');
        return '';
      }
      
      // Check for AlertDialog
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog != null) {
        overlayParts.add('Dialog geopend');
        final dialogContent = _extractTextFromWidgetHelper(alertDialog);
        if (dialogContent.isNotEmpty) {
          overlayParts.add(dialogContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for Dialog
      final dialog = context.findAncestorWidgetOfExactType<Dialog>();
      if (dialog != null) {
        overlayParts.add('Dialog geopend');
        final dialogContent = _extractTextFromWidgetHelper(dialog);
        if (dialogContent.isNotEmpty) {
          overlayParts.add(dialogContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for BottomSheet
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        overlayParts.add('Onderste menu geopend');
        final sheetContent = _extractTextFromWidgetHelper(bottomSheet);
        if (sheetContent.isNotEmpty) {
          overlayParts.add(sheetContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for SnackBar
      final snackBar = context.findAncestorWidgetOfExactType<SnackBar>();
      if (snackBar != null) {
        overlayParts.add('Melding getoond');
        final snackContent = _extractTextFromWidgetHelper(snackBar);
        if (snackContent.isNotEmpty) {
          overlayParts.add(snackContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for ModalBottomSheet - we can't easily detect this with findAncestorWidgetOfExactType
      // since ModalBottomSheetRoute is not a Widget but a Route
      // This check is removed as it was causing compilation errors
      
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
    }
    
    return '';
  }

  /// Extract page information (title, navigation, etc.)
  static String _extractPageInformation(BuildContext context) {
    final List<String> pageParts = [];
    
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _extractPageInformation');
        return '';
      }
      
      // Get page title from AppBar
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.appBar != null) {
        final appBar = scaffold!.appBar!;
        if (appBar is AppBar && appBar.title != null) {
          final titleText = _extractTextFromWidgetHelper(appBar.title!);
          if (titleText.isNotEmpty) {
            pageParts.add('Pagina: $titleText');
          }
        }
      }
      
      // Get route information as fallback
      if (pageParts.isEmpty) {
        final routeInfo = _getPageInfo(context);
        if (routeInfo != 'Onbekende pagina') {
          pageParts.add('Pagina: $routeInfo');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting page information: $e');
    }
    
    return pageParts.join('. ');
  }

  /// Extract main content from the screen
  static String _extractMainContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      // Use enhanced element tree traversal for comprehensive text extraction
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter and organize the extracted text
      final meaningfulTexts = elementTexts
          .where((text) => text.trim().isNotEmpty && 
                         text.trim() != 'Pagina geladen' &&
                         text.length > 2 &&
                         !text.toLowerCase().contains('loading') &&
                         !text.toLowerCase().contains('laden'))
          .toSet()
          .toList();
      
      if (meaningfulTexts.isNotEmpty) {
        contentParts.addAll(meaningfulTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting main content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Enhanced element tree traversal with better Dutch text processing
  static void _extractTextFromElementTreeEnhanced(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting enhanced element tree traversal from ${context.widget.runtimeType}');
      
      // Visit all child elements in the tree
      context.visitChildElements((element) {
        try {
          _extractTextFromElementEnhanced(element, textContent);
        } catch (e) {
          debugPrint('TTS: Error extracting from element: $e');
        }
      });
      
      debugPrint('TTS: Enhanced element tree traversal completed, found ${textContent.length} items');
    } catch (e) {
      debugPrint('TTS: Error in enhanced element tree extraction: $e');
    }
  }

  /// Enhanced text extraction from a specific element with Dutch processing
  static void _extractTextFromElementEnhanced(Element element, List<String> textContent) {
    try {
      final widget = element.widget;
      
      // Handle different widget types that contain text with enhanced Dutch processing
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
        final processedText = _processDutchText(text.trim());
        textContent.add(processedText);
        debugPrint('TTS: Found Text widget: $processedText');
        }
      } else if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
        final processedText = _processDutchText(text.trim());
        textContent.add(processedText);
        debugPrint('TTS: Found RichText widget: $processedText');
        }
      } else if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          final hintText = _processDutchText(widget.decoration!.hintText!);
          textContent.add('Invoerveld: $hintText');
          debugPrint('TTS: Found TextField hint: "$hintText"');
        }
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          final inputText = _processDutchText(widget.controller!.text);
          textContent.add('Ingevoerde tekst: $inputText');
          debugPrint('TTS: Found TextField content: "$inputText"');
        }
      } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton && widget.child is Text) {
          final text = (widget.child as Text).data;
        if (text != null && text.trim().isNotEmpty) {
          final processedText = _processDutchText(text.trim());
          textContent.add('Knop: $processedText');
          debugPrint('TTS: Found Button: $processedText');
        }
        }
      } else if (widget is IconButton && widget.tooltip != null) {
        final tooltipText = _processDutchText(widget.tooltip!);
        textContent.add('Knop: $tooltipText');
        debugPrint('TTS: Found IconButton tooltip: $tooltipText');
      } else if (widget is FloatingActionButton && widget.tooltip != null) {
        final tooltipText = _processDutchText(widget.tooltip!);
        textContent.add('Zwevende knop: $tooltipText');
        debugPrint('TTS: Found FAB tooltip: $tooltipText');
      } else if (widget is ListTile) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found ListTile title: $processedText');
          }
        }
        if (widget.subtitle is Text) {
          final subtitleText = (widget.subtitle as Text).data;
          if (subtitleText != null && subtitleText.trim().isNotEmpty) {
            final processedText = _processDutchText(subtitleText.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found ListTile subtitle: $processedText');
          }
        }
      } else if (widget is Chip && widget.label is Text) {
        final labelText = (widget.label as Text).data;
        if (labelText != null && labelText.trim().isNotEmpty) {
          final processedText = _processDutchText(labelText.trim());
          textContent.add('Filter: $processedText');
          debugPrint('TTS: Found Chip: $processedText');
        }
      } else if (widget is AppBar && widget.title is Text) {
        final titleText = (widget.title as Text).data;
        if (titleText != null && titleText.trim().isNotEmpty) {
          final processedText = _processDutchText(titleText.trim());
          textContent.add('Pagina: $processedText');
          debugPrint('TTS: Found AppBar title: $processedText');
        }
      }
      
      // Check for Semantics widgets which often contain accessibility labels
      if (widget is Semantics && widget.properties.label != null) {
        final label = widget.properties.label;
        if (label!.trim().isNotEmpty && label.trim() != 'Pagina geladen') {
          final processedLabel = _processDutchText(label.trim());
          textContent.add(processedLabel);
          debugPrint('TTS: Found Semantics label: $processedLabel');
        }
      }
      
      // Recursively visit child elements
      element.visitChildren((childElement) {
        _extractTextFromElementEnhanced(childElement, textContent);
      });
      
    } catch (e) {
      debugPrint('TTS: Error extracting from element ${element.widget.runtimeType}: $e');
    }
  }

  /// Extract interactive elements (buttons, links, etc.)
  static String _extractInteractiveElements(BuildContext context) {
    final List<String> interactiveParts = [];
    
    try {
      // Use enhanced element tree extraction for interactive elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for interactive elements
      final interactiveTexts = elementTexts
          .where((text) => text.startsWith('Knop:') || 
                         text.startsWith('Zwevende knop:') ||
                         text.startsWith('Filter:'))
          .toList();
      
      if (interactiveTexts.isNotEmpty) {
        interactiveParts.add('Beschikbare knoppen en opties:');
        interactiveParts.addAll(interactiveTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting interactive elements: $e');
    }
    
    return interactiveParts.join('. ');
  }

  /// Extract form content (input fields, labels, etc.)
  static String _extractFormContent(BuildContext context) {
    final List<String> formParts = [];
    
    try {
      // Use enhanced element tree extraction for form elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for form-related content
      final formTexts = elementTexts
          .where((text) => text.startsWith('Invoerveld:') || 
                         text.startsWith('Ingevoerde tekst:'))
          .toList();
      
      if (formTexts.isNotEmpty) {
        formParts.add('Formulier velden:');
        formParts.addAll(formTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting form content: $e');
    }
    
    return formParts.join('. ');
  }

  /// Extract text from a widget (helper method)
  static String _extractTextFromWidgetHelper(Widget widget) {
    final List<String> textParts = [];
    _extractTextFromWidget(widget, textParts);
    return textParts.join('. ');
  }

  /// Enhanced text extraction with better Dutch language support
  static void _extractTextFromWidgetEnhanced(Widget widget, List<String> textContent) {
    try {
      // Handle Text widgets with enhanced Dutch processing
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
        }
        return;
      }
      
      // Handle RichText widgets
      if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (text.trim().isNotEmpty && text.trim() != 'Pagina geladen') {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
        }
        return;
      }
      
      // Handle TextField widgets with better Dutch labels
      if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          final hintText = _processDutchText(widget.decoration!.hintText!);
          textContent.add('Invoerveld: $hintText');
        }
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          final inputText = _processDutchText(widget.controller!.text);
          textContent.add('Ingevoerde tekst: $inputText');
        }
        return;
      }
      
      // Handle buttons with enhanced Dutch processing
      if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton) {
          if (widget.child is Text) {
            final text = (widget.child as Text).data;
            if (text != null && text.trim().isNotEmpty) {
              final processedText = _processDutchText(text.trim());
              textContent.add('Knop: $processedText');
            }
          } else if (widget.child != null) {
            _extractTextFromWidgetEnhanced(widget.child!, textContent);
          }
        }
        return;
      }
      
      // Handle IconButton with tooltip
      if (widget is IconButton && widget.tooltip != null) {
        final tooltipText = _processDutchText(widget.tooltip!);
        textContent.add('Knop: $tooltipText');
        return;
      }
      
      // Handle FloatingActionButton
      if (widget is FloatingActionButton) {
        if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
          final tooltipText = _processDutchText(widget.tooltip!);
          textContent.add('Zwevende knop: $tooltipText');
        }
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
        return;
      }
      
      // Handle ListTile with enhanced processing
      if (widget is ListTile) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add(processedText);
          }
        } else if (widget.title != null) {
          _extractTextFromWidgetEnhanced(widget.title!, textContent);
        }
        
        if (widget.subtitle is Text) {
          final subtitleText = (widget.subtitle as Text).data;
          if (subtitleText != null && subtitleText.trim().isNotEmpty) {
            final processedText = _processDutchText(subtitleText.trim());
            textContent.add(processedText);
          }
        } else if (widget.subtitle != null) {
          _extractTextFromWidgetEnhanced(widget.subtitle!, textContent);
        }
        
        if (widget.leading != null) {
          _extractTextFromWidgetEnhanced(widget.leading!, textContent);
        }
        if (widget.trailing != null) {
          _extractTextFromWidgetEnhanced(widget.trailing!, textContent);
        }
        return;
      }
      
      // Handle AppBar with enhanced processing
      if (widget is AppBar) {
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add('Pagina: $processedText');
          }
        } else if (widget.title != null) {
          _extractTextFromWidgetEnhanced(widget.title!, textContent);
        }
        
        // Extract from actions
        if (widget.actions != null) {
          for (final action in widget.actions!) {
            _extractTextFromWidgetEnhanced(action, textContent);
          }
        }
        return;
      }
      
      // Handle Chip widgets
      if (widget is Chip) {
        if (widget.label is Text) {
          final labelText = (widget.label as Text).data;
          if (labelText != null && labelText.trim().isNotEmpty) {
            final processedText = _processDutchText(labelText.trim());
            textContent.add('Filter: $processedText');
          }
        } else {
          _extractTextFromWidgetEnhanced(widget.label, textContent);
        }
        return;
      }
      
      // Handle common layout widgets with children
      if (widget is Column) {
        for (final child in widget.children) {
          _extractTextFromWidgetEnhanced(child, textContent);
        }
      } else if (widget is Row) {
        for (final child in widget.children) {
          _extractTextFromWidgetEnhanced(child, textContent);
        }
      } else if (widget is Stack) {
        for (final child in widget.children) {
          _extractTextFromWidgetEnhanced(child, textContent);
        }
      } else if (widget is Wrap) {
        for (final child in widget.children) {
          _extractTextFromWidgetEnhanced(child, textContent);
        }
      } else if (widget is ListView) {
        textContent.add('Lijst met items');
      } else if (widget is GridView) {
        textContent.add('Raster met items');
      } else if (widget is Card) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Container) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Padding) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Center) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Align) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Expanded) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is Flexible) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is SizedBox) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      }
      
      // Handle containers and layout widgets - try to get their children
      else if (widget is SingleChildRenderObjectWidget) {
        if (widget.child != null) {
          _extractTextFromWidgetEnhanced(widget.child!, textContent);
        }
      } else if (widget is MultiChildRenderObjectWidget) {
        for (final child in widget.children) {
          _extractTextFromWidgetEnhanced(child, textContent);
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting text from widget ${widget.runtimeType}: $e');
    }
  }

  /// Process Dutch text for better speech pronunciation
  static String _processDutchText(String text) {
    if (text.isEmpty) return text;
    
    String processed = text;
    
    // Handle common Dutch abbreviations and acronyms
    processed = processed.replaceAll(RegExp(r'\bTTS\b', caseSensitive: false), 'T T S');
    processed = processed.replaceAll(RegExp(r'\bAPI\b', caseSensitive: false), 'A P I');
    processed = processed.replaceAll(RegExp(r'\bURL\b', caseSensitive: false), 'U R L');
    processed = processed.replaceAll(RegExp(r'\bHTML\b', caseSensitive: false), 'H T M L');
    processed = processed.replaceAll(RegExp(r'\bCSS\b', caseSensitive: false), 'C S S');
    processed = processed.replaceAll(RegExp(r'\bJS\b', caseSensitive: false), 'Javascript');
    
    // Handle common Dutch words that might be mispronounced
    processed = processed.replaceAll(RegExp(r'\bapp\b', caseSensitive: false), 'applicatie');
    processed = processed.replaceAll(RegExp(r'\bApp\b'), 'Applicatie');
    
    // Handle numbers for better pronunciation
    processed = processed.replaceAllMapped(RegExp(r'\b(\d+)\b'), (match) {
      final number = match.group(1)!;
      return _pronounceNumber(number);
    });
    
    // Handle email addresses
    processed = processed.replaceAllMapped(RegExp(r'\b[\w\.-]+@[\w\.-]+\.\w+\b'), (match) {
      return _pronounceEmail(match.group(0)!);
    });
    
    // Handle URLs
    processed = processed.replaceAllMapped(RegExp(r'https?://[^\s]+'), (match) {
      return 'Website link';
    });
    
    return processed;
  }

  /// Pronounce numbers in Dutch
  static String _pronounceNumber(String number) {
    if (number.length == 1) {
      return number;
    } else if (number.length == 2) {
      return '${number[0]} ${number[1]}';
    } else if (number.length == 3) {
      return '${number[0]} ${number[1]} ${number[2]}';
    } else {
      return number;
    }
  }

  /// Pronounce email addresses in Dutch
  static String _pronounceEmail(String email) {
    return email.replaceAll('@', ' at ').replaceAll('.', ' punt ');
  }

  /// Read specific text content with Dutch processing
  static Future<void> readText(BuildContext context, WidgetRef ref, String text) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Reading specific text: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}');
      print('📖 TTS: Reading specific text: ${text.length > 100 ? '${text.substring(0, 100)}...' : text}');
      
      // Process the text for better Dutch pronunciation
      final processedText = _processContentForDutchSpeech(_processDutchText(text));
      
      if (processedText.isNotEmpty) {
        print('🗣️ TTS: Speaking processed text: ${processedText.length > 200 ? '${processedText.substring(0, 200)}...' : processedText}');
        await accessibilityNotifier.speak(processedText);
      } else {
        print('⚠️ TTS: No processed text to speak');
      }
    } catch (e) {
      debugPrint('TTS Error reading text: $e');
      print('❌ TTS Error reading text: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de tekst.');
    }
  }

  /// Read content from a specific widget with Dutch processing
  static Future<void> readWidget(BuildContext context, WidgetRef ref, Widget widget) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Reading widget content...');
      print('🧩 TTS: Reading widget content...');
      
      // Extract text from the widget
      final List<String> textParts = [];
      _extractTextFromWidgetEnhanced(widget, textParts);
      
      if (textParts.isNotEmpty) {
        final combinedText = textParts.join('. ');
        print('📝 TTS: Extracted widget text: ${combinedText.length > 100 ? '${combinedText.substring(0, 100)}...' : combinedText}');
        
        final processedText = _processContentForDutchSpeech(combinedText);
        
        if (processedText.isNotEmpty) {
          print('🗣️ TTS: Speaking widget content: ${processedText.length > 200 ? '${processedText.substring(0, 200)}...' : processedText}');
          await accessibilityNotifier.speak(processedText);
        } else {
          print('⚠️ TTS: No processed widget text to speak');
        }
      } else {
        print('⚠️ TTS: No text found in widget');
      }
    } catch (e) {
      debugPrint('TTS Error reading widget: $e');
      print('❌ TTS Error reading widget: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van het element.');
    }
  }

  /// Check if TTS is currently speaking
  static bool isCurrentlySpeaking(WidgetRef ref) {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    return accessibilityState.isSpeaking;
  }

  /// Stop current TTS speech
  static Future<void> stopSpeaking(WidgetRef ref) async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.stopSpeaking();
  }

  /// Read everything visible on screen - comprehensive screen reading
  static Future<void> readEverythingOnScreen(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Starting comprehensive "read everything" mode...');
      print('🔊 TTS: Starting comprehensive "read everything" mode...');
      
      // Stop any current speech
      await accessibilityNotifier.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted, aborting comprehensive reading');
        print('❌ TTS: Context no longer mounted, aborting comprehensive reading');
        return;
      }
      
      // Extract ALL possible content from the screen
      final allContent = _extractEverythingFromScreen(context);
      
      debugPrint('TTS: Comprehensive extraction found ${allContent.length} characters');
      print('📊 TTS: Comprehensive extraction found ${allContent.length} characters');
      print('📄 TTS: Full content preview: ${allContent.length > 300 ? '${allContent.substring(0, 300)}...' : allContent}');
      
      if (allContent.isNotEmpty && allContent.length > 10) {
        // Process and speak the comprehensive content
        final processedContent = _processContentForDutchSpeech(allContent);
        print('🗣️ TTS: Speaking comprehensive content (${processedContent.length} chars)');
        await accessibilityNotifier.speak(processedContent);
      } else {
        // Fallback to regular screen reading
        debugPrint('TTS: Comprehensive extraction found little content, falling back to regular screen reading');
        print('⚠️ TTS: Comprehensive extraction found little content, falling back to regular screen reading');
        await readCurrentScreen(context, ref);
      }
      
    } catch (e) {
      debugPrint('TTS Error in comprehensive reading: $e');
      print('❌ TTS Error in comprehensive reading: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van alle inhoud op het scherm.');
    }
  }

  /// Comprehensive webpage scanning - reads ALL content including cards, forms, menus, popups, etc.
  /// This is the main method for complete page scanning functionality
  static Future<void> scanAndReadEntireWebpage(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Ensure TTS is enabled
    if (!accessibilityState.isTextToSpeechEnabled) {
      await accessibilityNotifier.setTextToSpeechEnabled(true);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    try {
      debugPrint('TTS: Starting comprehensive webpage scanning...');
      print('🔍 TTS: Starting comprehensive webpage scanning...');
      
      // Stop any current speech
      await accessibilityNotifier.stopSpeaking();
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted, aborting webpage scanning');
        print('❌ TTS: Context no longer mounted, aborting webpage scanning');
        return;
      }
      
      // Announce the start of comprehensive scanning
      await accessibilityNotifier.speak('Start met scannen van de hele pagina. Dit kan even duren.');
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Extract comprehensive content in organized sections
      final comprehensiveContent = _extractComprehensiveWebpageContent(context);
      
      debugPrint('TTS: Comprehensive webpage extraction found ${comprehensiveContent.length} characters');
      print('📊 TTS: Comprehensive webpage extraction found ${comprehensiveContent.length} characters');
      
      if (comprehensiveContent.isNotEmpty && comprehensiveContent.length > 10) {
        // Process and speak the comprehensive content with proper pacing
        final processedContent = _processContentForDutchSpeech(comprehensiveContent);
        print('🗣️ TTS: Speaking comprehensive webpage content (${processedContent.length} chars)');
        
        // Add introduction
        final fullContent = 'Hier is alle inhoud van de pagina: $processedContent';
        await accessibilityNotifier.speak(fullContent);
      } else {
        // Fallback to regular screen reading
        debugPrint('TTS: Comprehensive webpage extraction found little content, falling back to regular screen reading');
        print('⚠️ TTS: Comprehensive webpage extraction found little content, falling back to regular screen reading');
        await readCurrentScreen(context, ref);
      }
      
    } catch (e) {
      debugPrint('TTS Error in comprehensive webpage scanning: $e');
      print('❌ TTS Error in comprehensive webpage scanning: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het scannen van de hele pagina. Ik probeer een alternatieve methode.');
      
      // Try fallback method
      try {
        await readEverythingOnScreen(context, ref);
      } catch (fallbackError) {
        debugPrint('TTS: Fallback method also failed: $fallbackError');
        await accessibilityNotifier.speak('Het scannen van de pagina is mislukt. Probeer het opnieuw.');
      }
    }
  }



  /// Extract comprehensive webpage content in organized sections
  static String _extractComprehensiveWebpageContent(BuildContext context) {
    final List<String> contentSections = [];
    
    try {
      debugPrint('TTS: Starting comprehensive webpage content extraction...');
      print('🔍 TTS: Starting comprehensive webpage content extraction...');
      
      // 1. Page header and navigation
      final pageHeader = _extractPageHeaderAndNavigation(context);
      if (pageHeader.isNotEmpty) {
        contentSections.add('PAGINA KOP: $pageHeader');
        print('📄 TTS: Found page header: ${pageHeader.length} chars');
      }
      
      // 2. Search bars and filters
      final searchContent = _extractSearchBarsAndFilters(context);
      if (searchContent.isNotEmpty) {
        contentSections.add('ZOEK EN FILTERS: $searchContent');
        print('🔍 TTS: Found search content: ${searchContent.length} chars');
      }
      
      // 3. Main content cards and items
      final mainContent = _extractMainContentCards(context);
      if (mainContent.isNotEmpty) {
        contentSections.add('HOOFDINHOUD: $mainContent');
        print('📋 TTS: Found main content: ${mainContent.length} chars');
      }
      
      // 4. Interactive elements (buttons, links, menus)
      final interactiveElements = _extractInteractiveElementsComprehensive(context);
      if (interactiveElements.isNotEmpty) {
        contentSections.add('INTERACTIEVE ELEMENTEN: $interactiveElements');
        print('🔘 TTS: Found interactive elements: ${interactiveElements.length} chars');
      }
      
      // 5. Forms and input fields
      final formContent = _extractFormsAndInputFields(context);
      if (formContent.isNotEmpty) {
        contentSections.add('FORMULIEREN: $formContent');
        print('📝 TTS: Found form content: ${formContent.length} chars');
      }
      
      // 6. Comments and discussions
      final commentContent = _extractCommentsAndDiscussions(context);
      if (commentContent.isNotEmpty) {
        contentSections.add('REACTIES EN DISCUSSIES: $commentContent');
        print('💬 TTS: Found comment content: ${commentContent.length} chars');
      }
      
      // 7. Pop-ups, dialogs, and overlays
      final overlayContent = _extractPopupsAndOverlays(context);
      if (overlayContent.isNotEmpty) {
        contentSections.add('POP-UPS EN DIALOGEN: $overlayContent');
        print('🪟 TTS: Found overlay content: ${overlayContent.length} chars');
      }
      
      // 8. Footer and additional information
      final footerContent = _extractFooterAndAdditionalInfo(context);
      if (footerContent.isNotEmpty) {
        contentSections.add('ONDERKANT EN EXTRA INFO: $footerContent');
        print('📄 TTS: Found footer content: ${footerContent.length} chars');
      }
      
      // Combine all sections with clear separators
      final combinedContent = contentSections.join('. ');
      print('📊 TTS: Combined comprehensive content: ${combinedContent.length} total chars');
      
      return combinedContent;
      
    } catch (e) {
      debugPrint('TTS: Error in comprehensive webpage extraction: $e');
      print('❌ TTS: Error in comprehensive webpage extraction: $e');
      return _extractEverythingFromScreen(context); // Fallback to existing method
    }
  }

  /// Extract page header and navigation elements
  static String _extractPageHeaderAndNavigation(BuildContext context) {
    final List<String> headerParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Get page title from AppBar
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.appBar != null) {
        final appBar = scaffold!.appBar!;
        if (appBar is AppBar) {
          // Extract title
          if (appBar.title != null) {
            final titleText = _extractTextFromWidgetSingle(appBar.title!);
            if (titleText.isNotEmpty) {
              headerParts.add('Pagina titel: $titleText');
            }
          }
          
          // Extract actions
          if (appBar.actions != null && appBar.actions!.isNotEmpty) {
            final actionTexts = <String>[];
            for (final action in appBar.actions!) {
              final actionText = _extractTextFromWidgetSingle(action);
              if (actionText.isNotEmpty) {
                actionTexts.add(actionText);
              }
            }
            if (actionTexts.isNotEmpty) {
              headerParts.add('Navigatie knoppen: ${actionTexts.join(', ')}');
            }
          }
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting page header: $e');
    }
    
    return headerParts.join('. ');
  }

  /// Extract search bars and filter elements
  static String _extractSearchBarsAndFilters(BuildContext context) {
    final List<String> searchParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find search-related elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for search-related content
      final searchTexts = elementTexts
          .where((text) => text.toLowerCase().contains('zoek') ||
                          text.toLowerCase().contains('search') ||
                          text.toLowerCase().contains('filter') ||
                          text.startsWith('Invoerveld:') ||
                          text.contains('Zoek kata'))
          .toList();
      
      if (searchTexts.isNotEmpty) {
        searchParts.addAll(searchTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting search content: $e');
    }
    
    return searchParts.join('. ');
  }

  /// Extract main content cards and items
  static String _extractMainContentCards(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find main content
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for main content (exclude navigation, buttons, etc.)
      final mainTexts = elementTexts
          .where((text) => !text.startsWith('Knop:') &&
                          !text.startsWith('Zwevende knop:') &&
                          !text.startsWith('Filter:') &&
                          !text.startsWith('Invoerveld:') &&
                          !text.startsWith('Pagina:') &&
                          text.length > 5 &&
                          !text.toLowerCase().contains('loading') &&
                          !text.toLowerCase().contains('laden'))
          .toList();
      
      if (mainTexts.isNotEmpty) {
        contentParts.addAll(mainTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting main content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract interactive elements comprehensively
  static String _extractInteractiveElementsComprehensive(BuildContext context) {
    final List<String> interactiveParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find interactive elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for interactive elements
      final interactiveTexts = elementTexts
          .where((text) => text.startsWith('Knop:') || 
                          text.startsWith('Zwevende knop:') ||
                          text.startsWith('Filter:') ||
                          text.toLowerCase().contains('klik') ||
                          text.toLowerCase().contains('tap'))
          .toList();
      
      if (interactiveTexts.isNotEmpty) {
        interactiveParts.add('Beschikbare knoppen en opties:');
        interactiveParts.addAll(interactiveTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting interactive elements: $e');
    }
    
    return interactiveParts.join('. ');
  }

  /// Extract forms and input fields
  static String _extractFormsAndInputFields(BuildContext context) {
    final List<String> formParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find form elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for form-related content
      final formTexts = elementTexts
          .where((text) => text.startsWith('Invoerveld:') || 
                          text.startsWith('Ingevoerde tekst:') ||
                          text.toLowerCase().contains('formulier') ||
                          text.toLowerCase().contains('email') ||
                          text.toLowerCase().contains('wachtwoord'))
          .toList();
      
      if (formTexts.isNotEmpty) {
        formParts.add('Formulier velden en invoer:');
        formParts.addAll(formTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting form content: $e');
    }
    
    return formParts.join('. ');
  }

  /// Extract comments and discussions
  static String _extractCommentsAndDiscussions(BuildContext context) {
    final List<String> commentParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find comment elements
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for comment-related content
      final commentTexts = elementTexts
          .where((text) => text.toLowerCase().contains('reactie') ||
                          text.toLowerCase().contains('comment') ||
                          text.toLowerCase().contains('discussie') ||
                          text.toLowerCase().contains('bericht'))
          .toList();
      
      if (commentTexts.isNotEmpty) {
        commentParts.add('Reacties en discussies:');
        commentParts.addAll(commentTexts);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting comment content: $e');
    }
    
    return commentParts.join('. ');
  }

  /// Extract pop-ups, dialogs, and overlays
  static String _extractPopupsAndOverlays(BuildContext context) {
    final List<String> overlayParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Check for various overlay types
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog != null) {
        overlayParts.add('Waarschuwingsdialoog geopend');
        final dialogContent = _extractTextFromWidgetSingle(alertDialog);
        if (dialogContent.isNotEmpty) {
          overlayParts.add('Dialoog inhoud: $dialogContent');
        }
      }
      
      final dialog = context.findAncestorWidgetOfExactType<Dialog>();
      if (dialog != null) {
        overlayParts.add('Dialoog geopend');
        final dialogContent = _extractTextFromWidgetSingle(dialog);
        if (dialogContent.isNotEmpty) {
          overlayParts.add('Dialoog inhoud: $dialogContent');
        }
      }
      
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        overlayParts.add('Onderste menu geopend');
        final sheetContent = _extractTextFromWidgetSingle(bottomSheet);
        if (sheetContent.isNotEmpty) {
          overlayParts.add('Menu inhoud: $sheetContent');
        }
      }
      
      final snackBar = context.findAncestorWidgetOfExactType<SnackBar>();
      if (snackBar != null) {
        overlayParts.add('Melding getoond');
        final snackContent = _extractTextFromWidgetSingle(snackBar);
        if (snackContent.isNotEmpty) {
          overlayParts.add('Melding: $snackContent');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
    }
    
    return overlayParts.join('. ');
  }

  /// Extract footer and additional information
  static String _extractFooterAndAdditionalInfo(BuildContext context) {
    final List<String> footerParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Look for floating action buttons and bottom elements
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.floatingActionButton != null) {
        final fabText = _extractTextFromWidgetSingle(scaffold!.floatingActionButton!);
        if (fabText.isNotEmpty) {
          footerParts.add('Zwevende actie knop: $fabText');
        }
      }
      
      if (scaffold?.bottomNavigationBar != null) {
        final bottomNavText = _extractTextFromWidgetSingle(scaffold!.bottomNavigationBar!);
        if (bottomNavText.isNotEmpty) {
          footerParts.add('Onderste navigatie: $bottomNavText');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting footer content: $e');
    }
    
    return footerParts.join('. ');
  }

  /// Extract everything visible on screen using multiple extraction strategies
  static String _extractEverythingFromScreen(BuildContext context) {
    final List<String> allContentParts = [];
    
    try {
      debugPrint('TTS: Starting comprehensive "everything" extraction...');
      print('🔍 TTS: Starting comprehensive "everything" extraction...');
      
      // 1. Extract from overlays, dialogs, and popups first (highest priority)
      final overlayContent = _extractOverlayContent(context);
      if (overlayContent.isNotEmpty) {
        allContentParts.add('Overlay inhoud: $overlayContent');
        print('📋 TTS: Found overlay content: ${overlayContent.length} chars');
      }
      
      // 2. Extract page title and navigation information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        allContentParts.add('Pagina informatie: $pageInfo');
        print('📄 TTS: Found page info: ${pageInfo.length} chars');
      }
      
      // 3. Extract main content using multiple strategies
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        allContentParts.add('Hoofdinhoud: $mainContent');
        print('📝 TTS: Found main content: ${mainContent.length} chars');
      }
      
      // 4. Extract all text from element tree (most comprehensive)
      final elementTreeContent = _extractAllTextFromScreen(context);
      if (elementTreeContent.isNotEmpty) {
        allContentParts.add('Alle tekst: $elementTreeContent');
        print('🌳 TTS: Found element tree content: ${elementTreeContent.length} chars');
      }
      
      // 5. Extract interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        allContentParts.add('Interactieve elementen: $interactiveElements');
        print('🔘 TTS: Found interactive elements: ${interactiveElements.length} chars');
      }
      
      // 6. Extract form content if present
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        allContentParts.add('Formulier inhoud: $formContent');
        print('📋 TTS: Found form content: ${formContent.length} chars');
      }
      
      // 7. Extract from scaffold body, app bar, drawer, etc.
      final scaffoldContent = _extractFromScaffold(context);
      if (scaffoldContent.isNotEmpty) {
        allContentParts.add('Scaffold inhoud: $scaffoldContent');
        print('🏗️ TTS: Found scaffold content: ${scaffoldContent.length} chars');
      }
      
      // 8. Extract from any visible widgets using widget tree traversal
      final widgetTreeContent = _extractFromWidgetTree(context);
      if (widgetTreeContent.isNotEmpty) {
        allContentParts.add('Widget boom: $widgetTreeContent');
        print('🌿 TTS: Found widget tree content: ${widgetTreeContent.length} chars');
      }
      
      // Combine all content parts with clear separators
      final combinedContent = allContentParts.join('. ');
      print('📊 TTS: Combined everything content: ${combinedContent.length} total chars');
      
      return combinedContent;
      
    } catch (e) {
      debugPrint('TTS: Error in comprehensive extraction: $e');
      print('❌ TTS: Error in comprehensive extraction: $e');
      return '';
    }
  }

  /// Extract content from scaffold structure
  static String _extractFromScaffold(BuildContext context) {
    final List<String> scaffoldParts = [];
    
    try {
      if (!context.mounted) return '';
      
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold == null) return '';
      
      // Extract from app bar
      if (scaffold.appBar != null) {
        final appBarText = _extractTextFromWidgetSingle(scaffold.appBar!);
        if (appBarText.isNotEmpty) {
          scaffoldParts.add('App bar: $appBarText');
        }
      }
      
      // Extract from body
      if (scaffold.body != null) {
        final bodyText = _extractTextFromWidgetSingle(scaffold.body!);
        if (bodyText.isNotEmpty) {
          scaffoldParts.add('Body: $bodyText');
        }
      }
      
      // Extract from drawer
      if (scaffold.drawer != null) {
        final drawerText = _extractTextFromWidgetSingle(scaffold.drawer!);
        if (drawerText.isNotEmpty) {
          scaffoldParts.add('Drawer: $drawerText');
        }
      }
      
      // Extract from bottom navigation bar
      if (scaffold.bottomNavigationBar != null) {
        final bottomNavText = _extractTextFromWidgetSingle(scaffold.bottomNavigationBar!);
        if (bottomNavText.isNotEmpty) {
          scaffoldParts.add('Bottom navigation: $bottomNavText');
        }
      }
      
      // Extract from floating action button
      if (scaffold.floatingActionButton != null) {
        final fabText = _extractTextFromWidgetSingle(scaffold.floatingActionButton!);
        if (fabText.isNotEmpty) {
          scaffoldParts.add('Floating action button: $fabText');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting from scaffold: $e');
    }
    
    return scaffoldParts.join('. ');
  }

  /// Extract text from a single widget
  static String _extractTextFromWidgetSingle(Widget widget) {
    final List<String> textParts = [];
    _extractTextFromWidgetEnhanced(widget, textParts);
    return textParts.join('. ');
  }

  /// Extract content from widget tree using context
  static String _extractFromWidgetTree(BuildContext context) {
    final List<String> widgetParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Try to find and extract from common widget types
      final widgets = <Widget>[];
      
      // Find common container widgets
      final container = context.findAncestorWidgetOfExactType<Container>();
      if (container != null) widgets.add(container);
      
      final column = context.findAncestorWidgetOfExactType<Column>();
      if (column != null) widgets.add(column);
      
      final row = context.findAncestorWidgetOfExactType<Row>();
      if (row != null) widgets.add(row);
      
      final listView = context.findAncestorWidgetOfExactType<ListView>();
      if (listView != null) widgets.add(listView);
      
      final card = context.findAncestorWidgetOfExactType<Card>();
      if (card != null) widgets.add(card);
      
      // Extract text from found widgets
      for (final widget in widgets) {
        final text = _extractTextFromWidgetSingle(widget);
        if (text.isNotEmpty) {
          widgetParts.add(text);
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting from widget tree: $e');
    }
    
    return widgetParts.join('. ');
  }

  /// Extract content from dialogs and popups
  static String _extractDialogContent(BuildContext context) {
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _extractDialogContent');
        return '';
      }
      
      // Check for dialogs
      final dialog = context.findAncestorWidgetOfExactType<Dialog>() ?? 
                     context.findAncestorWidgetOfExactType<AlertDialog>();
      
      if (dialog != null) {
        return 'Dialog geopend met verschillende opties';
      }
      
      // Check for bottom sheets
      if (!context.mounted) return '';
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        return 'Onderste menu geopend';
      }
      
      // Check for snack bars
      if (!context.mounted) return '';
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
        if (!context.mounted) {
          debugPrint('TTS: Context no longer mounted in _extractAllTextFromScreen');
          return '';
        }
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
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _getPageInfo');
        return '';
      }
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
        if (label!.trim().isNotEmpty && label.trim() != 'Pagina geladen') {
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
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _getFallbackContentForCurrentRoute');
        return 'Karate app pagina geladen. Gebruik de navigatie knoppen om door de app te bewegen.';
      }
      
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

  /// Detect the current screen type for intelligent content reading
  static ScreenType _detectCurrentScreenType(BuildContext context) {
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _detectCurrentScreenType');
        return ScreenType.generic;
      }
      
      // First check for overlays and dialogs
      if (_hasOverlay(context)) {
        return ScreenType.overlay;
      }
      
      // Check for forms
      if (_hasForm(context)) {
        return ScreenType.form;
      }
      
      // Get route information
      final modalRoute = ModalRoute.of(context);
      if (modalRoute?.settings.name != null) {
        final routeName = modalRoute!.settings.name!;
        return _getScreenTypeFromRoute(routeName);
      }
      
      // Fallback to generic screen
      return ScreenType.generic;
    } catch (e) {
      debugPrint('TTS: Error detecting screen type: $e');
      return ScreenType.generic;
    }
  }

  /// Check if there's an overlay (dialog, bottom sheet, etc.)
  static bool _hasOverlay(BuildContext context) {
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _hasOverlay');
        return false;
      }
      
      return context.findAncestorWidgetOfExactType<AlertDialog>() != null ||
             context.findAncestorWidgetOfExactType<Dialog>() != null ||
             context.findAncestorWidgetOfExactType<BottomSheet>() != null ||
             context.findAncestorWidgetOfExactType<SnackBar>() != null;
    } catch (e) {
      debugPrint('TTS: Error checking for overlay: $e');
      return false;
    }
  }

  /// Check if there's a form on the screen
  static bool _hasForm(BuildContext context) {
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _hasForm');
        return false;
      }
      
      // Look for common form elements
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        final List<String> formElements = [];
        _extractTextFromWidget(scaffold!.body!, formElements);
        return formElements.any((text) => 
          text.contains('Invoerveld:') || 
          text.contains('Ingevoerde tekst:') ||
          text.toLowerCase().contains('email') ||
          text.toLowerCase().contains('wachtwoord') ||
          text.toLowerCase().contains('password'));
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get screen type from route name
  static ScreenType _getScreenTypeFromRoute(String routeName) {
    switch (routeName.toLowerCase()) {
      case '/':
      case '/home':
        return ScreenType.home;
      case '/login':
      case '/signup':
        return ScreenType.auth;
      case '/profile':
        return ScreenType.profile;
      case '/forum':
        return ScreenType.forum;
      case '/forum/post/':
        return ScreenType.forumDetail;
      case '/forum/create':
        return ScreenType.createPost;
      case '/favorites':
        return ScreenType.favorites;
      case '/user-management':
        return ScreenType.userManagement;
      case '/avatar-selection':
        return ScreenType.avatarSelection;
      case '/accessibility-demo':
        return ScreenType.accessibility;
      default:
        return ScreenType.generic;
    }
  }

  /// Extract screen content based on detected screen type
  static String _extractScreenContentByType(BuildContext context, ScreenType screenType) {
    switch (screenType) {
      case ScreenType.overlay:
        return _extractOverlayContent(context);
      case ScreenType.form:
        return _extractFormScreenContent(context);
      case ScreenType.auth:
        return _extractAuthScreenContent(context);
      case ScreenType.home:
        return _extractHomeScreenContent(context);
      case ScreenType.profile:
        return _extractProfileScreenContent(context);
      case ScreenType.forum:
        return _extractForumScreenContent(context);
      case ScreenType.forumDetail:
        return _extractForumDetailScreenContent(context);
      case ScreenType.createPost:
        return _extractCreatePostScreenContent(context);
      case ScreenType.favorites:
        return _extractFavoritesScreenContent(context);
      case ScreenType.userManagement:
        return _extractUserManagementScreenContent(context);
      case ScreenType.avatarSelection:
        return _extractAvatarSelectionScreenContent(context);
      case ScreenType.accessibility:
        return _extractAccessibilityScreenContent(context);
      case ScreenType.generic:
        return _extractComprehensiveScreenContent(context);
    }
  }


  /// Extract content from form screens
  static String _extractFormScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Formulier pagina');
      
      // Extract form fields and labels
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
      }
      
      // Extract buttons
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting form content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from authentication screens
  static String _extractAuthScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Inlog of registratie pagina');
      
      // Extract form fields
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
      }
      
      // Extract buttons and links
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting auth content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from home screen with enhanced kata-specific content
  static String _extractHomeScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Hoofdpagina van de Karate app');
      
      // Extract search functionality
      final searchContent = _extractSearchBarsAndFilters(context);
      if (searchContent.isNotEmpty) {
        contentParts.add('Zoek functionaliteit: $searchContent');
      }
      
      // Extract kata cards with enhanced information
      final kataContent = _extractKataCardsContent(context);
      if (kataContent.isNotEmpty) {
        contentParts.add('Kata technieken: $kataContent');
      }
      
      // Extract main content as fallback
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty && kataContent.isEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract navigation options
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting home content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content specifically from kata cards
  static String _extractKataCardsContent(BuildContext context) {
    final List<String> kataParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find kata-specific content
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for kata-related content
      final kataTexts = elementTexts
          .where((text) => text.toLowerCase().contains('kata') ||
                          text.toLowerCase().contains('techniek') ||
                          text.toLowerCase().contains('beweging') ||
                          text.toLowerCase().contains('karate') ||
                          text.length > 10) // Include longer descriptive text
          .toList();
      
      if (kataTexts.isNotEmpty) {
        // Limit to first 5 kata items to avoid overwhelming speech
        final limitedKataTexts = kataTexts.take(5).toList();
        kataParts.addAll(limitedKataTexts);
        
        if (kataTexts.length > 5) {
          kataParts.add('En nog ${kataTexts.length - 5} meer kata technieken');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting kata cards content: $e');
    }
    
    return kataParts.join('. ');
  }

  /// Extract content from profile screen
  static String _extractProfileScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Profiel pagina');
      
      // Extract user information
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract profile options
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting profile content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from forum screen with enhanced post-specific content
  static String _extractForumScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Forum pagina met berichten');
      
      // Extract forum posts with enhanced information
      final forumPosts = _extractForumPostsContent(context);
      if (forumPosts.isNotEmpty) {
        contentParts.add('Forum berichten: $forumPosts');
      }
      
      // Extract main content as fallback
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty && forumPosts.isEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract forum actions
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting forum content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content specifically from forum posts
  static String _extractForumPostsContent(BuildContext context) {
    final List<String> postParts = [];
    
    try {
      if (!context.mounted) return '';
      
      // Use element tree traversal to find forum-specific content
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      // Filter for forum-related content
      final forumTexts = elementTexts
          .where((text) => text.toLowerCase().contains('bericht') ||
                          text.toLowerCase().contains('post') ||
                          text.toLowerCase().contains('reactie') ||
                          text.toLowerCase().contains('discussie') ||
                          text.toLowerCase().contains('forum') ||
                          text.length > 15) // Include longer descriptive text
          .toList();
      
      if (forumTexts.isNotEmpty) {
        // Limit to first 3 forum posts to avoid overwhelming speech
        final limitedForumTexts = forumTexts.take(3).toList();
        postParts.addAll(limitedForumTexts);
        
        if (forumTexts.length > 3) {
          postParts.add('En nog ${forumTexts.length - 3} meer forum berichten');
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting forum posts content: $e');
    }
    
    return postParts.join('. ');
  }

  /// Extract content from forum detail screen
  static String _extractForumDetailScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Forum bericht detail pagina');
      
      // Extract post content
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract reply options
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting forum detail content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from create post screen
  static String _extractCreatePostScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Nieuw forum bericht maken');
      
      // Extract form fields
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
      }
      
      // Extract action buttons
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting create post content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from favorites screen
  static String _extractFavoritesScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Favorieten pagina');
      
      // Extract favorite items
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract favorite actions
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting favorites content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from user management screen
  static String _extractUserManagementScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Gebruikersbeheer pagina');
      
      // Extract user list
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract management options
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting user management content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from avatar selection screen
  static String _extractAvatarSelectionScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Avatar selectie pagina');
      
      // Extract avatar options
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract selection options
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting avatar selection content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Extract content from accessibility screen
  static String _extractAccessibilityScreenContent(BuildContext context) {
    final List<String> contentParts = [];
    
    try {
      contentParts.add('Toegankelijkheidsinstellingen pagina');
      
      // Extract accessibility options
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
      }
      
      // Extract setting controls
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting accessibility content: $e');
    }
    
    return contentParts.join('. ');
  }

  /// Generate cache key for content caching
  static String _generateCacheKey(BuildContext context, ScreenType screenType) {
    try {
      final route = ModalRoute.of(context);
      final routeName = route?.settings.name ?? 'unknown';
      return '${screenType.name}_$routeName';
    } catch (e) {
      return '${screenType.name}_unknown';
    }
  }

  /// Clear all cached content (useful for memory management)
  static void clearCache() {
    TTSCacheManager.clearCache();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return TTSCacheManager.getCacheStats();
  }
}

/// Screen types for intelligent content reading
enum ScreenType {
  overlay,
  form,
  auth,
  home,
  profile,
  forum,
  forumDetail,
  createPost,
  favorites,
  userManagement,
  avatarSelection,
  accessibility,
  generic,
}

/// Provider for the unified TTS service
final unifiedTTSServiceProvider = Provider<UnifiedTTSService>((ref) {
  return UnifiedTTSService();
});
