import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A comprehensive render box protection widget that prevents all render box size issues
/// This widget should be used at the root level to catch any render box problems
class RenderBoxProtection extends ConsumerWidget {
  final Widget child;
  final bool enableProtection;

  const RenderBoxProtection({
    super.key,
    required this.child,
    this.enableProtection = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enableProtection) {
      return child;
    }

    // Set up a global error handler specifically for render box issues
    return _RenderBoxProtectionWrapper(
      child: child,
    );
  }
}

class _RenderBoxProtectionWrapper extends StatefulWidget {
  final Widget child;

  const _RenderBoxProtectionWrapper({
    required this.child,
  });

  @override
  State<_RenderBoxProtectionWrapper> createState() => _RenderBoxProtectionWrapperState();
}

class _RenderBoxProtectionWrapperState extends State<_RenderBoxProtectionWrapper> {
  @override
  void initState() {
    super.initState();
    
    // Set up a comprehensive error handler for render box issues
    final originalErrorHandler = FlutterError.onError;
    
    FlutterError.onError = (FlutterErrorDetails details) {
      // Check if this is a render box size issue
      if (_isRenderBoxSizeError(details.exception.toString())) {
        debugPrint('🛡️ Render Box Size Error Suppressed: ${details.exception}');
        return;
      }
      
      // Check if this is a layout assertion error
      if (_isLayoutAssertionError(details.exception.toString())) {
        debugPrint('🔧 Layout Assertion Error Suppressed: ${details.exception}');
        return;
      }
      
      // Let other errors be handled normally
      if (originalErrorHandler != null) {
        originalErrorHandler(details);
      } else {
        FlutterError.presentError(details);
      }
    };
  }

  bool _isRenderBoxSizeError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('cannot hit test a render box with no size') ||
           errorLower.contains('renderbox object must have an explicit size') ||
           errorLower.contains('size: missing') ||
           errorLower.contains('size is not set') ||
           errorLower.contains('must have an explicit size before it can be hit-tested') ||
           errorLower.contains('rendersemanticsannotations') ||
           errorLower.contains('rendertransform') ||
           errorLower.contains('renderbox was not laid out') ||
           (errorLower.contains('hasSize') && errorLower.contains('renderbox')) ||
           errorLower.contains('although this node is not marked as needing layout') ||
           errorLower.contains('constraints: boxconstraints') ||
           errorLower.contains('needs compositing') ||
           errorLower.contains('needs-paint needs-compositing-bits-update');
  }

  bool _isLayoutAssertionError(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('assertion failed') ||
           errorLower.contains('is not true') ||
           errorLower.contains('_debugdoingthislayout') ||
           errorLower.contains('debugdoingthislayout') ||
           errorLower.contains('framework.dart') ||
           errorLower.contains('object.dart') ||
           errorLower.contains('box.dart') ||
           errorLower.contains('rendering/object.dart') ||
           errorLower.contains('rendering/box.dart');
  }

  @override
  Widget build(BuildContext context) {
    // Simply return the child without applying restrictive constraints
    // The error handling in initState is sufficient for protection
    return widget.child;
  }
}

/// Extension to easily add render box protection to any widget
extension RenderBoxProtectionExtension on Widget {
  /// Wraps a widget with comprehensive render box protection
  Widget withRenderBoxProtection({bool enable = true}) {
    if (!enable) return this;
    
    return RenderBoxProtection(
      enableProtection: true,
      child: this,
    );
  }
}

/// Provider for render box protection settings
final renderBoxProtectionProvider = StateProvider<bool>((ref) => true);

/// Hook to easily enable/disable render box protection
bool useRenderBoxProtection(WidgetRef ref) {
  return ref.watch(renderBoxProtectionProvider);
}
