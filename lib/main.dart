import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/storage/local_storage.dart' as app_storage;
import 'providers/error_boundary_provider.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables
  await Environment.initialize();
  
  // Initialize Hive for local storage (required for auth persistence)
  await ensureHiveInitialized();
  
  // Initialize local storage boxes
  await _initializeLocalStorage();
  
  // Initialize Supabase early to ensure session restoration works
  await ensureSupabaseInitialized();
  
  // Set up minimal error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };

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


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeState = ref.watch(themeNotifierProvider);
    
    return MaterialApp.router(
      title: 'Karatapp',
      theme: themeState.isHighContrast ? AppTheme.highContrastLightTheme : AppTheme.lightTheme,
      darkTheme: themeState.isHighContrast ? AppTheme.highContrastDarkTheme : AppTheme.darkTheme,
      themeMode: themeState.flutterThemeMode,
      routerConfig: router,
      builder: (context, child) {
        // Global error handling for uncaught exceptions
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
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
                    if (kDebugMode) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorDetails.exception.toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        };

        return child ?? const SizedBox.shrink();
      },
    );
  }
}
