import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/universal_tts_service.dart';

/// A universal wrapper that makes any widget speakable
/// This widget automatically extracts and speaks all text content
class UniversalTTSWrapper extends ConsumerStatefulWidget {
  final Widget child;
  final String? customText;
  final bool speakOnTap;
  final bool speakOnLongPress;
  final bool speakOnFocus;
  final bool speakOnBuild;
  final Duration delay;
  final String? semanticLabel;
  final bool excludeFromSemantics;

  const UniversalTTSWrapper({
    super.key,
    required this.child,
    this.customText,
    this.speakOnTap = true,
    this.speakOnLongPress = false,
    this.speakOnFocus = false,
    this.speakOnBuild = false,
    this.delay = const Duration(milliseconds: 300),
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  @override
  ConsumerState<UniversalTTSWrapper> createState() => _UniversalTTSWrapperState();
}

class _UniversalTTSWrapperState extends ConsumerState<UniversalTTSWrapper> {
  final FocusNode _focusNode = FocusNode();
  bool _hasSpokenOnBuild = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.speakOnFocus) {
      _focusNode.addListener(_onFocusChange);
    }

    if (widget.speakOnBuild) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasSpokenOnBuild) {
          _speakContent();
          _hasSpokenOnBuild = true;
        }
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus && widget.speakOnFocus) {
      _speakContent();
    }
  }

  Future<void> _speakContent() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    await Future.delayed(widget.delay);

    String textToSpeak;
    if (widget.customText != null) {
      textToSpeak = widget.customText!;
    } else {
      textToSpeak = _extractTextFromWidget(widget.child);
    }

    if (textToSpeak.isNotEmpty) {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(textToSpeak);
    }
  }

  String _extractTextFromWidget(Widget widget) {
    return UniversalTTSService.extractAllTextFromWidget(widget);
  }

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = widget.child;

    // Add focus capability if needed
    if (widget.speakOnFocus) {
      wrappedChild = Focus(
        focusNode: _focusNode,
        child: wrappedChild,
      );
    }

    // Add gesture detection for tap and long press
    if (widget.speakOnTap || widget.speakOnLongPress) {
      wrappedChild = GestureDetector(
        onTap: widget.speakOnTap ? _speakContent : null,
        onLongPress: widget.speakOnLongPress ? _speakContent : null,
        child: wrappedChild,
      );
    }

    // Add semantic information for screen readers
    if (widget.semanticLabel != null || !widget.excludeFromSemantics) {
      wrappedChild = Semantics(
        label: widget.semanticLabel ?? widget.customText,
        excludeSemantics: widget.excludeFromSemantics,
        onTap: widget.speakOnTap ? _speakContent : null,
        onLongPress: widget.speakOnLongPress ? _speakContent : null,
        child: wrappedChild,
      );
    }

    return wrappedChild;
  }
}

/// A wrapper specifically for text fields that speaks their content and state
class TTSTextFieldWrapper extends ConsumerWidget {
  final Widget child;
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool isPassword;

  const TTSTextFieldWrapper({
    super.key,
    required this.child,
    this.controller,
    this.label,
    this.hint,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalTTSWrapper(
      customText: _buildTextFieldDescription(),
      speakOnTap: true,
      speakOnFocus: true,
      child: child,
    );
  }

  String _buildTextFieldDescription() {
    String description = '';
    
    if (label != null) {
      description += '$label invoerveld. ';
    } else {
      description += 'Invoerveld. ';
    }

    if (controller?.text.isNotEmpty == true) {
      if (isPassword) {
        description += 'Bevat ${controller!.text.length} karakters. ';
      } else {
        description += 'Huidige waarde: ${controller!.text}. ';
      }
    } else {
      description += 'Leeg. ';
    }

    if (hint != null) {
      description += 'Hint: $hint. ';
    }

    return description;
  }
}

/// A wrapper for buttons that provides detailed button information
class TTSButtonWrapper extends ConsumerWidget {
  final Widget child;
  final String? label;
  final String? description;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const TTSButtonWrapper({
    super.key,
    required this.child,
    this.label,
    this.description,
    this.isEnabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalTTSWrapper(
      customText: _buildButtonDescription(),
      speakOnTap: true,
      child: GestureDetector(
        onTap: isEnabled ? onPressed : null,
        child: child,
      ),
    );
  }

  String _buildButtonDescription() {
    String description = '';
    
    if (label != null) {
      description += '$label ';
    }
    
    description += 'knop. ';
    
    if (!isEnabled) {
      description += 'Uitgeschakeld. ';
    }
    
    if (this.description != null) {
      description += this.description!;
    }

    return description;
  }
}

/// A wrapper for list items that provides context about position and content
class TTSListItemWrapper extends ConsumerWidget {
  final Widget child;
  final int index;
  final int totalItems;
  final String? customDescription;

