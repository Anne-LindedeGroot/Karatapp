import 'package:flutter/material.dart';

/// Screen types for intelligent content reading
enum ScreenType {
  overlay,
  form,
  auth,
  home,
  profile,
  forum,
  forumDetail,
  createPost,
  editPost,
  createKata,
  editKata,
  favorites,
  userManagement,
  avatarSelection,
  accessibility,
  generic,
}

/// TTS Screen Detector - Detects current screen type for intelligent content reading
class TTSScreenDetector {
  /// Detect the current screen type for intelligent content reading
  static ScreenType detectCurrentScreenType(BuildContext context) {
    try {
      // Check if context is still mounted
      if (!context.mounted) {
        debugPrint('TTS: Context no longer mounted in _detectCurrentScreenType');
        return ScreenType.generic;
      }
      
      // First check for overlays and dialogs
      if (_hasOverlay(context)) {
        return ScreenType.overlay;
      }
      
      // Check for forms
      if (_hasForm(context)) {
        return ScreenType.form;
      }
      
      // Get route information
      final modalRoute = ModalRoute.of(context);
      if (modalRoute?.settings.name != null) {
        final routeName = modalRoute!.settings.name!;
        return _getScreenTypeFromRoute(routeName);
      }
      
      // Fallback to generic screen
      return ScreenType.generic;
    } catch (e) {
      debugPrint('TTS: Error detecting screen type: $e');
      return ScreenType.generic;
    }
  }

  /// Check if there's an overlay (dialog, bottom sheet, etc.)
  static bool _hasOverlay(BuildContext context) {
    try {
      // Check for dialogs
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        // Check if we're in a dialog by looking at the route
        final route = ModalRoute.of(context);
        if (route != null) {
          final routeName = route.settings.name ?? '';
          if (routeName.contains('dialog') || 
              routeName.contains('bottomSheet') ||
              routeName.contains('modal')) {
            return true;
          }
        }
      }
      
      // Check for bottom sheets
      final scaffold = Scaffold.of(context);
      if (scaffold.hasDrawer || scaffold.hasEndDrawer) {
        // Additional checks for bottom sheets could be added here
      }
      
      return false;
    } catch (e) {
      debugPrint('TTS: Error checking for overlay: $e');
      return false;
    }
  }

  /// Check if current screen has forms
  static bool _hasForm(BuildContext context) {
    try {
      // Look for common form widgets in the widget tree
      final widget = context.widget;
      if (widget is StatefulWidget) {
        // Additional form detection logic could be added here
      }
      return false;
    } catch (e) {
      debugPrint('TTS: Error checking for form: $e');
      return false;
    }
  }

  /// Get screen type from route name
  static ScreenType _getScreenTypeFromRoute(String routeName) {
    final lowerRouteName = routeName.toLowerCase();
    
    switch (lowerRouteName) {
      case '/':
      case '/home':
        return ScreenType.home;
      case '/login':
      case '/signup':
      case '/auth':
        return ScreenType.auth;
      case '/profile':
        return ScreenType.profile;
      case '/forum':
        return ScreenType.forum;
      case '/forum/post/':
        return ScreenType.forumDetail;
      case '/forum/create':
        return ScreenType.createPost;
      case '/forum/edit':
        return ScreenType.editPost;
      case '/kata/create':
        return ScreenType.createKata;
      case '/kata/edit':
        return ScreenType.editKata;
      case '/favorites':
        return ScreenType.favorites;
      case '/user-management':
        return ScreenType.userManagement;
      case '/avatar-selection':
        return ScreenType.avatarSelection;
      case '/accessibility-demo':
        return ScreenType.accessibility;
      default:
        // Check for dynamic routes
        if (lowerRouteName.contains('create') && lowerRouteName.contains('kata')) {
          return ScreenType.createKata;
        } else if (lowerRouteName.contains('edit') && lowerRouteName.contains('kata')) {
          return ScreenType.editKata;
        } else if (lowerRouteName.contains('create') && lowerRouteName.contains('post')) {
          return ScreenType.createPost;
        } else if (lowerRouteName.contains('edit') && lowerRouteName.contains('post')) {
          return ScreenType.editPost;
        } else if (lowerRouteName.contains('login') || 
                   lowerRouteName.contains('signup') || 
                   lowerRouteName.contains('auth') ||
                   lowerRouteName.contains('register')) {
          return ScreenType.auth;
        }
        return ScreenType.generic;
    }
  }

  /// Generate cache key for content caching
  static String generateCacheKey(BuildContext context, ScreenType screenType) {
    try {
      final route = ModalRoute.of(context);
      final routeName = route?.settings.name ?? 'unknown';
      return '${screenType.name}_$routeName';
    } catch (e) {
      debugPrint('TTS: Error generating cache key: $e');
      return '${screenType.name}_error';
    }
  }
}
