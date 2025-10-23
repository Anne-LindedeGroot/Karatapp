import 'package:flutter/material.dart';

/// TTS Content Extractor Base - Handles various content extraction methods
class TTSContentExtractorBase {
  /// Extract content from overlays, dialogs, and popups
  static String extractOverlayContent(BuildContext context) {
    final List<String> overlayParts = [];
    
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractOverlayContent');
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
      
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
    }
    
    return '';
  }

  /// Extract page information (title, navigation, etc.)
  static String extractPageInformation(BuildContext context) {
    final List<String> pageParts = [];
    
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractPageInformation');
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
  static String extractMainContent(BuildContext context) {
    final List<String> mainContent = [];
    
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractMainContent');
        return '';
      }
      
      // Try to extract from Scaffold body
      final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
      if (scaffold?.body != null) {
        final bodyContent = _extractTextFromWidgetHelper(scaffold!.body!);
        if (bodyContent.isNotEmpty) {
          mainContent.add(bodyContent);
        }
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting main content: $e');
    }
    
    return mainContent.join('. ');
  }

  /// Extract interactive elements (buttons, links, etc.)
  static String extractInteractiveElements(BuildContext context) {
    final List<String> interactiveElements = [];
    
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractInteractiveElements');
        return '';
      }
      
      // This is a simplified version - the full implementation would traverse the widget tree
      // to find buttons, links, and other interactive elements
      
    } catch (e) {
      debugPrint('TTS: Error extracting interactive elements: $e');
    }
    
    return interactiveElements.join('. ');
  }

  /// Extract form content (input fields, labels, etc.)
  static String extractFormContent(BuildContext context) {
    final List<String> formContent = [];
    
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractFormContent');
        return '';
      }
      
      // This is a simplified version - the full implementation would traverse the widget tree
      // to find form elements
      
    } catch (e) {
      debugPrint('TTS: Error extracting form content: $e');
    }
    
    return formContent.join('. ');
  }

  /// Extract text from a widget (helper method)
  static String _extractTextFromWidgetHelper(Widget widget) {
    // Simplified implementation - would need full widget tree traversal
    return '';
  }

  /// Get basic page information
  static String _getPageInfo(BuildContext context) {
    try {
      final route = ModalRoute.of(context);
      if (route != null) {
        final routeName = route.settings.name ?? 'Unknown';
        return _getRouteDescription(routeName);
      }
    } catch (e) {
      debugPrint('TTS: Error getting page info: $e');
    }
    
    return 'Onbekende pagina';
  }

  /// Get a description for common routes
  static String _getRouteDescription(String routeName) {
    switch (routeName) {
      case '/':
        return 'Hoofdpagina';
      case '/profile':
        return 'Profiel pagina';
      case '/forum':
        return 'Forum pagina';
      case '/login':
        return 'Inlog pagina';
      case '/register':
        return 'Registratie pagina';
      default:
        return 'Pagina: $routeName';
    }
  }
}
