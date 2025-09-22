import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/accessibility_provider.dart';
import '../widgets/accessible_text.dart';

class AccessibilitySettingsScreen extends ConsumerWidget {
  const AccessibilitySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessibilityState = ref.watch(accessibilityNotifierProvider);
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const AccessibleText(
          'Toegankelijkheid',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    const AccessibleText(
                      'Toegankelijkheidsinstellingen',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 8),
                    const AccessibleText(
                      'Pas de app aan voor betere leesbaarheid en toegankelijkheid.',
                      style: TextStyle(fontSize: 14),
                      enableTextToSpeech: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Font Size Section
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
                        const Expanded(
                          child: AccessibleText(
                            'Lettergrootte',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Font size options
                    Column(
                      children: AccessibilityFontSize.values.map((fontSize) {
                        final isSelected = accessibilityState.fontSize == fontSize;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                            color: isSelected ? Theme.of(context).colorScheme.primary : null,
                          ),
                          title: AccessibleText(
                            fontSize.fontSizeDescription,
                            style: TextStyle(
                              fontSize: _getFontSizeForDemo(fontSize),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            enableTextToSpeech: true,
                          ),
                          subtitle: AccessibleText(
                            'Voorbeeld tekst in ${fontSize.fontSizeDescription.toLowerCase()} lettertype',
                            style: TextStyle(
                              fontSize: _getFontSizeForDemo(fontSize) * 0.8,
                            ),
                          ),
                          onTap: () => accessibilityNotifier.setFontSize(fontSize),
                        );
                      }).toList(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Quick toggle button
                    SizedBox(
                      width: double.infinity,
                      child: AccessibleButton(
                        text: 'Wissel tussen Normaal en Groot',
                        icon: const Icon(Icons.swap_horiz),
                        enableTextToSpeech: true,
                        onPressed: () => accessibilityNotifier.toggleFontSize(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Dyslexia-friendly Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            'Dyslexie-vriendelijke tekst',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AccessibleText(
                      'Verbetert de leesbaarheid voor mensen met dyslexie door extra ruimte tussen letters en regels.',
                      style: TextStyle(fontSize: 14),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const AccessibleText(
                        'Dyslexie-vriendelijke modus',
                        enableTextToSpeech: true,
                      ),
                      subtitle: AccessibleText(
                        accessibilityState.isDyslexiaFriendly 
                            ? 'Ingeschakeld - Extra ruimte tussen tekst'
                            : 'Uitgeschakeld - Normale tekstopmaak',
                        enableTextToSpeech: true,
                      ),
                      value: accessibilityState.isDyslexiaFriendly,
                      onChanged: (value) => accessibilityNotifier.setDyslexiaFriendly(value),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Example text
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
                            'Voorbeeld:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          AccessibleText(
                            'Dit is een voorbeeld van hoe tekst eruitziet met de dyslexie-vriendelijke instellingen. De letters hebben meer ruimte en zijn makkelijker te lezen.',
                            enableTextToSpeech: true,
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
                        const Expanded(
                          child: AccessibleText(
                            'Tekst voorlezen',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            enableTextToSpeech: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const AccessibleText(
                      'Laat de app tekst hardop voorlezen. Tik op tekst met een speaker-icoon om het te laten voorlezen.',
                      style: TextStyle(fontSize: 14),
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
                          onPressed: () => accessibilityNotifier.speak(
                            'Dit is een test van de spraakfunctie. Hallo, dit is hoe de app klinkt.',
                          ),
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
                        const Expanded(
                          child: AccessibleText(
                            'Snelle toegang',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  double _getFontSizeForDemo(AccessibilityFontSize fontSize) {
    switch (fontSize) {
      case AccessibilityFontSize.small:
        return 12.0;
      case AccessibilityFontSize.normal:
        return 14.0;
      case AccessibilityFontSize.large:
        return 17.0;
      case AccessibilityFontSize.extraLarge:
        return 21.0;
    }
  }
}
