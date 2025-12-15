import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_boundary_notifier.dart';
import 'error_boundary_state.dart';

// Provider for the ErrorBoundaryNotifier
final errorBoundaryProvider = StateNotifierProvider<ErrorBoundaryNotifier, ErrorBoundaryState>((ref) {
  return ErrorBoundaryNotifier();
});

// Convenience providers
final hasErrorProvider = Provider<bool>((ref) {
  return ref.watch(errorBoundaryProvider).isVisible;
});

final currentErrorProvider = Provider<String?>((ref) {
  final state = ref.watch(errorBoundaryProvider);
  return state.isVisible ? state.error : null;
});

final errorTimestampProvider = Provider<DateTime?>((ref) {
  return ref.watch(errorBoundaryProvider).timestamp;
});
