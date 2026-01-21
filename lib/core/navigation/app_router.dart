import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../screens/auth/auth_wrapper.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/forum/forum_screen.dart';
import '../../screens/forum/forum_post_detail_screen.dart';
import '../../screens/create_forum_post_screen.dart';
import '../../screens/favorites/favorites_screen.dart';
import '../../screens/kata/edit_kata_screen.dart';
import '../../screens/kata/create_kata_screen.dart';
import '../../screens/ohyo/create_ohyo_screen.dart';
import '../../screens/ohyo/edit_ohyo_screen.dart';
import '../../screens/profile/avatar_selection_screen.dart';
import '../../screens/admin/user_management_screen.dart';
import '../../screens/accessibility_demo_screen.dart';
import '../../screens/tts_test_screen.dart';
import '../../screens/auth/password_reset_screen.dart';
import '../../providers/kata_provider.dart';
import '../../providers/ohyo_provider.dart';
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
  static const String createKata = '/create-kata';
  static const String createOhyo = '/create-ohyo';
  static const String editOhyo = '/ohyo/edit/:ohyoId';
  static const String avatarSelection = '/avatar-selection';
  static const String userManagement = '/user-management';
  static const String accessibilityDemo = '/accessibility-demo';
  static const String ttsTest = '/tts-test';
  static const String passwordReset = '/reset-password';
}

/// Router provider for dependency injection
final routerProvider = Provider<GoRouter>((ref) {
  // Create a stable router that doesn't recreate on auth state changes
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    // Remove redirect logic to prevent router recreation
    // Let individual screens handle their own navigation logic
    routes: [
        // Splash screen route - now uses AuthWrapper for proper authentication persistence
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const GlobalErrorBoundary(
            child: AuthWrapper(),
          ),
        ),
      
      // Auth routes - these are now handled by AuthWrapper, but kept for direct navigation
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AuthWrapper(),
        ),
      ),
      
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const GlobalErrorBoundary(
          child: AuthWrapper(),
        ),
      ),

      GoRoute(
        path: AppRoutes.passwordReset,
        name: 'passwordReset',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return GlobalErrorBoundary(
            child: PasswordResetScreen(initialEmail: email),
          );
        },
      ),
      
      // Main app routes - these are now handled by AuthWrapper, but kept for direct navigation
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) {
          // Parse query parameters for initial tab and search
          final tabParam = state.uri.queryParameters['tab'];
          final initialTab = tabParam == 'ohyo' ? 1 : 0;
          final initialSearchQuery = state.uri.queryParameters['search'];
          return GlobalErrorBoundary(
            child: AuthWrapper(
              initialHomeTab: initialTab,
              initialSearchQuery: initialSearchQuery,
            ),
          );
        },
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
        path: AppRoutes.editOhyo,
        name: 'editOhyo',
        builder: (context, state) {
          final ohyoId = int.parse(state.pathParameters['ohyoId']!);
          return GlobalErrorBoundary(
            child: EditOhyoWrapper(ohyoId: ohyoId),
          );
        },
      ),

      GoRoute(
        path: AppRoutes.createKata,
        name: 'createKata',
        builder: (context, state) => const GlobalErrorBoundary(
          child: CreateKataScreen(),
        ),
      ),

      GoRoute(
        path: AppRoutes.createOhyo,
        name: 'createOhyo',
        builder: (context, state) => const GlobalErrorBoundary(
          child: CreateOhyoScreen(),
        ),
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
      
      GoRoute(
        path: AppRoutes.ttsTest,
        name: 'ttsTest',
        builder: (context, state) => const GlobalErrorBoundary(
          child: TTSTestScreen(),
        ),
      ),
      
        
      ],
      
      // Error handling
      errorBuilder: (context, state) {
        return Scaffold(
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
        );
      },
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

  /// Navigate to home screen with ohyo tab selected
  void goToHomeOhyo() => go('/home?tab=ohyo');

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
  void goToEditKata(String kataId) => go('/kata/edit/$kataId');

  /// Navigate to create kata
  void goToCreateKata() => go(AppRoutes.createKata);

  /// Navigate to create ohyo
  void goToCreateOhyo() => go(AppRoutes.createOhyo);

  /// Navigate to edit ohyo
  void goToEditOhyo(String ohyoId) => go('/ohyo/edit/$ohyoId');

  /// Navigate to avatar selection
  void goToAvatarSelection() => go('/profile/avatar-selection');

  /// Navigate to user management
  void goToUserManagement() => go(AppRoutes.userManagement);

  /// Navigate to one-on-one TTS demo

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

  /// Navigate to home screen with ohyo tab selected
  void goToHomeOhyo() => go('/home?tab=ohyo');

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
  void goToEditKata(String kataId) => go('/kata/edit/$kataId');

  /// Navigate to edit ohyo
  void goToEditOhyo(String ohyoId) => go('/ohyo/edit/$ohyoId');

  /// Navigate to create kata
  void goToCreateKata() => go(AppRoutes.createKata);

  /// Navigate to create ohyo
  void goToCreateOhyo() => go(AppRoutes.createOhyo);

  /// Navigate to avatar selection
  void goToAvatarSelection() => go('/profile/avatar-selection');

  /// Navigate to user management
  void goToUserManagement() => go(AppRoutes.userManagement);

  /// Navigate to one-on-one TTS demo

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
class EditKataWrapper extends ConsumerStatefulWidget {
  final int kataId;

