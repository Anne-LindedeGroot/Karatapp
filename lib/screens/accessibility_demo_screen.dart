import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/accessible_text.dart';
import '../providers/accessibility_provider.dart';
import '../utils/responsive_utils.dart';
import '../core/navigation/app_router.dart';

class AccessibilityDemoScreen extends ConsumerWidget {
  const AccessibilityDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: AccessibleText(
          'Toegankelijkheid Demo',
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
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'Welkom bij de Karate App!',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 24.0, tablet: 28.0, desktop: 32.0),
                        fontWeight: FontWeight.bold,
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 8),
                    AccessibleText(
                      'Deze app is ontworpen om toegankelijk te zijn voor iedereen, inclusief mensen met dyslexie en andere leesmoeilijkheden.',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                      ),
                      enableTextToSpeech: true,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Features section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'Toegankelijkheidsfuncties:',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                        fontWeight: FontWeight.w600,
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 12),
                    
                    _FeatureItem(
                      icon: Icons.text_fields,
                      title: 'Aanpasbare lettergrootte',
                      description: 'Maak tekst groter of kleiner voor betere leesbaarheid.',
                    ),
                    
                    _FeatureItem(
                      icon: Icons.text_format,
                      title: 'Dyslexie-vriendelijke tekst',
                      description: 'Extra ruimte tussen letters en regels voor mensen met dyslexie.',
                    ),
                    
                    _FeatureItem(
                      icon: Icons.record_voice_over,
                      title: 'Tekst voorlezen',
                      description: 'Laat de app tekst hardop voorlezen. Tik op tekst met een speaker-icoon.',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Example content
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'Voorbeeld inhoud',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                        fontWeight: FontWeight.w600,
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 12),
                    
                    AccessibleText(
                      'Karate is een traditionele Japanse vechtsport die zich richt op zelfverdediging, discipline en persoonlijke ontwikkeling. Het woord "karate" betekent letterlijk "lege hand", wat verwijst naar het feit dat karateka\'s geen wapens gebruiken.',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
                      enableTextToSpeech: true,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    AccessibleText(
                      'Belangrijke principes:',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                        fontWeight: FontWeight.w500,
                      ),
                      enableTextToSpeech: true,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    _PrincipleItem('Respect voor anderen en jezelf'),
                    _PrincipleItem('Discipline en zelfbeheersing'),
                    _PrincipleItem('Voortdurende verbetering (Kaizen)'),
                    _PrincipleItem('Nederigheid en bescheidenheid'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Interactive buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AccessibleText(
                      'Probeer de knoppen:',
                      style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                        fontWeight: FontWeight.w600,
                      ),
                      enableTextToSpeech: true,
                    ),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: AccessibleButton(
                            text: 'Lees voor',
                            icon: const Icon(Icons.volume_up),
                            enableTextToSpeech: true,
                            onPressed: () {
                              ref.read(accessibilityNotifierProvider.notifier).speak(
                                'Dit is een test van de spraakfunctie. De app kan tekst voorlezen voor mensen die moeite hebben met lezen.',
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AccessibleButton(
                            text: 'Stop spraak',
                            icon: const Icon(Icons.stop),
                            enableTextToSpeech: true,
                            onPressed: () {
                              ref.read(accessibilityNotifierProvider.notifier).stopSpeaking();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 80), // Space for floating button
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccessibleText(
                  title,
                  style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 16.0, tablet: 17.0, desktop: 18.0),
                        fontWeight: FontWeight.w500,
                      ),
                  enableTextToSpeech: true,
                ),
                const SizedBox(height: 4),
                AccessibleText(
                  description,
                  style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
                  enableTextToSpeech: true,
                ),
              ],
            ),
          ),
          
          // TTS Test Button
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AccessibleText(
                    'Test TTS in Popups',
                    style: TextStyle(
                      fontSize: context.responsiveValue(mobile: 18.0, tablet: 20.0, desktop: 22.0),
                      fontWeight: FontWeight.bold,
                    ),
                    enableTextToSpeech: true,
                  ),
                  const SizedBox(height: 8),
                  AccessibleText(
                    'Test de TTS functionaliteit in popups en dialogen. Klik op de knop hieronder om verschillende dialogen te openen en te testen of de tekst correct wordt voorgelezen.',
                    style: TextStyle(
                      fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                    ),
                    enableTextToSpeech: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.ttsTest),
                      icon: const Icon(Icons.record_voice_over),
                      label: const Text('Test TTS Popups'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrincipleItem extends StatelessWidget {
  final String text;

  const _PrincipleItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: AccessibleText(
              text,
              style: TextStyle(
                        fontSize: context.responsiveValue(mobile: 14.0, tablet: 15.0, desktop: 16.0),
                      ),
              enableTextToSpeech: true,
            ),
          ),
        ],
      ),
    );
  }
}
