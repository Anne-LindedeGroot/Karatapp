import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/context_aware_tts_service.dart';

/// Enhanced TTS headphones button with comprehensive page reading capabilities
class EnhancedTTSHeadphonesButton extends ConsumerWidget {
  final TTSPageType pageType;
  final EdgeInsets? margin;
  final double? iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? tooltip;
  final VoidCallback? onToggle;
  final bool showLabel;
  final String? customTestText;
  final String? pageTitle;
  final String? pageContent;
  final List<String>? comments;

  const EnhancedTTSHeadphonesButton({
    super.key,
    required this.pageType,
    this.margin,
    this.iconSize = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
    this.onToggle,
    this.showLabel = false,
    this.customTestText,
    this.pageTitle,
    this.pageContent,
    this.comments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isReading = ContextAwareTTSService.isReading;
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final readingColor = Colors.green;

    return Container(
      margin: margin,
      child: showLabel 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(context, ref, isEnabled, isSpeaking, isReading, effectiveActiveColor, effectiveInactiveColor, readingColor, accessibilityNotifier),
              const SizedBox(height: 4),
              Text(
                isReading ? 'Aan het lezen' : (isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak aan' : 'Spraak uit')),
                style: TextStyle(
                  fontSize: 10,
                  color: isReading ? readingColor : (isSpeaking ? readingColor : (isEnabled ? effectiveActiveColor : effectiveInactiveColor)),
                  fontWeight: (isEnabled || isSpeaking || isReading) ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          )
        : _buildIconButton(context, ref, isEnabled, isSpeaking, isReading, effectiveActiveColor, effectiveInactiveColor, readingColor, accessibilityNotifier),
    );
  }

  Widget _buildIconButton(
    BuildContext context,
    WidgetRef ref,
    bool isEnabled, 
    bool isSpeaking,
    bool isReading,
    Color activeColor, 
    Color inactiveColor, 
    Color readingColor,
    AccessibilityNotifier accessibilityNotifier
  ) {
    return IconButton(
      icon: Icon(
        isReading 
          ? Icons.menu_book
          : (isSpeaking 
            ? Icons.volume_up 
            : (isEnabled ? Icons.headphones : Icons.headphones_outlined)),
        size: iconSize,
        color: isReading 
          ? readingColor 
          : (isSpeaking 
            ? readingColor 
            : (isEnabled ? activeColor : inactiveColor)),
      ),
      tooltip: tooltip ?? _getTooltipText(isEnabled, isSpeaking, isReading),
      onPressed: () async {
        if (isReading || isSpeaking) {
          // Stop any current reading or speaking
          await ContextAwareTTSService.stopReading(context, ref);
        } else if (isEnabled) {
          // Start reading the page if TTS is enabled
          await _startPageReading(context, ref);
        } else {
          // Enable TTS first
          await accessibilityNotifier.toggleTextToSpeech();
          onToggle?.call();
          
          // Wait longer for TTS to initialize properly before testing
          await Future.delayed(const Duration(milliseconds: 500));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld. Druk opnieuw om de pagina voor te lezen.';
          await accessibilityNotifier.speak(testText);
        }
      },
    );
  }

  String _getTooltipText(bool isEnabled, bool isSpeaking, bool isReading) {
    if (isReading) {
      return 'Stop pagina voorlezen';
    } else if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return 'Pagina voorlezen';
    } else {
      return 'Spraak inschakelen';
    }
  }

  Future<void> _startPageReading(BuildContext context, WidgetRef ref) async {
    try {
      await ContextAwareTTSService.readPageContent(
        context,
        ref,
        pageType,
        customContent: pageContent,
        pageTitle: pageTitle,
        comments: comments,
      );
    } catch (e) {
      debugPrint('Error starting page reading: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij voorlezen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Compact version for app bars
class CompactEnhancedTTSButton extends ConsumerWidget {
  final TTSPageType pageType;
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? customTestText;
  final String? pageTitle;
  final String? pageContent;
  final List<String>? comments;

  const CompactEnhancedTTSButton({
    super.key,
    required this.pageType,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
    this.customTestText,
    this.pageTitle,
    this.pageContent,
    this.comments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isReading = ContextAwareTTSService.isReading;

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: FloatingActionButton.small(
        onPressed: () async {
          if (isReading || isSpeaking) {
            await ContextAwareTTSService.stopReading(context, ref);
          } else if (isEnabled) {
            await _startPageReading(context, ref);
          } else {
            await accessibilityNotifier.toggleTextToSpeech();
            
            await Future.delayed(const Duration(milliseconds: 100));
            final testText = customTestText ?? 'Spraak is nu ingeschakeld';
            await accessibilityNotifier.speak(testText);
          }
        },
        backgroundColor: backgroundColor ?? (isReading 
          ? Colors.green 
          : (isSpeaking 
            ? Colors.green 
            : (isEnabled 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.secondary))),
        foregroundColor: foregroundColor ?? (isReading || isSpeaking || isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary),
        tooltip: _getTooltipText(isEnabled, isSpeaking, isReading),
        child: Icon(
          isReading 
            ? Icons.menu_book
            : (isSpeaking 
              ? Icons.volume_up 
              : (isEnabled ? Icons.headphones : Icons.headphones_outlined)),
          size: 20,
        ),
      ),
    );
  }

  String _getTooltipText(bool isEnabled, bool isSpeaking, bool isReading) {
    if (isReading) {
      return 'Stop pagina voorlezen';
    } else if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return 'Pagina voorlezen';
    } else {
      return 'Spraak inschakelen';
    }
  }

  Future<void> _startPageReading(BuildContext context, WidgetRef ref) async {
    try {
      await ContextAwareTTSService.readPageContent(
        context,
        ref,
        pageType,
        customContent: pageContent,
        pageTitle: pageTitle,
        comments: comments,
      );
    } catch (e) {
      debugPrint('Error starting page reading: $e');
    }
  }
}

/// App bar version with enhanced functionality
class AppBarEnhancedTTSButton extends ConsumerWidget {
  final TTSPageType pageType;
  final String? customTestText;
  final VoidCallback? onToggle;
  final String? pageTitle;
  final String? pageContent;
  final List<String>? comments;

  const AppBarEnhancedTTSButton({
    super.key,
    required this.pageType,
    this.customTestText,
    this.onToggle,
    this.pageTitle,
    this.pageContent,
    this.comments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isReading = ContextAwareTTSService.isReading;

    return IconButton(
      icon: Icon(
        isReading 
          ? Icons.menu_book
          : (isSpeaking 
            ? Icons.volume_up 
            : (isEnabled ? Icons.headphones : Icons.headphones_outlined)),
        color: isReading 
          ? Colors.green 
          : (isSpeaking 
            ? Colors.green 
            : (isEnabled ? Theme.of(context).colorScheme.primary : null)),
      ),
      tooltip: _getTooltipText(isEnabled, isSpeaking, isReading),
      onPressed: () async {
        if (isReading || isSpeaking) {
          await ContextAwareTTSService.stopReading(context, ref);
        } else if (isEnabled) {
          await _startPageReading(context, ref);
        } else {
          await accessibilityNotifier.toggleTextToSpeech();
          onToggle?.call();
          
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld. Druk opnieuw om de pagina voor te lezen.';
          await accessibilityNotifier.speak(testText);
        }
      },
    );
  }

  String _getTooltipText(bool isEnabled, bool isSpeaking, bool isReading) {
    if (isReading) {
      return 'Stop pagina voorlezen';
    } else if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return 'Pagina voorlezen';
    } else {
      return 'Spraak inschakelen';
    }
  }

  Future<void> _startPageReading(BuildContext context, WidgetRef ref) async {
    try {
      await ContextAwareTTSService.readPageContent(
        context,
        ref,
        pageType,
        customContent: pageContent,
        pageTitle: pageTitle,
        comments: comments,
      );
    } catch (e) {
      debugPrint('Error starting page reading: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout bij voorlezen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog version with enhanced functionality
class DialogEnhancedTTSButton extends ConsumerWidget {
  final TTSPageType pageType;
  final String? customTestText;
  final bool showBackground;
  final EdgeInsets? padding;
  final String? pageTitle;
  final String? pageContent;
  final List<String>? comments;

  const DialogEnhancedTTSButton({
    super.key,
    required this.pageType,
    this.customTestText,
    this.showBackground = true,
    this.padding,
    this.pageTitle,
    this.pageContent,
    this.comments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isReading = ContextAwareTTSService.isReading;

    Widget button = IconButton(
      icon: Icon(
        isReading 
          ? Icons.menu_book
          : (isSpeaking 
            ? Icons.volume_up 
            : (isEnabled ? Icons.headphones : Icons.headphones_outlined)),
        color: isReading 
          ? Colors.green 
          : (isSpeaking 
            ? Colors.green 
            : (isEnabled 
              ? Theme.of(context).colorScheme.primary 
              : Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
      tooltip: _getTooltipText(isEnabled, isSpeaking, isReading),
      onPressed: () async {
        if (isReading || isSpeaking) {
          await ContextAwareTTSService.stopReading(context, ref);
        } else if (isEnabled) {
          await _startPageReading(context, ref);
        } else {
          await accessibilityNotifier.toggleTextToSpeech();
          
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld voor dit venster';
          await accessibilityNotifier.speak(testText);
        }
      },
    );

    if (showBackground) {
      button = Container(
        padding: padding ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isReading 
            ? Colors.green.withValues(alpha: 0.1)
            : (isSpeaking 
              ? Colors.green.withValues(alpha: 0.1)
              : (isEnabled 
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5))),
          borderRadius: BorderRadius.circular(8),
          border: (isEnabled || isSpeaking || isReading)
            ? Border.all(color: (isReading || isSpeaking ? Colors.green : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3))
            : null,
        ),
        child: button,
      );
    }

    return button;
  }

  String _getTooltipText(bool isEnabled, bool isSpeaking, bool isReading) {
    if (isReading) {
      return 'Stop pagina voorlezen';
    } else if (isSpeaking) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return 'Pagina voorlezen';
    } else {
      return 'Spraak inschakelen';
    }
  }

  Future<void> _startPageReading(BuildContext context, WidgetRef ref) async {
    try {
      await ContextAwareTTSService.readPageContent(
        context,
        ref,
        pageType,
        customContent: pageContent,
        pageTitle: pageTitle,
        comments: comments,
      );
    } catch (e) {
      debugPrint('Error starting page reading: $e');
    }
  }
}
