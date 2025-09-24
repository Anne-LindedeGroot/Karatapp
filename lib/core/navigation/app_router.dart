import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/splash_screen.dart';
import '../../screens/auth_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/forum_screen.dart';
import '../../screens/forum_post_detail_screen.dart';
import '../../screens/create_forum_post_screen.dart';
import '../../screens/favorites_screen.dart';
import '../../screens/edit_kata_screen.dart';
import '../../screens/avatar_selection_screen.dart';
import '../../screens/user_management_screen.dart';
import '../../screens/accessibility_demo_screen.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kata_provider.dart';
import '../../widgets/global_error_widget.dart';

/// App routes configuration
class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String forum = '/forum';
  static const String forumPostDetail = '/forum/post/:postId';
  static const String createForumPost = '/forum/create';
  static const String favorites = '/favorites';
  static const String editKata = '/kata/edit/:kataId';
  static const String avatarSelection = '/avatar-selection';
  static const String userManagement = '/user-management';
  static const String accessibilityDemo = '/accessibility-demo';
}

/// Router provider for dependency injection
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final isLoading = authState.isLoading;
      
      // Don't redirect while loading (session restoration in progress)
      if (isLoading) {
        return null;
      }
      
      // If not authenticated and trying to access protected routes, redirect to login
      if (!isAuthenticated && state.matchedLocation != AppRoutes.splash && state.matchedLocation != AppRoutes.login && state.matchedLocation != AppRoutes.signup) {
        return AppRoutes.login;
      }
      
      // If authenticated and on splash/login/signup, redirect to home
      if (isAuthenticated && (state.matchedLocation == AppRoutes.splash || state.matchedLocation == AppRoutes.login || state.matchedLocation == AppRoutes.signup)) {
        return AppRoutes.home;
      }
      
      return null;
    },
    routes: [
      // Splash screen route
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Auth routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AuthScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AuthScreen(),
        ),
      ),
      
      // Main app routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const GlobalErrorBoundary(
          child: HomeScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const GlobalErrorBoundary(
          child: ProfileScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.forum,
        name: 'forum',
        builder: (context, state) => const GlobalErrorBoundary(
          child: ForumScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.forumPostDetail,
        name: 'forumPostDetail',
        builder: (context, state) {
          final postId = int.parse(state.pathParameters['postId']!);
          return GlobalErrorBoundary(
            child: ForumPostDetailScreen(postId: postId),
          );
        },
      ),
      
      GoRoute(
        path: AppRoutes.createForumPost,
        name: 'createForumPost',
        builder: (context, state) => const GlobalErrorBoundary(
          child: CreateForumPostScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.favorites,
        name: 'favorites',
        builder: (context, state) => const GlobalErrorBoundary(
          child: FavoritesScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.editKata,
        name: 'editKata',
        builder: (context, state) {
          final kataId = int.parse(state.pathParameters['kataId']!);
          return GlobalErrorBoundary(
            child: EditKataWrapper(kataId: kataId),
          );
        },
      ),
      
      GoRoute(
        path: AppRoutes.avatarSelection,
        name: 'avatarSelection',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AvatarSelectionScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.userManagement,
        name: 'userManagement',
        builder: (context, state) => const GlobalErrorBoundary(
          child: UserManagementScreen(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.accessibilityDemo,
        name: 'accessibilityDemo',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AccessibilityDemoScreen(),
        ),
      ),
      
    ],
    
    // Error handling
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Pagina Niet Gevonden'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.home),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Pagina Niet Gevonden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'De pagina die je zoekt bestaat niet.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Naar Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Navigation helper extensions
extension AppRouterExtension on GoRouter {
  /// Navigate to login screen
  void goToLogin() => go(AppRoutes.login);
  
  /// Navigate to signup screen
  void goToSignup() => go(AppRoutes.signup);
  
  /// Navigate to home screen
  void goToHome() => go(AppRoutes.home);
  
  /// Navigate to profile screen
  void goToProfile() => go(AppRoutes.profile);
  
  /// Navigate to forum screen
  void goToForum() => go(AppRoutes.forum);
  
  /// Navigate to favorites screen
  void goToFavorites() => go(AppRoutes.favorites);
  
  /// Navigate to forum post detail
  void goToForumPost(String postId) => go('/forum/post/$postId');
  
  /// Navigate to create forum post
  void goToCreateForumPost() => go('/forum/create');
  
  /// Navigate to edit kata
  void goToEditKata(String kataId) => go('/home/kata/edit/$kataId');
  
  /// Navigate to avatar selection
  void goToAvatarSelection() => go('/profile/avatar-selection');
  
  /// Navigate to user management
  void goToUserManagement() => go(AppRoutes.userManagement);
}

/// Context extension for easy navigation
extension BuildContextExtension on BuildContext {
  /// Get the router instance
  GoRouter get router => GoRouter.of(this);
  
  /// Navigate to login screen
  void goToLogin() => go(AppRoutes.login);
  
  /// Navigate to signup screen
  void goToSignup() => go(AppRoutes.signup);
  
  /// Navigate to home screen
  void goToHome() => go(AppRoutes.home);
  
  /// Navigate to profile screen
  void goToProfile() => go(AppRoutes.profile);
  
  /// Navigate to forum screen
  void goToForum() => go(AppRoutes.forum);
  
  /// Navigate to favorites screen
  void goToFavorites() => go(AppRoutes.favorites);
  
  /// Navigate to forum post detail
  void goToForumPost(String postId) => go('/forum/post/$postId');
  
  /// Navigate to create forum post
  void goToCreateForumPost() => go('/forum/create');
  
  /// Navigate to edit kata
  void goToEditKata(String kataId) => go('/home/kata/edit/$kataId');
  
  /// Navigate to avatar selection
  void goToAvatarSelection() => go('/profile/avatar-selection');
  
  /// Navigate to user management
  void goToUserManagement() => go(AppRoutes.userManagement);
  
  /// Navigate back with fallback to home
  void goBackOrHome() {
    if (canPop()) {
      pop();
    } else {
      goToHome();
    }
  }
}

/// Deep linking helper
class DeepLinkHandler {
  /// Handle incoming deep links
  static String? handleDeepLink(String link) {
    final uri = Uri.tryParse(link);
    if (uri == null) return null;
    
    // Handle different deep link patterns
    switch (uri.pathSegments.first) {
      case 'forum':
        if (uri.pathSegments.length >= 3 && uri.pathSegments[1] == 'post') {
          return '/forum/post/${uri.pathSegments[2]}';
        }
        return AppRoutes.forum;
      
      case 'kata':
        if (uri.pathSegments.length >= 3 && uri.pathSegments[1] == 'edit') {
          return '/home/kata/edit/${uri.pathSegments[2]}';
        }
        return AppRoutes.home;
      
      case 'profile':
        return AppRoutes.profile;
      
      case 'favorites':
        return AppRoutes.favorites;
      
      default:
        return AppRoutes.home;
    }
  }
  
  /// Generate shareable links
  static String generateShareLink(String route, {Map<String, String>? params}) {
    const baseUrl = 'https://karatapp.com'; // Replace with your actual domain
    
    if (params != null && params.isNotEmpty) {
      final queryString = params.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      return '$baseUrl$route?$queryString';
    }
    
    return '$baseUrl$route';
  }
}

/// Wrapper widget to load kata by ID for EditKataScreen
class EditKataWrapper extends ConsumerWidget {
  final int kataId;

  const EditKataWrapper({
    required this.kataId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kataState = ref.watch(kataNotifierProvider);

    if (kataState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laden...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (kataState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Fout bij laden kata',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                kataState.error ?? 'Onbekende fout',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goToHome(),
                child: const Text('Naar Home'),
              ),
            ],
          ),
        ),
      );
    }

    try {
      final kata = kataState.katas.firstWhere(
        (k) => k.id == kataId,
      );
      return EditKataScreen(kata: kata);
    } catch (e) {
      return Scaffold(
        appBar: AppBar(title: const Text('Fout')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Kata niet gevonden',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'De kata die je zoekt bestaat niet.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.goToHome(),
                child: const Text('Naar Home'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

/// Navigation analytics helper
class NavigationAnalytics {
  /// Track navigation events
  static void trackNavigation(String from, String to) {
    // Implement your analytics tracking here
    // Example: Firebase Analytics, Mixpanel, etc.
    debugPrint('Navigation: $from -> $to');
  }
  
  /// Track deep link usage
  static void trackDeepLink(String link) {
    // Implement deep link analytics
    debugPrint('Deep link opened: $link');
  }
}
