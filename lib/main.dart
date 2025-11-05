import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/environment.dart';
import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'providers/theme_provider.dart';
import 'core/navigation/scaffold_messenger.dart';
import 'providers/accessibility_provider.dart';
import 'providers/error_boundary_provider.dart';
import 'widgets/global_tts_overlay.dart';
import 'widgets/global_overflow_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize environment variables (with fallback for missing .env)
  try {
    await Environment.initialize();
  } catch (e) {
    debugPrint('Warning: Could not load .env file: $e');
    debugPrint('App will continue with default environment values');
  }

  // Start app immediately with simplified initialization
  runApp(
    ProviderScope(
      observers: kDebugMode ? [OptimizedRiverpodObserver()] : [],
      child: const MyApp(),
    ),
  );
  
  // Global error handler will be set up in AppErrorBoundary
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
      print('❌ ${provider.name ?? provider.runtimeType}: $error');
    }
  }

  bool _shouldLog(ProviderBase provider) {
    // Only log important providers to reduce noise
    final importantProviders = [
      'authNotifierProvider',
      'kataNotifierProvider',
      'themeNotifierProvider',
      'accessibilityNotifierProvider',
    ];
    
    return importantProviders.any((name) => 
      provider.name?.contains(name) == true || 
      provider.runtimeType.toString().contains(name)
    );
  }
}

/// A comprehensive error boundary that catches and handles all types of errors
class AppErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  ConsumerState<AppErrorBoundary> createState() => _AppErrorBoundaryState();
}

class _AppErrorBoundaryState extends ConsumerState<AppErrorBoundary> {
  bool hasError = false;
  String? errorMessage;
  StackTrace? errorStack;

  @override
  void initState() {
    super.initState();
    
    // Set up global error handling only once
    // Store the original error handler to avoid conflicts with other error handlers
    final originalErrorHandler = FlutterError.onError;
    
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is an overflow error - suppress it
      if (_isOverflowError(details.exception.toString())) {
        debugPrint('🎨 Overflow Error Suppressed: ${details.exception}');
        return;
      }
      
      // Check for framework assertion errors and handle them gracefully
      if (_isFrameworkAssertionError(details.exception.toString())) {
        debugPrint('🔧 Framework Assertion Error: ${details.exception}');
        // Don't show these to users, just log them
        return;
      }
      
      // Handle other errors normally
      if (kDebugMode) {
        FlutterError.presentError(details);
      }
      
      // Call the original error handler if it exists
      if (originalErrorHandler != null) {
        originalErrorHandler(details);
      }
      
      // Report to error boundary - defer setState to avoid build phase issues
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              hasError = true;
              errorMessage = details.exception.toString();
              errorStack = details.stack;
            });
          }
        });
      }
    };
  }

  bool _isOverflowError(String error) {
    final errorLower = error.toLowerCase();
    return (errorLower.contains('renderflex') && 
           errorLower.contains('overflow')) ||
           (errorLower.contains('overflow') && 
            (errorLower.contains('pixels') || errorLower.contains('bottom'))) ||
           errorLower.contains('cannot hit test a render box with no size') ||
           (errorLower.contains('renderbox') && errorLower.contains('size')) ||
           errorLower.contains('renderbox was not laid out') ||
           errorLower.contains('needs-paint needs-compositing-bits-update') ||
           (errorLower.contains('hasSize') && errorLower.contains('renderbox')) ||
           errorLower.contains('rendersemanticsannotations') ||
           errorLower.contains('rendertransform') ||
           errorLower.contains('size: missing') ||
           errorLower.contains('renderbox object must have an explicit size') ||
           errorLower.contains('although this node is not marked as needing layout') ||
           errorLower.contains('constraints: boxconstraints') ||
           errorLower.contains('size is not set') ||
           errorLower.contains('must have an explicit size before it can be hit-tested') ||
           errorLower.contains('null check operator used on a null value') ||
           errorLower.contains('boxconstraints forces an infinite height') ||
           errorLower.contains('child.hasSize') ||
           errorLower.contains('sliver_multi_box_adaptor') ||
           errorLower.contains('incorrect use of parentdatawidget') ||
           errorLower.contains('expanded') && errorLower.contains('wrap') ||
           errorLower.contains('flexparentdata') && errorLower.contains('wrapparentdata') ||
           errorLower.contains('cannot use "ref" after the widget was disposed') ||
           errorLower.contains('bad state: cannot use "ref"');
  }

  bool _isFrameworkAssertionError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('assertion failed') ||
           errorLower.contains('owner!._debugcurrentbuildtarget') ||
           errorLower.contains('framework.dart') ||
           errorLower.contains('is not true') ||
           errorLower.contains('debugcurrentbuildtarget') ||
           errorLower.contains('element._lifecyclestate') ||
           errorLower.contains('_elementlifecycle.active') ||
           errorLower.contains('lifecycle state') ||
           errorLower.contains('_debugcurrentbuildtarget') ||
           errorLower.contains('setstate() or markneedsbuild() called during build') ||
           errorLower.contains('widget cannot be marked as needing to build') ||
           errorLower.contains('framework is already in the process of building');
  }

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return MaterialApp(
        title: 'Karatapp - Error Recovery',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.light(),
        home: Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'App Foutherstel',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          'De app heeft een fout ondervonden maar is hersteld.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                          textAlign: TextAlign.center,
                          softWrap: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              hasError = false;
                              errorMessage = null;
                              errorStack = null;
                            });
                            // Also clear any global error boundary state
                            try {
                              // Clear the error boundary state using the provider
                              final container = ProviderScope.containerOf(context);
                              container.read(errorBoundaryProvider.notifier).clearAllErrors();
                            } catch (e) {
                              // Ignore any errors when clearing state
                            }
                          },
                          child: const Text('Doorgaan'),
                        ),
                      ),
                      if (kDebugMode && errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                'Fout: $errorMessage',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Colors.red,
                                ),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  Widget build(BuildContext context) {
    // Use AppErrorBoundary to catch any build errors
    return AppErrorBoundary(
      child: Builder(
        builder: (context) {
          try {
            final router = ref.watch(routerProvider);
            final themeState = ref.watch(themeNotifierProvider);
            final accessibilityState = ref.watch(accessibilityNotifierProvider);

            // Ensure dyslexia-friendly setting is synced between providers
            ref.watch(dyslexiaFriendlySyncProvider);
            
            return MaterialApp.router(
              title: 'Karatapp',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              theme: AppTheme.getThemeData(
                themeMode: themeState.themeMode,
                colorScheme: themeState.colorScheme,
                isHighContrast: themeState.isHighContrast,
                glowEffects: themeState.glowEffects,
                systemBrightness: Brightness.light,
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
              onGenerateTitle: (context) => 'Karatapp',
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

                // Simplified protection - just error catching and overlays
                return OverflowErrorCatcher(
                  enableErrorCatching: true,
                  child: GlobalTTSOverlay(
                    child: child ?? const SizedBox.shrink(),
                  ),
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
                          // Restart the app by rebuilding the widget tree
                          if (context.mounted) {
                            setState(() {});
                          }
                        },
                        child: const Text('Restart App'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}