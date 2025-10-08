import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/accessible_text.dart';
import 'widgets/enhanced_accessible_text.dart';
import 'widgets/unified_tts_button.dart';
import 'providers/accessibility_provider.dart';
import 'services/unified_tts_service.dart';

/// Comprehensive TTS Test Screen
/// This screen tests the enhanced TTS functionality across different UI components
class ComprehensiveTTSTestScreen extends ConsumerStatefulWidget {
  const ComprehensiveTTSTestScreen({super.key});

  @override
  ConsumerState<ComprehensiveTTSTestScreen> createState() => _ComprehensiveTTSTestScreenState();
}

class _ComprehensiveTTSTestScreenState extends ConsumerState<ComprehensiveTTSTestScreen> {
  final TextEditingController _testController = TextEditingController();
  bool _showDialog = false;
  bool _showBottomSheet = false;

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  void _showTestDialog() {
    setState(() {
      _showDialog = true;
    });
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Dialog'),
        content: const Text(
          'Dit is een test dialog om te controleren of de TTS functionaliteit werkt in pop-ups en dialogen. '
          'De TTS knop zou alle tekst in deze dialog moeten kunnen voorlezen in het Nederlands.'
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _showDialog = false;
              });
              Navigator.pop(context);
            },
            child: const Text('Sluiten'),
          ),
          ElevatedButton(
            onPressed: () {
              // Test TTS in dialog
              UnifiedTTSService.readText(context, ref, 'Test knop ingedrukt in dialog');
            },
            child: const Text('Test TTS'),
          ),
        ],
      ),
    ).then((_) {
      setState(() {
        _showDialog = false;
      });
    });
  }

  void _showTestBottomSheet() {
    setState(() {
      _showBottomSheet = true;
    });
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Test Bottom Sheet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Dit is een test bottom sheet om te controleren of de TTS functionaliteit werkt in modale sheets. '
              'De TTS knop zou alle tekst in deze sheet moeten kunnen voorlezen.'
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    UnifiedTTSService.readText(context, ref, 'Eerste test knop in bottom sheet');
                  },
                  child: const Text('Test 1'),
                ),
                ElevatedButton(
                  onPressed: () {
                    UnifiedTTSService.readText(context, ref, 'Tweede test knop in bottom sheet');
                  },
                  child: const Text('Test 2'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _showBottomSheet = false;
                });
                Navigator.pop(context);
              },
              child: const Text('Sluiten'),
            ),
          ],
        ),
      ),
    ).then((_) {
      setState(() {
        _showBottomSheet = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TTS Test - Uitgebreid'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help),
            onPressed: () {
              UnifiedTTSService.readText(context, ref, 
                'Dit is de uitgebreide TTS test pagina. Hier kun je alle TTS functionaliteiten testen. '
                'Gebruik de TTS knop om de hele pagina voor te lezen, of test individuele elementen.'
              );
            },
            tooltip: 'Help',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Uitgebreide TTS Test',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Deze pagina test alle TTS functionaliteiten van de app. '
                      'Gebruik de TTS knop om de hele pagina voor te lezen, of test individuele elementen.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            UnifiedTTSService.readCurrentScreen(context, ref);
                          },
                          child: const Text('Lees hele pagina'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            UnifiedTTSService.stopSpeaking(ref);
                          },
                          child: const Text('Stop voorlezen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Text widgets section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tekst Widgets',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Regular Text widget
                    const Text(
                      'Dit is een gewone Text widget. De TTS knop zou deze tekst moeten kunnen voorlezen.',
                    ),
                    const SizedBox(height: 16),
                    
                    // AccessibleText widget
                    AccessibleText(
                      'Dit is een AccessibleText widget met ingebouwde TTS functionaliteit. Tik erop om te testen.',
                      enableTextToSpeech: true,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 16),
                    
                    // EnhancedAccessibleText widget
                    EnhancedAccessibleText(
                      'Dit is een EnhancedAccessibleText widget met geavanceerde TTS opties.',
                      enableTTS: true,
                      speakOnTap: true,
                      speakOnLongPress: true,
                      style: const TextStyle(color: Colors.blue),
                    ),
                    const SizedBox(height: 16),
                    
                    // Rich text
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(color: Colors.black),
                        children: [
                          TextSpan(text: 'Dit is '),
                          TextSpan(
                            text: 'rich text',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          TextSpan(text: ' met verschillende stijlen.'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Form elements section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Formulier Elementen',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // Text field
                    TextField(
                      controller: _testController,
                      decoration: const InputDecoration(
                        labelText: 'Test invoerveld',
                        hintText: 'Voer hier test tekst in',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            UnifiedTTSService.readText(context, ref, 'Verhoogde knop ingedrukt');
                          },
                          child: const Text('Verhoogde Knop'),
                        ),
                        TextButton(
                          onPressed: () {
                            UnifiedTTSService.readText(context, ref, 'Tekst knop ingedrukt');
                          },
                          child: const Text('Tekst Knop'),
                        ),
                        OutlinedButton(
                          onPressed: () {
                            UnifiedTTSService.readText(context, ref, 'Omrande knop ingedrukt');
                          },
                          child: const Text('Omrande Knop'),
                        ),
                        IconButton(
                          onPressed: () {
                            UnifiedTTSService.readText(context, ref, 'Pictogram knop ingedrukt');
                          },
                          icon: const Icon(Icons.favorite),
                          tooltip: 'Pictogram knop',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // List elements section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lijst Elementen',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    // List tiles
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Eerste lijst item'),
                      subtitle: const Text('Dit is de ondertitel van het eerste item'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        UnifiedTTSService.readText(context, ref, 'Eerste lijst item geselecteerd');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Tweede lijst item'),
                      subtitle: const Text('Dit is de ondertitel van het tweede item'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        UnifiedTTSService.readText(context, ref, 'Tweede lijst item geselecteerd');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.info),
                      title: const Text('Derde lijst item'),
                      subtitle: const Text('Dit is de ondertitel van het derde item'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        UnifiedTTSService.readText(context, ref, 'Derde lijst item geselecteerd');
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Modal elements section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Modale Elementen',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _showTestDialog,
                          child: const Text('Toon Dialog'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _showTestBottomSheet,
                          child: const Text('Toon Bottom Sheet'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _showDialog ? 'Dialog is geopend' : 'Dialog is gesloten',
                      style: TextStyle(
                        color: _showDialog ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _showBottomSheet ? 'Bottom Sheet is geopend' : 'Bottom Sheet is gesloten',
                      style: TextStyle(
                        color: _showBottomSheet ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Status section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TTS Status',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    
                    Consumer(
                      builder: (context, ref, child) {
                        final accessibilityState = ref.watch(accessibilityNotifierProvider);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TTS Ingeschakeld: ${accessibilityState.isTextToSpeechEnabled ? "Ja" : "Nee"}'),
                            Text('Aan het spreken: ${accessibilityState.isSpeaking ? "Ja" : "Nee"}'),
                            Text('Spraaksnelheid: ${accessibilityState.speechRate}'),
                            Text('Spraaktoon: ${accessibilityState.speechPitch}'),
                            Text('Koptelefoon: ${accessibilityState.useHeadphones ? "Ja" : "Nee"}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
      floatingActionButton: const UnifiedTTSButton(
        showLabel: true,
      ),
    );
  }
}
