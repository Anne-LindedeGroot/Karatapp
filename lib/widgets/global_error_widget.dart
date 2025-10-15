import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/error_boundary_provider.dart';

class GlobalErrorWidget extends ConsumerWidget {
  const GlobalErrorWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = ref.watch(hasErrorProvider);
    final currentError = ref.watch(currentErrorProvider);

    if (!hasError || currentError == null) {
      return const SizedBox.shrink();
    }

    // Use a simple container instead of Positioned to avoid render object conflicts
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 16,
        right: 16,
      ),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Error',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentError,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      ref.read(errorBoundaryProvider.notifier).retryLastOperation();
                    },
                    child: Text(
                      'Opnieuw proberen',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      ref.read(errorBoundaryProvider.notifier).hideError();
                    },
                    icon: Icon(
                      Icons.close,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlobalErrorBoundary extends ConsumerWidget {
  final Widget child;

  const GlobalErrorBoundary({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use Column instead of Stack to avoid render object conflicts
    return Column(
      children: [
        const GlobalErrorWidget(),
        Expanded(child: child),
      ],
    );
  }
}
