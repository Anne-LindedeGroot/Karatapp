import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../providers/theme_provider.dart';
import '../services/unified_tts_service.dart';

/// Unified TTS Button - One button to rule them all!
/// This button works on ANY page, with ANY content, including popups, forms, and dialogs.
/// It's simple, reliable, and always works.
class UnifiedTTSButton extends ConsumerStatefulWidget {
  final bool showLabel;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const UnifiedTTSButton({
    super.key,
    this.showLabel = false,
    this.margin,
    this.size = 56.0,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  ConsumerState<UnifiedTTSButton> createState() => _UnifiedTTSButtonState();
}

class _UnifiedTTSButtonState extends ConsumerState<UnifiedTTSButton>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final themeState = ref.watch(themeNotifierProvider);
    
    final isEnabled = accessibilityState.isTextToSpeechEnabled;
    final isSpeaking = accessibilityState.isSpeaking;
    final isHighContrast = themeState.isHighContrast;
    
    // Start pulse animation when speaking
    if (isSpeaking && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isSpeaking && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }

    // Use high contrast colors when needed
    final effectiveBackgroundColor = widget.backgroundColor ?? 
        (isSpeaking 
          ? (isHighContrast ? Colors.green.shade700 : Colors.green)
          : (isEnabled 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.secondary));
    
    final effectiveForegroundColor = widget.foregroundColor ?? 
        (isSpeaking || isEnabled 
          ? Theme.of(context).colorScheme.onPrimary 
          : Theme.of(context).colorScheme.onSecondary);

    Widget button = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isSpeaking ? _pulseAnimation.value : 1.0,
          child: FloatingActionButton(
            onPressed: () => _handleTTSAction(context, ref),
            backgroundColor: effectiveBackgroundColor,
            foregroundColor: effectiveForegroundColor,
            // Remove tooltip to avoid overlay issues
            // tooltip: isSpeaking 
            //   ? 'Stop voorlezen' 
            //   : (isEnabled 
            //     ? 'Lees pagina voor' 
            //     : 'Schakel spraak in en lees voor'),
            child: Icon(
              isSpeaking 
                ? Icons.volume_up 
                : (isEnabled 
                    ? (isHighContrast ? Icons.headset_mic : Icons.headphones)
                    : (isHighContrast ? Icons.headset_mic_outlined : Icons.headphones_outlined)),
              size: (widget.size ?? 56.0) * 0.4,
            ),
          ),
        );
      },
    );

    if (widget.showLabel) {
      button = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          button,
          const SizedBox(height: 8),
          Text(
            isSpeaking ? 'Aan het spreken' : (isEnabled ? 'Spraak aan' : 'Spraak uit'),
            style: TextStyle(
              fontSize: 12,
              color: isSpeaking 
                ? Colors.green 
                : (isEnabled 
                  ? Theme.of(context).colorScheme.primary 
                  : Theme.of(context).colorScheme.onSurfaceVariant),
              fontWeight: (isEnabled || isSpeaking) ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.all(16),
      child: button,
    );
  }

  Future<void> _handleTTSAction(BuildContext context, WidgetRef ref) async {
    final accessibilityState = ref.read(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    if (accessibilityState.isSpeaking) {
      // Stop speaking if currently speaking
      debugPrint('UnifiedTTS: Stopping speech');
      await accessibilityNotifier.stopSpeaking();
    } else if (accessibilityState.isTextToSpeechEnabled) {
      // Read all text from current screen
      debugPrint('UnifiedTTS: Reading current screen');
      await UnifiedTTSService.readCurrentScreen(context, ref);
    } else {
      // Enable TTS first, then read content
      debugPrint('UnifiedTTS: Enabling TTS and reading screen');
      await accessibilityNotifier.toggleTextToSpeech();
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        await UnifiedTTSService.readCurrentScreen(context, ref);
      }
    }
  }
}

/// Global TTS overlay that provides the unified TTS button on all screens
class UnifiedTTSOverlay extends ConsumerWidget {
  final Widget child;
  final bool enabled;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showLabel;

  const UnifiedTTSOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.margin,
    this.size = 56.0,
    this.backgroundColor,
    this.foregroundColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTTSButton = ref.watch(showTTSButtonProvider);
    
    if (!enabled || !showTTSButton) {
      return child;
    }

    return Stack(
      children: [
        child,
        Positioned(
          right: margin?.right ?? 0,
          bottom: margin?.bottom ?? 120, // Position above other floating buttons
          child: UnifiedTTSButton(
            showLabel: showLabel,
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            margin: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }
}

/// Helper function to easily add unified TTS to any screen
Widget withUnifiedTTS({
  required Widget child,
  bool enabled = true,
  EdgeInsets? margin,
  double? size = 56.0,
  Color? backgroundColor,
  Color? foregroundColor,
  bool showLabel = false,
}) {
  return Consumer(
    builder: (context, ref, _) {
      final showTTSButton = ref.watch(showTTSButtonProvider);
      
      if (!enabled || !showTTSButton) {
        return child;
      }

      return UnifiedTTSOverlay(
        enabled: enabled,
        margin: margin,
        size: size,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        showLabel: showLabel,
        child: child,
      );
    },
  );
}
