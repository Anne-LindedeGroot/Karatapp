import 'package:flutter/material.dart';

void main() {
  runApp(const TestApp());
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test App'),
        ),
        body: const Center(
          child: Text(
            'App is working!',
            style: TextStyle(fontSize: 24),
          ),
        ),
      ),
    );
  }
}
