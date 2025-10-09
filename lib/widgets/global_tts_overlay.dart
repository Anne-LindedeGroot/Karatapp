import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'unified_tts_button.dart';
import '../providers/accessibility_provider.dart';
import '../services/unified_tts_service.dart';

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
    this.size = 56.0, // Same size as FAB for consistency
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

    return Directionality(
      textDirection: TextDirection.ltr, // Explicitly set text direction
      child: Stack(
        children: [
          child,
        Positioned(
          right: _calculateRightPosition(context),
          bottom: _calculateBottomPosition(context),
          child: UnifiedTTSButton(
            showLabel: showLabel,
            size: size,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            margin: const EdgeInsets.all(8),
          ),
        ),
        ],
      ),
    );
  }

  /// Calculate bottom position to avoid conflicts with other UI elements
  double _calculateBottomPosition(BuildContext context) {
    // Use MediaQuery to get screen dimensions for center positioning
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    
    // Position TTS button in middle-right area of screen
    // Calculate middle-right position: 20% from bottom (more down middle right)
    final middleRightPosition = screenHeight * 0.2;
    
    return (margin?.bottom ?? middleRightPosition);
  }

  /// Calculate right position to place TTS button on the right side
  double _calculateRightPosition(BuildContext context) {
    // Position TTS button more to the right for better appearance
    // Closer to the right edge: 8px from right edge
    return (margin?.right ?? 8);
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