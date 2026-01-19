import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import 'auth_screen.dart';
import '../home_screen.dart';
import '../profile/profile_screen.dart';
import '../forum/forum_screen.dart';
import '../forum/forum_post_detail_screen.dart';
import '../create_forum_post_screen.dart';
import '../favorites/favorites_screen.dart';
import '../profile/avatar_selection_screen.dart';
import '../admin/user_management_screen.dart';
import '../accessibility_demo_screen.dart';
import '../../core/navigation/app_router.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key, this.initialHomeTab = 0});

  final int initialHomeTab;

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  late final int _initialHomeTab;
  bool _hasTimedOut = false;

  /// Check if an error is a critical system error that should show full-screen
  /// Auth errors (login/signup) should be handled in the AuthScreen UI
  bool _isCriticalSystemError(String error) {
    final errorLower = error.toLowerCase();

    // Auth-related and network/auth token errors should not show full-screen
    if (errorLower.contains('authenticatie') ||
        errorLower.contains('auth') ||
        errorLower.contains('/auth/') ||
        errorLower.contains('token') ||
        errorLower.contains('password') ||
        errorLower.contains('sign in') ||
        errorLower.contains('login') ||
        errorLower.contains('socketexception') ||
        errorLower.contains('operation not permitted')) {
      return false;
    }
    
    // Critical system errors that need full-screen display
    if (errorLower.contains('initialization') ||
        errorLower.contains('supabase') ||
        errorLower.contains('database') ||
        errorLower.contains('connection') ||
        errorLower.contains('network') ||
        errorLower.contains('timeout') ||
        errorLower.contains('server error') ||
        errorLower.contains('internal error')) {
      return true;
    }
    
    // Auth errors should be handled in AuthScreen UI, not full-screen
    return false;
  }

  @override
  void initState() {
    super.initState();
    _initialHomeTab = widget.initialHomeTab;
    // Set a timeout to prevent infinite loading (reduced for faster UX)
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        final authState = ref.read(authStateProvider);
        if (authState.isLoading) {
          setState(() {
            _hasTimedOut = true;
          });
          // Force stop loading
          ref.read(authNotifierProvider.notifier).forceStopLoading();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final currentLocation = GoRouterState.of(context).uri.path;

    if (authState.isLoading && !_hasTimedOut) {
      // Show minimal loading state for faster initial render
      return Container(
        color: Theme.of(context).primaryColor,
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    // If timed out, show auth screen
    if (_hasTimedOut) {
      return const AuthScreen();
    }

    // Only show full-screen error for critical system errors, not auth errors
    // Auth errors are handled properly in the AuthScreen UI
    if (authState.error != null && _isCriticalSystemError(authState.error!)) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'Systeem Fout',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                authState.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Retry by invalidating the provider
                  ref.invalidate(authNotifierProvider);
                },
                child: const Text('Opnieuw'),
              ),
            ],
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      // User is logged in - show the appropriate screen based on current route
      return _buildAuthenticatedScreen(currentLocation, context);
    } else {
      // User is not logged in - show the unified auth screen (login/signup)
      return const AuthScreen();
    }
  }

  Widget _buildAuthenticatedScreen(String currentLocation, BuildContext context) {
    // Handle different routes for authenticated users
    switch (currentLocation) {
      case AppRoutes.splash:
      case AppRoutes.home:
        return HomeScreen(initialTabIndex: _initialHomeTab);
      case AppRoutes.profile:
        return const ProfileScreen();
      case AppRoutes.forum:
        return const ForumScreen();
      case AppRoutes.createForumPost:
        return const CreateForumPostScreen();
      case AppRoutes.favorites:
        return const FavoritesScreen();
      case AppRoutes.avatarSelection:
        return const AvatarSelectionScreen();
      case AppRoutes.userManagement:
        return const UserManagementScreen();
      case AppRoutes.accessibilityDemo:
        return const AccessibilityDemoScreen();
      default:
        // Handle dynamic routes like forum post details and edit kata
        if (currentLocation.startsWith('/forum/post/')) {
          final postId = int.tryParse(currentLocation.split('/').last);
          if (postId != null) {
            return ForumPostDetailScreen(postId: postId);
          }
        } else if (currentLocation.startsWith('/kata/edit/')) {
          final kataId = int.tryParse(currentLocation.split('/').last);
          if (kataId != null) {
            // This would need to be wrapped in a provider to get the kata
            // For now, redirect to home
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.go(AppRoutes.home);
            });
            return HomeScreen(initialTabIndex: _initialHomeTab);
          }
        }

        // Default to home screen for unknown routes
        return HomeScreen(initialTabIndex: _initialHomeTab);
    }
  }
}
