import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../main.dart' show ensureSupabaseInitialized, ensureHiveInitialized;
import '../core/storage/local_storage.dart';
import '../providers/auth_provider.dart';
import '../widgets/global_tts_overlay.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // Setup minimal animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _animationController.forward();
    
    // Initialize services in background
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Add timeout to prevent infinite loading
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 10)), // 10 second timeout
      ]);
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        
        // Navigate to main app
        _navigateToApp();
      }
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Initialization error: $e');
      if (mounted) {
        _navigateToApp(); // Continue anyway
      }
    }
  }

  Future<void> _performInitialization() async {
    // Run initialization in parallel for speed
    await Future.wait([
      ensureSupabaseInitialized(),
      _initializeLocalStorage(),
      // Minimum splash duration for smooth UX
      Future.delayed(const Duration(milliseconds: 800)),
    ]);
    
    // Wait for auth provider to initialize and restore session
    await _waitForAuthInitialization();
  }

  Future<void> _waitForAuthInitialization() async {
    // Trigger auth provider initialization by reading it
    ref.read(authNotifierProvider.notifier);
    
    // Wait a bit for the auth initialization to complete
    // The AuthNotifier._initializeAuth() method runs in the constructor
    // so we give it time to complete the session restoration
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Check if auth state is still loading and wait if needed
    int attempts = 0;
    while (attempts < 10) { // Max 5 seconds wait
      final authState = ref.read(authNotifierProvider);
      if (!authState.isLoading) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }
    
    print('🏁 Splash: Auth initialization complete');
  }

  Future<void> _initializeLocalStorage() async {
    await ensureHiveInitialized();
    await LocalStorage.initialize();
  }

  void _navigateToApp() {
    // Small delay for smooth transition
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        // Check auth state and navigate accordingly
        final authState = ref.read(authNotifierProvider);
        
        if (authState.isAuthenticated) {
          print('🏠 Splash: User is authenticated, navigating to home');
          context.go('/home');
        } else {
          print('🔐 Splash: User not authenticated, navigating to login');
          context.go('/login');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalTTSOverlay(
      enabled: true,
      child: Scaffold(
        backgroundColor: const Color(0xFF4CAF50), // Use a fixed green color
        body: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo/icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.sports_martial_arts,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // App name
                const Text(
                  'Karatapp',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Tagline
                Text(
                  'Jouw Karate Reis',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Loading indicator
                if (!_isInitialized)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
