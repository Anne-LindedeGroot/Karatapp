import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/accessibility_provider.dart';
import 'services/unified_tts_service.dart';

/// Test screen to demonstrate enhanced TTS functionality
/// This screen shows how the TTS system intelligently detects different screen types
/// and reads appropriate content for each screen
class TestEnhancedTTSScreen extends ConsumerStatefulWidget {
  const TestEnhancedTTSScreen({super.key});

  @override
  ConsumerState<TestEnhancedTTSScreen> createState() => _TestEnhancedTTSScreenState();
}

class _TestEnhancedTTSScreenState extends ConsumerState<TestEnhancedTTSScreen> {
  final TextEditingController _testController = TextEditingController();
  bool _showDialog = false;
  bool _showBottomSheet = false;

  @override
  void dispose() {
    _testController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enhanced TTS Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced TTS Test Screen',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen demonstrates the enhanced TTS functionality that intelligently detects different screen types and reads appropriate content.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // TTS Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TTS Status',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final accessibilityState = ref.watch(accessibilityNotifierProvider);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('TTS Enabled: ${accessibilityState.isTextToSpeechEnabled ? "Yes" : "No"}'),
                            Text('Currently Speaking: ${accessibilityState.isSpeaking ? "Yes" : "No"}'),
                            Text('Speech Rate: ${accessibilityState.speechRate}'),
                            Text('Speech Pitch: ${accessibilityState.speechPitch}'),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Form
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Form',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _testController,
                      decoration: const InputDecoration(
                        labelText: 'Test Input Field',
                        hintText: 'Enter some text to test form detection',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showDialog = true;
                              });
                              _showTestDialog();
                            },
                            child: const Text('Show Dialog'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _showBottomSheet = true;
                              });
                              _showTestBottomSheet();
                            },
                            child: const Text('Show Bottom Sheet'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Test Buttons
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Actions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: () => _testScreenDetection(),
                          child: const Text('Test Screen Detection'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testFormDetection(),
                          child: const Text('Test Form Detection'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testOverlayDetection(),
                          child: const Text('Test Overlay Detection'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testManualTTS(),
                          child: const Text('Test Manual TTS'),
                        ),
                        ElevatedButton(
                          onPressed: () => _testComprehensiveReading(),
                          child: const Text('Read Everything'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to Test',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Use the global TTS button (floating button) to read the entire screen\n'
                      '2. Test different screen types by navigating to different pages\n'
                      '3. Test form detection by filling in the text field above\n'
                      '4. Test overlay detection by showing dialogs and bottom sheets\n'
                      '5. The TTS system will automatically detect the screen type and read appropriate content',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 100), // Space for floating button
          ],
        ),
      ),
    );
  }

  void _showTestDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test Dialog'),
        content: const Text(
          'This is a test dialog to demonstrate overlay detection. '
          'The TTS system should detect this as an overlay and read its content.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showDialog = false;
              });
            },
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _showDialog = false;
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTestBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Test Bottom Sheet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            const Text(
              'This is a test bottom sheet to demonstrate overlay detection. '
              'The TTS system should detect this as an overlay and read its content.',
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showBottomSheet = false;
                    });
                  },
                  child: const Text('Close'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _showBottomSheet = false;
                    });
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _testScreenDetection() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Screen detection test - check console for details'),
        duration: Duration(seconds: 3),
      ),
    );
    
    // This will be handled by the global TTS button
    // The system will automatically detect this as a test screen
  }

  void _testFormDetection() {
    if (_testController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form contains: ${_testController.text}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some text in the form field first'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _testOverlayDetection() {
    if (_showDialog || _showBottomSheet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Overlay is currently visible - TTS should detect it'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No overlay visible - show a dialog or bottom sheet first'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _testManualTTS() async {
    final accessibilityNotifier = ref.read(accessibilityNotifierProvider.notifier);
    
    // Test manual TTS with specific text
    await accessibilityNotifier.speak(
      'Dit is een test van de handmatige TTS functionaliteit. '
      'De enhanced TTS service kan verschillende schermtypes detecteren en '
      'geschikte inhoud voorlezen voor elk schermtype.',
    );
  }

  void _testComprehensiveReading() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Starting comprehensive screen reading - check terminal for detailed output'),
        duration: Duration(seconds: 3),
      ),
    );
    
    // Test the new comprehensive reading functionality
    await UnifiedTTSService.readEverythingOnScreen(context, ref);
  }
}
