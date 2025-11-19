import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../widgets/video_player_widget.dart';
import '../../widgets/universal_video_player.dart';
import 'tts_screen_detector.dart';
import 'tts_text_field_reader.dart';
import 'tts_dialog_overlay_extractor.dart';
import 'tts_form_interactive_extractor.dart';

/// TTS Content Extractor - Handles content extraction for different screen types
class TTSContentExtractor {
  // RegExp constants for content extraction
  static final RegExp _digitRegex = RegExp(r'\d+');
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
      final overlayContent = TTSDialogOverlayExtractor.extractOverlayContent(context);
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
      final formContent = TTSFormInteractiveExtractor.extractFormContent(context);
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
      final interactiveElements = TTSFormInteractiveExtractor.extractInteractiveElements(context);
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
        
        // Extract dialog content
        final dialogContent = _extractDialogContent(context);
        if (dialogContent.isNotEmpty) {
          overlayContent.add('Dialog inhoud: $dialogContent');
        }
      }
      
      // Check for bottom sheets
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        overlayContent.add('Bottom sheet geopend');
        
        // Extract bottom sheet content
        final bottomSheetContent = _extractBottomSheetContent(context);
        if (bottomSheetContent.isNotEmpty) {
          overlayContent.add('Bottom sheet inhoud: $bottomSheetContent');
        }
      }
      
      // Check for popup menus
      final popupMenu = context.findAncestorWidgetOfExactType<PopupMenuButton>();
      if (popupMenu != null) {
        overlayContent.add('Popup menu geopend');
      }
      
      // Extract all text content from overlay
      final overlayTextContent = _extractAllTextContent(context);
      if (overlayTextContent.isNotEmpty) {
        overlayContent.add('Overlay tekst: $overlayTextContent');
      }
      
      // Extract form content from overlay
      final overlayFormContent = _extractFormContent(context);
      if (overlayFormContent.isNotEmpty) {
        overlayContent.add('Overlay formulier: $overlayFormContent');
      }
      
      return overlayContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
      return '';
    }
  }

  /// Extract content specifically from dialog widgets
  static String _extractDialogContent(BuildContext context) {
    try {
      final List<String> dialogContent = [];
      
      // Look for dialog title
      final dialogTitle = _extractDialogTitle(context);
      if (dialogTitle.isNotEmpty) {
        dialogContent.add('Titel: $dialogTitle');
      }
      
      // Look for dialog text content
      final dialogText = _extractDialogText(context);
      if (dialogText.isNotEmpty) {
        dialogContent.add('Tekst: $dialogText');
      }
      
      // Look for dialog buttons
      final dialogButtons = _extractDialogButtons(context);
      if (dialogButtons.isNotEmpty) {
        dialogContent.add('Knoppen: ${dialogButtons.join(', ')}');
      }
      
      return dialogContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting dialog content: $e');
      return '';
    }
  }

  /// Extract dialog title
  static String _extractDialogTitle(BuildContext context) {
    try {
      String title = '';
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          // Look for title-like text (usually shorter and bold)
          if (widget.data!.length < 100 && 
              (widget.style?.fontWeight == FontWeight.bold ||
               widget.style?.fontSize != null && widget.style!.fontSize! > 16)) {
            title = widget.data!;
            return;
          }
        }
      });
      return title;
    } catch (e) {
      debugPrint('TTS: Error extracting dialog title: $e');
      return '';
    }
  }

  /// Extract dialog text content
  static String _extractDialogText(BuildContext context) {
    try {
      final List<String> textContent = [];
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          // Look for regular text content (not titles or buttons)
          if (widget.data!.length > 10 && 
              widget.style?.fontWeight != FontWeight.bold) {
            textContent.add(widget.data!);
          }
        }
      });
      return textContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting dialog text: $e');
      return '';
    }
  }

  /// Extract dialog buttons
  static List<String> _extractDialogButtons(BuildContext context) {
    final List<String> buttons = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is ElevatedButton) {
          final child = widget.child;
          if (child is Text) {
            buttons.add(child.data ?? 'Knop');
          }
        } else if (widget is TextButton) {
          final child = widget.child;
          if (child is Text) {
            buttons.add(child.data ?? 'Knop');
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting dialog buttons: $e');
    }
    
    return buttons;
  }

  /// Extract content from bottom sheet
  static String _extractBottomSheetContent(BuildContext context) {
    try {
      final List<String> bottomSheetContent = [];
      
      // Extract all text content from bottom sheet
      final textContent = _extractAllTextContent(context);
      if (textContent.isNotEmpty) {
        bottomSheetContent.add('Tekst: $textContent');
      }
      
      // Extract buttons from bottom sheet
      final buttons = _extractButtonText(context);
      if (buttons.isNotEmpty) {
        bottomSheetContent.add('Knoppen: ${buttons.join(', ')}');
      }
      
      return bottomSheetContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting bottom sheet content: $e');
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
      
      // Extract from cards and containers
      final cardTexts = _extractCardTexts(context);
      allTexts.addAll(cardTexts);
      
      // Extract from list tiles
      final listTileTexts = _extractListTileTexts(context);
      allTexts.addAll(listTileTexts);
      
      // Extract from switches and checkboxes
      final switchTexts = _extractSwitchTexts(context);
      allTexts.addAll(switchTexts);
      
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

  /// Extract text from cards and containers
  static List<String> _extractCardTexts(BuildContext context) {
    final List<String> cardTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Card) {
          // Extract text from card content
          final child = widget.child;
          final cardContent = _extractTextFromWidget(child ?? const SizedBox());
          cardTexts.addAll(cardContent);
        } else if (widget is Container) {
          // Extract text from container content
          final child = widget.child;
          final containerContent = _extractTextFromWidget(child ?? const SizedBox());
          cardTexts.addAll(containerContent);
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting card texts: $e');
    }
    
    return cardTexts;
  }

  /// Extract text from list tiles
  static List<String> _extractListTileTexts(BuildContext context) {
    final List<String> listTileTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is ListTile) {
          final title = widget.title;
          if (title is Text) {
            final titleText = title.data;
            if (titleText != null && titleText.isNotEmpty) {
              listTileTexts.add(titleText);
            }
          }
          final subtitle = widget.subtitle;
          if (subtitle is Text) {
            final subtitleText = subtitle.data;
            if (subtitleText != null && subtitleText.isNotEmpty) {
              listTileTexts.add(subtitleText);
            }
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting list tile texts: $e');
    }
    
    return listTileTexts;
  }

  /// Extract text from switches and checkboxes
  static List<String> _extractSwitchTexts(BuildContext context) {
    final List<String> switchTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is SwitchListTile) {
          if (widget.title is Text) {
            final title = (widget.title as Text).data;
            if (title != null && title.isNotEmpty) {
              switchTexts.add('$title: ${widget.value ? 'aan' : 'uit'}');
            }
          }
          if (widget.subtitle is Text) {
            final subtitle = (widget.subtitle as Text).data;
            if (subtitle != null && subtitle.isNotEmpty) {
              switchTexts.add(subtitle);
            }
          }
        } else if (widget is CheckboxListTile) {
          if (widget.title is Text) {
            final title = (widget.title as Text).data;
            if (title != null && title.isNotEmpty) {
              switchTexts.add('$title: ${widget.value == true ? 'aangevinkt' : 'niet aangevinkt'}');
            }
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting switch texts: $e');
    }
    
    return switchTexts;
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
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.isNotEmpty) {
              buttonTexts.add(text);
            }
          }
        } else if (widget is TextButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
            if (text != null && text.isNotEmpty) {
              buttonTexts.add(text);
            }
          }
        } else if (widget is OutlinedButton) {
          final child = widget.child;
          if (child is Text) {
            final text = child.data;
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
      
      // Add comprehensive form content including all text fields
      final allTextFields = TTSTextFieldReader.readAllTextFields(context);
      if (allTextFields.isNotEmpty && !allTextFields.contains('Geen tekstvelden gevonden')) {
        contentParts.add('Formulier velden: $allTextFields');
      }
      
      // Add specialized content form fields
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Inhoudsvelden: $contentFields');
      }
      
      // Add all visible text content
      final allTextContent = _extractAllTextContent(context);
      if (allTextContent.isNotEmpty) {
        contentParts.add('Inhoud: $allTextContent');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      // Add form sections and guidelines
      final formSections = _extractFormSections(context);
      if (formSections.isNotEmpty) {
        contentParts.add(formSections);
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
      
      // Add comprehensive form content including all text fields
      final allTextFields = TTSTextFieldReader.readAllTextFields(context);
      if (allTextFields.isNotEmpty && !allTextFields.contains('Geen tekstvelden gevonden')) {
        contentParts.add('Formulier velden: $allTextFields');
      }
      
      // Add specialized kata form fields
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Kata velden: $contentFields');
      }
      
      // Add media form fields
      final mediaFields = TTSTextFieldReader.readMediaFormFields(context);
      if (mediaFields.isNotEmpty && !mediaFields.contains('Geen media velden gevonden')) {
        contentParts.add('Media velden: $mediaFields');
      }
      
      // Add media content information
      final mediaContent = _extractMediaContent(context);
      if (mediaContent.isNotEmpty) {
        contentParts.add(mediaContent);
      }
      
      // Add all visible text content
      final allTextContent = _extractAllTextContent(context);
      if (allTextContent.isNotEmpty) {
        contentParts.add('Inhoud: $allTextContent');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      // Add form sections and tips
      final formSections = _extractFormSections(context);
      if (formSections.isNotEmpty) {
        contentParts.add(formSections);
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
      
      // Add comprehensive form content including all text fields
      final allTextFields = TTSTextFieldReader.readAllTextFields(context);
      if (allTextFields.isNotEmpty && !allTextFields.contains('Geen tekstvelden gevonden')) {
        contentParts.add('Bewerk formulier velden: $allTextFields');
      }
      
      // Add specialized kata form fields for editing
      final contentFields = TTSTextFieldReader.readContentFormFields(context);
      if (contentFields.isNotEmpty && !contentFields.contains('Geen inhoudsvelden gevonden')) {
        contentParts.add('Bewerk kata velden: $contentFields');
      }
      
      // Add media form fields for editing
      final mediaFields = TTSTextFieldReader.readMediaFormFields(context);
      if (mediaFields.isNotEmpty && !mediaFields.contains('Geen media velden gevonden')) {
        contentParts.add('Bewerk media velden: $mediaFields');
      }
      
      // Add media content information
      final mediaContent = _extractMediaContent(context);
      if (mediaContent.isNotEmpty) {
        contentParts.add(mediaContent);
      }
      
      // Add all visible text content
      final allTextContent = _extractAllTextContent(context);
      if (allTextContent.isNotEmpty) {
        contentParts.add('Inhoud: $allTextContent');
      }
      
      // Add interactive elements
      final interactiveElements = _extractInteractiveElements(context);
      if (interactiveElements.isNotEmpty) {
        contentParts.add(interactiveElements);
      }
      
      // Add form sections and tips
      final formSections = _extractFormSections(context);
      if (formSections.isNotEmpty) {
        contentParts.add(formSections);
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

  /// Extract media content information (photos, videos, etc.) with enhanced descriptions
  static String _extractMediaContent(BuildContext context) {
    try {
      final List<String> mediaContent = [];
      
      // Look for image-related text
      final imageTexts = _extractImageRelatedText(context);
      if (imageTexts.isNotEmpty) {
        mediaContent.add('Afbeeldingen: ${imageTexts.join(', ')}');
      }
      
      // Look for video-related text
      final videoTexts = _extractVideoRelatedText(context);
      if (videoTexts.isNotEmpty) {
        mediaContent.add('Video\'s: ${videoTexts.join(', ')}');
      }
      
      // Look for media buttons and controls
      final mediaButtons = _extractMediaButtons(context);
      if (mediaButtons.isNotEmpty) {
        mediaContent.add('Media knoppen: ${mediaButtons.join(', ')}');
      }
      
      // Extract actual media URLs and file information with enhanced descriptions
      final mediaUrls = _extractMediaUrlsWithDescriptions(context);
      if (mediaUrls.isNotEmpty) {
        mediaContent.add('Media bestanden: ${mediaUrls.join(', ')}');
      }
      
      // Extract detailed media metadata and accessibility information
      final mediaMetadata = _extractMediaMetadataWithAccessibility(context);
      if (mediaMetadata.isNotEmpty) {
        mediaContent.add(mediaMetadata);
      }
      
      // Extract image gallery information with detailed descriptions
      final imageGalleryInfo = _extractImageGalleryInfoWithDescriptions(context);
      if (imageGalleryInfo.isNotEmpty) {
        mediaContent.add(imageGalleryInfo);
      }
      
      // Extract video gallery information with detailed descriptions
      final videoGalleryInfo = _extractVideoGalleryInfoWithDescriptions(context);
      if (videoGalleryInfo.isNotEmpty) {
        mediaContent.add(videoGalleryInfo);
      }
      
      // Extract photo upload information
      final photoUploadInfo = _extractPhotoUploadInfo(context);
      if (photoUploadInfo.isNotEmpty) {
        mediaContent.add(photoUploadInfo);
      }
      
      // Extract video URL input information with enhanced descriptions
      final videoUrlInputInfo = _extractVideoUrlInputInfoWithDescriptions(context);
      if (videoUrlInputInfo.isNotEmpty) {
        mediaContent.add(videoUrlInputInfo);
      }
      
      // Extract media descriptions from kata content
      final kataMediaDescriptions = _extractKataMediaDescriptions(context);
      if (kataMediaDescriptions.isNotEmpty) {
        mediaContent.add(kataMediaDescriptions);
      }
      
      return mediaContent.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting media content: $e');
      return '';
    }
  }

  /// Extract image-related text from the screen
  static List<String> _extractImageRelatedText(BuildContext context) {
    final List<String> imageTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          final text = widget.data!.toLowerCase();
          if (text.contains('afbeelding') || 
              text.contains('foto') || 
              text.contains('image') || 
              text.contains('galerij') || 
              text.contains('camera') ||
              text.contains('photo')) {
            imageTexts.add(widget.data!);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting image text: $e');
    }
    
    return imageTexts;
  }

  /// Extract video-related text from the screen
  static List<String> _extractVideoRelatedText(BuildContext context) {
    final List<String> videoTexts = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          final text = widget.data!.toLowerCase();
          if (text.contains('video') || 
              text.contains('url') || 
              text.contains('youtube') || 
              text.contains('vimeo') ||
              text.contains('link')) {
            videoTexts.add(widget.data!);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting video text: $e');
    }
    
    return videoTexts;
  }

  /// Extract media-related buttons and controls
  static List<String> _extractMediaButtons(BuildContext context) {
    final List<String> mediaButtons = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is ElevatedButton || widget is TextButton || widget is IconButton) {
          // Check button text or icon
          if (widget is ElevatedButton) {
            final child = widget.child;
            if (child is Text) {
              final text = child.data?.toLowerCase() ?? '';
              if (text.contains('galerij') || text.contains('camera') || text.contains('video') || text.contains('url')) {
                mediaButtons.add(child.data!);
              }
            }
          } else if (widget is TextButton) {
            final child = widget.child;
            if (child is Text) {
              final text = child.data?.toLowerCase() ?? '';
              if (text.contains('galerij') || text.contains('camera') || text.contains('video') || text.contains('url')) {
                mediaButtons.add(child.data!);
              }
            }
          } else if (widget is IconButton) {
            // Check icon type
            if (widget.icon is Icon) {
              final icon = widget.icon as Icon;
              if (icon.icon == Icons.photo_library || 
                  icon.icon == Icons.camera_alt || 
                  icon.icon == Icons.video_library ||
                  icon.icon == Icons.link) {
                mediaButtons.add('Media knop');
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting media buttons: $e');
    }
    
    return mediaButtons;
  }

  /// Extract form sections and helpful information
  static String _extractFormSections(BuildContext context) {
    try {
      final List<String> sections = [];
      
      // Look for section headers and tips
      final sectionTexts = _extractSectionHeaders(context);
      if (sectionTexts.isNotEmpty) {
        sections.add('Secties: ${sectionTexts.join(', ')}');
      }
      
      // Look for tips and guidelines
      final tipTexts = _extractTipsAndGuidelines(context);
      if (tipTexts.isNotEmpty) {
        sections.add('Tips: ${tipTexts.join(', ')}');
      }
      
      return sections.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting form sections: $e');
      return '';
    }
  }

  /// Extract section headers from the screen
  static List<String> _extractSectionHeaders(BuildContext context) {
    final List<String> headers = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          // Look for section headers (usually shorter text that might be titles)
          if (text.length < 50 && 
              (text.contains('Informatie') || 
               text.contains('Toevoegen') || 
               text.contains('Tips') ||
               text.contains('Richtlijnen') ||
               text.contains('Sectie'))) {
            headers.add(text);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting section headers: $e');
    }
    
    return headers;
  }

  /// Extract tips and guidelines from the screen
  static List<String> _extractTipsAndGuidelines(BuildContext context) {
    final List<String> tips = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          // Look for tip-like text (usually longer text with helpful information)
          if (text.length > 20 && 
              (text.contains('tip') || 
               text.contains('richtlijn') || 
               text.contains('instructie') ||
               text.contains('help') ||
               text.contains('•'))) {
            tips.add(text);
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting tips: $e');
    }
    
    return tips;
  }

  /// Extract media URLs from text fields and widgets



  /// Extract photo upload information
  static String _extractPhotoUploadInfo(BuildContext context) {
    try {
      final List<String> uploadInfo = [];
      
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for photo upload buttons
        if (widget is ElevatedButton) {
          final button = widget;
          final child = button.child;
          if (child is Text) {
            final text = child.data?.toLowerCase() ?? '';
            if (text.contains('galerij') || text.contains('camera') || text.contains('foto')) {
              uploadInfo.add('Foto upload: ${child.data}');
            }
          } else if (child is Row) {
            // Check for icon + text buttons
            final row = child;
            for (final child in row.children) {
              if (child is Icon) {
                if (child.icon == Icons.photo_library || 
                    child.icon == Icons.camera_alt ||
                    child.icon == Icons.add_a_photo) {
                  uploadInfo.add('Foto upload knop');
                  break;
                }
              }
            }
          }
        } else if (widget is TextButton) {
          final button = widget;
          final child = button.child;
          if (child is Text) {
            final text = child.data?.toLowerCase() ?? '';
            if (text.contains('galerij') || text.contains('camera') || text.contains('foto')) {
              uploadInfo.add('Foto upload: ${child.data}');
            }
          }
        }
        
        // Check for image selection information
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          if (text.contains('afbeelding') && 
              (text.contains('selecteer') || text.contains('toevoeg') || text.contains('upload'))) {
            uploadInfo.add('Foto instructies: $text');
          }
        }
      });
      
      return uploadInfo.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting photo upload info: $e');
      return '';
    }
  }


  /// Check if a string is a valid URL
  static bool _isValidUrl(String url) {
    if (url.trim().isEmpty) return false;
    
    try {
      final uri = Uri.parse(url.trim());
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Check if a URL is a media URL
  static bool _isMediaUrl(String url) {
    final lowerUrl = url.toLowerCase();
    
    // Video platforms
    if (lowerUrl.contains('youtube.com') || 
        lowerUrl.contains('youtu.be') ||
        lowerUrl.contains('vimeo.com') ||
        lowerUrl.contains('dailymotion.com') ||
        lowerUrl.contains('twitch.tv')) {
      return true;
    }
    
    // Direct video file extensions
    final videoExtensions = ['.mp4', '.avi', '.mov', '.wmv', '.flv', '.webm', '.mkv', '.m4v'];
    if (videoExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Audio file extensions
    final audioExtensions = ['.mp3', '.wav', '.aac', '.ogg', '.flac', '.m4a'];
    if (audioExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    // Image file extensions
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.svg'];
    if (imageExtensions.any((ext) => lowerUrl.endsWith(ext))) {
      return true;
    }
    
    return false;
  }

  /// Get a readable display name for a URL

  /// Extract media URLs with enhanced descriptions
  static List<String> _extractMediaUrlsWithDescriptions(BuildContext context) {
    final List<String> mediaUrls = [];
    
    try {
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for TextEditingController with URL content
        if (widget.runtimeType.toString().contains('TextField') || 
            widget.runtimeType.toString().contains('TextFormField')) {
          try {
            // Try to access controller property safely using reflection
            final dynamic widgetDynamic = widget;
            if (widgetDynamic.hasProperty('controller')) {
              final controller = widgetDynamic.controller;
              if (controller != null && controller.hasProperty('text')) {
                final text = controller.text;
                if (text is String && text.isNotEmpty) {
                  final trimmedText = text.trim();
                  if (_isValidUrl(trimmedText) && _isMediaUrl(trimmedText)) {
                    mediaUrls.add(_getEnhancedUrlDescription(trimmedText));
                  }
                }
              }
            }
          } catch (e) {
            // Ignore errors accessing controller
            debugPrint('TTS: Error accessing TextField controller: $e');
          }
        }
        
        // Check for VideoUrlInputWidget
        if (widget.runtimeType.toString().contains('VideoUrlInputWidget')) {
          try {
            // Try to access videoUrls property safely using reflection
            final dynamic widgetDynamic = widget;
            if (widgetDynamic.hasProperty('videoUrls')) {
              final videoUrls = widgetDynamic.videoUrls;
              if (videoUrls != null && videoUrls is List && videoUrls.isNotEmpty) {
                for (final url in videoUrls) {
                  if (url is String && _isValidUrl(url)) {
                    mediaUrls.add(_getEnhancedUrlDescription(url));
                  }
                }
              }
            }
          } catch (e) {
            // Ignore errors accessing videoUrls
            debugPrint('TTS: Error accessing VideoUrlInputWidget videoUrls: $e');
          }
        }
        
        // Check for text content that might be URLs
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          if (_isValidUrl(text) && _isMediaUrl(text)) {
            mediaUrls.add(_getEnhancedUrlDescription(text));
          }
        }
      });
    } catch (e) {
      debugPrint('TTS: Error extracting media URLs with descriptions: $e');
    }
    
    return mediaUrls;
  }

  /// Get enhanced description for media URLs
  static String _getEnhancedUrlDescription(String url) {
    try {
      final uri = Uri.parse(url);
      
      // YouTube with enhanced description
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        final videoId = _extractYouTubeVideoId(url);
        if (videoId != null) {
          return 'YouTube video (ID: $videoId) - Karate demonstratie video';
        }
        return 'YouTube video - Karate demonstratie video';
      }
      
      // Vimeo with enhanced description
      if (uri.host.contains('vimeo.com')) {
        final videoId = _extractVimeoVideoId(url);
        if (videoId != null) {
          return 'Vimeo video (ID: $videoId) - Karate instructie video';
        }
        return 'Vimeo video - Karate instructie video';
      }
      
      // Dailymotion with enhanced description
      if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion video - Karate training video';
      }
      
      // Twitch with enhanced description
      if (uri.host.contains('twitch.tv')) {
        return 'Twitch video - Live karate stream';
      }
      
      // Direct file with enhanced description
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp4')) return 'MP4 video bestand - Karate demonstratie';
      if (path.endsWith('.avi')) return 'AVI video bestand - Karate techniek';
      if (path.endsWith('.mov')) return 'MOV video bestand - Karate beweging';
      if (path.endsWith('.wmv')) return 'WMV video bestand - Karate training';
      if (path.endsWith('.flv')) return 'FLV video bestand - Karate video';
      if (path.endsWith('.webm')) return 'WebM video bestand - Karate demonstratie';
      if (path.endsWith('.mkv')) return 'MKV video bestand - Karate instructie';
      if (path.endsWith('.m4v')) return 'M4V video bestand - Karate techniek';
      
      if (path.endsWith('.mp3')) return 'MP3 audio bestand - Karate uitleg';
      if (path.endsWith('.wav')) return 'WAV audio bestand - Karate instructie';
      if (path.endsWith('.aac')) return 'AAC audio bestand - Karate uitleg';
      if (path.endsWith('.ogg')) return 'OGG audio bestand - Karate instructie';
      if (path.endsWith('.flac')) return 'FLAC audio bestand - Karate uitleg';
      if (path.endsWith('.m4a')) return 'M4A audio bestand - Karate instructie';
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'JPEG afbeelding - Karate foto';
      if (path.endsWith('.png')) return 'PNG afbeelding - Karate illustratie';
      if (path.endsWith('.gif')) return 'GIF afbeelding - Karate animatie';
      if (path.endsWith('.bmp')) return 'BMP afbeelding - Karate foto';
      if (path.endsWith('.webp')) return 'WebP afbeelding - Karate illustratie';
      if (path.endsWith('.svg')) return 'SVG afbeelding - Karate diagram';
      
      // Generic with enhanced description
      return 'Media bestand van ${uri.host.isNotEmpty ? uri.host : 'onbekende bron'} - Karate content';
    } catch (e) {
      return 'Media bestand - Karate content';
    }
  }

  /// Extract YouTube video ID from URL
  static String? _extractYouTubeVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      } else if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Extract Vimeo video ID from URL
  static String? _extractVimeoVideoId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('vimeo.com')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Extract image gallery information with detailed descriptions
  static String _extractImageGalleryInfoWithDescriptions(BuildContext context) {
    try {
      final List<String> galleryInfo = [];
      
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for ImageGallery widget
        if (widget.runtimeType.toString().contains('ImageGallery')) {
          try {
            // Try to access imageUrls property safely using reflection
            final dynamic widgetDynamic = widget;
            if (widgetDynamic.hasProperty('imageUrls')) {
              final imageUrls = widgetDynamic.imageUrls;
              if (imageUrls != null && imageUrls is List && imageUrls.isNotEmpty) {
                galleryInfo.add('Afbeeldingen galerij met ${imageUrls.length} foto\'s van karate technieken en demonstraties');
                
                // Add descriptions for first few images
                for (int i = 0; i < imageUrls.length && i < 3; i++) {
                  final url = imageUrls[i];
                  final description = _getImageDescription(url, i + 1);
                  galleryInfo.add('Foto ${i + 1}: $description');
                }
                
                if (imageUrls.length > 3) {
                  galleryInfo.add('En ${imageUrls.length - 3} meer karate foto\'s');
                }
              }
            }
          } catch (e) {
            // Ignore errors accessing imageUrls
            debugPrint('TTS: Error accessing imageUrls: $e');
          }
        }
        
        // Check for image count displays
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          if (text.contains('afbeelding') && text.contains(_digitRegex)) {
            galleryInfo.add('Afbeeldingen: $text');
          }
        }
      });
      
      return galleryInfo.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting image gallery info with descriptions: $e');
      return '';
    }
  }

  /// Extract video gallery information with detailed descriptions
  static String _extractVideoGalleryInfoWithDescriptions(BuildContext context) {
    try {
      final List<String> galleryInfo = [];
      
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for VideoGallery widget
        if (widget.runtimeType.toString().contains('VideoGallery')) {
          try {
            // Try to access videoUrls property safely using reflection
            final dynamic widgetDynamic = widget;
            if (widgetDynamic.hasProperty('videoUrls')) {
              final videoUrls = widgetDynamic.videoUrls;
              if (videoUrls != null && videoUrls is List && videoUrls.isNotEmpty) {
                galleryInfo.add('Video galerij met ${videoUrls.length} video\'s van karate technieken en demonstraties');
                
                // Add descriptions for first few videos
                for (int i = 0; i < videoUrls.length && i < 3; i++) {
                  final url = videoUrls[i];
                  final description = _getEnhancedUrlDescription(url);
                  galleryInfo.add('Video ${i + 1}: $description');
                }
                
                if (videoUrls.length > 3) {
                  galleryInfo.add('En ${videoUrls.length - 3} meer karate video\'s');
                }
              }
            }
          } catch (e) {
            // Ignore errors accessing videoUrls
            debugPrint('TTS: Error accessing videoUrls: $e');
          }
        }
        
        // Check for video count displays
        if (widget is Text && widget.data != null) {
          final text = widget.data!;
          if (text.contains('video') && text.contains(_digitRegex)) {
            galleryInfo.add('Video\'s: $text');
          }
        }
      });
      
      return galleryInfo.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting video gallery info with descriptions: $e');
      return '';
    }
  }

  /// Get description for image based on URL and position
  static String _getImageDescription(String url, int position) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      
      // Try to determine image type and content
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'JPEG foto van karate techniek';
      } else if (path.endsWith('.png')) {
        return 'PNG afbeelding van karate beweging';
      } else if (path.endsWith('.gif')) {
        return 'GIF animatie van karate techniek';
      } else if (path.endsWith('.webp')) {
        return 'WebP afbeelding van karate demonstratie';
      } else {
        return 'Afbeelding van karate techniek';
      }
    } catch (e) {
      return 'Afbeelding van karate techniek';
    }
  }

  /// Extract video URL input information with enhanced descriptions
  static String _extractVideoUrlInputInfoWithDescriptions(BuildContext context) {
    try {
      final List<String> inputInfo = [];
      
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for VideoUrlInputWidget
        if (widget.runtimeType.toString().contains('VideoUrlInputWidget')) {
          try {
            // Try to access widget properties safely using reflection
            final dynamic widgetDynamic = widget;
            String? title;
            List<String>? videoUrls;
            
            if (widgetDynamic.hasProperty('title')) {
              title = widgetDynamic.title;
            }
            if (widgetDynamic.hasProperty('videoUrls')) {
              final urls = widgetDynamic.videoUrls;
              if (urls is List) {
                videoUrls = urls.cast<String>();
              }
            }
            
            if (title != null && title.isNotEmpty) {
              inputInfo.add('Video URL sectie: $title');
            }
            
            if (videoUrls != null && videoUrls.isNotEmpty) {
              inputInfo.add('Toegevoegde video URLs: ${videoUrls.length} karate demonstratie video\'s');
              for (int i = 0; i < videoUrls.length && i < 3; i++) {
                final description = _getEnhancedUrlDescription(videoUrls[i]);
                inputInfo.add('Video ${i + 1}: $description');
              }
              if (videoUrls.length > 3) {
                inputInfo.add('En ${videoUrls.length - 3} meer karate video\'s');
              }
            } else {
              inputInfo.add('Geen video URLs toegevoegd voor karate demonstraties');
            }
          } catch (e) {
            // Ignore errors accessing widget properties
            debugPrint('TTS: Error accessing VideoUrlInputWidget properties: $e');
          }
        }
        
        // Check for video URL input fields
        if (widget is TextField) {
          try {
            final textField = widget;
            final decoration = textField.decoration;
            if (decoration != null) {
              final labelText = decoration.labelText;
              final hintText = decoration.hintText;
              
              if (labelText != null && 
                  (labelText.toLowerCase().contains('video') || 
                   labelText.toLowerCase().contains('url'))) {
                inputInfo.add('Video URL invoerveld: $labelText');
              } else if (hintText != null && 
                         (hintText.toLowerCase().contains('video') || 
                          hintText.toLowerCase().contains('url'))) {
                inputInfo.add('Video URL hint: $hintText');
              }
            }
          } catch (e) {
            // Ignore errors accessing decoration
          }
        } else if (widget is TextFormField) {
          // TextFormField doesn't expose decoration directly, skip for now
          // Could be enhanced in the future with more sophisticated reflection
        }
      });
      
      return inputInfo.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting video URL input info with descriptions: $e');
      return '';
    }
  }

  /// Extract media descriptions from kata content
  static String _extractKataMediaDescriptions(BuildContext context) {
    try {
      final List<String> descriptions = [];
      
      // Look for kata-related media content
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for kata cards or kata-related widgets
        if (widget.runtimeType.toString().contains('Kata') || 
            widget.runtimeType.toString().contains('CollapsibleKataCard')) {
          try {
            // Try to access kata properties
            final kataCard = widget as dynamic;
            final kata = kataCard.kata;
            if (kata != null) {
              // Extract detailed image information with context
              if (kata.imageUrls != null && kata.imageUrls!.isNotEmpty) {
                final imageCount = kata.imageUrls!.length;
                final imageDescriptions = _generateDetailedImageDescriptions(kata.imageUrls!, kata.name);
                descriptions.add('Kata "${kata.name}" heeft $imageCount afbeeldingen van karate technieken: $imageDescriptions');
              }
              
              // Extract detailed video information with context
              if (kata.videoUrls != null && kata.videoUrls!.isNotEmpty) {
                final videoCount = kata.videoUrls!.length;
                final videoDescriptions = _generateDetailedVideoDescriptions(kata.videoUrls!, kata.name);
                descriptions.add('Kata "${kata.name}" heeft $videoCount video\'s van karate demonstraties: $videoDescriptions');
              }
              
              // Add media accessibility information
              if ((kata.imageUrls?.isNotEmpty == true) || (kata.videoUrls?.isNotEmpty == true)) {
                descriptions.add('Media content voor kata "${kata.name}" is beschikbaar voor toegankelijkheidsondersteuning');
              }
            }
          } catch (e) {
            // Ignore errors accessing kata properties
          }
        }
        
        // Check for media sections in kata cards
        if (widget.runtimeType.toString().contains('Media') || 
            widget.runtimeType.toString().contains('Gallery')) {
          try {
            // Look for media-related text
            final mediaTexts = _extractTextFromWidget(widget);
            if (mediaTexts.isNotEmpty) {
              descriptions.add('Media sectie: ${mediaTexts.join(', ')}');
            }
          } catch (e) {
            // Ignore errors extracting text
          }
        }
      });
      
      return descriptions.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting kata media descriptions: $e');
      return '';
    }
  }

  /// Extract detailed media metadata and accessibility information
  static String _extractMediaMetadataWithAccessibility(BuildContext context) {
    try {
      final List<String> metadata = [];
      
      context.visitChildElements((element) {
        final widget = element.widget;
        
        // Check for CachedNetworkImage widgets
        if (widget is CachedNetworkImage) {
          try {
            final cachedImage = widget;
            final imageUrl = cachedImage.imageUrl;
            if (imageUrl.isNotEmpty) {
              final imageInfo = _getDetailedImageMetadata(imageUrl);
              metadata.add('Afbeelding metadata: $imageInfo');
            }
          } catch (e) {
            // Ignore errors accessing imageUrl
          }
        }
        
        // Check for video player widgets
        if (widget is VideoPlayerWidget) {
          try {
            final videoPlayer = widget;
            final videoUrl = videoPlayer.videoUrl;
            if (videoUrl.isNotEmpty) {
              final videoInfo = _getDetailedVideoMetadata(videoUrl);
              metadata.add('Video metadata: $videoInfo');
            }
          } catch (e) {
            // Ignore errors accessing videoUrl
          }
        } else if (widget is UniversalVideoPlayer) {
          try {
            final universalPlayer = widget;
            final videoUrl = universalPlayer.videoUrl;
            if (videoUrl.isNotEmpty) {
              final videoInfo = _getDetailedVideoMetadata(videoUrl);
              metadata.add('Video metadata: $videoInfo');
            }
          } catch (e) {
            // Ignore errors accessing videoUrl
          }
        }
        
        // Check for media loading states
        if (widget.runtimeType.toString().contains('CircularProgressIndicator')) {
          metadata.add('Media wordt geladen - wacht even');
        }
        
        // Check for media error states
        if (widget is Icon) {
          final icon = widget;
          if (icon.icon == Icons.broken_image) {
            metadata.add('Media kon niet worden geladen - controleer internetverbinding');
          }
        }
      });
      
      return metadata.join('. ');
    } catch (e) {
      debugPrint('TTS: Error extracting media metadata: $e');
      return '';
    }
  }

  /// Generate detailed descriptions for image URLs
  static String _generateDetailedImageDescriptions(List<String> imageUrls, String kataName) {
    try {
      final List<String> descriptions = [];
      
      for (int i = 0; i < imageUrls.length && i < 5; i++) {
        final url = imageUrls[i];
        final imageType = _getImageTypeFromUrl(url);
        final position = i + 1;
        
        descriptions.add('Afbeelding $position: $imageType voor kata "$kataName"');
      }
      
      if (imageUrls.length > 5) {
        descriptions.add('En ${imageUrls.length - 5} meer afbeeldingen');
      }
      
      return descriptions.join(', ');
    } catch (e) {
      return 'Afbeeldingen van karate technieken';
    }
  }

  /// Generate detailed descriptions for video URLs
  static String _generateDetailedVideoDescriptions(List<String> videoUrls, String kataName) {
    try {
      final List<String> descriptions = [];
      
      for (int i = 0; i < videoUrls.length && i < 3; i++) {
        final url = videoUrls[i];
        final videoDescription = _getEnhancedUrlDescription(url);
        final position = i + 1;
        
        descriptions.add('Video $position: $videoDescription voor kata "$kataName"');
      }
      
      if (videoUrls.length > 3) {
        descriptions.add('En ${videoUrls.length - 3} meer video\'s');
      }
      
      return descriptions.join(', ');
    } catch (e) {
      return 'Video\'s van karate demonstraties';
    }
  }

  /// Get detailed image metadata from URL
  static String _getDetailedImageMetadata(String imageUrl) {
    try {
      final uri = Uri.parse(imageUrl);
      final path = uri.path.toLowerCase();
      
      // Determine image format and quality
      String format = 'Onbekend formaat';
      String quality = 'Standaard kwaliteit';
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        format = 'JPEG afbeelding';
        quality = 'Hoge kwaliteit foto';
      } else if (path.endsWith('.png')) {
        format = 'PNG afbeelding';
        quality = 'Transparante achtergrond ondersteuning';
      } else if (path.endsWith('.gif')) {
        format = 'GIF afbeelding';
        quality = 'Animaties ondersteuning';
      } else if (path.endsWith('.webp')) {
        format = 'WebP afbeelding';
        quality = 'Geoptimaliseerd voor web';
      } else if (path.endsWith('.svg')) {
        format = 'SVG vector afbeelding';
        quality = 'Schaalbaar zonder kwaliteitsverlies';
      }
      
      // Add accessibility information
      return '$format - $quality - Geschikt voor schermlezers en toegankelijkheidsondersteuning';
    } catch (e) {
      return 'Afbeelding metadata niet beschikbaar';
    }
  }

  /// Get detailed video metadata from URL
  static String _getDetailedVideoMetadata(String videoUrl) {
    try {
      final uri = Uri.parse(videoUrl);
      
      // Check for streaming platforms
      if (uri.host.contains('youtube.com') || uri.host.contains('youtu.be')) {
        final videoId = _extractYouTubeVideoId(videoUrl);
        return 'YouTube video (ID: ${videoId ?? 'onbekend'}) - Streaming kwaliteit, ondertitels mogelijk beschikbaar';
      } else if (uri.host.contains('vimeo.com')) {
        final videoId = _extractVimeoVideoId(videoUrl);
        return 'Vimeo video (ID: ${videoId ?? 'onbekend'}) - Hoge kwaliteit streaming';
      } else if (uri.host.contains('dailymotion.com')) {
        return 'Dailymotion video - Streaming platform';
      } else if (uri.host.contains('twitch.tv')) {
        return 'Twitch video - Live streaming platform';
      }
      
      // Check for direct video files
      final path = uri.path.toLowerCase();
      if (path.endsWith('.mp4')) {
        return 'MP4 video bestand - Hoge compatibiliteit, geschikt voor alle apparaten';
      } else if (path.endsWith('.webm')) {
        return 'WebM video bestand - Geoptimaliseerd voor web, open source formaat';
      } else if (path.endsWith('.avi')) {
        return 'AVI video bestand - Klassiek video formaat';
      } else if (path.endsWith('.mov')) {
        return 'MOV video bestand - Apple QuickTime formaat';
      }
      
      return 'Video bestand - Media content voor karate demonstraties';
    } catch (e) {
      return 'Video metadata niet beschikbaar';
    }
  }

  /// Get image type from URL
  static String _getImageTypeFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path.toLowerCase();
      
      if (path.endsWith('.jpg') || path.endsWith('.jpeg')) {
        return 'JPEG foto van karate techniek';
      } else if (path.endsWith('.png')) {
        return 'PNG afbeelding van karate beweging';
      } else if (path.endsWith('.gif')) {
        return 'GIF animatie van karate techniek';
      } else if (path.endsWith('.webp')) {
        return 'WebP afbeelding van karate demonstratie';
      } else if (path.endsWith('.svg')) {
        return 'SVG diagram van karate techniek';
      } else {
        return 'Afbeelding van karate techniek';
      }
    } catch (e) {
      return 'Afbeelding van karate techniek';
    }
  }
}
