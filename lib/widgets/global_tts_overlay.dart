import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'global_floating_tts_button.dart';
import '../providers/accessibility_provider.dart';

/// Global TTS overlay that provides a floating TTS button on all screens
class GlobalTTSOverlay extends ConsumerWidget {
  final Widget child;
  final bool enabled;
  final FloatingActionButtonLocation? location;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showLabel;

  const GlobalTTSOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.location,
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
          bottom: margin?.bottom ?? 120, // Position above plus button with spacing
          child: GlobalFloatingTTSButton(
            showLabel: showLabel,
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
          ),
        ),
      ],
    );
  }
}

/// Provider to control global TTS overlay visibility
final globalTTSOverlayProvider = StateProvider<bool>((ref) => true);

/// Hook to easily add global TTS to any screen
Widget withGlobalTTS({
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
      final isEnabled = ref.watch(globalTTSOverlayProvider);
      final showTTSButton = ref.watch(showTTSButtonProvider);
      
      if (!isEnabled || !enabled || !showTTSButton) {
        return child;
      }

      return GlobalTTSOverlay(
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