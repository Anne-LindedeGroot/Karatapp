import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';

class AccessibilitySettingsPopup extends ConsumerWidget {
  const AccessibilitySettingsPopup({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Combined accessibility settings popup
          PopupMenuButton<String>(
            icon: Icon(
              Icons.text_fields,
              color: (accessibilityState.fontSize != AccessibilityFontSize.normal ||
                      accessibilityState.isDyslexiaFriendly)
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            tooltip: 'Tekst instellingen',
            constraints: BoxConstraints(
              minWidth: accessibilityState.fontSize == AccessibilityFontSize.extraLarge ||
                      accessibilityState.isDyslexiaFriendly
                  ? 320
                  : 280,
            ),
            itemBuilder: (context) => [
              // Font size section
              PopupMenuItem<String>(
                enabled: false,
                child: Text(
                  'Lettergrootte',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ),
              ...AccessibilityFontSize.values.map((fontSize) {
                final isSelected = accessibilityState.fontSize == fontSize;
                return PopupMenuItem<String>(
                  value: 'font_${fontSize.name}',
                  child: Row(
                    children: [
                      Icon(
                        _getFontSizeIcon(fontSize),
                        size: 20,
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        fontSize == AccessibilityFontSize.small
                            ? 'Klein'
                            : fontSize == AccessibilityFontSize.normal
                                ? 'Normaal'
                                : fontSize == AccessibilityFontSize.large
                                    ? 'Groot'
                                    : 'Extra Groot',
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        Icon(
                          Icons.check,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    ],
                  ),
                );
              }),
              const PopupMenuDivider(),
              // Dyslexia toggle
              PopupMenuItem<String>(
                value: 'toggle_dyslexia',
                child: Row(
                  children: [
                    Icon(
                      accessibilityState.isDyslexiaFriendly
                          ? Icons.format_line_spacing
                          : Icons.format_line_spacing_outlined,
                      size: 18,
                      color: accessibilityState.isDyslexiaFriendly
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'dyslexie\nvriendelijk',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.scale(
                      scale: 0.7,
                      child: Switch(
                        value: accessibilityState.isDyslexiaFriendly,
                        onChanged: (value) {
                          accessibilityNotifier.toggleDyslexiaFriendly();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (String value) {
              if (value.startsWith('font_')) {
                final fontSizeName = value.substring(5);
                final fontSize = AccessibilityFontSize.values.firstWhere(
                  (size) => size.name == fontSizeName,
                );
                accessibilityNotifier.setFontSize(fontSize);
              } else if (value == 'toggle_dyslexia') {
                accessibilityNotifier.toggleDyslexiaFriendly();
              }
            },
          ),
        ],
      ),
    );
  }
}
