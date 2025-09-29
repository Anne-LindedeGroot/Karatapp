import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

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

  /// Public method to extract text from any widget
  static String extractAllTextFromWidget(Widget widget) {
    return _extractAllTextFromWidget(widget);
  }

  /// Get screen-specific content descriptions
  static String getScreenDescription(String routeName) {
    switch (routeName) {
      case '/':
      case '/home':
        return 'de hoofdpagina waar je alle kata\'s kunt bekijken en zoeken';
      case '/profile':
        return 'je profiel pagina waar je je gegevens kunt bewerken';
      case '/favorites':
        return 'je favorieten pagina met opgeslagen kata\'s';
      case '/forum':
        return 'het community forum voor discussies';
      case '/create-kata':
        return 'de pagina om een nieuwe kata aan te maken';
      case '/edit-kata':
        return 'de pagina om een kata te bewerken';
      case '/login':
        return 'de inlog pagina';
      case '/signup':
        return 'de registratie pagina';
      case '/accessibility-settings':
        return 'de toegankelijkheids instellingen';
      default:
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
      
      // Get the current route for context
      final currentRoute = ModalRoute.of(context)?.settings.name ?? '/';
      
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
      } else {
        // Fallback: try to extract from the current widget
        final widget = context.widget;
        final widgetText = _extractAllTextFromWidget(widget);
        if (widgetText.isNotEmpty) {
          content.write('Pagina inhoud: $widgetText. ');
        }
      }
    } catch (e) {
      debugPrint('Error extracting page content: $e');
      content.write('Er was een probleem bij het lezen van de pagina inhoud. ');
    }
    
    // Remove the confusing navigation instructions
    
    final result = content.toString();
    return result.isNotEmpty ? result : 'Deze pagina bevat geen leesbare tekst.';
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
      if (widget.data != null) {
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
      if (widget.tooltip != null) {
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
      _extractFromWidget(widget.child);
    } else if (widget is Flexible) {
      _extractFromWidget(widget.child);
    } else if (widget is SizedBox) {
      if (widget.child != null) {
        _extractFromWidget(widget.child!);
      }
    } else if (widget is RefreshIndicator) {
      _extractFromWidget(widget.child);
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
