import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/offline_queue_service.dart';
import '../services/comment_cache_service.dart';
import '../services/conflict_resolution_service.dart';
import '../services/offline_sync_service.dart';
import '../services/offline_kata_service.dart';
import '../services/offline_ohyo_service.dart';
import '../services/offline_forum_service.dart';
import 'interaction_provider.dart';
import 'auth_provider.dart';

// Initialize offline services
final offlineServicesInitializerProvider = FutureProvider<void>((ref) async {
  // Wait for Supabase to be initialized by ensuring auth service is ready
  final _ = ref.watch(authServiceProvider);

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

  // Get offline sync service and inject services
  final offlineSyncService = OfflineSyncService();
  offlineSyncService.initializeOfflineServices(
    offlineQueueService,
    commentCacheService,
    conflictResolutionService,
    interactionService,
  );

  // Initialize offline sync notifier with queue service
  ref.read(offlineSyncProvider.notifier).initializeOfflineQueueService(offlineQueueService);

  // Clear expired cache on startup
  await commentCacheService.clearExpiredCache();
});

// Override providers for offline services
final offlineQueueServiceProviderOverride = Provider<OfflineQueueService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineQueueService(prefs);
});

final commentCacheServiceProviderOverride = Provider<CommentCacheService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return CommentCacheService(prefs);
});

final conflictResolutionServiceProviderOverride = Provider<ConflictResolutionService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return ConflictResolutionService(prefs);
});

final offlineKataServiceProviderOverride = Provider<OfflineKataService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineKataService(prefs);
});

final offlineOhyoServiceProviderOverride = Provider<OfflineOhyoService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineOhyoService(prefs);
});

final offlineForumServiceProviderOverride = Provider<OfflineForumService>((ref) {
  // Wait for initialization to complete
  final initResult = ref.watch(offlineServicesInitializerProvider);
  initResult.maybeWhen(
    data: (_) => null,
    error: (error, stack) => throw error,
    orElse: () => throw StateError('Offline services not initialized'),
  );

  final prefs = ref.watch(sharedPreferencesProvider);
  return OfflineForumService(prefs);
});

// Helper provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized');
});

// Provider that waits for offline services to be initialized
final offlineServicesReadyProvider = Provider<bool>((ref) {
  final initializer = ref.watch(offlineServicesInitializerProvider);
  return initializer.maybeWhen(
    data: (_) => true,
    orElse: () => false,
  );
});