  const EditKataWrapper({
    required this.kataId,
    super.key,
  });

  @override
  ConsumerState<EditKataWrapper> createState() => _EditKataWrapperState();
}

/// Wrapper widget to load ohyo by ID for EditOhyoScreen
class EditOhyoWrapper extends ConsumerStatefulWidget {
  final int ohyoId;

  const EditOhyoWrapper({
    required this.ohyoId,
    super.key,
  });

  @override
  ConsumerState<EditOhyoWrapper> createState() => _EditOhyoWrapperState();
}

class _EditKataWrapperState extends ConsumerState<EditKataWrapper> {
  bool _hasTriedLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure katas are loaded when accessing edit screen directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kataState = ref.read(kataNotifierProvider);
      if (kataState.katas.isEmpty && !kataState.isLoading && !_hasTriedLoading) {
        _hasTriedLoading = true;
        ref.read(kataNotifierProvider.notifier).loadKatas();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        (k) => k.id == widget.kataId,
      );
      return EditKataScreen(kata: kata);
    } catch (e) {
      // If kata not found and we're not currently loading, try loading
      if (!kataState.isLoading && !_hasTriedLoading) {
        _hasTriedLoading = true;
        // Load katas immediately in the build method
        Future.microtask(() => ref.read(kataNotifierProvider.notifier).loadKatas());
      }

      // Show loading if we're loading or just started loading
      if (kataState.isLoading || !_hasTriedLoading) {
        return Scaffold(
          appBar: AppBar(title: const Text('Laden...')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      // If we tried loading and still can't find the kata, show error
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
                'De kata die je zoekt bestaat niet of kon niet worden geladen.',
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

class _EditOhyoWrapperState extends ConsumerState<EditOhyoWrapper> {
  bool _hasTriedLoading = false;

  @override
  void initState() {
    super.initState();
    // Ensure ohyos are loaded when accessing edit screen directly
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ohyoState = ref.read(ohyoNotifierProvider);
      if (ohyoState.ohyos.isEmpty && !ohyoState.isLoading && !_hasTriedLoading) {
        _hasTriedLoading = true;
        ref.read(ohyoNotifierProvider.notifier).initializeOhyoLoading();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ohyoState = ref.watch(ohyoNotifierProvider);

    if (ohyoState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Laden...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (ohyoState.error != null) {
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
                'Fout bij laden ohyo',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                ohyoState.error ?? 'Onbekende fout',
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
      final ohyo = ohyoState.ohyos.firstWhere(
        (o) => o.id == widget.ohyoId,
      );
      return EditOhyoScreen(ohyo: ohyo);
    } catch (e) {
      // If ohyo not found and we're not currently loading, try loading
      if (!ohyoState.isLoading && !_hasTriedLoading) {
        _hasTriedLoading = true;
        // Load ohyos immediately in the build method
        Future.microtask(() => ref.read(ohyoNotifierProvider.notifier).initializeOhyoLoading());
      }

      // Show loading if we're loading or just started loading
      if (ohyoState.isLoading || !_hasTriedLoading) {
        return Scaffold(
          appBar: AppBar(title: const Text('Laden...')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }

      // If we tried loading and still can't find the ohyo, show error
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
                'Ohyo niet gevonden',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'De ohyo met ID ${widget.ohyoId} bestaat niet of kon niet worden geladen.',
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
