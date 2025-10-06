import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

/// Enhanced accessible text widget that automatically applies TTS and accessibility features
class EnhancedAccessibleText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;
  
  // TTS specific properties
  final bool enableTTS;
  final bool speakOnTap;
  final bool speakOnLongPress;
  final String? customTTSText;
  final Duration ttsDelay;

  const EnhancedAccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
    this.enableTTS = true,
    this.speakOnTap = true,
    this.speakOnLongPress = false,
    this.customTTSText,
    this.ttsDelay = const Duration(milliseconds: 200),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    
    // Use theme-based styling (font scaling is already applied at theme level)
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final accessibleStyle = accessibilityNotifier.getDyslexiaFriendlyTextStyle(baseStyle);

    Widget textWidget = Text(
      text,
      style: accessibleStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaleFactor != null ? TextScaler.linear(textScaleFactor!) : TextScaler.noScaling,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );

    // TTS functionality is now handled by the global floating button

    return textWidget;
  }
}

/// Enhanced accessible text field that speaks its content and state
class EnhancedAccessibleTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? initialValue;
  final FocusNode? focusNode;
  final InputDecoration? decoration;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextDirection? textDirection;
  final TextAlign textAlign;
  final TextAlignVertical? textAlignVertical;
  final bool autofocus;
  final bool readOnly;
  final bool? showCursor;
  final String obscuringCharacter;
  final bool obscureText;
  final bool? autocorrect;
  final SmartDashesType? smartDashesType;
  final SmartQuotesType? smartQuotesType;
  final bool enableSuggestions;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final List<TextInputFormatter>? inputFormatters;
  final bool? enabled;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Color? cursorColor;
  final Brightness? keyboardAppearance;
  final EdgeInsets scrollPadding;
  final bool enableInteractiveSelection;
  final TextSelectionControls? selectionControls;
  final ScrollController? scrollController;
  final ScrollPhysics? scrollPhysics;
  final Iterable<String>? autofillHints;
  final String? restorationId;
  final bool enableIMEPersonalizedLearning;
  
  // TTS specific properties
  final bool enableTTS;
  final bool speakOnFocus;
  final bool speakOnChange;
  final String? customTTSLabel;
  final Duration ttsDelay;

  const EnhancedAccessibleTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.decoration = const InputDecoration(),
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.style,
    this.strutStyle,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.textAlignVertical,
    this.autofocus = false,
    this.readOnly = false,
    this.showCursor,
    this.obscuringCharacter = '•',
    this.obscureText = false,
    this.autocorrect,
    this.smartDashesType,
    this.smartQuotesType,
    this.enableSuggestions = true,
    this.maxLines = 1,
    this.minLines,
    this.expands = false,
    this.maxLength,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.inputFormatters,
    this.enabled,
    this.cursorWidth = 2.0,
    this.cursorHeight,
    this.cursorRadius,
    this.cursorColor,
    this.keyboardAppearance,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.enableInteractiveSelection = true,
    this.selectionControls,
    this.scrollController,
    this.scrollPhysics,
    this.autofillHints,
    this.restorationId,
    this.enableIMEPersonalizedLearning = true,
    this.enableTTS = true,
    this.speakOnFocus = true,
    this.speakOnChange = false,
    this.customTTSLabel,
    this.ttsDelay = const Duration(milliseconds: 300),
  });

  @override
  ConsumerState<EnhancedAccessibleTextField> createState() => _EnhancedAccessibleTextFieldState();
}

