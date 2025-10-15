import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'unified_tts_button.dart';
import '../providers/accessibility_provider.dart';

/// Global TTS overlay that provides a floating TTS button on all screens, dialogs, and popups
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
    this.size = 40.0, // Smaller, more compact size
    this.backgroundColor,
    this.foregroundColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final showTTSButton = ref.watch(showTTSButtonProvider);
      
      if (!enabled || !showTTSButton) {
        return child;
      }

      // Use a safer approach that doesn't rely on Stack positioning
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only render if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return child;
          }
          
          // Calculate safe positioning
          final buttonSize = 56.0;
          final rightMargin = 8.0;
          final bottomMargin = 120.0;
          
          // Ensure button fits within available space
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          
          if (buttonSize + rightMargin > availableWidth || 
              buttonSize + bottomMargin > availableHeight) {
            return child;
          }
          
          // Use a more stable approach with proper constraints and clip behavior
          return Stack(
            clipBehavior: Clip.hardEdge, // Use hard edge clipping to prevent overflow
            children: [
              child,
              // Position the TTS button safely with proper constraints
              Positioned(
                right: rightMargin,
                bottom: bottomMargin,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: buttonSize,
                    maxWidth: buttonSize,
                    minHeight: buttonSize,
                    maxHeight: buttonSize,
                  ),
                  child: UnifiedTTSButton(
                    showLabel: showLabel,
                    size: buttonSize,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // If there's any error in the TTS overlay, just return the child
      debugPrint('Error in GlobalTTSOverlay: $e');
      return child;
    }
  }
}

/// Dialog-aware TTS overlay that works specifically in dialogs and popups
class DialogTTSOverlay extends ConsumerWidget {
  final Widget child;
  final bool enabled;
  final EdgeInsets? margin;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool showLabel;

  const DialogTTSOverlay({
    super.key,
    required this.child,
    this.enabled = true,
    this.margin,
    this.size = 40.0,
    this.backgroundColor,
    this.foregroundColor,
    this.showLabel = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final showTTSButton = ref.watch(showTTSButtonProvider);
      
      if (!enabled || !showTTSButton) {
        return child;
      }

      // For dialogs, use a safer approach that doesn't rely on Stack positioning
      return LayoutBuilder(
        builder: (context, constraints) {
          // Only render if we have valid constraints
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return child;
          }
          
          // Calculate safe positioning for dialog
          final buttonSize = 48.0;
          final topMargin = 8.0;
          final rightMargin = 8.0;
          
          // Ensure button fits within available space
          final availableWidth = constraints.maxWidth;
          final availableHeight = constraints.maxHeight;
          
          if (buttonSize + rightMargin > availableWidth || 
              buttonSize + topMargin > availableHeight) {
            return child;
          }
          
          // Use a more stable approach with proper constraints and clip behavior
          return Stack(
            clipBehavior: Clip.hardEdge, // Use hard edge clipping to prevent overflow
            children: [
              child,
              // Position the TTS button safely in top-right corner with proper constraints
              Positioned(
                top: topMargin,
                right: rightMargin,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: buttonSize,
                    maxWidth: buttonSize,
                    minHeight: buttonSize,
                    maxHeight: buttonSize,
                  ),
                  child: UnifiedTTSButton(
                    showLabel: false, // Don't show label in dialogs to save space
                    size: buttonSize,
                    backgroundColor: backgroundColor,
                    foregroundColor: foregroundColor,
                    margin: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // If there's any error in the dialog TTS overlay, just return the child
      debugPrint('Error in DialogTTSOverlay: $e');
      return child;
    }
  }
}

/// Provider to control global TTS overlay visibility
final globalTTSOverlayProvider = StateProvider<bool>((ref) => true);

/// Hook to easily add global TTS to any screen
/// Note: This is now optional since TTS is globally available through main.dart
Widget withGlobalTTS({
  required Widget child,
  bool enabled = true,
  EdgeInsets? margin,
  double? size = 40.0,
  Color? backgroundColor,
  Color? foregroundColor,
  bool showLabel = false,
}) {
  // Since TTS is now globally available, just return the child
  // This function is kept for backward compatibility
  return child;
}