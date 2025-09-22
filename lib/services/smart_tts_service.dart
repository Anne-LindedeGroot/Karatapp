import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../models/kata_model.dart';

/// Smart TTS Service that only reads user-visible content, not technical data
class SmartTTSService {
  static final SmartTTSService _instance = SmartTTSService._internal();
  factory SmartTTSService() => _instance;
  SmartTTSService._internal();

  /// Speak kata information in a user-friendly way
  static Future<void> speakKata(Kata kata, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Create user-friendly kata description
    String kataText = 'Kata: ${kata.name}. ';
    
    // Only add style if it's meaningful (not just technical data)
    if (kata.style.isNotEmpty && !isTechnicalData(kata.style)) {
      kataText += 'Stijl: ${kata.style}. ';
    }
    
    // Add description if available
    if (kata.description.isNotEmpty) {
      // Clean up description - remove technical formatting
      final cleanDescription = _cleanDescription(kata.description);
      kataText += cleanDescription;
    }
    
    // Add media information if available
    final hasImages = kata.imageUrls?.isNotEmpty == true;
    final hasVideos = kata.videoUrls?.isNotEmpty == true;
    
    if (hasImages || hasVideos) {
      kataText += ' Deze kata heeft ';
      if (hasImages) {
        kataText += '${kata.imageUrls!.length} afbeelding${kata.imageUrls!.length == 1 ? '' : 'en'}';
      }
      if (hasImages && hasVideos) {
        kataText += ' en ';
      }
      if (hasVideos) {
        kataText += '${kata.videoUrls!.length} video${kata.videoUrls!.length == 1 ? '' : '\'s'}';
      }
      kataText += '.';
    }

    await accessibilityNotifier.speak(kataText);
  }

  /// Speak form content intelligently - only read what user sees
  static Future<void> speakFormContent(String formTitle, Map<String, dynamic> visibleFields, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    String formContent = 'Formulier: $formTitle. ';
    
    // Only describe fields that have user-visible labels
    final meaningfulFields = <String>[];
    visibleFields.forEach((label, value) {
      if (!isTechnicalData(label) && label.isNotEmpty) {
        if (value != null && value.toString().isNotEmpty && !isTechnicalData(value.toString())) {
          meaningfulFields.add('$label: ${_cleanFieldValue(value.toString())}');
        } else {
          meaningfulFields.add('$label veld');
        }
      }
    });
    
    if (meaningfulFields.isNotEmpty) {
      formContent += 'Velden: ${meaningfulFields.join(', ')}.';
    }
    
    await accessibilityNotifier.speak(formContent);
  }

  /// Speak only user-visible text from a widget
  static Future<void> speakUserVisibleContent(Widget widget, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final textContent = _extractUserVisibleText(widget);
    if (textContent.isNotEmpty) {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(textContent);
    }
  }

  /// Extract only user-visible text, filtering out technical data
  static String _extractUserVisibleText(Widget widget) {
    final extractor = _SmartTextExtractor();
    return extractor.extractUserVisibleText(widget);
  }

  /// Check if text is technical data that shouldn't be read
  static bool isTechnicalData(String text) {
    if (text.isEmpty) return true;
    
    // Filter out technical field names and IDs
    final technicalPatterns = [
      RegExp(r'^[a-z_]+$'), // snake_case field names
      RegExp(r'^[A-Z_]+$'), // CONSTANT names
      RegExp(r'^\d+$'), // Pure numbers/IDs
      RegExp(r'^[a-f0-9-]{8,}$'), // UUIDs or hashes
      RegExp(r'^(id|uuid|url|uri|api|json|xml)$', caseSensitive: false),
      RegExp(r'^(created_at|updated_at|deleted_at)$', caseSensitive: false),
      RegExp(r'^(true|false|null|undefined)$', caseSensitive: false),
    ];
    
    return technicalPatterns.any((pattern) => pattern.hasMatch(text.trim()));
  }

  /// Clean description text for TTS
  static String _cleanDescription(String description) {
    // Remove markdown formatting
    String cleaned = description
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'\1') // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'\1') // Code
        .replaceAll(RegExp(r'#{1,6}\s*'), '') // Headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'\1') // Links
        .replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]+\)'), r'\1') // Images
        .trim();
    
    // Remove excessive whitespace
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    
    // Ensure proper sentence ending
    if (cleaned.isNotEmpty && !cleaned.endsWith('.') && !cleaned.endsWith('!') && !cleaned.endsWith('?')) {
      cleaned += '.';
    }
    
    return cleaned;
  }

  /// Clean field values for TTS
  static String _cleanFieldValue(String value) {
    // Remove technical formatting
    return value
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Speak button or action description
  static Future<void> speakAction(String actionName, String? description, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    String actionText = actionName;
    if (description != null && description.isNotEmpty && !isTechnicalData(description)) {
      actionText += ': $description';
    }
    
    await accessibilityNotifier.speak(actionText);
  }

  /// Speak list content with smart filtering
  static Future<void> speakSmartList(String listTitle, List<dynamic> items, WidgetRef ref, {
    String Function(dynamic)? itemFormatter,
  }) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Filter out technical items
    final meaningfulItems = items.where((item) {
      final itemText = itemFormatter?.call(item) ?? item.toString();
      return !isTechnicalData(itemText);
    }).toList();
    
    String listContent = '$listTitle. ';
    
    if (meaningfulItems.isEmpty) {
      listContent += 'Geen items beschikbaar.';
    } else {
      listContent += 'Deze lijst heeft ${meaningfulItems.length} item${meaningfulItems.length == 1 ? '' : 's'}. ';
      
      // Read first few items
      final itemsToRead = meaningfulItems.take(5).toList();
      for (int i = 0; i < itemsToRead.length; i++) {
        final itemText = itemFormatter?.call(itemsToRead[i]) ?? itemsToRead[i].toString();
        listContent += 'Item ${i + 1}: ${_cleanFieldValue(itemText)}. ';
      }
      
      if (meaningfulItems.length > 5) {
        listContent += 'En ${meaningfulItems.length - 5} meer items.';
      }
    }
    
    await accessibilityNotifier.speak(listContent);
  }

  /// Get user-friendly screen description
  static String getSmartScreenDescription(String routeName) {
    switch (routeName) {
      case '/':
      case '/home':
        return 'Hoofdpagina met kata overzicht';
      case '/profile':
        return 'Profiel pagina';
      case '/favorites':
        return 'Favorieten pagina';
      case '/forum':
        return 'Community forum';
      case '/create-kata':
        return 'Nieuwe kata maken';
      case '/edit-kata':
        return 'Kata bewerken';
      case '/login':
        return 'Inlog pagina';
      case '/signup':
        return 'Registratie pagina';
      case '/accessibility-settings':
        return 'Toegankelijkheids instellingen';
      default:
        return 'App pagina';
    }
  }
}

