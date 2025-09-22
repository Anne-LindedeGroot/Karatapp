import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

/// A reusable TTS headphones button that can be placed anywhere in the app
class TTSHeadphonesButton extends ConsumerWidget {
  final EdgeInsets? margin;
  final double? iconSize;
  final Color? activeColor;
  final Color? inactiveColor;
  final String? tooltip;
  final VoidCallback? onToggle;
  final bool showLabel;
  final String? customTestText;

  const TTSHeadphonesButton({
    super.key,
    this.margin,
    this.iconSize = 24.0,
    this.activeColor,
    this.inactiveColor,
    this.tooltip,
    this.onToggle,
    this.showLabel = false,
    this.customTestText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      margin: margin,
      child: showLabel 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(context, isEnabled, effectiveActiveColor, effectiveInactiveColor, accessibilityNotifier),
              const SizedBox(height: 4),
              Text(
                isEnabled ? 'Spraak aan' : 'Spraak uit',
                style: TextStyle(
                  fontSize: 10,
                  color: isEnabled ? effectiveActiveColor : effectiveInactiveColor,
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          )
        : _buildIconButton(context, isEnabled, effectiveActiveColor, effectiveInactiveColor, accessibilityNotifier),
    );
  }

  Widget _buildIconButton(
    BuildContext context, 
    bool isEnabled, 
    Color activeColor, 
    Color inactiveColor, 
    AccessibilityNotifier accessibilityNotifier
  ) {
    return IconButton(
      icon: Icon(
        isEnabled ? Icons.headphones : Icons.headphones_outlined,
        size: iconSize,
        color: isEnabled ? activeColor : inactiveColor,
      ),
      tooltip: tooltip ?? (isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen'),
      onPressed: () async {
        await accessibilityNotifier.toggleTextToSpeech();
        
        // Call custom callback if provided
        onToggle?.call();
        
        // Test TTS when enabling with custom or default text
        if (!isEnabled) {
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld';
          await accessibilityNotifier.speak(testText);
        }
      },
    );
  }
}

/// A compact floating TTS button for minimal UI spaces
class CompactTTSButton extends ConsumerWidget {
  final EdgeInsets? margin;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final String? customTestText;

  const CompactTTSButton({
    super.key,
    this.margin,
    this.backgroundColor,
    this.foregroundColor,
    this.customTestText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: FloatingActionButton.small(
        onPressed: () async {
          await accessibilityNotifier.toggleTextToSpeech();
          
          // Test TTS when enabling
          if (!isEnabled) {
            await Future.delayed(const Duration(milliseconds: 100));
            final testText = customTestText ?? 'Spraak is nu ingeschakeld';
            await accessibilityNotifier.speak(testText);
          }
        },
        backgroundColor: backgroundColor ?? (isEnabled 
          ? Theme.of(context).colorScheme.primary 
          : Theme.of(context).colorScheme.secondary),
        foregroundColor: foregroundColor ?? (isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary),
        tooltip: isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen',
        child: Icon(
          isEnabled ? Icons.headphones : Icons.headphones_outlined,
          size: 20,
        ),
      ),
    );
  }
}

/// A TTS button designed for app bars and toolbars
class AppBarTTSButton extends ConsumerWidget {
  final String? customTestText;
  final VoidCallback? onToggle;

  const AppBarTTSButton({
    super.key,
    this.customTestText,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;

    return IconButton(
      icon: Icon(
        isEnabled ? Icons.headphones : Icons.headphones_outlined,
        color: isEnabled ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen',
      onPressed: () async {
        await accessibilityNotifier.toggleTextToSpeech();
        
        // Call custom callback if provided
        onToggle?.call();
        
        // Test TTS when enabling
        if (!isEnabled) {
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld';
          await accessibilityNotifier.speak(testText);
        }
      },
    );
  }
}

/// A TTS button for dialogs and popups
class DialogTTSButton extends ConsumerWidget {
  final String? customTestText;
  final bool showBackground;
  final EdgeInsets? padding;

  const DialogTTSButton({
    super.key,
    this.customTestText,
    this.showBackground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;

    Widget button = IconButton(
      icon: Icon(
        isEnabled ? Icons.headphones : Icons.headphones_outlined,
        color: isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen',
      onPressed: () async {
        await accessibilityNotifier.toggleTextToSpeech();
        
        // Test TTS when enabling
        if (!isEnabled) {
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
          color: isEnabled 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: isEnabled 
            ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
            : null,
        ),
        child: button,
      );
    }

    return button;
  }
}

/// A TTS button for tab bars
class TabTTSButton extends ConsumerWidget {
  final String? customTestText;
  final bool isCompact;

  const TabTTSButton({
    super.key,
    this.customTestText,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;

    return GestureDetector(
      onTap: () async {
        await accessibilityNotifier.toggleTextToSpeech();
        
        // Test TTS when enabling
        if (!isEnabled) {
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = customTestText ?? 'Spraak is nu ingeschakeld voor deze tab';
          await accessibilityNotifier.speak(testText);
        }
      },
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: isEnabled 
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isEnabled 
            ? Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3))
            : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isEnabled ? Icons.headphones : Icons.headphones_outlined,
              size: isCompact ? 16 : 20,
              color: isEnabled 
                ? Theme.of(context).colorScheme.primary 
                : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              Text(
                'TTS',
                style: TextStyle(
                  fontSize: 10,
                  color: isEnabled 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: isEnabled ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A widget that speaks text when TTS is enabled and provides a TTS button
class TTSTextWidget extends ConsumerWidget {
  final String text;
  final Widget child;
  final bool showButton;
  final EdgeInsets? buttonMargin;
  final MainAxisAlignment alignment;

  const TTSTextWidget({
    super.key,
    required this.text,
    required this.child,
    this.showButton = true,
    this.buttonMargin,
    this.alignment = MainAxisAlignment.spaceBetween,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Row(
      mainAxisAlignment: alignment,
      children: [
        Expanded(child: child),
        if (showButton)
          TTSHeadphonesButton(
            margin: buttonMargin ?? const EdgeInsets.only(left: 8),
            iconSize: 20,
            customTestText: text,
            onToggle: () {
              // Speak the text when button is pressed and TTS is enabled
              final isEnabled = ref.read(accessibilityNotifierProvider).isTextToSpeechEnabled;
              if (isEnabled) {
                accessibilityNotifier.speak(text);
              }
            },
          ),
      ],
    );
  }
}
