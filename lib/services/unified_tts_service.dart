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
    
    // Check if TTS button is visible - if not, don't read anything
    if (!accessibilityState.showTTSButton) {
      debugPrint('TTS: TTS button is hidden, not reading screen content');
      print('❌ TTS: TTS button is hidden, not reading screen content');
      return;
    }
    
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
        
        // If still empty, try comprehensive extraction as backup
        if (screenContent.isEmpty) {
          debugPrint('TTS: Screen-specific extraction found no content, trying comprehensive extraction');
          print('🔄 TTS: Screen-specific extraction found no content, trying comprehensive extraction');
          final comprehensiveContent = _extractAllVisibleTextComprehensive(context);
          if (comprehensiveContent.isNotEmpty) {
            screenContent = comprehensiveContent.join('. ');
            debugPrint('TTS: Comprehensive extraction found ${comprehensiveContent.length} items');
            print('✅ TTS: Comprehensive extraction found ${comprehensiveContent.length} items');
          }
        }
        
        TTSCacheManager.cacheContent(cacheKey, screenContent);
      } else {
        debugPrint('TTS: Using cached content for $screenType');
        print('💾 TTS: Using cached content for $screenType');
      }
      
      debugPrint('TTS: Extracted content length: ${screenContent.length}');
      debugPrint('TTS: Content preview: ${screenContent.length > 100 ? '${screenContent.substring(0, 100)}...' : screenContent}');
      print('📝 TTS: Extracted content length: ${screenContent.length}');
      print('📄 TTS: Content preview: ${screenContent.length > 100 ? '${screenContent.substring(0, 100)}...' : screenContent}');
      
      // Show full content in terminal for debugging
      if (screenContent.isNotEmpty) {
        print('📋 FULL EXTRACTED CONTENT: "$screenContent"');
      }
      
      if (screenContent.isNotEmpty && screenContent.length > 5) {
        // Process and speak the content with proper Dutch formatting
        final processedContent = _processContentForDutchSpeech(screenContent);
        print('🗣️ TTS: Speaking processed content: ${processedContent.length > 200 ? '${processedContent.substring(0, 200)}...' : processedContent}');
        await accessibilityNotifier.speak(processedContent);
      } else {
        // Provide helpful fallback based on current route
        debugPrint('TTS: Using fallback content due to insufficient extracted content');
        print('⚠️ TTS: Using fallback content due to insufficient extracted content');
        print('📊 TTS: Screen content length: ${screenContent.length}, Content: "$screenContent"');
        
        // Check context again before fallback
        if (!context.mounted) {
          debugPrint('TTS: Context no longer mounted during fallback');
          print('❌ TTS: Context no longer mounted during fallback');
          return;
        }
        
        // Try comprehensive extraction one more time as a last resort
        final comprehensiveContent = _extractAllVisibleTextComprehensive(context);
        if (comprehensiveContent.isNotEmpty) {
          final processedComprehensive = _processContentForDutchSpeech(comprehensiveContent.join('. '));
          print('🔄 TTS: Using comprehensive extraction as fallback: ${processedComprehensive.length > 200 ? '${processedComprehensive.substring(0, 200)}...' : processedComprehensive}');
          await accessibilityNotifier.speak(processedComprehensive);
        } else {
          // Don't use fake fallback content - try one more comprehensive extraction
          debugPrint('TTS: No content found, trying one more comprehensive extraction');
          print('⚠️ TTS: No content found, trying one more comprehensive extraction');
          
          final lastResortContent = _extractAllVisibleTextComprehensive(context);
          if (lastResortContent.isNotEmpty) {
            final processedLastResort = _processContentForDutchSpeech(lastResortContent.join('. '));
            print('🔄 TTS: Found content on last resort: ${processedLastResort.length > 200 ? '${processedLastResort.substring(0, 200)}...' : processedLastResort}');
            await accessibilityNotifier.speak(processedLastResort);
          } else {
            // Generate helpful fallback based on current screen context
            final fallbackContent = _generateContextualFallbackContent(context);
            final processedFallback = _processContentForDutchSpeech(fallbackContent);
            debugPrint('TTS: Using contextual fallback content: $processedFallback');
            print('🔄 TTS: Using contextual fallback content: $processedFallback');
            await accessibilityNotifier.speak(processedFallback);
          }
        }
      }
      
    } catch (e) {
      debugPrint('TTS Error: $e');
      print('❌ TTS Error: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het voorlezen van de pagina.');
    }
  }


  /// Process content for better Dutch speech pronunciation
  static String _processContentForDutchSpeech(String content) {
    if (content.isEmpty) return content;
    
    // Clean up the content for better speech
    String processed = content;
    
    // Remove excessive whitespace and normalize
    processed = processed.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Remove UI element descriptions to make speech more natural
    processed = processed.replaceAll(RegExp(r'Knop:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Zwevende knop:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Filter:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Invoerveld:\s*', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Pagina:\s*', caseSensitive: false), '');
    
    // Remove redundant phrases that make speech unnatural
    processed = processed.replaceAll(RegExp(r'Dit is de\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit zijn de\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit is je\s+', caseSensitive: false), '');
    processed = processed.replaceAll(RegExp(r'Dit zijn je\s+', caseSensitive: false), '');
    
    // Clean up multiple dots and spaces
    processed = processed.replaceAll(RegExp(r'\.\s*\.\s*\.'), '.');
    processed = processed.replaceAll(RegExp(r'\s+'), ' ');
    
    // Add natural pauses for better readability
    processed = processed.replaceAll(RegExp(r'\.\s*'), '. ');
    processed = processed.replaceAll(RegExp(r'!\s*'), '! ');
    processed = processed.replaceAll(RegExp(r'\?\s*'), '? ');
    
    // Handle common abbreviations and acronyms for better pronunciation
    processed = processed.replaceAll(RegExp(r'\bTTS\b', caseSensitive: false), 'T T S');
    processed = processed.replaceAll(RegExp(r'\bAPI\b', caseSensitive: false), 'A P I');
    processed = processed.replaceAll(RegExp(r'\bURL\b', caseSensitive: false), 'U R L');
    
    // Ensure proper sentence endings
    if (!processed.endsWith('.') && !processed.endsWith('!') && !processed.endsWith('?')) {
      processed += '.';
    }
    
    return processed.trim();
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
      try {
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
      } catch (e) {
        debugPrint('TTS: Error accessing Scaffold for page info: $e');
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

  /// Aggressive text extraction that tries multiple approaches
  static void _extractTextAggressively(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting aggressive text extraction');
      
      // Try to find Scaffold and extract from its body
      try {
        final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        if (scaffold != null) {
          debugPrint('TTS: Found Scaffold, extracting from body');
          if (scaffold.body != null) {
            _extractTextFromWidgetRecursively(scaffold.body!, textContent);
          }
          if (scaffold.appBar != null) {
            debugPrint('TTS: Extracting from AppBar');
            _extractTextFromWidgetRecursively(scaffold.appBar!, textContent);
          }
        } else {
          debugPrint('TTS: No Scaffold found in context, skipping scaffold extraction');
        }
      } catch (e) {
        debugPrint('TTS: Error accessing Scaffold: $e');
      }
      
      // Try to find MaterialApp and extract from its home
      final materialApp = context.findAncestorWidgetOfExactType<MaterialApp>();
      if (materialApp != null && materialApp.home != null) {
        debugPrint('TTS: Found MaterialApp, extracting from home');
        _extractTextFromWidgetRecursively(materialApp.home!, textContent);
      }
      
      debugPrint('TTS: Aggressive extraction completed, found ${textContent.length} items');
    } catch (e) {
      debugPrint('TTS: Error in aggressive text extraction: $e');
    }
  }
  
  /// Recursively extract text from any widget
  static void _extractTextFromWidgetRecursively(Widget widget, List<String> textContent) {
    try {
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty && text.trim() != ' ') {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
          debugPrint('TTS: Aggressive found Text: $processedText');
        }
      } else if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (text.trim().isNotEmpty && text.trim() != ' ') {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
          debugPrint('TTS: Aggressive found RichText: $processedText');
        }
      } else if (widget is StatefulWidget || widget is StatelessWidget) {
        // For complex widgets, we can't easily extract text, but we can try
        debugPrint('TTS: Found complex widget: ${widget.runtimeType}');
      }
    } catch (e) {
      debugPrint('TTS: Error extracting from widget recursively: $e');
    }
  }

  /// Alternative text extraction methods when standard approaches fail
  static void _extractTextWithAlternativeMethods(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting alternative text extraction methods');
      
      // Method 1: Try to extract from RenderObject tree
      _extractTextFromRenderObject(context, textContent);
      
      // Method 2: Try to find text in common widget patterns
      _extractTextFromCommonPatterns(context, textContent);
      
      // Method 3: Try to extract from Material widgets specifically
      _extractTextFromMaterialWidgets(context, textContent);
      
      // Method 4: Try a more aggressive widget tree traversal
      _extractTextFromWidgetTreeAggressive(context, textContent);
      
      debugPrint('TTS: Alternative extraction completed, found ${textContent.length} items');
    } catch (e) {
      debugPrint('TTS: Error in alternative text extraction: $e');
    }
  }
  
  /// Extract text from RenderObject tree
  static void _extractTextFromRenderObject(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Trying RenderObject extraction');
      
      // Get the RenderObject from the context
      final renderObject = context.findRenderObject();
      if (renderObject != null) {
        _traverseRenderObject(renderObject, textContent);
      }
    } catch (e) {
      debugPrint('TTS: Error in RenderObject extraction: $e');
    }
  }
  
  /// Traverse RenderObject tree to find text
  static void _traverseRenderObject(RenderObject renderObject, List<String> textContent) {
    try {
      // Check if this is a RenderParagraph (contains text)
      // Note: RenderParagraph is not directly accessible, so we'll skip this for now
      // and rely on other extraction methods
      debugPrint('TTS: Traversing RenderObject: ${renderObject.runtimeType}');
      
      // Traverse children safely
      renderObject.visitChildren((child) {
        try {
          _traverseRenderObject(child, textContent);
        } catch (e) {
          debugPrint('TTS: Error traversing child RenderObject: $e');
        }
      });
    } catch (e) {
      debugPrint('TTS: Error traversing RenderObject: $e');
    }
  }
  
  /// Extract text from common widget patterns
  static void _extractTextFromCommonPatterns(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Trying common patterns extraction');
      
      // Look for common text-containing widgets in the widget tree
      context.visitChildElements((element) {
        try {
          if (!element.mounted) return;
          
          final widget = element.widget;
          
          // Check for Card widgets that might contain text
          if (widget is Card) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
          
          // Check for Container widgets that might contain text
          if (widget is Container) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
          
          // Check for Column and Row widgets
          if (widget is Column || widget is Row) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
          
          // Check for ListView and other scrollable widgets
          if (widget is ListView || widget is SingleChildScrollView) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
        } catch (e) {
          debugPrint('TTS: Error processing element: $e');
        }
      });
    } catch (e) {
      debugPrint('TTS: Error in common patterns extraction: $e');
    }
  }
  
  /// Extract text from Material widgets specifically
  static void _extractTextFromMaterialWidgets(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Trying Material widgets extraction');
      
      // Look for Material-specific widgets that commonly contain text
      context.visitChildElements((element) {
        try {
          if (!element.mounted) return;
          
          final widget = element.widget;
          
          // Check for Material widgets
          if (widget is Material) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
          
          // Check for InkWell widgets
          if (widget is InkWell) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
          
          // Check for GestureDetector widgets
          if (widget is GestureDetector) {
            _extractTextFromWidgetRecursively(widget, textContent);
          }
        } catch (e) {
          debugPrint('TTS: Error processing Material element: $e');
        }
      });
    } catch (e) {
      debugPrint('TTS: Error in Material widgets extraction: $e');
    }
  }

  /// Aggressive widget tree traversal that tries to extract text from any widget
  static void _extractTextFromWidgetTreeAggressive(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting aggressive widget tree traversal');
      
      // Try to find the root widget and traverse it completely
      final rootElement = context.findRootAncestorStateOfType<State<StatefulWidget>>();
      if (rootElement != null) {
        debugPrint('TTS: Found root element: ${rootElement.runtimeType}');
      }
      
      // Try to traverse the entire widget tree from the context
      context.visitChildElements((element) {
        try {
          if (element.mounted) {
            _extractTextFromElementAggressive(element, textContent);
          }
        } catch (e) {
          debugPrint('TTS: Error in aggressive element traversal: $e');
        }
      });
      
      debugPrint('TTS: Aggressive widget tree traversal completed');
    } catch (e) {
      debugPrint('TTS: Error in aggressive widget tree traversal: $e');
    }
  }
  
  /// Aggressive text extraction from any element
  static void _extractTextFromElementAggressive(Element element, List<String> textContent) {
    try {
      final widget = element.widget;
      
      // Try to extract text from any widget that might contain text
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && text.trim().isNotEmpty) {
          textContent.add(text.trim());
          debugPrint('TTS: Aggressive found Text: ${text.trim()}');
        }
      } else if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (text.trim().isNotEmpty) {
          textContent.add(text.trim());
          debugPrint('TTS: Aggressive found RichText: ${text.trim()}');
        }
      } else if (widget is TextField) {
        if (widget.decoration?.hintText != null) {
          textContent.add(widget.decoration!.hintText!);
          debugPrint('TTS: Aggressive found TextField hint: ${widget.decoration!.hintText}');
        }
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add(widget.controller!.text);
          debugPrint('TTS: Aggressive found TextField content: ${widget.controller!.text}');
        }
      } else if (widget is TextFormField) {
        // Note: TextFormField decoration is not directly accessible, so we skip hint text
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add(widget.controller!.text);
          debugPrint('TTS: Aggressive found TextFormField content: ${widget.controller!.text}');
        }
      }
      
      // Recursively visit child elements
      element.visitChildElements((childElement) {
        _extractTextFromElementAggressive(childElement, textContent);
      });
      
    } catch (e) {
      debugPrint('TTS: Error in aggressive element extraction: $e');
    }
  }

  /// Enhanced element tree traversal with better Dutch text processing
  static void _extractTextFromElementTreeEnhanced(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting enhanced element tree traversal from ${context.widget.runtimeType}');
      print('🔍 TTS: Starting enhanced element tree traversal from ${context.widget.runtimeType}');
      
      int elementCount = 0;
      int textWidgetCount = 0;
      
      // Visit all child elements in the tree recursively
      context.visitChildElements((element) {
        elementCount++;
        try {
          if (!element.mounted) return;
          
          final beforeCount = textContent.length;
          _extractTextFromElementEnhanced(element, textContent);
          final afterCount = textContent.length;
          
          if (afterCount > beforeCount) {
            textWidgetCount++;
            debugPrint('TTS: Found text in element ${element.widget.runtimeType}: ${textContent.sublist(beforeCount)}');
          }
          
          // Also visit child elements recursively for deeper traversal
          element.visitChildElements((childElement) {
            elementCount++;
            try {
              if (!childElement.mounted) return;
              
              final beforeChildCount = textContent.length;
              _extractTextFromElementEnhanced(childElement, textContent);
              final afterChildCount = textContent.length;
              
              if (afterChildCount > beforeChildCount) {
                textWidgetCount++;
                debugPrint('TTS: Found text in child element ${childElement.widget.runtimeType}: ${textContent.sublist(beforeChildCount)}');
              }
            } catch (e) {
              debugPrint('TTS: Error extracting from child element: $e');
            }
          });
        } catch (e) {
          debugPrint('TTS: Error extracting from element: $e');
        }
      });
      
      debugPrint('TTS: Enhanced element tree traversal completed, found ${textContent.length} items from $elementCount elements ($textWidgetCount text widgets)');
      print('✅ TTS: Enhanced element tree traversal completed, found ${textContent.length} items from $elementCount elements ($textWidgetCount text widgets)');
    } catch (e) {
      debugPrint('TTS: Error in enhanced element tree extraction: $e');
      print('❌ TTS: Error in enhanced element tree extraction: $e');
    }
  }

  /// Enhanced text extraction from a specific element with Dutch processing
  static void _extractTextFromElementEnhanced(Element element, List<String> textContent) {
    try {
      final widget = element.widget;
      
      // Handle different widget types that contain text with enhanced Dutch processing
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && _isValidText(text)) {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
          debugPrint('TTS: Found Text widget: $processedText');
        }
      } else if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (_isValidText(text)) {
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
      } else if (widget is TextFormField) {
        // Note: TextFormField decoration is not directly accessible, so we skip hint text
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          final inputText = _processDutchText(widget.controller!.text);
          textContent.add('Ingevoerde tekst: $inputText');
          debugPrint('TTS: Found TextFormField content: "$inputText"');
        }
      } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.trim().isNotEmpty) {
              final processedText = _processDutchText(text.trim());
              textContent.add('Knop: $processedText');
              debugPrint('TTS: Found Button: $processedText');
            }
          }
        }
      } else if (widget is IconButton && widget.tooltip != null) {
        final tooltipText = _processDutchText(widget.tooltip!);
        textContent.add('Knop: $tooltipText');
        debugPrint('TTS: Found IconButton tooltip: $tooltipText');
      } else if (widget is FloatingActionButton && widget.tooltip != null) {
        // Skip TTS button tooltip to avoid reading its own description
        final tooltipText = widget.tooltip!;
        if (!tooltipText.contains('Scan hele pagina') && !tooltipText.contains('voorlezen')) {
          final processedTooltip = _processDutchText(tooltipText);
          textContent.add('Zwevende knop: $processedTooltip');
          debugPrint('TTS: Found FAB tooltip: $processedTooltip');
        }
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
      } else if (widget is Card) {
        // Extract text from card content
        final child = widget.child;
        if (child is Text) {
          final text = child.data;
          if (text != null && text.trim().isNotEmpty) {
            final processedText = _processDutchText(text.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found Card text: $processedText');
          }
        }
      } else if (widget is Container) {
        // Extract text from container content
        final child = widget.child;
        if (child is Text) {
          final text = child.data;
          if (text != null && text.trim().isNotEmpty) {
            final processedText = _processDutchText(text.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found Container text: $processedText');
          }
        }
      } else if (widget is Column || widget is Row) {
        // Extract text from column/row children
        if (widget is Flex) {
          for (final child in widget.children) {
            if (child is Text) {
              final text = child.data;
              if (text != null && text.trim().isNotEmpty) {
                final processedText = _processDutchText(text.trim());
                textContent.add(processedText);
                debugPrint('TTS: Found Flex child text: $processedText');
              }
            }
          }
        }
      } else if (widget is PopupMenuButton) {
        // Extract text from popup menu items
        if (widget.tooltip != null) {
          final tooltipText = _processDutchText(widget.tooltip!);
          textContent.add('Menu: $tooltipText');
          debugPrint('TTS: Found PopupMenuButton tooltip: $tooltipText');
        }
      } else if (widget is DropdownButton) {
        // Extract text from dropdown items
        if (widget.hint is Text) {
          final hintText = (widget.hint as Text).data;
          if (hintText != null && hintText.trim().isNotEmpty) {
            final processedText = _processDutchText(hintText.trim());
            textContent.add('Dropdown: $processedText');
            debugPrint('TTS: Found DropdownButton hint: $processedText');
          }
        }
      } else if (widget is ListTile) {
        // Extract text from ListTile
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
      } else if (widget is Card) {
        // Extract text from Card content
        final child = widget.child;
        if (child is Column) {
          // Handle cards with Column children
          final columnChild = child;
          for (final flexChildItem in columnChild.children) {
            if (flexChildItem is Text) {
              final text = flexChildItem.data;
              if (text != null && text.trim().isNotEmpty) {
                final processedText = _processDutchText(text.trim());
                textContent.add(processedText);
                debugPrint('TTS: Found Card column text: $processedText');
              }
            }
          }
        } else if (child is Row) {
          // Handle cards with Row children
          final rowChild = child;
          for (final flexChildItem in rowChild.children) {
            if (flexChildItem is Text) {
              final text = flexChildItem.data;
              if (text != null && text.trim().isNotEmpty) {
                final processedText = _processDutchText(text.trim());
                textContent.add(processedText);
                debugPrint('TTS: Found Card flex text: $processedText');
              }
            }
          }
        }
      } else if (widget is ExpansionTile) {
        // Extract text from ExpansionTile
        final title = widget.title;
        if (title is Text) {
          final titleText = title.data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found ExpansionTile title: $processedText');
          }
        }
      } else if (widget is Switch) {
        // Extract text from switch labels
        if (widget.activeThumbColor != null) {
          textContent.add('Schakelaar');
          debugPrint('TTS: Found Switch');
        }
      } else if (widget is Checkbox) {
        // Extract text from checkbox labels
        textContent.add('Selectievakje');
        debugPrint('TTS: Found Checkbox');
      } else if (widget is Radio) {
        // Extract text from radio button labels
        textContent.add('Keuzerondje');
        debugPrint('TTS: Found Radio');
      } else if (widget is Slider) {
        // Extract text from slider labels
        textContent.add('Schuifbalk');
        debugPrint('TTS: Found Slider');
      } else if (widget is ProgressIndicator) {
        // Extract text from progress indicators
        textContent.add('Voortgangsindicator');
        debugPrint('TTS: Found ProgressIndicator');
      } else if (widget is CircularProgressIndicator) {
        // Extract text from circular progress indicators
        textContent.add('Laden');
        debugPrint('TTS: Found CircularProgressIndicator');
      } else if (widget is LinearProgressIndicator) {
        // Extract text from linear progress indicators
        textContent.add('Voortgang');
        debugPrint('TTS: Found LinearProgressIndicator');
      } else if (widget is SnackBar) {
        // Extract text from snackbars
        if (widget.content is Text) {
          final text = (widget.content as Text).data;
          if (text != null && text.trim().isNotEmpty) {
            final processedText = _processDutchText(text.trim());
            textContent.add('Bericht: $processedText');
            debugPrint('TTS: Found SnackBar text: $processedText');
          }
        }
      } else if (widget is AlertDialog) {
        // Extract text from alert dialogs
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add('Dialoog: $processedText');
            debugPrint('TTS: Found AlertDialog title: $processedText');
          }
        }
        if (widget.content is Text) {
          final contentText = (widget.content as Text).data;
          if (contentText != null && contentText.trim().isNotEmpty) {
            final processedText = _processDutchText(contentText.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found AlertDialog content: $processedText');
          }
        }
      } else if (widget is Drawer) {
        // Extract text from drawer content
        textContent.add('Navigatiemenu');
        debugPrint('TTS: Found Drawer');
      } else if (widget is BottomNavigationBar) {
        // Extract text from bottom navigation
        textContent.add('Ondernavigatie');
        debugPrint('TTS: Found BottomNavigationBar');
      } else if (widget is TabBar) {
        // Extract text from tab bar
        textContent.add('Tabbladen');
        debugPrint('TTS: Found TabBar');
      } else if (widget is ExpansionTile) {
        // Extract text from expansion tiles
        if (widget.title is Text) {
          final titleText = (widget.title as Text).data;
          if (titleText != null && titleText.trim().isNotEmpty) {
            final processedText = _processDutchText(titleText.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found ExpansionTile title: $processedText');
          }
        }
      } else if (widget is DataTable) {
        // Extract text from data tables
        textContent.add('Tabel');
        debugPrint('TTS: Found DataTable');
      } else if (widget is DataColumn) {
        // Extract text from data columns
        final dataColumn = widget as DataColumn;
        if (dataColumn.label is Text) {
          final labelText = (dataColumn.label as Text).data;
          if (labelText != null && labelText.trim().isNotEmpty) {
            final processedText = _processDutchText(labelText.trim());
            textContent.add('Kolom: $processedText');
            debugPrint('TTS: Found DataColumn: $processedText');
          }
        }
      } else if (widget is DataRow) {
        // Extract text from data rows
        textContent.add('Rij');
        debugPrint('TTS: Found DataRow');
      } else if (widget is DataCell) {
        // Extract text from data cells
        final dataCell = widget as DataCell;
        final child = dataCell.child;
        if (child is Text) {
          final text = child.data;
          if (text != null && text.trim().isNotEmpty) {
            final processedText = _processDutchText(text.trim());
            textContent.add(processedText);
            debugPrint('TTS: Found DataCell: $processedText');
          }
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

  /// Check if text is valid and meaningful for TTS
  static bool _isValidText(String text) {
    if (text.isEmpty) return false;
    
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    
    // Filter out common empty or meaningless text patterns
    final invalidPatterns = [
      'Pagina geladen',
      'Loading...',
      'Laden...',
      ' ', // Single space
      '\u200B', // Zero-width space
      '\u200C', // Zero-width non-joiner
      '\u200D', // Zero-width joiner
      '\uFEFF', // Zero-width no-break space
    ];
    
    for (final pattern in invalidPatterns) {
      if (trimmed == pattern) return false;
    }
    
    // Check if text contains only whitespace or special characters
    if (trimmed.replaceAll(RegExp(r'\s'), '').isEmpty) return false;
    
    // Check if text is too short (less than 2 characters)
    if (trimmed.length < 2) return false;
    
    // Check if text contains only special characters or symbols
    if (trimmed.replaceAll(RegExp(r'[a-zA-Z0-9\u00C0-\u017F\u0100-\u017F\u0180-\u024F\u1E00-\u1EFF]'), '').length == trimmed.length) {
      return false;
    }
    
    return true;
  }

  /// Enhanced text extraction with better Dutch language support
  static void _extractTextFromWidgetEnhanced(Widget widget, List<String> textContent) {
    try {
      // Handle Text widgets with enhanced Dutch processing
      if (widget is Text) {
        final text = widget.data ?? widget.textSpan?.toPlainText();
        if (text != null && _isValidText(text)) {
          final processedText = _processDutchText(text.trim());
          textContent.add(processedText);
        }
        return;
      }
      
      // Handle RichText widgets
      if (widget is RichText) {
        final text = widget.text.toPlainText();
        if (_isValidText(text)) {
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
      
      // Handle TextFormField widgets (same as TextField but for forms)
      if (widget is TextFormField) {
        // Note: TextFormField decoration is not directly accessible, so we skip hint text
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          final inputText = _processDutchText(widget.controller!.text);
          textContent.add('Ingevoerde tekst: $inputText');
        }
        return;
      }
      
      // Handle buttons with enhanced Dutch processing
      if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.trim().isNotEmpty) {
              final processedText = _processDutchText(text.trim());
              textContent.add('Knop: $processedText');
            }
          } else if (child != null) {
            _extractTextFromWidgetEnhanced(child, textContent);
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
          // Skip TTS button tooltip to avoid reading its own description
          final tooltipText = widget.tooltip!;
          if (!tooltipText.contains('Scan hele pagina') && !tooltipText.contains('voorlezen')) {
            final processedTooltip = _processDutchText(tooltipText);
            textContent.add('Zwevende knop: $processedTooltip');
          }
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
        _extractTextFromWidgetEnhanced(widget.child, textContent);
      } else if (widget is Flexible) {
        _extractTextFromWidgetEnhanced(widget.child, textContent);
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
    // Check if context is still mounted before using ref
    if (!context.mounted) {
      debugPrint('TTS: Context no longer mounted, aborting text reading');
      return;
    }
    
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Check if TTS button is visible - if not, don't read anything
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.showTTSButton) {
      debugPrint('TTS: TTS button is hidden, not reading text');
      print('❌ TTS: TTS button is hidden, not reading text');
      return;
    }
    
    // Ensure TTS is enabled
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
    // Check if context is still mounted before using ref
    if (!context.mounted) {
      debugPrint('TTS: Context no longer mounted, aborting widget reading');
      return;
    }
    
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Check if TTS button is visible - if not, don't read anything
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.showTTSButton) {
      debugPrint('TTS: TTS button is hidden, not reading widget');
      print('❌ TTS: TTS button is hidden, not reading widget');
      return;
    }
    
    // Ensure TTS is enabled
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
      if (!context.mounted) return;
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
        if (context.mounted) {
          await readCurrentScreen(context, ref);
        }
      }
      
    } catch (e) {
      debugPrint('TTS Error in comprehensive webpage scanning: $e');
      print('❌ TTS Error in comprehensive webpage scanning: $e');
      await accessibilityNotifier.speak('Er was een probleem bij het scannen van de hele pagina. Ik probeer een alternatieve methode.');
      
      // Try fallback method
      try {
        if (context.mounted) {
          await readEverythingOnScreen(context, ref);
        }
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
                          !text.startsWith('Beschikbare knoppen') &&
                          !text.startsWith('Navigatie') &&
                          !text.toLowerCase().contains('scan hele pagina') &&
                          !text.toLowerCase().contains('voorlezen') &&
                          !text.toLowerCase().contains('spraak') &&
                          text.length > 5 &&
                          !text.toLowerCase().contains('loading') &&
                          !text.toLowerCase().contains('laden') &&
                          !text.toLowerCase().contains('welkom bij de karate app'))
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
            // Skip TTS button tooltip to avoid reading its own description
            final tooltipText = fab.tooltip!;
            if (!tooltipText.contains('Scan hele pagina') && !tooltipText.contains('voorlezen')) {
              textContent.add('Zwevende knop: $tooltipText');
            }
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
      
      // Handle TextFormField widgets (same as TextField but for forms)
      if (widget is TextFormField) {
        // Note: TextFormField decoration is not directly accessible, so we skip hint text
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add('Ingevoerde tekst: ${widget.controller!.text}');
        }
        return;
      }
      
      // Handle buttons with text
      if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        // Try to extract text from button child
        if (widget is ButtonStyleButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.trim().isNotEmpty) {
              textContent.add('Knop: $text');
            }
          } else if (child != null) {
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
          // Skip TTS button tooltip to avoid reading its own description
          final tooltipText = widget.tooltip!;
          if (!tooltipText.contains('Scan hele pagina') && !tooltipText.contains('voorlezen')) {
            textContent.add('Zwevende knop: $tooltipText');
          }
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
        _extractTextFromWidget(widget.child, textContent);
      } else if (widget is Flexible) {
        _extractTextFromWidget(widget.child, textContent);
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
      } else if (widget is TextFormField) {
        // Note: TextFormField decoration is not directly accessible, so we skip hint text
        if (widget.controller?.text != null && widget.controller!.text.isNotEmpty) {
          textContent.add('Ingevoerde tekst: ${widget.controller!.text}');
          debugPrint('TTS: Found TextFormField content: "${widget.controller!.text}"');
        }
      } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
        if (widget is ButtonStyleButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.trim().isNotEmpty) {
              textContent.add('Knop: $text');
              debugPrint('TTS: Found Button: "$text"');
            }
          }
        }
      } else if (widget is IconButton && widget.tooltip != null) {
        textContent.add('Knop: ${widget.tooltip}');
        debugPrint('TTS: Found IconButton tooltip: "${widget.tooltip}"');
      } else if (widget is FloatingActionButton && widget.tooltip != null) {
        // Skip TTS button tooltip to avoid reading its own description
        final tooltipText = widget.tooltip!;
        if (!tooltipText.contains('Scan hele pagina') && !tooltipText.contains('voorlezen')) {
          textContent.add('Zwevende knop: $tooltipText');
          debugPrint('TTS: Found FAB tooltip: "$tooltipText"');
        }
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
        final label = widget.properties.label;
        if (label != null && label.trim().isNotEmpty && label.trim() != 'Pagina geladen') {
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


  /// Generate contextual fallback content based on current screen context
  static String _generateContextualFallbackContent(BuildContext context) {
    try {
      // Try to determine the current screen type from route
      final route = ModalRoute.of(context)?.settings.name ?? '';
      
      // Also try to get page title from AppBar
      String pageTitle = '';
      try {
        final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
        if (scaffold?.appBar is AppBar) {
          final appBar = scaffold!.appBar as AppBar;
          if (appBar.title is Text) {
            pageTitle = (appBar.title as Text).data ?? '';
          }
        }
      } catch (e) {
        debugPrint('TTS: Could not get page title: $e');
      }
      
      // Generate content based on route and title
      if (route.contains('home') || route.contains('Home') || pageTitle.toLowerCase().contains('home')) {
        return 'Je bent op de hoofdpagina van de Karate app. Hier kun je navigeren naar verschillende onderdelen zoals kata\'s, het forum, en je profiel. Gebruik de navigatie knoppen onderaan het scherm om door de app te bewegen.';
      } else if (route.contains('auth') || route.contains('login') || route.contains('signup') || 
                 route.contains('Auth') || route.contains('Login') || route.contains('Signup') ||
                 pageTitle.toLowerCase().contains('inlog') || pageTitle.toLowerCase().contains('registr')) {
        return 'Je bent op de inlog en registratie pagina van de Karate app. Hier kun je inloggen met je bestaande account of een nieuw account aanmaken. Gebruik de tabbladen bovenaan om tussen inloggen en registreren te wisselen. Vul je e-mailadres en wachtwoord in en klik op de knop om in te loggen of te registreren.';
      } else if (route.contains('kata') || route.contains('Kata') || pageTitle.toLowerCase().contains('kata')) {
        return 'Je bent in de kata sectie. Hier kun je verschillende karate kata\'s bekijken en oefenen. Scroll door de lijst om verschillende technieken te vinden.';
      } else if (route.contains('forum') || route.contains('Forum') || pageTitle.toLowerCase().contains('forum')) {
        return 'Je bent in het forum. Hier kun je berichten lezen en nieuwe berichten plaatsen over karate. Gebruik de zoekfunctie om specifieke onderwerpen te vinden.';
      } else if (route.contains('favorites') || route.contains('Favorites') || pageTitle.toLowerCase().contains('favoriet')) {
        return 'Je bent in je favorieten. Hier vind je alle kata\'s en forumberichten die je hebt opgeslagen. Tik op een item om het te bekijken.';
      } else if (route.contains('profile') || route.contains('Profile') || pageTitle.toLowerCase().contains('profiel')) {
        return 'Je bent in je profiel. Hier kun je je persoonlijke informatie bekijken en bewerken, inclusief je avatar en instellingen.';
      } else if (route.contains('settings') || route.contains('Settings') || pageTitle.toLowerCase().contains('instelling')) {
        return 'Je bent in de instellingen. Hier kun je de app aanpassen naar je voorkeuren, inclusief toegankelijkheidsopties en thema instellingen.';
      } else if (route.contains('user-management') || pageTitle.toLowerCase().contains('gebruiker')) {
        return 'Je bent in het gebruikersbeheer. Hier kun je gebruikers beheren en instellingen aanpassen.';
      } else {
        // Try to provide more specific help based on what's visible
        return 'Je bent in de Karate app. Gebruik de navigatie knoppen onderaan het scherm om door de verschillende onderdelen te bewegen. Je kunt ook de spraakknop gebruiken om de inhoud van elke pagina te laten voorlezen.';
      }
    } catch (e) {
      debugPrint('TTS: Error generating contextual fallback: $e');
      return 'Je bent in de Karate app. Gebruik de navigatie om door de app te bewegen.';
    }
  }

  /// Generate helpful fallback content based on page type

  /// Get fallback content based on current route







  /// Extract content from form screens



  /// Extract ALL visible text content comprehensively from the current screen
  static List<String> _extractAllVisibleTextComprehensive(BuildContext context) {
    final List<String> allTextContent = [];
    
    try {
      debugPrint('TTS: Starting comprehensive visible text extraction...');
      
      if (!context.mounted) return allTextContent;
      
      // Use enhanced element tree traversal to get ALL text
      final elementTexts = <String>[];
      _extractTextFromElementTreeEnhanced(context, elementTexts);
      
      debugPrint('TTS: Enhanced traversal found ${elementTexts.length} text elements');
      print('🔍 TTS: Enhanced traversal found ${elementTexts.length} text elements');
      
      // Also try a more aggressive approach - extract from the entire widget tree
      if (elementTexts.isEmpty) {
        debugPrint('TTS: No text found with enhanced traversal, trying aggressive extraction');
        print('🔄 TTS: No text found with enhanced traversal, trying aggressive extraction');
        _extractTextAggressively(context, elementTexts);
        debugPrint('TTS: Aggressive extraction found ${elementTexts.length} text elements');
        print('🔍 TTS: Aggressive extraction found ${elementTexts.length} text elements');
      }
      
      // If still no text found, try alternative extraction methods
      if (elementTexts.isEmpty) {
        debugPrint('TTS: Still no text found, trying alternative extraction methods');
        print('🔄 TTS: Still no text found, trying alternative extraction methods');
        _extractTextWithAlternativeMethods(context, elementTexts);
        debugPrint('TTS: Alternative extraction found ${elementTexts.length} text elements');
        print('🔍 TTS: Alternative extraction found ${elementTexts.length} text elements');
      }
      
      // Try one more approach - look for specific widget types that commonly contain text
      if (elementTexts.isEmpty) {
        debugPrint('TTS: Trying widget-specific extraction');
        print('🔄 TTS: Trying widget-specific extraction');
        _extractTextFromSpecificWidgets(context, elementTexts);
        debugPrint('TTS: Widget-specific extraction found ${elementTexts.length} text elements');
        print('🔍 TTS: Widget-specific extraction found ${elementTexts.length} text elements');
      }
      
      // Debug: Show all extracted text before filtering
      debugPrint('TTS: All extracted text before filtering: $elementTexts');
      print('🔍 TTS: All extracted text before filtering: $elementTexts');
      
      // Process and filter the extracted text to get meaningful content
      final meaningfulTexts = elementTexts
          .where((text) => text.trim().isNotEmpty && 
                         text.trim() != 'Pagina geladen' &&
                         text.trim() != ' ' && // Filter out single spaces
                         text.trim().isNotEmpty && // Allow any non-empty text
                         !text.startsWith('Knop:') &&
                         !text.startsWith('Zwevende knop:') &&
                         !text.startsWith('Filter:') &&
                         !text.startsWith('Invoerveld:') &&
                         !text.startsWith('Pagina:') &&
                         !text.startsWith('Beschikbare knoppen') &&
                         !text.startsWith('Navigatie') &&
                         !text.toLowerCase().contains('scan hele pagina') &&
                         !text.toLowerCase().contains('voorlezen') &&
                         !text.toLowerCase().contains('spraak') &&
                         !text.toLowerCase().contains('welkom bij de karate app') &&
                         !text.toLowerCase().contains('loading') &&
                         !text.toLowerCase().contains('laden') &&
                         !text.toLowerCase().contains('error') &&
                         !text.toLowerCase().contains('fout') &&
                         // Filter out strange Unicode characters and control characters
                         !_isStrangeUnicodeCharacter(text.trim()) &&
                         // Filter out very short meaningless text
                         (text.trim().length > 1 || _isMeaningfulShortText(text.trim())))
          .map((text) => text.trim())
          .toSet() // Remove duplicates
          .toList();
      
      // Debug: Show filtered text
      debugPrint('TTS: Filtered meaningful text: $meaningfulTexts');
      print('✅ TTS: Filtered meaningful text: $meaningfulTexts');
      
      // Sort by length (longer text first) to prioritize meaningful content
      meaningfulTexts.sort((a, b) => b.length.compareTo(a.length));
      
      // Add all meaningful text to the result
      allTextContent.addAll(meaningfulTexts);
      
      debugPrint('TTS: Comprehensive extraction found ${allTextContent.length} text elements');
      print('📝 TTS: Comprehensive extraction found ${allTextContent.length} text elements');
      
      // Log first few items for debugging
      if (allTextContent.isNotEmpty) {
        final preview = allTextContent.take(5).join(', ');
        debugPrint('TTS: Content preview: $preview');
        print('📄 TTS: Content preview: $preview');
      }
      
    } catch (e) {
      debugPrint('TTS: Error in comprehensive text extraction: $e');
      print('❌ TTS: Error in comprehensive text extraction: $e');
    }
    
    return allTextContent;
  }

  /// Check if text is a strange Unicode character that should be filtered out
  static bool _isStrangeUnicodeCharacter(String text) {
    if (text.isEmpty) return true;
    
    // Check for common strange Unicode characters
    final strangeChars = [
      '\u{20000}', // 𠀿 - the character we're seeing in logs
      '\u{20001}', // 𠀁
      '\u{20002}', // 𠀂
      '\u{20003}', // 𠀃
      '\u{20004}', // 𠀄
      '\u{20005}', // 𠀅
      '\u{20006}', // 𠀆
      '\u{20007}', // 𠀇
      '\u{20008}', // 𠀈
      '\u{20009}', // 𠀉
      '\u{2000A}', // 𠀊
      '\u{2000B}', // 𠀋
      '\u{2000C}', // 𠀌
      '\u{2000D}', // 𠀍
      '\u{2000E}', // 𠀎
      '\u{2000F}', // 𠀏
      '\u{20010}', // 𠀐
      '\u{20011}', // 𠀑
      '\u{20012}', // 𠀒
      '\u{20013}', // 𠀓
      '\u{20014}', // 𠀔
      '\u{20015}', // 𠀕
      '\u{20016}', // 𠀖
      '\u{20017}', // 𠀗
      '\u{20018}', // 𠀘
      '\u{20019}', // 𠀙
      '\u{2001A}', // 𠀚
      '\u{2001B}', // 𠀛
      '\u{2001C}', // 𠀜
      '\u{2001D}', // 𠀝
      '\u{2001E}', // 𠀞
      '\u{2001F}', // 𠀟
      '\u{20020}', // 𠀠
      '\u{20021}', // 𠀡
      '\u{20022}', // 𠀢
      '\u{20023}', // 𠀣
      '\u{20024}', // 𠀤
      '\u{20025}', // 𠀥
      '\u{20026}', // 𠀦
      '\u{20027}', // 𠀧
      '\u{20028}', // 𠀨
      '\u{20029}', // 𠀩
      '\u{2002A}', // 𠀪
      '\u{2002B}', // 𠀫
      '\u{2002C}', // 𠀬
      '\u{2002D}', // 𠀭
      '\u{2002E}', // 𠀮
      '\u{2002F}', // 𠀯
      '\u{20030}', // 𠀰
      '\u{20031}', // 𠀱
      '\u{20032}', // 𠀲
      '\u{20033}', // 𠀳
      '\u{20034}', // 𠀴
      '\u{20035}', // 𠀵
      '\u{20036}', // 𠀶
      '\u{20037}', // 𠀷
      '\u{20038}', // 𠀸
      '\u{20039}', // 𠀹
      '\u{2003A}', // 𠀺
      '\u{2003B}', // 𠀻
      '\u{2003C}', // 𠀼
      '\u{2003D}', // 𠀽
      '\u{2003E}', // 𠀾
      '\u{2003F}', // 𠀿
      // Add more control characters and strange Unicode ranges
      '\u{0000}', // NULL
      '\u{0001}', // START OF HEADING
      '\u{0002}', // START OF TEXT
      '\u{0003}', // END OF TEXT
      '\u{0004}', // END OF TRANSMISSION
      '\u{0005}', // ENQUIRY
      '\u{0006}', // ACKNOWLEDGE
      '\u{0007}', // BELL
      '\u{0008}', // BACKSPACE
      '\u{000B}', // VERTICAL TAB
      '\u{000C}', // FORM FEED
      '\u{000E}', // SHIFT OUT
      '\u{000F}', // SHIFT IN
      '\u{0010}', // DATA LINK ESCAPE
      '\u{0011}', // DEVICE CONTROL ONE
      '\u{0012}', // DEVICE CONTROL TWO
      '\u{0013}', // DEVICE CONTROL THREE
      '\u{0014}', // DEVICE CONTROL FOUR
      '\u{0015}', // NEGATIVE ACKNOWLEDGE
      '\u{0016}', // SYNCHRONOUS IDLE
      '\u{0017}', // END OF TRANSMISSION BLOCK
      '\u{0018}', // CANCEL
      '\u{0019}', // END OF MEDIUM
      '\u{001A}', // SUBSTITUTE
      '\u{001B}', // ESCAPE
      '\u{001C}', // FILE SEPARATOR
      '\u{001D}', // GROUP SEPARATOR
      '\u{001E}', // RECORD SEPARATOR
      '\u{001F}', // UNIT SEPARATOR
      '\u{007F}', // DELETE
      '\u{0080}', // PADDING CHARACTER
      '\u{0081}', // HIGH OCTET PRESET
      '\u{0082}', // BREAK PERMITTED HERE
      '\u{0083}', // NO BREAK HERE
      '\u{0084}', // INDEX
      '\u{0085}', // NEXT LINE
      '\u{0086}', // START OF SELECTED AREA
      '\u{0087}', // END OF SELECTED AREA
      '\u{0088}', // CHARACTER TABULATION SET
      '\u{0089}', // CHARACTER TABULATION WITH JUSTIFICATION
      '\u{008A}', // LINE TABULATION SET
      '\u{008B}', // PARTIAL LINE FORWARD
      '\u{008C}', // PARTIAL LINE BACKWARD
      '\u{008D}', // REVERSE LINE FEED
      '\u{008E}', // SINGLE SHIFT TWO
      '\u{008F}', // SINGLE SHIFT THREE
      '\u{0090}', // DEVICE CONTROL STRING
      '\u{0091}', // PRIVATE USE ONE
      '\u{0092}', // PRIVATE USE TWO
      '\u{0093}', // SET TRANSMIT STATE
      '\u{0094}', // CANCEL CHARACTER
      '\u{0095}', // MESSAGE WAITING
      '\u{0096}', // START OF GUARDED AREA
      '\u{0097}', // END OF GUARDED AREA
      '\u{0098}', // START OF STRING
      '\u{0099}', // SINGLE GRAPHIC CHARACTER INTRODUCER
      '\u{009A}', // SINGLE CHARACTER INTRODUCER
      '\u{009B}', // CONTROL SEQUENCE INTRODUCER
      '\u{009C}', // STRING TERMINATOR
      '\u{009D}', // OPERATING SYSTEM COMMAND
      '\u{009E}', // PRIVACY MESSAGE
      '\u{009F}', // APPLICATION PROGRAM COMMAND
    ];
    
    // Check if text contains any strange characters
    for (final char in strangeChars) {
      if (text.contains(char)) {
        debugPrint('TTS: Filtering out strange Unicode character: $text (contains $char)');
        return true;
      }
    }
    
    // Check for other problematic patterns
    // Single character that's not a letter, number, or common punctuation
    if (text.length == 1) {
      final char = text.codeUnitAt(0);
      // Allow letters, numbers, and common punctuation
      if (!((char >= 65 && char <= 90) || // A-Z
            (char >= 97 && char <= 122) || // a-z
            (char >= 48 && char <= 57) || // 0-9
            (char >= 192 && char <= 255) || // Extended Latin
            char == 32 || // space
            char == 33 || // !
            char == 34 || // "
            char == 39 || // '
            char == 40 || // (
            char == 41 || // )
            char == 44 || // ,
            char == 45 || // -
            char == 46 || // .
            char == 58 || // :
            char == 59 || // ;
            char == 63 || // ?
            char == 95 || // _
            char == 228 || // ä
            char == 246 || // ö
            char == 252 || // ü
            char == 223 || // ß
            char == 196 || // Ä
            char == 214 || // Ö
            char == 220 || // Ü
            char == 233 || // é
            char == 232 || // è
            char == 234 || // ê
            char == 235 || // ë
            char == 201 || // É
            char == 200 || // È
            char == 202 || // Ê
            char == 203 || // Ë
            char == 225 || // á
            char == 224 || // à
            char == 226 || // â
            char == 227 || // ã
            char == 193 || // Á
            char == 192 || // À
            char == 194 || // Â
            char == 195 || // Ã
            char == 237 || // í
            char == 236 || // ì
            char == 238 || // î
            char == 239 || // ï
            char == 205 || // Í
            char == 204 || // Ì
            char == 206 || // Î
            char == 207 || // Ï
            char == 243 || // ó
            char == 242 || // ò
            char == 244 || // ô
            char == 245 || // õ
            char == 211 || // Ó
            char == 210 || // Ò
            char == 212 || // Ô
            char == 213 || // Õ
            char == 250 || // ú
            char == 249 || // ù
            char == 251 || // û
            char == 218 || // Ú
            char == 217 || // Ù
            char == 219 || // Û
            char == 241 || // ñ
            char == 209 || // Ñ
            char == 231 || // ç
            char == 199 || // Ç
            char == 255 || // ÿ
            char == 159 || // Ÿ
            char == 255 || // ÿ
            char == 159)) { // Ÿ
        debugPrint('TTS: Filtering out non-printable character: $text (code: $char)');
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if short text is meaningful (like single letters that are valid)
  static bool _isMeaningfulShortText(String text) {
    if (text.length != 1) return false;
    
    final char = text.codeUnitAt(0);
    // Allow single letters, numbers, and common punctuation
    return ((char >= 65 && char <= 90) || // A-Z
            (char >= 97 && char <= 122) || // a-z
            (char >= 48 && char <= 57) || // 0-9
            char == 33 || // !
            char == 44 || // ,
            char == 46 || // .
            char == 58 || // :
            char == 59 || // ;
            char == 63 || // ?
            char == 95); // _
  }

  /// Extract text from specific widget types that commonly contain text
  static void _extractTextFromSpecificWidgets(BuildContext context, List<String> textContent) {
    try {
      debugPrint('TTS: Starting widget-specific text extraction');
      
      // Look for specific widget types that commonly contain text
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for Text widgets
        if (widget is Text) {
          final text = widget.data ?? widget.textSpan?.toPlainText();
          if (text != null && text.trim().isNotEmpty && text.trim().length > 2) {
            final processedText = _processDutchText(text.trim());
            if (!_isStrangeUnicodeCharacter(processedText)) {
              textContent.add(processedText);
              debugPrint('TTS: Widget-specific found Text: $processedText');
            }
          }
        }
        
        // Check for RichText widgets
        else if (widget is RichText) {
          final text = widget.text.toPlainText();
          if (text.trim().isNotEmpty && text.trim().length > 2) {
            final processedText = _processDutchText(text.trim());
            if (!_isStrangeUnicodeCharacter(processedText)) {
              textContent.add(processedText);
              debugPrint('TTS: Widget-specific found RichText: $processedText');
            }
          }
        }
        
        // Check for TextField widgets
        else if (widget is TextField) {
          if (widget.decoration?.hintText != null && widget.decoration!.hintText!.trim().isNotEmpty) {
            final hintText = widget.decoration!.hintText!.trim();
            if (hintText.length > 2 && !_isStrangeUnicodeCharacter(hintText)) {
              textContent.add('Hint: $hintText');
              debugPrint('TTS: Widget-specific found TextField hint: $hintText');
            }
          }
          if (widget.controller?.text != null && widget.controller!.text.trim().isNotEmpty) {
            final fieldText = widget.controller!.text.trim();
            if (fieldText.length > 2 && !_isStrangeUnicodeCharacter(fieldText)) {
              textContent.add(fieldText);
              debugPrint('TTS: Widget-specific found TextField content: $fieldText');
            }
          }
        }
        
        // Check for TextFormField widgets (same as TextField but for forms)
        else if (widget is TextFormField) {
          // Note: TextFormField decoration is not directly accessible, so we skip hint text
          if (widget.controller?.text != null && widget.controller!.text.trim().isNotEmpty) {
            final fieldText = widget.controller!.text.trim();
            if (fieldText.length > 2 && !_isStrangeUnicodeCharacter(fieldText)) {
              textContent.add(fieldText);
              debugPrint('TTS: Widget-specific found TextFormField content: $fieldText');
            }
          }
        }
        
        // Check for Card widgets (common in kata cards)
        else if (widget is Card) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
        
        // Check for Container widgets that might contain text
        else if (widget is Container) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
        
        // Check for Column and Row widgets
        else if (widget is Column || widget is Row) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
        
        // Check for ListView and other scrollable widgets
        else if (widget is ListView || widget is SingleChildScrollView) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
        
        // Check for Material widgets
        else if (widget is Material) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
        
        // Check for InkWell and GestureDetector widgets
        else if (widget is InkWell || widget is GestureDetector) {
          _extractTextFromWidgetRecursively(widget, textContent);
        }
      });
      
      debugPrint('TTS: Widget-specific extraction completed, found ${textContent.length} items');
    } catch (e) {
      debugPrint('TTS: Error in widget-specific text extraction: $e');
    }
  }

  /// Extract content specifically from kata cards

  /// Extract content from profile screen

  /// Extract content from forum screen with enhanced post-specific content

  /// Extract content specifically from forum posts

  /// Extract content from forum detail screen

  /// Extract content from create post screen

  /// Extract content from favorites screen

  /// Extract content from user management screen

  /// Extract content from avatar selection screen

  /// Extract content from accessibility screen

  /// Generate cache key for content caching

  /// Clear all cached content (useful for memory management)
  static void clearCache() {
    TTSCacheManager.clearCache();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return TTSCacheManager.getCacheStats();
  }

}


/// Provider for the unified TTS service
final unifiedTTSServiceProvider = Provider<UnifiedTTSService>((ref) {
  return UnifiedTTSService();
});