/// Smart text extractor that filters out technical content
class _SmartTextExtractor {
  final List<String> _userTexts = [];

  String extractUserVisibleText(Widget widget) {
    _userTexts.clear();
    _extractFromWidget(widget);
    
    // Filter and clean texts
    final meaningfulTexts = _userTexts
        .where((text) => !SmartTTSService.isTechnicalData(text))
        .map((text) => SmartTTSService._cleanFieldValue(text))
        .where((text) => text.isNotEmpty)
        .toList();
    
    return meaningfulTexts.join(' ').trim();
  }

  void _extractFromWidget(Widget widget) {
    // Only extract from user-facing text widgets
    if (widget is Text) {
      if (widget.data != null && widget.data!.isNotEmpty) {
        _userTexts.add(widget.data!);
      }
    } else if (widget is RichText) {
      _extractFromTextSpan(widget.text);
    } else if (widget is ListTile) {
      _extractFromListTile(widget);
    } else if (widget is AppBar) {
      _extractFromAppBar(widget);
    } else if (widget is ElevatedButton || widget is TextButton || widget is OutlinedButton) {
      _extractFromButton(widget);
    } else if (widget is Card && widget.child != null) {
      _extractFromWidget(widget.child!);
    } else if (widget is Container && widget.child != null) {
      _extractFromWidget(widget.child!);
    } else if (widget is Padding && widget.child != null) {
      _extractFromWidget(widget.child!);
    } else if (widget is Center && widget.child != null) {
      _extractFromWidget(widget.child!);
    } else if (widget is Column) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Row) {
      for (final child in widget.children) {
        _extractFromWidget(child);
      }
    } else if (widget is Expanded) {
      _extractFromWidget(widget.child);
    } else if (widget is Flexible) {
      _extractFromWidget(widget.child);
    }
    // Skip technical widgets like TextField internals, form validators, etc.
  }

  void _extractFromTextSpan(InlineSpan span) {
    if (span is TextSpan) {
      if (span.text != null && span.text!.isNotEmpty) {
        _userTexts.add(span.text!);
      }
      if (span.children != null) {
        for (final child in span.children!) {
          _extractFromTextSpan(child);
        }
      }
    }
  }

  void _extractFromListTile(ListTile widget) {
    if (widget.title is Text) {
      final titleText = (widget.title as Text).data;
      if (titleText != null && titleText.isNotEmpty) {
        _userTexts.add(titleText);
      }
    }
    if (widget.subtitle is Text) {
      final subtitleText = (widget.subtitle as Text).data;
      if (subtitleText != null && subtitleText.isNotEmpty) {
        _userTexts.add(subtitleText);
      }
    }
  }

  void _extractFromAppBar(AppBar widget) {
    if (widget.title is Text) {
      final titleText = (widget.title as Text).data;
      if (titleText != null && titleText.isNotEmpty) {
        _userTexts.add(titleText);
      }
    }
  }

  void _extractFromButton(Widget button) {
    Widget? child;
    if (button is ElevatedButton) {
      child = button.child;
    } else if (button is TextButton) {
      child = button.child;
    } else if (button is OutlinedButton) {
      child = button.child;
    }
    
    if (child != null) {
      _extractFromWidget(child);
    }
  }
}

/// Provider for the smart TTS service
final smartTTSServiceProvider = Provider<SmartTTSService>((ref) {
  return SmartTTSService();
});
