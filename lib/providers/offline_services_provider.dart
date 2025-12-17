import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_queue_service.dart';
import '../services/comment_cache_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/offline_sync_service.dart';
import '../services/offline_kata_service.dart';
import '../services/offline_ohyo_service.dart';
import '../services/offline_forum_service.dart';
import '../main.dart' as main_app;
import 'interaction_provider.dart' show interactionServiceProvider;
import 'auth_provider.dart';
import 'network_provider.dart';
import 'data_usage_provider.dart';

// Provider for SharedPreferences instance
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  // SharedPreferences is initialized in main.dart, but we provide async access for consistency
  return await SharedPreferences.getInstance();
});

// Initialize offline services
final offlineServicesInitializerProvider = FutureProvider<void>((ref) async {
  // Wait for Supabase to be initialized by ensuring auth service is ready
  final _ = ref.watch(authServiceProvider);

  // Create offline services with a temporary prefs instance
  // This will be replaced when SharedPreferences is properly available
  final prefs = await SharedPreferences.getInstance();

  // Create offline services
  final offlineQueueService = OfflineQueueService(prefs);
  final commentCacheService = CommentCacheService(prefs);
  final conflictResolutionService = ConflictResolutionService(prefs);

  // Get interaction service and inject offline services
  final interactionService = ref.read(interactionServiceProvider);
  interactionService.initializeOfflineServices(
    offlineQueueService,
    commentCacheService,
  );

  // Initialize offline sync notifier with all services
  ref.read(offlineSyncProvider.notifier).initializeServices(
    offlineQueueService,
    commentCacheService,
    conflictResolutionService,
    interactionService,
  );

  // Start background sync automatically
  try {
    // Start periodic background sync
    ref.read(offlineSyncProvider.notifier).startBackgroundSync(ref);

    // Trigger initial sync with a small delay to allow app to settle
    Future.delayed(const Duration(seconds: 3), () async {
      // First do the basic metadata sync
      await ref.read(offlineSyncProvider.notifier).startFullSync(ref);

      // Then check if comprehensive cache has been done
      final isComprehensiveDone = await ref.read(offlineSyncProvider.notifier).isComprehensiveCacheCompleted();

      // If comprehensive cache hasn't been done and we're connected, do it automatically
      final networkState = ref.read(networkProvider);
      final dataUsageState = ref.read(dataUsageProvider);

      if (!isComprehensiveDone && networkState.isConnected && dataUsageState.shouldAllowDataUsage) {
        debugPrint('🏗️ Automatically starting comprehensive cache on first app launch...');
        await ref.read(offlineSyncProvider.notifier).comprehensiveCache(ref);
      }
    });
  } catch (e) {
    debugPrint('Error during offline sync initialization: $e');
    // Ignore errors during sync startup
  }

  // Clear expired cache on startup
  await commentCacheService.clearExpiredCache();
});

// Override providers for offline services (renamed to match the ones they override)
final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  // Since SharedPreferences is initialized in main.dart, we can access it synchronously
  return OfflineQueueService(main_app.getSharedPreferences());
});

final commentCacheServiceProvider = Provider<CommentCacheService>((ref) {
  return CommentCacheService(main_app.getSharedPreferences());
});

final conflictResolutionServiceProvider = Provider<ConflictResolutionService>((ref) {
  return ConflictResolutionService(main_app.getSharedPreferences());
});

final offlineKataServiceProvider = Provider<OfflineKataService>((ref) {
  return OfflineKataService(main_app.getSharedPreferences());
});

final offlineOhyoServiceProvider = Provider<OfflineOhyoService>((ref) {
  return OfflineOhyoService(main_app.getSharedPreferences());
});

final offlineForumServiceProvider = Provider<OfflineForumService>((ref) {
  return OfflineForumService(main_app.getSharedPreferences());
});

// The sharedPreferencesProvider is defined at the top of this file

// Provider that waits for offline services to be initialized
final offlineServicesReadyProvider = Provider<bool>((ref) {
  final initializer = ref.watch(offlineServicesInitializerProvider);
  return initializer.maybeWhen(
    data: (_) => true,
    orElse: () => false,
  );
});
