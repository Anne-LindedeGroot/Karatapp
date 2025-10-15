import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lib/widgets/cleaning_animation_widget.dart';
import 'lib/providers/kata_provider.dart';

/// Simple test to verify cleanup functionality works
void main() {
  runApp(
    ProviderScope(
      child: MaterialApp(
        home: TestCleanupScreen(),
      ),
    ),
  );
}

class TestCleanupScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<TestCleanupScreen> createState() => _TestCleanupScreenState();
}

class _TestCleanupScreenState extends ConsumerState<TestCleanupScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cleanup Test'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test the safe cleanup functionality
                  await EnhancedCleaningService.performCleaningWithAnimation(
                    context,
                    ref,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Test failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Test Cleanup'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  // Test direct safe cleanup call
                  final deletedPaths = await ref
                      .read(kataNotifierProvider.notifier)
                      .safeCleanupTempFolders();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Cleaned ${deletedPaths.length} files'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Direct cleanup failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Direct Cleanup Test'),
            ),
          ],
        ),
      ),
    );
  }
}
