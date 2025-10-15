import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/unified_tts_service.dart';

/// A widget that makes text clickable for TTS functionality
/// This is especially useful in dialogs and popups where TTS might not work automatically
class TTSClickableText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool enableTTS;
  final String? ttsLabel; // Optional custom label for TTS

  const TTSClickableText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.enableTTS = true,
    this.ttsLabel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final isTTSEnabled = accessibilityState.isTextToSpeechEnabled;

    // If TTS is not enabled or text is empty, return regular text
    if (!enableTTS || !isTTSEnabled || text.isEmpty) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
      );
    }

    // Return clickable text with TTS functionality
    return GestureDetector(
      onTap: () => _handleTTSClick(context, ref),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          text,
          style: style?.copyWith(
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue.withValues(alpha: 0.7),
            decorationThickness: 1.0,
          ) ?? TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.blue.withValues(alpha: 0.7),
            decorationThickness: 1.0,
          ),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    );
  }

  Future<void> _handleTTSClick(BuildContext context, WidgetRef ref) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      final textToSpeak = ttsLabel ?? text;
      
      // Stop any current speech
      if (accessibilityNotifier.isSpeaking()) {
        await accessibilityNotifier.stopSpeaking();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Speak the text
      await accessibilityNotifier.speak(textToSpeak);
      
      // Show feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voorlezen: ${textToSpeak.length > 50 ? '${textToSpeak.substring(0, 50)}...' : textToSpeak}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('TTS Clickable Text Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fout bij voorlezen van tekst'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// A widget that makes any widget clickable for TTS functionality
class TTSClickableWidget extends ConsumerWidget {
  final Widget child;
  final String ttsText;
  final bool enableTTS;
  final VoidCallback? onTap;

  const TTSClickableWidget({
    super.key,
    required this.child,
    required this.ttsText,
    this.enableTTS = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final isTTSEnabled = accessibilityState.isTextToSpeechEnabled;

    // If TTS is not enabled, return regular widget
    if (!enableTTS || !isTTSEnabled) {
      return child;
    }

    // Return clickable widget with TTS functionality
    return GestureDetector(
      onTap: () {
        // Call custom onTap if provided
        onTap?.call();
        // Handle TTS
        _handleTTSClick(context, ref);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: child,
      ),
    );
  }

  Future<void> _handleTTSClick(BuildContext context, WidgetRef ref) async {
    try {
      final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
      
      // Stop any current speech
      if (accessibilityNotifier.isSpeaking()) {
        await accessibilityNotifier.stopSpeaking();
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Speak the text
      await accessibilityNotifier.speak(ttsText);
      
      // Show feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voorlezen: ${ttsText.length > 50 ? '${ttsText.substring(0, 50)}...' : ttsText}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('TTS Clickable Widget Error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fout bij voorlezen'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
