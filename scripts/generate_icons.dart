import 'dart:io';

void main() async {
  print('🎨 Karatapp Icon Generator');
  print('========================');
  
  // Check if icon files exist
  final appIcon = File('assets/icons/app_icon.png');
  final foregroundIcon = File('assets/icons/app_icon_foreground.png');
  
  print('\n📋 Checking icon files...');
  
  if (!appIcon.existsSync()) {
    print('❌ Missing: assets/icons/app_icon.png');
    print('   Please save your complete logo with GREEN karate figure (1024x1024 px) as app_icon.png');
  } else {
    print('✅ Found: assets/icons/app_icon.png');
  }
  
  if (!foregroundIcon.existsSync()) {
    print('❌ Missing: assets/icons/app_icon_foreground.png');
    print('   Please save just the GREEN karate figure (transparent background, 1024x1024 px) as app_icon_foreground.png');
  } else {
    print('✅ Found: assets/icons/app_icon_foreground.png');
  }
  
  if (appIcon.existsSync() && foregroundIcon.existsSync()) {
    print('\n🚀 All icon files found! Ready to generate app icons.');
    print('\nNext steps:');
    print('1. Run: flutter pub run flutter_launcher_icons:main');
    print('2. Run: flutter clean');
    print('3. Run: flutter pub get');
    print('4. Run: flutter run');
    print('\n🎯 Your custom Karatapp logo will replace the Flutter logo!');
  } else {
    print('\n⚠️  Please add the missing icon files first.');
    print('📖 See scripts/setup_app_icon.md for detailed instructions.');
  }
  
  print('\n💡 Current color scheme: GREEN karate figure (#7ED321)');
  print('💡 To change colors later:');
  print('   1. Edit your logo files in assets/icons/');
  print('   2. Re-run: flutter pub run flutter_launcher_icons:main');
  print('   3. Rebuild your app');
}
