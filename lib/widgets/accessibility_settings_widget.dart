import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import 'accessible_text.dart';

/// A compact accessibility settings widget that can be embedded in other screens
class AccessibilitySettingsWidget extends ConsumerWidget {
  final bool showTitle;
  final bool isCompact;

  const AccessibilitySettingsWidget({
    super.key,
    this.showTitle = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Row(
                children: [
                  Icon(
                    Icons.settings_accessibility,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: AccessibleText(
                      'Toegankelijkheidsinstellingen',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      enableTextToSpeech: true,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.pushNamed(context, '/accessibility_settings');
                    },
                    tooltip: 'Meer instellingen',
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Font size controls - More responsive layout
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 400;
                return isWide
                    ? Row(
                        children: [
                          const Icon(Icons.text_fields, size: 18),
                          const SizedBox(width: 6),
                          const Expanded(
                            flex: 2,
                            child: AccessibleText(
                              'Lettergrootte:',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                              enableTextToSpeech: true,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: AccessibleText(
                              accessibilityState.fontSizeDescription,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              enableTextToSpeech: true,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                final currentIndex = AccessibilityFontSize.values.indexOf(accessibilityState.fontSize);
                                if (currentIndex > 0) {
                                  accessibilityNotifier.setFontSize(AccessibilityFontSize.values[currentIndex - 1]);
                                }
                              },
                              tooltip: 'Kleinere tekst',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                final currentIndex = AccessibilityFontSize.values.indexOf(accessibilityState.fontSize);
                                if (currentIndex < AccessibilityFontSize.values.length - 1) {
                                  accessibilityNotifier.setFontSize(AccessibilityFontSize.values[currentIndex + 1]);
                                }
                              },
                              tooltip: 'Grotere tekst',
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.text_fields, size: 18),
                              const SizedBox(width: 6),
                              const Expanded(
                                child: AccessibleText(
                                  'Lettergrootte:',
                                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                  enableTextToSpeech: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const SizedBox(width: 24),
                              Expanded(
                                child: AccessibleText(
                                  accessibilityState.fontSizeDescription,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                  enableTextToSpeech: true,
                                  overflow: TextOverflow.visible,
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () {
                                    final currentIndex = AccessibilityFontSize.values.indexOf(accessibilityState.fontSize);
                                    if (currentIndex > 0) {
                                      accessibilityNotifier.setFontSize(AccessibilityFontSize.values[currentIndex - 1]);
                                    }
                                  },
                                  tooltip: 'Kleinere tekst',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () {
                                    final currentIndex = AccessibilityFontSize.values.indexOf(accessibilityState.fontSize);
                                    if (currentIndex < AccessibilityFontSize.values.length - 1) {
                                      accessibilityNotifier.setFontSize(AccessibilityFontSize.values[currentIndex + 1]);
                                    }
                                  },
                                  tooltip: 'Grotere tekst',
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
              },
            ),

            if (!isCompact) ...[
              const SizedBox(height: 12),
              
              // Dyslexia-friendly toggle
              Row(
                children: [
                  const Icon(Icons.text_format, size: 18),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: AccessibleText(
                      'dyslexie vriendelijk',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      enableTextToSpeech: true,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: accessibilityState.isDyslexiaFriendly,
                      onChanged: (value) => accessibilityNotifier.setDyslexiaFriendly(value),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Text-to-speech controls
            Row(
              children: [
                Icon(
                  accessibilityState.isTextToSpeechEnabled 
                      ? Icons.volume_up 
                      : Icons.volume_off,
                  size: 18,
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: AccessibleText(
                    'Tekst voorlezen',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                    enableTextToSpeech: true,
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: accessibilityState.isTextToSpeechEnabled,
                    onChanged: (value) => accessibilityNotifier.setTextToSpeechEnabled(value),
                  ),
                ),
              ],
            ),

            if (accessibilityState.isTextToSpeechEnabled && !isCompact) ...[
              const SizedBox(height: 12),
              
              // Headphones toggle
              Row(
                children: [
                  Icon(
                    accessibilityState.useHeadphones 
                        ? Icons.headphones 
                        : Icons.speaker,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: AccessibleText(
                      'Gebruik koptelefoon',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                      enableTextToSpeech: true,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch(
                      value: accessibilityState.useHeadphones,
                      onChanged: (value) => accessibilityNotifier.setUseHeadphones(value),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Test button
              SizedBox(
                width: double.infinity,
                child: AccessibleButton(
                  text: 'Test spraakfunctie',
                  icon: const Icon(Icons.play_arrow),
                  isElevated: false,
                  onPressed: () => accessibilityNotifier.speak(
                    'Dit is een test van de spraakfunctie. De tekst wordt nu voorgelezen.',
                  ),
                ),
              ),
            ],

            if (isCompact && accessibilityState.isTextToSpeechEnabled) ...[
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 300;
                  return isWide
                      ? Row(
                          children: [
                            Expanded(
                              child: AccessibleButton(
                                text: 'Test spraak',
                                icon: const Icon(Icons.play_arrow),
                                isElevated: false,
                                onPressed: () => accessibilityNotifier.speak(
                                  'Test van de spraakfunctie.',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: AccessibleButton(
                                text: accessibilityState.useHeadphones ? 'Luidspreker' : 'Koptelefoon',
                                icon: Icon(accessibilityState.useHeadphones ? Icons.speaker : Icons.headphones),
                                isElevated: false,
                                onPressed: () => accessibilityNotifier.toggleUseHeadphones(),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            AccessibleButton(
                              text: 'Test spraak',
                              icon: const Icon(Icons.play_arrow),
                              isElevated: false,
                              onPressed: () => accessibilityNotifier.speak(
                                'Test van de spraakfunctie.',
                              ),
                            ),
                            const SizedBox(height: 8),
                            AccessibleButton(
                              text: accessibilityState.useHeadphones ? 'Luidspreker' : 'Koptelefoon',
                              icon: Icon(accessibilityState.useHeadphones ? Icons.speaker : Icons.headphones),
                              isElevated: false,
                              onPressed: () => accessibilityNotifier.toggleUseHeadphones(),
                            ),
                          ],
                        );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A floating accessibility button that provides quick access to common settings
class AccessibilityQuickActions extends ConsumerWidget {
  const AccessibilityQuickActions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Font size toggle
            IconButton(
              icon: const Icon(Icons.text_fields),
              onPressed: () => accessibilityNotifier.toggleFontSize(),
              tooltip: 'Wissel lettergrootte',
            ),
            
            // Dyslexia toggle
            IconButton(
              icon: Icon(
                accessibilityState.isDyslexiaFriendly 
                    ? Icons.text_format 
                    : Icons.font_download,
              ),
              onPressed: () => accessibilityNotifier.toggleDyslexiaFriendly(),
              tooltip: 'Wissel dyslexie vriendelijk',
            ),
            
            // TTS toggle
            IconButton(
              icon: Icon(
                accessibilityState.isTextToSpeechEnabled 
                    ? Icons.volume_up 
                    : Icons.volume_off,
              ),
              onPressed: () => accessibilityNotifier.toggleTextToSpeech(),
              tooltip: 'Wissel tekst voorlezen',
            ),
            
            // Headphones toggle (only show if TTS is enabled)
            if (accessibilityState.isTextToSpeechEnabled)
              IconButton(
                icon: Icon(
                  accessibilityState.useHeadphones 
                      ? Icons.headphones 
                      : Icons.speaker,
                ),
                onPressed: () => accessibilityNotifier.toggleUseHeadphones(),
                tooltip: 'Wissel audio uitgang',
              ),
          ],
        ),
      ),
    );
  }
}
