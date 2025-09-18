import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

/// A text widget that automatically applies accessibility settings
class AccessibleText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final bool enableTextToSpeech;
  final VoidCallback? onTap;

  const AccessibleText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.enableTextToSpeech = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final isTextToSpeechEnabled = ref.watch(isTextToSpeechEnabledProvider);
    
    // Get the base text style from theme or provided style
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    
    // Apply accessibility modifications
    final accessibleStyle = accessibilityNotifier.getAccessibleTextStyle(baseStyle);

    Widget textWidget = Text(
      text,
      style: accessibleStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
    );

    // Add text-to-speech functionality if enabled
    if (enableTextToSpeech && isTextToSpeechEnabled) {
      textWidget = GestureDetector(
        onTap: onTap ?? () => accessibilityNotifier.speak(text),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: textWidget),
            const SizedBox(width: 8),
            Icon(
              Icons.headphones,
              size: accessibleStyle.fontSize != null 
                  ? accessibleStyle.fontSize! * 0.8 
                  : 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    } else if (onTap != null) {
      textWidget = GestureDetector(
        onTap: onTap,
        child: textWidget,
      );
    }

    return textWidget;
  }
}

/// A rich text widget that supports accessibility features
class AccessibleRichText extends ConsumerWidget {
  final List<TextSpan> textSpans;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;
  final String? semanticsLabel;
  final bool enableTextToSpeech;
  final VoidCallback? onTap;

  const AccessibleRichText({
    super.key,
    required this.textSpans,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.maxLines,
    this.semanticsLabel,
    this.enableTextToSpeech = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final isTextToSpeechEnabled = ref.watch(isTextToSpeechEnabledProvider);
    
    // Apply accessibility modifications to all text spans
    final accessibleSpans = textSpans.map((span) {
      if (span.style != null) {
        return TextSpan(
          text: span.text,
          style: accessibilityNotifier.getAccessibleTextStyle(span.style!),
          children: span.children,
          recognizer: span.recognizer,
          semanticsLabel: span.semanticsLabel,
        );
      }
      return span;
    }).toList();

    Widget richTextWidget = RichText(
      text: TextSpan(children: accessibleSpans),
      textAlign: textAlign ?? TextAlign.start,
      textDirection: textDirection,
      softWrap: softWrap ?? true,
      overflow: overflow ?? TextOverflow.clip,
      maxLines: maxLines,
    );

    // Add text-to-speech functionality if enabled
    if (enableTextToSpeech && isTextToSpeechEnabled) {
      final fullText = textSpans.map((span) => span.text ?? '').join(' ');
      richTextWidget = GestureDetector(
        onTap: onTap ?? () => accessibilityNotifier.speak(fullText),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: richTextWidget),
            const SizedBox(width: 8),
            Icon(
              Icons.volume_up,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      );
    } else if (onTap != null) {
      richTextWidget = GestureDetector(
        onTap: onTap,
        child: richTextWidget,
      );
    }

    return richTextWidget;
  }
}

/// A text field widget that supports accessibility features
class AccessibleTextField extends ConsumerWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? helperText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final TextStyle? style;
  final InputDecoration? decoration;

  const AccessibleTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.helperText,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.enabled = true,
    this.onChanged,
    this.onTap,
    this.style,
    this.decoration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Get the base text style from theme or provided style
    final baseStyle = style ?? Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
    
    // Apply accessibility modifications
    final accessibleStyle = accessibilityNotifier.getAccessibleTextStyle(baseStyle);

    return TextField(
      controller: controller,
      style: accessibleStyle,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      minLines: minLines,
      enabled: enabled,
      onChanged: onChanged,
      onTap: onTap,
      decoration: decoration ?? InputDecoration(
        labelText: labelText,
        hintText: hintText,
        helperText: helperText,
        // Apply accessibility font scaling to label and hint text
        labelStyle: accessibilityNotifier.getAccessibleTextStyle(
          Theme.of(context).inputDecorationTheme.labelStyle ?? const TextStyle(),
        ),
        hintStyle: accessibilityNotifier.getAccessibleTextStyle(
          Theme.of(context).inputDecorationTheme.hintStyle ?? const TextStyle(),
        ),
        helperStyle: accessibilityNotifier.getAccessibleTextStyle(
          Theme.of(context).inputDecorationTheme.helperStyle ?? const TextStyle(),
        ),
      ),
    );
  }
}

/// A button widget that supports accessibility features and text-to-speech
class AccessibleButton extends ConsumerWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonStyle? style;
  final bool enableTextToSpeech;
  final Widget? icon;
  final bool isElevated;

  const AccessibleButton({
    super.key,
    required this.text,
    this.onPressed,
    this.style,
    this.enableTextToSpeech = false,
    this.icon,
    this.isElevated = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    final isTextToSpeechEnabled = ref.watch(isTextToSpeechEnabledProvider);
    
    // Get the base text style
    final baseStyle = Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    
    // Apply accessibility modifications
    final accessibleStyle = accessibilityNotifier.getAccessibleTextStyle(baseStyle);

    final buttonStyle = style?.copyWith(
      textStyle: WidgetStateProperty.all(accessibleStyle),
    ) ?? ButtonStyle(
      textStyle: WidgetStateProperty.all(accessibleStyle),
    );

    void handlePress() {
      if (enableTextToSpeech && isTextToSpeechEnabled) {
        accessibilityNotifier.speak(text);
      }
      onPressed?.call();
    }

    if (icon != null) {
      return isElevated
          ? ElevatedButton.icon(
              onPressed: handlePress,
              style: buttonStyle,
              icon: icon!,
              label: Text(text),
            )
          : TextButton.icon(
              onPressed: handlePress,
              style: buttonStyle,
              icon: icon!,
              label: Text(text),
            );
    }

    return isElevated
        ? ElevatedButton(
            onPressed: handlePress,
            style: buttonStyle,
            child: Text(text),
          )
        : TextButton(
            onPressed: handlePress,
            style: buttonStyle,
            child: Text(text),
          );
  }
}
