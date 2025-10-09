#!/usr/bin/env dart

import 'dart:io';

/// Script to run optimized Flutter builds with various performance improvements
void main(List<String> args) async {
  print('🚀 Starting optimized Flutter build...');
  
  // Clean build cache for fresh start
  if (args.contains('--clean')) {
    print('🧹 Cleaning build cache...');
    await Process.run('flutter', ['clean']);
    await Process.run('flutter', ['pub', 'get']);
  }
  
  // Run code generation if needed
  if (args.contains('--generate')) {
    print('⚙️  Running code generation...');
    await Process.run('dart', ['run', 'build_runner', 'build', '--delete-conflicting-outputs']);
  }
  
  // Determine build type
  final isRelease = args.contains('--release');
  final buildType = isRelease ? 'release' : 'debug';
  
  print('🔨 Building $buildType version...');
  
  // Build with optimizations
  final buildArgs = [
    'build',
    'apk',
    if (isRelease) '--release' else '--debug',
    '--target-platform', 'android-arm64',
    '--split-per-abi',
    '--no-tree-shake-icons',
  ];
  
  final result = await Process.run('flutter', buildArgs);
  
  if (result.exitCode == 0) {
    print('✅ Build completed successfully!');
    
    // Show build info
    final buildDir = Directory('build/app/outputs/flutter-apk');
    if (buildDir.existsSync()) {
      await for (final file in buildDir.list()) {
        if (file is File && file.path.endsWith('.apk')) {
          final size = await file.length();
          print('📱 APK size: ${(size / 1024 / 1024).toStringAsFixed(1)}MB');
        }
      }
    }
  } else {
    print('❌ Build failed:');
    print(result.stderr);
  }
}

/// Show usage information
void showUsage() {
  print('''
🚀 Fast Build Script for Flutter

Usage: dart scripts/fast_build.dart [options]

Options:
  --clean     Clean build cache before building
  --generate  Run code generation before building
  --release   Build release version (default: debug)
  --help      Show this help message

Examples:
  dart scripts/fast_build.dart                    # Debug build
  dart scripts/fast_build.dart --release          # Release build
  dart scripts/fast_build.dart --clean --release  # Clean + release build
''');
}
