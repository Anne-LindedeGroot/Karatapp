import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../screens/accessibility_settings_screen.dart';

/// A floating accessibility button that provides quick access to accessibility features
class AccessibilityFloatingButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final bool showQuickActions;
  final EdgeInsets? margin;

  const AccessibilityFloatingButton({
    super.key,
    this.onPressed,
    this.showQuickActions = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(
      accessibilityNotifierProvider.notifier,
    );

    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Quick action buttons (when expanded)
          if (showQuickActions) ...[
            // Font size toggle
            _QuickActionButton(
              icon: _getFontSizeIcon(accessibilityState.fontSize),
              label: 'Lettergrootte: ${accessibilityState.fontSizeDescription}',
              onPressed: () => accessibilityNotifier.toggleFontSize(),
              backgroundColor:
                  accessibilityState.fontSize != AccessibilityFontSize.normal
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),

            // Dyslexia toggle
            _QuickActionButton(
              icon: accessibilityState.isDyslexiaFriendly
                  ? Icons.text_format
                  : Icons.font_download,
              label: accessibilityState.isDyslexiaFriendly
                  ? 'Dyslexie uit'
                  : 'Dyslexie aan',
              onPressed: () => accessibilityNotifier.toggleDyslexiaFriendly(),
              backgroundColor: accessibilityState.isDyslexiaFriendly
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),

            // Text-to-speech toggle
            _QuickActionButton(
              icon: accessibilityState.isTextToSpeechEnabled
                  ? Icons.headphones
                  : Icons.headphones_outlined,
              label: accessibilityState.isTextToSpeechEnabled
                  ? 'Spraak uit'
                  : 'Spraak aan',
              onPressed: () => accessibilityNotifier.toggleTextToSpeech(),
              backgroundColor: accessibilityState.isTextToSpeechEnabled
                  ? Theme.of(context).colorScheme.tertiary
                  : Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),
          ],

          // Main accessibility button
          FloatingActionButton(
            onPressed: onPressed ?? () => _showAccessibilitySettings(context),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            child: const Icon(Icons.settings_accessibility, size: 28),
          ),
        ],
      ),
    );
  }

  void _showAccessibilitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccessibilitySettingsScreen(),
      ),
    );
  }

  /// Get appropriate icon for font size
  IconData _getFontSizeIcon(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return Icons.text_decrease;
      case AccessibilityFontSize.normal:
        return Icons.text_fields;
      case AccessibilityFontSize.large:
        return Icons.text_increase;
      case AccessibilityFontSize.extraLarge:
        return Icons.format_size;
    }
  }
}

/// A compact floating accessibility button for minimal UI
class CompactAccessibilityButton extends ConsumerWidget {
  final VoidCallback? onPressed;
  final EdgeInsets? margin;

  const CompactAccessibilityButton({super.key, this.onPressed, this.margin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: margin ?? const EdgeInsets.all(16),
      child: FloatingActionButton.small(
        onPressed: onPressed ?? () => _showAccessibilitySettings(context),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.settings_accessibility, size: 20),
      ),
    );
  }

  void _showAccessibilitySettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AccessibilitySettingsScreen(),
      ),
    );
  }
}

/// Quick action button for accessibility features
class _QuickActionButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(
      accessibilityNotifierProvider.notifier,
    );
    final isTextToSpeechEnabled = ref.watch(isTextToSpeechEnabledProvider);

    return FloatingActionButton.small(
      onPressed: () {
        onPressed();
        // Provide audio feedback if text-to-speech is enabled
        if (isTextToSpeechEnabled) {
          accessibilityNotifier.speak(label);
        }
      },
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.secondary,
      foregroundColor: Theme.of(context).colorScheme.onSecondary,
      tooltip: label,
      child: Icon(icon, size: 20),
    );
  }
}

/// Accessibility toolbar that can be placed at the top or bottom of screens
class AccessibilityToolbar extends ConsumerWidget {
  final bool isVisible;
  final VoidCallback? onToggleVisibility;

  const AccessibilityToolbar({
    super.key,
    this.isVisible = true,
    this.onToggleVisibility,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(
      accessibilityNotifierProvider.notifier,
    );

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Font size button
          _ToolbarButton(
            icon: Icons.text_fields,
            label: accessibilityState.fontSizeDescription,
            isActive:
                accessibilityState.fontSize != AccessibilityFontSize.normal,
            onPressed: () => accessibilityNotifier.toggleFontSize(),
          ),

          // Dyslexia button
          _ToolbarButton(
            icon: Icons.text_format,
            label: 'Dyslexie',
            isActive: accessibilityState.isDyslexiaFriendly,
            onPressed: () => accessibilityNotifier.toggleDyslexiaFriendly(),
          ),

          // Text-to-speech button
          _ToolbarButton(
            icon: Icons.record_voice_over,
            label: 'Spraak',
            isActive: accessibilityState.isTextToSpeechEnabled,
            onPressed: () => accessibilityNotifier.toggleTextToSpeech(),
          ),

          // Settings button
          _ToolbarButton(
            icon: Icons.settings,
            label: 'Instellingen',
            isActive: false,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const AccessibilitySettingsScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual button for the accessibility toolbar
class _ToolbarButton extends ConsumerWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityNotifier = ref.read(
      accessibilityNotifierProvider.notifier,
    );
    final isTextToSpeechEnabled = ref.watch(isTextToSpeechEnabledProvider);

    return InkWell(
      onTap: () {
        onPressed();
        // Provide audio feedback if text-to-speech is enabled
        if (isTextToSpeechEnabled) {
          accessibilityNotifier.speak(label);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: isActive
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