class _EnhancedAccessibleTextFieldState extends ConsumerState<EnhancedAccessibleTextField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasFocus = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
    
    if (widget.enableTTS) {
      _focusNode.addListener(_onFocusChange);
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus != _hasFocus) {
      _hasFocus = _focusNode.hasFocus;
      if (_hasFocus && widget.speakOnFocus) {
        _speakFieldDescription();
      }
    }
  }

  void _onTextChange() {
    if (widget.speakOnChange && _hasFocus) {
      _speakCurrentValue();
    }
  }

  Future<void> _speakFieldDescription() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    await Future.delayed(widget.ttsDelay);

    String description = '';
    
    if (widget.customTTSLabel != null) {
      description += '${widget.customTTSLabel} ';
    } else if (widget.decoration?.labelText != null) {
      description += '${widget.decoration!.labelText} ';
    }
    
    description += 'invoerveld. ';
    
    if (_controller.text.isNotEmpty) {
      if (widget.obscureText) {
        description += 'Bevat ${_controller.text.length} karakters. ';
      } else {
        description += 'Huidige waarde: ${_controller.text}. ';
      }
    } else {
      description += 'Leeg. ';
    }
    
    if (widget.decoration?.hintText != null) {
      description += 'Hint: ${widget.decoration!.hintText}. ';
    }

    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.speak(description);
  }

  Future<void> _speakCurrentValue() async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    if (!accessibilityState.isTextToSpeechEnabled) return;

    if (_controller.text.isNotEmpty && !widget.obscureText) {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      await accessibilityNotifier.speak(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    
    // Apply accessibility styling
    final baseStyle = widget.style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    final scaledStyle = baseStyle.copyWith(
      fontSize: (baseStyle.fontSize ?? 14) * accessibilityState.fontScaleFactor,
    );
    final accessibleStyle = accessibilityNotifier.getDyslexiaFriendlyTextStyle(scaledStyle);

    Widget textField = TextField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: widget.decoration,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      style: accessibleStyle,
      strutStyle: widget.strutStyle,
      textDirection: widget.textDirection,
      textAlign: widget.textAlign,
      textAlignVertical: widget.textAlignVertical,
      autofocus: widget.autofocus,
      readOnly: widget.readOnly,
      showCursor: widget.showCursor,
      obscuringCharacter: widget.obscuringCharacter,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      maxLength: widget.maxLength,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.inputFormatters,
      enabled: widget.enabled,
      cursorWidth: widget.cursorWidth,
      cursorHeight: widget.cursorHeight,
      cursorRadius: widget.cursorRadius,
      cursorColor: widget.cursorColor,
      keyboardAppearance: widget.keyboardAppearance,
      scrollPadding: widget.scrollPadding,
      enableInteractiveSelection: widget.enableInteractiveSelection,
      selectionControls: widget.selectionControls,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      autofillHints: widget.autofillHints,
      restorationId: widget.restorationId,
      enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
    );

    // TTS functionality is now handled by the global floating button

    return textField;
  }
}

/// Extension to easily convert regular text widgets to accessible ones
extension AccessibleTextExtension on Text {
  /// Convert this Text widget to an EnhancedAccessibleText
  EnhancedAccessibleText toAccessible({
    bool enableTTS = true,
    bool speakOnTap = true,
    bool speakOnLongPress = false,
    String? customTTSText,
    Duration ttsDelay = const Duration(milliseconds: 200),
  }) {
    return EnhancedAccessibleText(
      data ?? '',
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
      enableTTS: enableTTS,
      speakOnTap: speakOnTap,
      speakOnLongPress: speakOnLongPress,
      customTTSText: customTTSText,
      ttsDelay: ttsDelay,
    );
  }
}

/// Extension to easily convert regular TextField widgets to accessible ones
extension AccessibleTextFieldExtension on TextField {
  /// Convert this TextField widget to an EnhancedAccessibleTextField
  EnhancedAccessibleTextField toAccessible({
    bool enableTTS = true,
    bool speakOnFocus = true,
    bool speakOnChange = false,
    String? customTTSLabel,
    Duration ttsDelay = const Duration(milliseconds: 300),
  }) {
    return EnhancedAccessibleTextField(
      controller: controller,
      focusNode: focusNode,
      decoration: decoration,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      style: style,
      strutStyle: strutStyle,
      textDirection: textDirection,
      textAlign: textAlign,
      textAlignVertical: textAlignVertical,
      autofocus: autofocus,
      readOnly: readOnly,
      showCursor: showCursor,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      autocorrect: autocorrect,
      smartDashesType: smartDashesType,
      smartQuotesType: smartQuotesType,
      enableSuggestions: enableSuggestions,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      maxLength: maxLength,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters,
      enabled: enabled,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorColor: cursorColor,
      keyboardAppearance: keyboardAppearance,
      scrollPadding: scrollPadding,
      enableInteractiveSelection: enableInteractiveSelection,
      selectionControls: selectionControls,
      scrollController: scrollController,
      scrollPhysics: scrollPhysics,
      autofillHints: autofillHints,
      restorationId: restorationId,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning,
      enableTTS: enableTTS,
      speakOnFocus: speakOnFocus,
      speakOnChange: speakOnChange,
      customTTSLabel: customTTSLabel,
      ttsDelay: ttsDelay,
    );
  }
}
