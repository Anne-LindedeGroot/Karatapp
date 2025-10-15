import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'forum_screen.dart';
import 'forum_post_detail_screen.dart';
import 'create_forum_post_screen.dart';
import 'favorites_screen.dart';
import 'avatar_selection_screen.dart';
import 'user_management_screen.dart';
import 'accessibility_demo_screen.dart';
import '../core/navigation/app_router.dart';

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _hasTimedOut = false;

  @override
  void initState() {
    super.initState();
    // Set a timeout to prevent infinite loading
    Future.delayed(const Duration(seconds: 10), () {
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
      return Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_martial_arts,
                size: 64,
                color: Colors.white,
              ),
              SizedBox(height: 16),
              Text(
                'Karatapp',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 16),
              Text(
                'Initialiseren...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If timed out, show auth screen
    if (_hasTimedOut) {
      return const AuthScreen();
    }

    if (authState.error != null) {
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
                'Authenticatie Fout',
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
        return const HomeScreen();
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
            return const HomeScreen();
          }
        }
        
        // Default to home screen for unknown routes
        return const HomeScreen();
    }
  }
}
