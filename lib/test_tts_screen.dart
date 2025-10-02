import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/unified_tts_button.dart';

/// Simple test screen to verify TTS functionality
class TestTTSScreen extends ConsumerWidget {
  const TestTTSScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return withUnifiedTTS(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('TTS Test Pagina'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welkom bij de TTS Test Pagina',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              Text(
                'Deze pagina bevat verschillende tekstelementen om de TTS functionaliteit te testen.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Kaart',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Dit is een test kaart met wat tekst om te controleren of de TTS service alle content kan lezen.',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              ListTile(
                leading: Icon(Icons.check_circle),
                title: Text('Test Lijst Item'),
                subtitle: Text('Dit is een lijst item met een subtitel'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: null,
                child: Text('Test Knop'),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Test Invoerveld',
                  hintText: 'Voer hier tekst in',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
