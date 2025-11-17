import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_boundary_provider.dart';

/// Error boundary widget that catches render errors and shows a fallback UI
class ErrorBoundary extends ConsumerStatefulWidget {
  final Widget child;
  final Widget? fallback;
  final String? errorMessage;
  final bool showErrorDialog;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.fallback,
    this.errorMessage,
    this.showErrorDialog = false,
  });

  @override
  ConsumerState<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends ConsumerState<ErrorBoundary> {
  Error? _error;

  @override
  void initState() {
    super.initState();
    // Set up error handling for this subtree
    ErrorWidget.builder = (FlutterErrorDetails details) {
      // Report the error to the global error boundary
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(errorBoundaryProvider.notifier).reportError(
            details.exception.toString(),
            details.stack,
          );
        }
      });

      // Return a minimal error widget
      return Container(
        color: Colors.red.shade50,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red.shade700,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Er is iets misgegaan bij het laden van deze component.',
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show fallback UI if provided
      if (widget.fallback != null) {
        return widget.fallback!;
      }

      // Default fallback
      return Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.orange.shade700,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Component kon niet worden geladen.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    try {
      return widget.child;
    } catch (error, stackTrace) {
      // Catch any synchronous errors during build
      _error = error as Error?;

      // Report to global error boundary
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(errorBoundaryProvider.notifier).reportError(
            error.toString(),
            stackTrace,
          );
        }
      });

      // Return fallback
      return widget.fallback ?? Container(
        color: Colors.grey.shade100,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: Colors.orange.shade700,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              widget.errorMessage ?? 'Component kon niet worden geladen.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
  }
}

/// Simple error boundary that just returns a placeholder when errors occur
class SafeWidget extends StatelessWidget {
  final Widget child;
  final Widget placeholder;

  const SafeWidget({
    super.key,
    required this.child,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return child;
    } catch (e) {
      // Log the error for debugging
      debugPrint('SafeWidget caught error: $e');
      return placeholder;
    }
  }
}
