import 'package:flutter/material.dart';

/// TTS Dialog and Overlay Extractor - Handles extraction from dialogs, overlays, and popups
class TTSDialogOverlayExtractor {
  /// Extract content from overlays, dialogs, and popups
  static String extractOverlayContent(BuildContext context) {
    final List<String> overlayParts = [];
    
    try {
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in extractOverlayContent');
        return '';
      }
      
      // Check for AlertDialog
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog != null) {
        overlayParts.add('Dialog geopend');
        final dialogContent = _extractDialogContent(context);
        if (dialogContent.isNotEmpty) {
          overlayParts.add(dialogContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for Dialog
      final dialog = context.findAncestorWidgetOfExactType<Dialog>();
      if (dialog != null) {
        overlayParts.add('Dialog geopend');
        final dialogContent = _extractDialogContent(context);
        if (dialogContent.isNotEmpty) {
          overlayParts.add(dialogContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for BottomSheet
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        overlayParts.add('Onderste menu geopend');
        final sheetContent = _extractBottomSheetContent(context);
        if (sheetContent.isNotEmpty) {
          overlayParts.add(sheetContent);
        }
        return overlayParts.join('. ');
      }
      
      // Check for SnackBar
      final snackBar = context.findAncestorWidgetOfExactType<SnackBar>();
      if (snackBar != null) {
        overlayParts.add('Melding getoond');
        final snackContent = _extractTextFromWidget(snackBar);
        if (snackContent.isNotEmpty) {
          overlayParts.add(snackContent);
        }
        return overlayParts.join('. ');
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting overlay content: $e');
    }
    
    return overlayParts.join('. ');
  }

  /// Extract content specifically from dialog widgets
  static String _extractDialogContent(BuildContext context) {
    final List<String> dialogParts = [];
    
    try {
      // Extract dialog title
      final title = _extractDialogTitle(context);
      if (title.isNotEmpty) {
        dialogParts.add('Titel: $title');
      }
      
      // Extract dialog text content
      final textContent = _extractDialogText(context);
      if (textContent.isNotEmpty) {
        dialogParts.add(textContent);
      }
      
      // Extract dialog buttons
      final buttons = _extractDialogButtons(context);
      if (buttons.isNotEmpty) {
        dialogParts.add('Knoppen: ${buttons.join(', ')}');
      }
      
    } catch (e) {
      debugPrint('TTS: Error extracting dialog content: $e');
    }
    
    return dialogParts.join('. ');
  }

  /// Extract dialog title
  static String _extractDialogTitle(BuildContext context) {
    try {
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog?.title != null) {
        return _extractTextFromWidget(alertDialog!.title!);
      }
    } catch (e) {
      debugPrint('TTS: Error extracting dialog title: $e');
    }
    return '';
  }

  /// Extract dialog text content
  static String _extractDialogText(BuildContext context) {
    try {
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog?.content != null) {
        return _extractTextFromWidget(alertDialog!.content!);
      }
    } catch (e) {
      debugPrint('TTS: Error extracting dialog text: $e');
    }
    return '';
  }

  /// Extract dialog buttons
  static List<String> _extractDialogButtons(BuildContext context) {
    final List<String> buttons = [];
    
    try {
      final alertDialog = context.findAncestorWidgetOfExactType<AlertDialog>();
      if (alertDialog?.actions != null) {
        for (final action in alertDialog!.actions!) {
          final buttonText = _extractTextFromWidget(action);
          if (buttonText.isNotEmpty) {
            buttons.add(buttonText);
          }
        }
      }
    } catch (e) {
      debugPrint('TTS: Error extracting dialog buttons: $e');
    }
    
    return buttons;
  }

  /// Extract content from bottom sheet
  static String _extractBottomSheetContent(BuildContext context) {
    try {
      final bottomSheet = context.findAncestorWidgetOfExactType<BottomSheet>();
      if (bottomSheet != null) {
        return _extractTextFromWidget(bottomSheet);
      }
    } catch (e) {
      debugPrint('TTS: Error extracting bottom sheet content: $e');
    }
    return '';
  }

  /// Helper method to extract text from a widget
  static String _extractTextFromWidget(Widget widget) {
    // Simplified implementation - would need full widget tree traversal
    if (widget is Text) {
      return widget.data ?? '';
    }
    return '';
  }
}
