import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/initialization/app_initialization.dart';
import '../providers/auth_provider.dart';

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
  bool _isDisposed = false;
  bool _isNavigating = false;

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

  @override
  void dispose() {
    _isDisposed = true;
    _isNavigating = true; // Prevent navigation after disposal
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    if (_isDisposed || _isNavigating) return;
    
    try {
      // Simple initialization with timeout
      await Future.any([
        _performInitialization(),
        Future.delayed(const Duration(seconds: 3)), // 3 second timeout
      ]);
    } catch (e) {
      // Handle initialization errors gracefully
      debugPrint('Initialization error: $e');
    }
    
    // Always navigate after initialization (success or failure)
    if (mounted && !_isDisposed && !_isNavigating) {
      setState(() {
        _isInitialized = true;
      });
      
      // Navigate immediately
      _navigateToApp();
    }
  }

  Future<void> _performInitialization() async {
    try {
      // Run initialization in parallel for speed with individual timeouts
      await Future.wait([
        ensureSupabaseInitialized().timeout(const Duration(seconds: 2)),
        _initializeLocalStorage().timeout(const Duration(seconds: 2)),
        // Minimum splash duration for smooth UX
        Future.delayed(const Duration(milliseconds: 800)),
      ]);
      
      // Wait for auth provider to initialize and restore session with timeout
      await _waitForAuthInitialization().timeout(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('Initialization step failed: $e');
      // Continue anyway - the app should work without some services
    }
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
    await initializeLocalStorage();
  }

  void _navigateToApp() {
    if (!mounted || _isDisposed || _isNavigating || !context.mounted) return;
    
    _isNavigating = true; // Set flag to prevent multiple navigations
    
    try {
      // Check auth state and navigate accordingly
      final authState = ref.read(authNotifierProvider);
      
      if (authState.isAuthenticated) {
        print('🏠 Splash: User is authenticated, navigating to home');
        context.go('/home');
      } else {
        print('🔐 Splash: User not authenticated, navigating to login');
        context.go('/login');
      }
    } catch (e) {
      debugPrint('Navigation error in splash screen: $e');
      // Fallback navigation
      if (context.mounted && !_isDisposed) {
        context.go('/login');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }
}
