#!/usr/bin/env dart

import 'dart:io';

/// Script to analyze large Dart files and suggest optimizations
void main() async {
  print('📊 Analyzing large Dart files...');
  
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found');
    return;
  }
  
  final largeFiles = <MapEntry<String, int>>[];
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final lines = await _countLines(entity);
      if (lines > 500) { // Files larger than 500 lines
        largeFiles.add(MapEntry(entity.path, lines));
      }
    }
  }
  
  // Sort by line count (descending)
  largeFiles.sort((a, b) => b.value.compareTo(a.value));
  
  print('\n📋 Large Dart files (>500 lines):');
  print('─' * 60);
  
  for (final file in largeFiles) {
    final size = _formatFileSize(file.value);
    final recommendation = _getOptimizationRecommendation(file.value);
    print('${file.key.padRight(40)} $size $recommendation');
  }
  
  if (largeFiles.isEmpty) {
    print('✅ No large files found!');
  } else {
    print('\n💡 Optimization recommendations:');
    print('• Split files >1000 lines into smaller modules');
    print('• Extract utility functions into separate files');
    print('• Use mixins for shared functionality');
    print('• Consider using code generation for repetitive code');
  }
}

Future<int> _countLines(File file) async {
  final content = await file.readAsString();
  return content.split('\n').length;
}

String _formatFileSize(int lines) {
  if (lines > 2000) return '${lines} lines 🔴';
  if (lines > 1000) return '${lines} lines 🟡';
  return '${lines} lines 🟢';
}

String _getOptimizationRecommendation(int lines) {
  if (lines > 2000) return '(Consider splitting)';
  if (lines > 1000) return '(Monitor size)';
  return '';
}
