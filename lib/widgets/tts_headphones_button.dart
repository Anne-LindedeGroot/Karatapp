import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../services/visual_tts_service.dart';

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
    final isSpeaking = accessibilityState.isSpeaking;
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    final effectiveInactiveColor = inactiveColor ?? Theme.of(context).colorScheme.onSurfaceVariant;
    final speakingColor = Colors.green;

    return Container(
      margin: margin,
      child: showLabel 
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildIconButton(context, isEnabled, isSpeaking, effectiveActiveColor, effectiveInactiveColor, speakingColor, accessibilityNotifier),
              const SizedBox(height: 4),
              Text(
                isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak aan' : 'Spraak uit'),
                style: TextStyle(
                  fontSize: 10,
                  color: isSpeaking ? speakingColor : (isEnabled ? effectiveActiveColor : effectiveInactiveColor),
                  fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          )
        : _buildIconButton(context, isEnabled, isSpeaking, effectiveActiveColor, effectiveInactiveColor, speakingColor, accessibilityNotifier),
    );
  }

  Widget _buildIconButton(
    BuildContext context, 
    bool isEnabled, 
    bool isSpeaking,
    Color activeColor, 
    Color inactiveColor, 
    Color speakingColor,
    AccessibilityNotifier accessibilityNotifier
  ) {
    return IconButton(
      icon: Icon(
        isSpeaking 
          ? Icons.volume_up 
          : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
        size: iconSize,
        color: isSpeaking 
          ? speakingColor 
          : (isEnabled ? activeColor : inactiveColor),
      ),
      tooltip: tooltip ?? (isSpeaking 
        ? 'Stop spraak' 
        : (isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen')),
      onPressed: () async {
        if (isSpeaking) {
          // Stop speaking if currently speaking
          await accessibilityNotifier.stopSpeaking();
        } else {
          // Toggle TTS
          await accessibilityNotifier.toggleTextToSpeech();
          
          // Call custom callback if provided
          onToggle?.call();
          
          // Test TTS when enabling with custom or default text
          if (!isEnabled) {
            await Future.delayed(const Duration(milliseconds: 100));
            final testText = customTestText ?? 'Spraak is nu ingeschakeld';
            await accessibilityNotifier.speak(testText);
          }
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
    final isSpeaking = accessibilityState.isSpeaking;

    return Container(
      margin: margin ?? const EdgeInsets.all(8),
      child: FloatingActionButton.small(
        onPressed: () async {
          if (isSpeaking) {
            // Stop speaking if currently speaking
            await accessibilityNotifier.stopSpeaking();
          } else {
            // Toggle TTS
            await accessibilityNotifier.toggleTextToSpeech();
            
            // Test TTS when enabling
            if (!isEnabled) {
              await Future.delayed(const Duration(milliseconds: 100));
              final testText = customTestText ?? 'Spraak is nu ingeschakeld';
              await accessibilityNotifier.speak(testText);
            }
          }
        },
        backgroundColor: backgroundColor ?? (isSpeaking 
          ? Colors.green 
          : (isEnabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.secondary)),
        foregroundColor: foregroundColor ?? (isSpeaking || isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary),
        tooltip: isSpeaking 
          ? 'Stop spraak' 
          : (isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen'),
        child: Icon(
          isSpeaking 
            ? Icons.volume_up 
            : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
          size: 20,
        ),
      ),
    );
  }
}

/// A TTS button designed for app bars and toolbars with page reading functionality
class AppBarTTSButton extends ConsumerStatefulWidget {
  final String? customTestText;
  final VoidCallback? onToggle;

  const AppBarTTSButton({
    super.key,
    this.customTestText,
    this.onToggle,
  });

  @override
  ConsumerState<AppBarTTSButton> createState() => _AppBarTTSButtonState();
}

class _AppBarTTSButtonState extends ConsumerState<AppBarTTSButton> {
  bool _isReading = false;
  OverlayEntry? _progressOverlay;

  @override
  void dispose() {
    _removeProgressOverlay();
    super.dispose();
  }

  void _removeProgressOverlay() {
    _progressOverlay?.remove();
    _progressOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;

    return IconButton(
      icon: Icon(
        isSpeaking 
          ? Icons.volume_up 
          : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
        color: isSpeaking 
          ? Colors.green 
          : (isEnabled ? Theme.of(context).colorScheme.primary : null),
      ),
      tooltip: _getTooltipText(isEnabled, isSpeaking),
      onPressed: () async {
        if (isSpeaking || _isReading) {
          // Stop any current speech or reading
          await _stopReading();
          await accessibilityNotifier.stopSpeaking();
        } else if (isEnabled) {
          // Start reading the page if TTS is enabled
          await _startPageReading(context, ref);
        } else {
          // Enable TTS first, then start reading
          await accessibilityNotifier.toggleTextToSpeech();
          widget.onToggle?.call();
          
          // Test TTS when enabling
          await Future.delayed(const Duration(milliseconds: 100));
          final testText = widget.customTestText ?? 'Spraak is nu ingeschakeld. Druk opnieuw om de pagina voor te lezen.';
          await accessibilityNotifier.speak(testText);
        }
      },
    );
  }

  String _getTooltipText(bool isEnabled, bool isSpeaking) {
    if (isSpeaking || _isReading) {
      return 'Stop spraak';
    } else if (isEnabled) {
      return 'Pagina voorlezen';
    } else {
      return 'Spraak inschakelen';
    }
  }

  Future<void> _startPageReading(BuildContext context, WidgetRef ref) async {
    if (_isReading) return;

    setState(() {
      _isReading = true;
    });

    try {
      // Use the new visual highlighting TTS service
      await VisualTTSService.readPageWithHighlighting(context, ref);
    } finally {
      if (mounted) {
        setState(() {
          _isReading = false;
        });
      }
    }
  }

  Future<void> _stopReading() async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    await accessibilityNotifier.stopSpeaking();
    
    setState(() {
      _isReading = false;
    });
    _removeProgressOverlay();
  }

}

/// Overlay widget that shows reading progress
class PageReadingProgressOverlay extends StatefulWidget {
  final String content;
  final VoidCallback onClose;

  const PageReadingProgressOverlay({
    super.key,
    required this.content,
    required this.onClose,
  });

  @override
  State<PageReadingProgressOverlay> createState() => _PageReadingProgressOverlayState();
}

class _PageReadingProgressOverlayState extends State<PageReadingProgressOverlay>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    
    _progressController = AnimationController(
      duration: Duration(seconds: _estimateReadingTime(widget.content)),
      vsync: this,
    );
    
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));
    
    // Start the progress animation
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  int _estimateReadingTime(String text) {
    // Estimate reading time based on average speaking speed (150-160 words per minute)
    final wordCount = text.split(' ').length;
    final estimatedSeconds = (wordCount / 2.5).ceil(); // ~150 words per minute
    return estimatedSeconds.clamp(5, 60); // Between 5 and 60 seconds
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.record_voice_over,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pagina wordt voorgelezen...',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(Icons.close),
                      tooltip: 'Stop voorlezen',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Progress bar
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: _progressAnimation.value,
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                          minHeight: 8,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${(_progressAnimation.value * 100).toInt()}% voltooid',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Content preview (first few words)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getContentPreview(widget.content),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Stop button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.onClose,
                    icon: const Icon(Icons.stop),
                    label: const Text('Stop voorlezen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getContentPreview(String content) {
    final words = content.split(' ');
    if (words.length <= 15) return content;
    return '${words.take(15).join(' ')}...';
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
    final isSpeaking = accessibilityState.isSpeaking;

    Widget button = IconButton(
      icon: Icon(
        isSpeaking 
          ? Icons.volume_up 
          : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
        color: isSpeaking 
          ? Colors.green 
          : (isEnabled ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      tooltip: isSpeaking 
        ? 'Stop spraak' 
        : (isEnabled ? 'Spraak uitschakelen' : 'Spraak inschakelen'),
      onPressed: () async {
        if (isSpeaking) {
          await accessibilityNotifier.stopSpeaking();
        } else {
          await accessibilityNotifier.toggleTextToSpeech();
          
          // Test TTS when enabling
          if (!isEnabled) {
            await Future.delayed(const Duration(milliseconds: 100));
            final testText = customTestText ?? 'Spraak is nu ingeschakeld voor dit venster';
            await accessibilityNotifier.speak(testText);
          }
        }
      },
    );

    if (showBackground) {
      button = Container(
        padding: padding ?? const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isSpeaking 
            ? Colors.green.withValues(alpha: 0.1)
            : (isEnabled 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(8),
          border: (isEnabled || isSpeaking)
            ? Border.all(color: (isSpeaking ? Colors.green : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3))
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
    final isSpeaking = accessibilityState.isSpeaking;

    return GestureDetector(
      onTap: () async {
        if (isSpeaking) {
          await accessibilityNotifier.stopSpeaking();
        } else {
          await accessibilityNotifier.toggleTextToSpeech();
          
          // Test TTS when enabling
          if (!isEnabled) {
            await Future.delayed(const Duration(milliseconds: 100));
            final testText = customTestText ?? 'Spraak is nu ingeschakeld voor deze tab';
            await accessibilityNotifier.speak(testText);
          }
        }
      },
      child: Container(
        padding: EdgeInsets.all(isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: isSpeaking 
            ? Colors.green.withValues(alpha: 0.1)
            : (isEnabled 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent),
          borderRadius: BorderRadius.circular(6),
          border: (isEnabled || isSpeaking)
            ? Border.all(color: (isSpeaking ? Colors.green : Theme.of(context).colorScheme.primary).withValues(alpha: 0.3))
            : Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSpeaking 
                ? Icons.volume_up 
                : (isEnabled ? Icons.headphones : Icons.headphones_outlined),
              size: isCompact ? 16 : 20,
              color: isSpeaking 
                ? Colors.green 
                : (isEnabled 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            if (!isCompact) ...[
              const SizedBox(height: 2),
              Text(
                isSpeaking ? 'STOP' : 'TTS',
                style: TextStyle(
                  fontSize: 10,
                  color: isSpeaking 
                    ? Colors.green 
                    : (isEnabled 
                      ? Theme.of(context).colorScheme.primary 
                      : Theme.of(context).colorScheme.onSurfaceVariant),
                  fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
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
