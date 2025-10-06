import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/local_storage.dart' as app_storage;
import 'providers/error_boundary_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/accessibility_provider.dart';
import 'widgets/global_tts_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables (with fallback for missing .env)
  try {
    await Environment.initialize();
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('App will continue with default environment values');
  }
  
  // Set up error handling to catch and display errors
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Initialize Hive for local storage (required for auth persistence)
  await ensureHiveInitialized();
  
  // Initialize local storage boxes
  await _initializeLocalStorage();
  
  // Initialize Supabase early to ensure session restoration works
  await ensureSupabaseInitialized();

  // Start app immediately - defer all heavy initialization
  runApp(
    ProviderScope(
      observers: kDebugMode ? [OptimizedRiverpodObserver()] : [],
      child: const MyApp(),
    ),
  );
}

// Global initialization state
bool _supabaseInitialized = false;
bool _hiveInitialized = false;

// Lazy initialization - only when needed
Future<void> ensureSupabaseInitialized() async {
  if (!_supabaseInitialized) {
    try {
      await Supabase.initialize(
        url: Environment.supabaseUrl,
        anonKey: Environment.supabaseAnonKey,
      );
      _supabaseInitialized = true;
    } catch (e) {
      debugPrint('Supabase initialization error: $e');
    }
  }
}

// Lazy Hive initialization
Future<void> ensureHiveInitialized() async {
  if (!_hiveInitialized) {
    try {
      await Hive.initFlutter();
      _hiveInitialized = true;
    } catch (e) {
      debugPrint('Hive initialization error: $e');
    }
  }
}

// Initialize local storage boxes
Future<void> _initializeLocalStorage() async {
  try {
    await app_storage.LocalStorage.initialize();
  } catch (e) {
    debugPrint('Local storage initialization error: $e');
  }
}

// Optimized Riverpod observer for better performance
class OptimizedRiverpodObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // Only log critical provider updates to reduce overhead
    if (kDebugMode && _shouldLog(provider)) {
      print('🔄 ${provider.name ?? provider.runtimeType}');
    }
  }

  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      print('❌ Provider failed: ${provider.name ?? provider.runtimeType}');
      print('   Error: $error');
    }
  }

  // Only log important providers to reduce debug overhead
  bool _shouldLog(ProviderBase provider) {
    final name = provider.name ?? provider.runtimeType.toString();
    return name.contains('auth') || 
           name.contains('error') || 
           name.contains('theme');
  }
}

/// Helper function to determine if global TTS overlay should be shown
bool _shouldShowGlobalTTS(BuildContext context) {
  // Show the global floating TTS button on all screens
  // The user wants TTS to work everywhere, so we enable it globally
  return true;
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    try {
      final router = ref.watch(routerProvider);
      final themeState = ref.watch(themeNotifierProvider);
      final accessibilityState = ref.watch(accessibilityNotifierProvider);
      
      // Sync dyslexia-friendly setting between providers
      ref.watch(dyslexiaFriendlySyncProvider);
      
      // Get the current system brightness
      final systemBrightness = MediaQuery.of(context).platformBrightness;
      
      return MaterialApp.router(
        title: 'Karatapp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getThemeData(
          themeMode: themeState.themeMode,
          colorScheme: themeState.colorScheme,
          isHighContrast: themeState.isHighContrast,
          glowEffects: themeState.glowEffects,
          systemBrightness: systemBrightness,
          fontScaleFactor: accessibilityState.fontScaleFactor,
          isDyslexiaFriendly: themeState.isDyslexiaFriendly,
        ),
        darkTheme: AppTheme.getThemeData(
          themeMode: AppThemeMode.dark,
          colorScheme: themeState.colorScheme,
          isHighContrast: themeState.isHighContrast,
          glowEffects: themeState.glowEffects,
          systemBrightness: Brightness.dark,
          fontScaleFactor: accessibilityState.fontScaleFactor,
          isDyslexiaFriendly: themeState.isDyslexiaFriendly,
        ),
        themeMode: themeState.flutterThemeMode,
        routerConfig: router,
        builder: (context, child) {
          // Set system UI overlay style based on current theme
          final brightness = Theme.of(context).brightness;
          SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
              statusBarBrightness: brightness,
              systemNavigationBarColor: Theme.of(context).scaffoldBackgroundColor,
              systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
            ),
          );

          // Global error handling for uncaught exceptions
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          // Log the error for debugging
          debugPrint('ErrorWidget.builder called with: ${errorDetails.exception}');
          debugPrint('Stack trace: ${errorDetails.stack}');
          
          // Report error to global error boundary
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              try {
                final container = ProviderScope.containerOf(context);
                container.read(errorBoundaryProvider.notifier).reportError(
                  errorDetails.exception.toString(),
                  errorDetails.stack,
                );
              } catch (e) {
                // Fallback if provider is not available
                debugPrint('Failed to report error to global boundary: $e');
              }
            }
          });

          return Material(
            child: Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(16),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please restart the app',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error: ${errorDetails.exception}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (kDebugMode) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Stack: ${errorDetails.stack}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        };

        // Add global TTS overlay to all screens
        return GlobalTTSOverlay(
          enabled: _shouldShowGlobalTTS(context),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
    } catch (e, stackTrace) {
      debugPrint('Error in MyApp.build: $e');
      debugPrint('Stack trace: $stackTrace');
      
      // Return a fallback app with basic theme
      return MaterialApp(
        title: 'Karatapp',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Initialization Error',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Error: $e',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    runApp(const MyApp());
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}
