import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/precaching_service.dart';
import 'network_provider.dart';
import 'data_usage_provider.dart';
import 'kata_provider.dart';
import 'ohyo_provider.dart';

/// Provider for managing pre-caching operations
class PreCachingNotifier extends StateNotifier<PreCachingState> {
  PreCachingNotifier() : super(PreCachingState.initial()) {
    _setupPreCachingTriggers();
  }

  Timer? _debounceTimer;
  static const Duration _debounceDuration = Duration(seconds: 5);

  bool _isRefMounted(dynamic ref) {
    try {
      final mounted = ref.mounted;
      if (mounted is bool) {
        return mounted;
      }
    } catch (_) {
      // Ref doesn't expose mounted, assume valid
    }
    return true;
  }

  void _setupPreCachingTriggers() {
    // This will be called when providers are available
    // The actual pre-caching will be triggered from UI components
    // that have access to ref.read()
  }

  /// Trigger pre-caching of all media when conditions are met
  Future<void> triggerPreCaching(dynamic ref) async {
    // Debounce to avoid multiple rapid calls
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () async {
      if (!_isRefMounted(ref)) return;
      await _performPreCaching(ref);
    });
  }

  Future<void> _performPreCaching(dynamic ref) async {
    try {
      if (!_isRefMounted(ref)) return;
      state = state.copyWith(isPreCaching: true, lastPreCacheAttempt: DateTime.now());

      await PreCachingService.preCacheAllMedia(ref);

      state = state.copyWith(
        isPreCaching: false,
        lastPreCacheSuccess: DateTime.now(),
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isPreCaching: false,
        error: e.toString(),
      );
    }
  }

  /// Force immediate pre-caching
  Future<void> forcePreCache(dynamic ref) async {
    await _performPreCaching(ref);
  }

  /// Check if pre-caching should be triggered
  bool shouldTriggerPreCaching(dynamic ref) {
    // Check if we're online
    final networkState = ref.read(networkProvider);
    if (!networkState.isConnected) return false;

    // Check data usage permission
    final dataUsageState = ref.read(dataUsageProvider);
    if (!dataUsageState.shouldAllowDataUsage) return false;

    // Check if we have data to cache
    final kataState = ref.read(kataNotifierProvider);
    final ohyoState = ref.read(ohyoNotifierProvider);

    final hasKatas = kataState.katas.isNotEmpty;
    final hasOhyos = ohyoState.ohyos.isNotEmpty;

    // Require at least some data to be loaded
    if (!hasKatas && !hasOhyos) return false;

    // Check if we recently attempted pre-caching (reduce frequency to avoid spam)
    final lastAttempt = state.lastPreCacheAttempt;
    if (lastAttempt != null) {
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      // Don't pre-cache more than once every 2 hours unless forced
      if (timeSinceLastAttempt < const Duration(hours: 2)) return false;
    }

    return true;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

class PreCachingState {
  final bool isPreCaching;
  final DateTime? lastPreCacheAttempt;
  final DateTime? lastPreCacheSuccess;
  final String? error;

  const PreCachingState({
    required this.isPreCaching,
    this.lastPreCacheAttempt,
    this.lastPreCacheSuccess,
    this.error,
  });

  factory PreCachingState.initial() {
    return const PreCachingState(isPreCaching: false);
  }

  PreCachingState copyWith({
    bool? isPreCaching,
    DateTime? lastPreCacheAttempt,
    DateTime? lastPreCacheSuccess,
    String? error,
  }) {
    return PreCachingState(
      isPreCaching: isPreCaching ?? this.isPreCaching,
      lastPreCacheAttempt: lastPreCacheAttempt ?? this.lastPreCacheAttempt,
      lastPreCacheSuccess: lastPreCacheSuccess ?? this.lastPreCacheSuccess,
      error: error ?? this.error,
    );
  }
}

// Provider for pre-caching state
final preCachingProvider = StateNotifierProvider<PreCachingNotifier, PreCachingState>((ref) {
  return PreCachingNotifier();
});

// Convenience providers
final isPreCachingProvider = Provider<bool>((ref) {
  return ref.watch(preCachingProvider).isPreCaching;
});

final shouldTriggerPreCachingProvider = Provider<bool>((ref) {
  return ref.watch(preCachingProvider.notifier).shouldTriggerPreCaching(ref);
});
