import 'package:flutter/material.dart';
import 'tts_screen_detector.dart';
import 'tts_text_field_reader.dart';

/// TTS Content Extractor - Handles content extraction for different screen types
class TTSContentExtractor {
  /// Extract screen content based on detected screen type
  static String extractScreenContentByType(BuildContext context, ScreenType screenType) {
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
      case ScreenType.editPost:
        return _extractEditPostScreenContent(context);
      case ScreenType.createKata:
        return _extractCreateKataScreenContent(context);
      case ScreenType.editKata:
        return _extractEditKataScreenContent(context);
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
      
      // 3. Extract all text content from the screen
      final allTextContent = _extractAllTextContent(context);
      if (allTextContent.isNotEmpty) {
        contentParts.add('Inhoud: $allTextContent');
        debugPrint('TTS: Found all text content: ${allTextContent.length} characters');
      }
      
      // 4. Extract form content if present (including text fields)
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
        debugPrint('TTS: Found form content: $formContent');
      }
      
      // 5. Extract main content using multiple strategies
      final mainContent = _extractMainContent(context);
      if (mainContent.isNotEmpty) {
        contentParts.add(mainContent);
        debugPrint('TTS: Found main content: ${mainContent.length} characters');
      }
      
      // 6. Extract interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
        debugPrint('TTS: Found interactive elements: $interactiveElements');
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

