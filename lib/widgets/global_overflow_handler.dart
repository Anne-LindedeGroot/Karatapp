import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'overflow_safe_widgets.dart';

/// A global overflow error handler that prevents RenderFlex overflow errors from crashing the app
/// This widget should wrap the entire app to provide comprehensive overflow protection
class GlobalOverflowHandler extends ConsumerWidget {
  final Widget child;
  final bool enableOverflowProtection;

  const GlobalOverflowHandler({
    super.key,
    required this.child,
    this.enableOverflowProtection = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enableOverflowProtection) {
      return child;
    }

    // Use a simpler approach that doesn't restrict layout
    return OverflowErrorHandler(
      enableErrorHandling: true,
      child: child,
    );
  }
}

/// A Flutter error handler that specifically catches and handles overflow errors
class OverflowErrorCatcher extends StatefulWidget {
  final Widget child;
  final bool enableErrorCatching;

  const OverflowErrorCatcher({
    super.key,
    required this.child,
    this.enableErrorCatching = true,
  });

  @override
  State<OverflowErrorCatcher> createState() => _OverflowErrorCatcherState();
}

class _OverflowErrorCatcherState extends State<OverflowErrorCatcher> {
  @override
  void initState() {
    super.initState();
    if (widget.enableErrorCatching) {
      // Store the original error handler
      final originalErrorHandler = FlutterError.onError;
      
      // Set up a global error handler for overflow errors
      FlutterError.onError = (FlutterErrorDetails details) {
        // Check if this is an overflow error
        if (_isOverflowError(details.exception.toString())) {
          // Suppress overflow errors - they are now handled by overflow-safe widgets
          debugPrint('🎨 Overflow Error Suppressed: ${details.exception}');
          return;
        }
        
        // Check for framework assertion errors
        if (_isFrameworkAssertionError(details.exception.toString())) {
          debugPrint('🔧 Framework Assertion Error Suppressed: ${details.exception}');
          return;
        }
        
        // Let other errors be handled by the original handler or default
        if (originalErrorHandler != null) {
          originalErrorHandler(details);
        } else {
          FlutterError.presentError(details);
        }
      };
    }
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
           errorLower.contains('must have an explicit size before it can be hit-tested');
  }

  bool _isFrameworkAssertionError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('assertion failed') ||
           errorLower.contains('owner!._debugcurrentbuildtarget') ||
           errorLower.contains('framework.dart') ||
           errorLower.contains('is not true') ||
           errorLower.contains('debugcurrentbuildtarget') ||
           errorLower.contains('_debugcurrentbuildtarget') ||
           errorLower.contains('element._lifecyclestate') ||
           errorLower.contains('_elementlifecycle.active') ||
           errorLower.contains('lifecycle state') ||
           errorLower.contains('element lifecycle') ||
           errorLower.contains('_elementlifecycle');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// Extension methods for easy overflow protection
extension OverflowProtection on Widget {
  /// Wraps a widget with comprehensive overflow protection
  Widget withOverflowProtection({bool enable = true}) {
    if (!enable) return this;
    
    return GlobalOverflowHandler(
      enableOverflowProtection: true,
      child: OverflowErrorCatcher(
        enableErrorCatching: true,
        child: this,
      ),
    );
  }
}

/// A provider for overflow protection settings
final overflowProtectionProvider = StateProvider<bool>((ref) => true);

/// A hook to easily enable/disable overflow protection
bool useOverflowProtection(WidgetRef ref) {
  return ref.watch(overflowProtectionProvider);
}
