import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/accessible_text.dart';
import '../widgets/enhanced_accessible_text.dart';
import '../utils/responsive_utils.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: AccessibleText(
          'Toegankelijkheid',
          style: TextStyle(
            fontSize: context.responsiveValue(mobile: 20.0, tablet: 22.0, desktop: 24.0),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'Toegankelijkheidsinstellingen',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                        fontWeight: FontWeight.bold,
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 8),
                    AccessibleText(
                      'Pas de app aan voor betere leesbaarheid en toegankelijkheid.',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
                      enableTextToSpeech: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Combined Font Settings Section (same as forum/home)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AccessibleText(
                            'Tekst instellingen',
                            style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                        fontWeight: FontWeight.w600,
                      ),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AccessibleText(
                      'Pas de lettergrootte en dyslexie vriendelijke instellingen aan.',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 16),

                    // Combined accessibility settings popup (same as forum/home)
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: PopupMenuButton<String>(
                        position: PopupMenuPosition.under,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Icon(
                                Icons.text_fields,
                                color: (accessibilityState.fontSize != AccessibilityFontSize.normal ||
                                       accessibilityState.isDyslexiaFriendly)
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AccessibleText(
                                      'Lettergrootte: ${accessibilityState.fontSizeDescription}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    AccessibleText(
                                      accessibilityState.isDyslexiaFriendly
                                          ? 'Dyslexie vriendelijk: Aan'
                                          : 'Dyslexie vriendelijk: Uit',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
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
                                    color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    fontSize == AccessibilityFontSize.small ? 'Klein' :
                                    fontSize == AccessibilityFontSize.normal ? 'Normaal' :
                                    fontSize == AccessibilityFontSize.large ? 'Groot' : 'Extra Groot',
                                    style: TextStyle(
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Theme.of(context).colorScheme.primary : null,
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
                            child: SizedBox(
                              width: 280, // Fixed width to prevent overflow
                              child: Row(
                                children: [
                                  Icon(
                                    accessibilityState.isDyslexiaFriendly
                                        ? Icons.format_line_spacing
                                        : Icons.format_line_spacing_outlined,
                                    size: 18, // Slightly smaller icon
                                    color: accessibilityState.isDyslexiaFriendly
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                                  const SizedBox(width: 8), // Reduced spacing
                                  Expanded(
                                    child: Text(
                                      'dyslexie vriendelijk', // No hyphen for better dyslexie friendly display
                                      style: const TextStyle(
                                        fontSize: 14, // Smaller font size
                                        fontWeight: FontWeight.w500,
                                      ),
                                      // Show full text without truncation
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Transform.scale(
                                    scale: 0.7, // Smaller switch
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
                    ),

                    const SizedBox(height: 16),

                    // Example text section
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AccessibleText(
                            'Voorbeeld tekst:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          EnhancedAccessibleText(
                            'Dit is een voorbeeld van hoe tekst eruitziet met de huidige instellingen. De lettergrootte en dyslexie vriendelijke instellingen zijn hier zichtbaar.',
                            enableTTS: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Text-to-Speech Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.record_voice_over,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AccessibleText(
                            'Tekst voorlezen',
                            style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                        fontWeight: FontWeight.w600,
                      ),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AccessibleText(
                      'Laat de app tekst hardop voorlezen. Tik op tekst met een speaker-icoon om het te laten voorlezen.',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const AccessibleText(
                        'Tekst voorlezen inschakelen',
                        enableTextToSpeech: true,
                      ),
                      subtitle: AccessibleText(
                        accessibilityState.isTextToSpeechEnabled 
                            ? 'Ingeschakeld - Tik op tekst om te laten voorlezen'
                            : 'Uitgeschakeld - Geen spraakfunctie',
                        enableTextToSpeech: true,
                      ),
                      value: accessibilityState.isTextToSpeechEnabled,
                      onChanged: (value) => accessibilityNotifier.setTextToSpeechEnabled(value),
                    ),
                    
                    if (accessibilityState.isTextToSpeechEnabled) ...[
                      const SizedBox(height: 8),
                      
                      // Headphones option
                      SwitchListTile(
                        title: const AccessibleText(
                          'Gebruik koptelefoon/headset',
                          enableTextToSpeech: true,
                        ),
                        subtitle: AccessibleText(
                          accessibilityState.useHeadphones 
                              ? 'Audio wordt afgespeeld via koptelefoon/headset'
                              : 'Audio wordt afgespeeld via apparaat speakers',
                          enableTextToSpeech: true,
                        ),
                        value: accessibilityState.useHeadphones,
                        onChanged: (value) => accessibilityNotifier.setUseHeadphones(value),
                      ),
                    ],
                    
                    if (accessibilityState.isTextToSpeechEnabled) ...[
                      const SizedBox(height: 16),
                      
                      // Speech rate slider
                      const AccessibleText(
                        'Spreeksnelheid:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                        enableTextToSpeech: true,
                      ),
                      Slider(
                        value: accessibilityState.speechRate,
                        min: 0.1,
                        max: 1.0,
                        divisions: 9,
                        label: '${(accessibilityState.speechRate * 100).round()}%',
                        onChanged: (value) => accessibilityNotifier.setSpeechRate(value),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Speech pitch slider
                      const AccessibleText(
                        'Toonhoogte:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                        enableTextToSpeech: true,
                      ),
                      Slider(
                        value: accessibilityState.speechPitch,
                        min: 0.5,
                        max: 2.0,
                        divisions: 15,
                        label: accessibilityState.speechPitch.toStringAsFixed(1),
                        onChanged: (value) => accessibilityNotifier.setSpeechPitch(value),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Test button
                      SizedBox(
                        width: double.infinity,
                        child: AccessibleButton(
                          text: 'Test spraakfunctie',
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () async {
                            // Only speak if TTS is enabled
                            if (accessibilityState.isTextToSpeechEnabled) {
                              await accessibilityNotifier.speak(
                                'Dit is een test van de spraakfunctie. Hallo, dit is hoe de app klinkt.',
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Spraak is uitgeschakeld. Schakel spraak eerst in om te testen.'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick Access Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.speed,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AccessibleText(
                            'Snelle toegang',
                            style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                        fontWeight: FontWeight.w600,
                      ),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AccessibleButton(
                            text: 'Grote tekst',
                            icon: const Icon(Icons.text_increase),
                            enableTextToSpeech: true,
                            onPressed: () => accessibilityNotifier.setFontSize(AccessibilityFontSize.large),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AccessibleButton(
                            text: 'Normale tekst',
                            icon: const Icon(Icons.text_decrease),
                            enableTextToSpeech: true,
                            onPressed: () => accessibilityNotifier.setFontSize(AccessibilityFontSize.normal),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AccessibleButton(
                            text: accessibilityState.isDyslexiaFriendly ? 'Dyslexie uit' : 'Dyslexie aan',
                            icon: Icon(accessibilityState.isDyslexiaFriendly ? Icons.text_format : Icons.font_download),
                            enableTextToSpeech: true,
                            onPressed: () => accessibilityNotifier.toggleDyslexiaFriendly(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AccessibleButton(
                            text: accessibilityState.isTextToSpeechEnabled ? 'Spraak uit' : 'Spraak aan',
                            icon: Icon(accessibilityState.isTextToSpeechEnabled ? Icons.volume_up : Icons.volume_off),
                            enableTextToSpeech: true,
                            onPressed: () => accessibilityNotifier.toggleTextToSpeech(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Info section
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AccessibleText(
                            'Informatie',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    AccessibleText(
                      'Deze instellingen helpen mensen met dyslexie en andere leesmoeilijkheden. '
                      'De instellingen worden automatisch opgeslagen en toegepast in de hele app.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      enableTextToSpeech: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