  /// Extract content from overlays, dialogs, and popups
  static String _extractOverlayContent(BuildContext context) {
    try {
      final List<String> overlayContent = [];
      
      // Check for dialogs
      final dialog = context.findAncestorWidgetOfExactType<Dialog>();
      if (dialog != null) {
        overlayContent.add('Dialog venster geopend');
      }
      
      // Check for bottom sheets
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        overlayContent.add('Bottom sheet geopend');
      }
      
      // Check for popup menus
      final popupMenu = context.findAncestorWidgetOfExactType<PopupMenuButton>();
      if (popupMenu != null) {
        overlayContent.add('Popup menu geopend');
      }
      
      return overlayContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
      return '';
    }
  }

  /// Extract page information including title and navigation
  static String _extractPageInformation(BuildContext context) {
    try {
      final List<String> pageInfo = [];
      
      // Get page title from AppBar
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.appBar is AppBar) {
        final appBar = scaffold!.appBar as AppBar;
        if (appBar.title is Text) {
          final title = (appBar.title as Text).data;
          if (title != null && title.isNotEmpty) {
            pageInfo.add('Pagina: $title');
          }
        }
      }
      
      // Get route information
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        final routeName = route!.settings.name!;
        final routeDescription = _getRouteDescription(routeName);
        if (routeDescription.isNotEmpty) {
          pageInfo.add(routeDescription);
        }
      }
      
      return pageInfo.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting page information: $e');
      return '';
    }
  }

  /// Extract main content from the screen
  static String _extractMainContent(BuildContext context) {
    try {
      final List<String> mainContent = [];
      
      // Extract text from Text widgets
      final textWidgets = _extractTextWidgets(context);
      if (textWidgets.isNotEmpty) {
        mainContent.addAll(textWidgets);
      }
      
      // Extract content from cards and containers
      final cardContent = _extractCardContent(context);
      if (cardContent.isNotEmpty) {
        mainContent.addAll(cardContent);
      }
      
      return mainContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting main content: $e');
      return '';
    }
  }

  /// Extract interactive elements like buttons and links
  static String _extractInteractiveElements(BuildContext context) {
    try {
      final List<String> interactiveElements = [];
      
      // Extract button text
      final buttons = _extractButtonText(context);
      if (buttons.isNotEmpty) {
        interactiveElements.add('Knoppen: ${buttons.join(', ')}');
      }
      
      // Extract link text
      final links = _extractLinkText(context);
      if (links.isNotEmpty) {
        interactiveElements.add('Links: ${links.join(', ')}');
      }
      
      return interactiveElements.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting interactive elements: $e');
      return '';
    }
  }

  /// Extract form content including text fields, labels, and values
  static String _extractFormContent(BuildContext context) {
    try {
      final List<String> formContent = [];
      
      // Use specialized text field reader for better text field extraction
      final textFieldContent = TTSTextFieldReader.readAllTextFields(context);
      if (textFieldContent.isNotEmpty && !textFieldContent.contains('Geen tekstvelden gevonden')) {
        formContent.add('Tekstvelden: $textFieldContent');
      }
      
      // Extract form labels
      final formLabels = _extractFormLabels(context);
      if (formLabels.isNotEmpty) {
        formContent.add('Formulier labels: ${formLabels.join(', ')}');
      }
      
      // Extract dropdown/select content
      final dropdowns = _extractDropdownContent(context);
      if (dropdowns.isNotEmpty) {
        formContent.add('Keuzemenu\'s: ${dropdowns.join(', ')}');
      }
      
      return formContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting form content: $e');
      return '';
    }
  }

  /// Extract text from Text widgets in the widget tree
  static List<String> _extractTextWidgets(BuildContext context) {
    final List<String> textWidgets = [];
    
    try {
      // This is a simplified approach - in a real implementation,
      // you would traverse the widget tree more comprehensively
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null && widget.data!.isNotEmpty) {
          // Skip very short text that might be UI elements
          if (widget.data!.length > 2) {
            textWidgets.add(widget.data!);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting text widgets: $e');
    }
    
    return textWidgets;
  }

  /// Extract all text content from the screen comprehensively
  static String _extractAllTextContent(BuildContext context) {
    final List<String> allTexts = [];
    
    try {
      debugPrint('TTS: Extracting all text content from screen...');
      
      // Extract from Text widgets
      final textWidgets = _extractTextWidgets(context);
      allTexts.addAll(textWidgets);
      
      // Extract from buttons
      final buttonTexts = _extractButtonText(context);
      allTexts.addAll(buttonTexts);
      
      // Extract from form labels and hints
      final formLabels = _extractFormLabels(context);
      allTexts.addAll(formLabels);
      
      // Remove duplicates and filter out empty or very short texts
      final uniqueTexts = allTexts
          .where((text) => text.trim().isNotEmpty && text.trim().length > 1)
          .toSet()
          .toList();
      
      debugPrint('TTS: Found ${uniqueTexts.length} unique text elements');
      
      return uniqueTexts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting all text content: $e');
      return '';
    }
  }

  /// Extract content from Card widgets
  static List<String> _extractCardContent(BuildContext context) {
    final List<String> cardContent = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Card) {
          // Extract text from card content
          final cardTexts = _extractTextFromWidget(widget);
          if (cardTexts.isNotEmpty) {
            cardContent.addAll(cardTexts);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting card content: $e');
    }
    
    return cardContent;
  }


  /// Extract form labels
  static List<String> _extractFormLabels(BuildContext context) {
    final List<String> formLabels = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          // Look for text that might be form labels
          final text = widget.data!;
          if (text.contains(':') || text.length < 50) {
            formLabels.add(text);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting form labels: $e');
    }
    
    return formLabels;
  }

  /// Extract button text
  static List<String> _extractButtonText(BuildContext context) {
    final List<String> buttonTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is ElevatedButton) {
          if (widget.child is Text) {
            final text = (widget.child as Text).data;
            if (text != null && text.isNotEmpty) {
              buttonTexts.add(text);
            }
          }
        } else if (widget is TextButton) {
          if (widget.child is Text) {
            final text = (widget.child as Text).data;
            if (text != null && text.isNotEmpty) {
              buttonTexts.add(text);
            }
          }
        } else if (widget is OutlinedButton) {
          if (widget.child is Text) {
            final text = (widget.child as Text).data;
            if (text != null && text.isNotEmpty) {
              buttonTexts.add(text);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting button text: $e');
    }
    
    return buttonTexts;
  }

  /// Extract link text
  static List<String> _extractLinkText(BuildContext context) {
    final List<String> linkTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is InkWell || widget is GestureDetector) {
          // Look for text children that might be links
          final childTexts = _extractTextFromWidget(widget);
          if (childTexts.isNotEmpty) {
            linkTexts.addAll(childTexts);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting link text: $e');
    }
    
    return linkTexts;
  }

  /// Extract dropdown content
  static List<String> _extractDropdownContent(BuildContext context) {
    final List<String> dropdownContent = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is DropdownButton) {
          // Extract dropdown label and selected value
          if (widget.hint is Text) {
            final hint = (widget.hint as Text).data;
            if (hint != null && hint.isNotEmpty) {
              dropdownContent.add('Dropdown: $hint');
            }
          }
        } else if (widget is DropdownButtonFormField) {
          // Extract dropdown label and selected value
          final decoration = widget.decoration;
          if (decoration.hintText?.isNotEmpty == true) {
            dropdownContent.add('Dropdown: ${decoration.hintText}');
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting dropdown content: $e');
    }
    
    return dropdownContent;
  }

  /// Helper method to extract text from a widget recursively
  static List<String> _extractTextFromWidget(Widget widget) {
    final List<String> texts = [];
    
    try {
      if (widget is Text && widget.data != null && widget.data!.isNotEmpty) {
        texts.add(widget.data!);
      } else if (widget is Container) {
        if (widget.child != null) {
          texts.addAll(_extractTextFromWidget(widget.child!));
        }
      } else if (widget is Column) {
        if (widget.children.isNotEmpty) {
          for (final child in widget.children) {
            texts.addAll(_extractTextFromWidget(child));
          }
        }
      } else if (widget is Row) {
        if (widget.children.isNotEmpty) {
          for (final child in widget.children) {
            texts.addAll(_extractTextFromWidget(child));
          }
        }
      } else if (widget is Padding) {
        if (widget.child != null) {
          texts.addAll(_extractTextFromWidget(widget.child!));
        }
      }
    } catch (e) {
      debugPrint('TTS: Error extracting text from widget: $e');
    }
    
    return texts;
  }

  /// Get route description for TTS
  static String _getRouteDescription(String routeName) {
    switch (routeName.toLowerCase()) {
      case '/':
      case '/home':
        return 'Hoofdpagina met alle kata technieken';
      case '/forum':
        return 'Forum pagina voor berichten en discussies';
      case '/favorites':
        return 'Favorieten pagina met opgeslagen kata\'s en berichten';
      case '/profile':
        return 'Profiel pagina voor gebruikersinstellingen';
      case '/user-management':
        return 'Gebruikersbeheer pagina';
      case '/accessibility-settings':
        return 'Toegankelijkheidsinstellingen';
      case '/create-kata':
      case '/kata/create':
        return 'Nieuwe kata aanmaken pagina';
      case '/edit-kata':
      case '/kata/edit':
        return 'Kata bewerken pagina';
      case '/create-post':
      case '/forum/create':
        return 'Nieuw forumbericht aanmaken pagina';
      case '/edit-post':
      case '/forum/edit':
        return 'Forumbericht bewerken pagina';
      case '/login':
      case '/auth':
        return 'Inlog en registratie pagina';
      default:
        return 'Karate app pagina';
    }
  }

  /// Get fallback content for current route
  static String _getFallbackContentForCurrentRoute(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      if (route?.settings.name != null) {
        final routeName = route!.settings.name!;
        return _getRouteDescription(routeName);
      }
    } catch (e) {
      debugPrint('TTS: Error getting fallback content: $e');
    }
    return 'Karate app pagina geladen';
  }

  // Screen-specific extraction methods
  static String _extractFormScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractAuthScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      debugPrint('TTS: Starting auth screen content extraction...');
      
      // Add app branding and title information
      contentParts.add('Karatapp - Inlog en Registratie pagina');
      contentParts.add('Welkom bij de Karate app');
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add tab information for auth screen
      contentParts.add('Deze pagina heeft twee tabbladen: Inloggen en Registreren');
      
      // Add specialized auth form content
      final authFields = TTSTextFieldReader.readAuthFormFields(context);
      if (authFields.isNotEmpty && !authFields.contains('Geen inlogvelden gevonden')) {
        contentParts.add('Inlogvelden: $authFields');
      }
      
      // Add all text content from the screen
      final allTextContent = _extractAllTextContent(context);
      if (allTextContent.isNotEmpty) {
        contentParts.add('Inhoud: $allTextContent');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      // Add navigation information
      contentParts.add('Gebruik de tabbladen bovenaan om tussen inloggen en registreren te wisselen');
      contentParts.add('Vul je gegevens in en klik op de knop om in te loggen of te registreren');
      
      final result = contentParts.join('. ');
      debugPrint('TTS: Auth screen content extracted: $result');
      return result;
    } catch (e) {
      debugPrint('TTS: Error extracting auth screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }
  
  static String _extractHomeScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractProfileScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add specialized profile name fields
      final nameFields = TTSTextFieldReader.readProfileNameFields(context);
      if (nameFields.isNotEmpty && !nameFields.contains('Geen naamvelden gevonden')) {
        contentParts.add('Naamvelden: $nameFields');
      }
      
      // Add other form content
      final formContent = _extractFormContent(context);
      if (formContent.isNotEmpty) {
        contentParts.add(formContent);
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      return contentParts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting profile screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }
  
  static String _extractForumScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractForumDetailScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractCreatePostScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add specialized content form fields
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Inhoudsvelden: $contentFields');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      return contentParts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting create post screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }

  static String _extractEditPostScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add specialized content form fields for editing
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Bewerk velden: $contentFields');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      return contentParts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting edit post screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }

  static String _extractCreateKataScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add specialized kata form fields
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Kata velden: $contentFields');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      return contentParts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting create kata screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }

  static String _extractEditKataScreenContent(BuildContext context) {
    try {
      final List<String> contentParts = [];
      
      // Add page information
      final pageInfo = _extractPageInformation(context);
      if (pageInfo.isNotEmpty) {
        contentParts.add(pageInfo);
      }
      
      // Add specialized kata form fields for editing
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Bewerk kata velden: $contentFields');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      return contentParts.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting edit kata screen content: $e');
      return _extractComprehensiveScreenContent(context);
    }
  }
  
  static String _extractFavoritesScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractUserManagementScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractAvatarSelectionScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
  
  static String _extractAccessibilityScreenContent(BuildContext context) {
    return _extractComprehensiveScreenContent(context);
  }
}