  const TTSListItemWrapper({
    super.key,
    required this.child,
    required this.index,
    required this.totalItems,
    this.customDescription,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalTTSWrapper(
      customText: _buildListItemDescription(),
      speakOnTap: true,
      child: child,
    );
  }

  String _buildListItemDescription() {
    String description = 'Item ${index + 1} van $totalItems. ';
    
    if (customDescription != null) {
      description += customDescription!;
    } else {
      // Extract text from the child widget
      final childText = UniversalTTSService.extractAllTextFromWidget(child);
      if (childText.isNotEmpty) {
        description += childText;
      }
    }

    return description;
  }
}

/// A wrapper for form fields that provides comprehensive form context
class TTSFormFieldWrapper extends ConsumerWidget {
  final Widget child;
  final String? fieldName;
  final bool isRequired;
  final String? validationError;
  final String? helpText;

  const TTSFormFieldWrapper({
    super.key,
    required this.child,
    this.fieldName,
    this.isRequired = false,
    this.validationError,
    this.helpText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalTTSWrapper(
      customText: _buildFormFieldDescription(),
      speakOnTap: true,
      speakOnFocus: true,
      child: child,
    );
  }

  String _buildFormFieldDescription() {
    String description = '';
    
    if (fieldName != null) {
      description += '$fieldName ';
    }
    
    description += 'formulierveld. ';
    
    if (isRequired) {
      description += 'Verplicht veld. ';
    }
    
    if (validationError != null) {
      description += 'Fout: $validationError. ';
    }
    
    if (helpText != null) {
      description += 'Help: $helpText. ';
    }

    return description;
  }
}

/// A wrapper for navigation elements
class TTSNavigationWrapper extends ConsumerWidget {
  final Widget child;
  final String destination;
  final String? description;

  const TTSNavigationWrapper({
    super.key,
    required this.child,
    required this.destination,
    this.description,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UniversalTTSWrapper(
      customText: _buildNavigationDescription(),
      speakOnTap: true,
      child: child,
    );
  }

  String _buildNavigationDescription() {
    String desc = 'Navigatie naar $destination. ';
    if (description != null) {
      desc += description!;
    }
    return desc;
  }
}

/// Extension to easily wrap any widget with TTS functionality
extension TTSWidgetExtension on Widget {
  /// Wrap this widget with universal TTS functionality
  Widget withTTS({
    String? customText,
    bool speakOnTap = true,
    bool speakOnLongPress = false,
    bool speakOnFocus = false,
    bool speakOnBuild = false,
    Duration delay = const Duration(milliseconds: 300),
    String? semanticLabel,
  }) {
    return UniversalTTSWrapper(
      customText: customText,
      speakOnTap: speakOnTap,
      speakOnLongPress: speakOnLongPress,
      speakOnFocus: speakOnFocus,
      speakOnBuild: speakOnBuild,
      delay: delay,
      semanticLabel: semanticLabel,
      child: this,
    );
  }

  /// Wrap this widget as a speakable button
  Widget asTTSButton({
    String? label,
    String? description,
    bool isEnabled = true,
    VoidCallback? onPressed,
  }) {
    return TTSButtonWrapper(
      label: label,
      description: description,
      isEnabled: isEnabled,
      onPressed: onPressed,
      child: this,
    );
  }

  /// Wrap this widget as a speakable list item
  Widget asTTSListItem({
    required int index,
    required int totalItems,
    String? customDescription,
  }) {
    return TTSListItemWrapper(
      index: index,
      totalItems: totalItems,
      customDescription: customDescription,
      child: this,
    );
  }

  /// Wrap this widget as a speakable form field
  Widget asTTSFormField({
    String? fieldName,
    bool isRequired = false,
    String? validationError,
    String? helpText,
  }) {
    return TTSFormFieldWrapper(
      fieldName: fieldName,
      isRequired: isRequired,
      validationError: validationError,
      helpText: helpText,
      child: this,
    );
  }

  /// Wrap this widget as a speakable navigation element
  Widget asTTSNavigation({
    required String destination,
    String? description,
  }) {
    return TTSNavigationWrapper(
      destination: destination,
      description: description,
      child: this,
    );
  }
}
