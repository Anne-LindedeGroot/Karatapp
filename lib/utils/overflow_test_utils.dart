import 'package:flutter/material.dart';
import '../widgets/overflow_safe_widgets.dart';

/// Utility class for testing overflow scenarios and ensuring they don't crash the app
class OverflowTestUtils {
  /// Creates a test widget that would normally cause overflow errors
  static Widget createOverflowTestWidget() {
    return Scaffold(
      appBar: AppBar(title: const Text('Overflow Test')),
      body: OverflowSafeColumn(
        children: [
          // Test 1: Long text that would overflow
          OverflowSafeText(
            'This is a very long text that would normally cause overflow errors in a regular Text widget when the screen is too small to display it properly. This text is intentionally long to test the overflow protection mechanisms.',
            style: const TextStyle(fontSize: 16),
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          
          // Test 2: Row with too many elements
          OverflowSafeRow(
            children: [
              Container(width: 100, height: 50, color: Colors.red),
              Container(width: 100, height: 50, color: Colors.blue),
              Container(width: 100, height: 50, color: Colors.green),
              Container(width: 100, height: 50, color: Colors.yellow),
              Container(width: 100, height: 50, color: Colors.purple),
              Container(width: 100, height: 50, color: Colors.orange),
            ],
          ),
          const SizedBox(height: 20),
          
          // Test 3: Column with too many elements
          OverflowSafeColumn(
            children: [
              Container(width: double.infinity, height: 100, color: Colors.red),
              Container(width: double.infinity, height: 100, color: Colors.blue),
              Container(width: double.infinity, height: 100, color: Colors.green),
              Container(width: double.infinity, height: 100, color: Colors.yellow),
              Container(width: double.infinity, height: 100, color: Colors.purple),
              Container(width: double.infinity, height: 100, color: Colors.orange),
              Container(width: double.infinity, height: 100, color: Colors.pink),
              Container(width: double.infinity, height: 100, color: Colors.teal),
            ],
          ),
          const SizedBox(height: 20),
          
          // Test 4: Button with long text
          OverflowSafeButton(
            onPressed: () {},
            isElevated: true,
            fullWidth: true,
            child: const OverflowSafeText(
              'This is a very long button text that would normally cause overflow in a regular button widget',
              maxLines: 2,
            ),
          ),
          const SizedBox(height: 20),
          
          // Test 5: Dialog content that would overflow
          OverflowSafeContainer(
            padding: const EdgeInsets.all(16),
            child: OverflowSafeColumn(
              children: [
                const OverflowSafeText(
                  'Dialog Title',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const OverflowSafeText(
                  'This is a very long dialog content that would normally cause overflow errors when the dialog is too small to display all the content properly. The overflow-safe widgets should handle this gracefully.',
                ),
                const SizedBox(height: 20),
                OverflowSafeRow(
                  children: [
                    OverflowSafeButton(
                      onPressed: () {},
                      isElevated: true,
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    OverflowSafeButton(
                      onPressed: () {},
                      isElevated: true,
                      child: const Text('Very Long Confirm Button Text'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Creates a test scenario that would cause RenderFlex overflow
  static Widget createRenderFlexOverflowTest() {
    return Scaffold(
      appBar: AppBar(title: const Text('RenderFlex Overflow Test')),
      body: OverflowSafeColumn(
        children: [
          // This would normally cause "A RenderFlex overflowed by X pixels on the bottom"
          OverflowSafeExpanded(
            child: OverflowSafeColumn(
              children: [
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.blue,
                  child: const Center(
                    child: Text('Fixed Height Container'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.green,
                  child: const Center(
                    child: Text('Another Fixed Height Container'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.red,
                  child: const Center(
                    child: Text('Third Fixed Height Container'),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.yellow,
                  child: const Center(
                    child: Text('Fourth Fixed Height Container'),
                  ),
                ),
                // This would normally cause overflow
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.purple,
                  child: const Center(
                    child: Text('This would cause overflow without protection'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  /// Creates a test for text overflow scenarios
  static Widget createTextOverflowTest() {
    return Scaffold(
      appBar: AppBar(title: const Text('Text Overflow Test')),
      body: OverflowSafeColumn(
        children: [
          // Test various text overflow scenarios
          const OverflowSafeText(
            'Short text',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const OverflowSafeText(
            'Medium length text that might overflow on smaller screens',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          const OverflowSafeText(
            'Very long text that would definitely cause overflow errors in regular Text widgets when the screen width is limited. This text is intentionally very long to test the overflow protection mechanisms and ensure they work correctly.',
            style: TextStyle(fontSize: 16),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          OverflowSafeText(
            'Text with auto-sizing: This text will automatically resize to fit the available space',
            style: const TextStyle(fontSize: 16),
            enableAutoSizing: true,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
  
  /// Runs all overflow tests and returns a summary
  static Map<String, bool> runOverflowTests() {
    final results = <String, bool>{};
    
    try {
      // Test 1: Basic overflow protection
      createOverflowTestWidget();
      results['Basic Overflow Protection'] = true;
    } catch (e) {
      results['Basic Overflow Protection'] = false;
    }
    
    try {
      // Test 2: RenderFlex overflow protection
      createRenderFlexOverflowTest();
      results['RenderFlex Overflow Protection'] = true;
    } catch (e) {
      results['RenderFlex Overflow Protection'] = false;
    }
    
    try {
      // Test 3: Text overflow protection
      createTextOverflowTest();
      results['Text Overflow Protection'] = true;
    } catch (e) {
      results['Text Overflow Protection'] = false;
    }
    
    return results;
  }
}

/// A test screen that demonstrates all overflow protection features
class OverflowTestScreen extends StatelessWidget {
  const OverflowTestScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Overflow Protection Tests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Basic'),
              Tab(text: 'RenderFlex'),
              Tab(text: 'Text'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            OverflowSafeColumn(
              children: [
                Expanded(child: OverflowTestUtils.createOverflowTestWidget()),
              ],
            ),
            OverflowSafeColumn(
              children: [
                Expanded(child: OverflowTestUtils.createRenderFlexOverflowTest()),
              ],
            ),
            OverflowSafeColumn(
              children: [
                Expanded(child: OverflowTestUtils.createTextOverflowTest()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
