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
          child: _buildStableTTSButton(context, ref),
        ),
        ],
      ),
    );
  }

  /// Build a stable TTS button without animations
  Widget _buildStableTTSButton(BuildContext context, WidgetRef ref) {
    return Semantics(
      label: 'Text to speech knop',
      button: true,
      child: FloatingActionButton(
        heroTag: "global_tts_fab",
        onPressed: () async {
          // Use the unified TTS service to read current screen content
          await UnifiedTTSService.readCurrentScreen(context, ref);
        },
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
        foregroundColor: foregroundColor ?? Colors.white,
        child: const Icon(Icons.volume_up),
      ),
    );
  }

  /// Calculate bottom position to avoid conflicts with other UI elements
  double _calculateBottomPosition(BuildContext context) {
    // Check if there are floating action buttons
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.floatingActionButton != null) {
      // Position much higher above FAB with generous spacing (FAB is typically 56px + 16px margin = 72px from bottom)
      // We want the TTS button to be well above it with plenty of clearance
      return (margin?.bottom ?? 16); // Same level as FAB for horizontal alignment
    }
    
    // Check for bottom navigation bar
    if (scaffold?.bottomNavigationBar != null) {
      return (margin?.bottom ?? 80) + 20; // Position above bottom nav
    }
    
    // Default position
    return margin?.bottom ?? 80;
  }

  /// Calculate right position to place TTS button above FAB
  double _calculateRightPosition(BuildContext context) {
    // Check if there are floating action buttons
    final scaffold = context.findAncestorWidgetOfExactType<Scaffold>();
    if (scaffold?.floatingActionButton != null) {
      // Perfect vertical alignment with FAB - both buttons should be at exactly the same horizontal position
      // FAB with FloatingActionButtonLocation.endDocked is positioned at 16px from right edge
      return (margin?.right ?? 0); // Position to the left of FAB for horizontal layout
    }
    
    // Default position
    return margin?.right ?? 0;
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