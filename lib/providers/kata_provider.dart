import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kata_model.dart';
import '../services/offline_kata_service.dart';
import '../utils/image_utils.dart';
import '../utils/retry_utils.dart';
import '../core/storage/local_storage.dart' as app_storage;
import 'error_boundary_provider.dart';
import 'offline_services_provider.dart';
import 'interaction_provider.dart';

// OfflineKataService provider is now imported from offline_services_provider.dart

// StateNotifier for kata management
class KataNotifier extends StateNotifier<KataState> {
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;
  OfflineKataService? _offlineKataService;

  KataNotifier(this._errorBoundary, this._ref) : super(KataState.initial()) {
    // Don't auto-load katas on initialization - wait for explicit call
  }

  void initializeOfflineService(OfflineKataService offlineKataService) {
    _offlineKataService = offlineKataService;
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Initialize kata loading when user is authenticated and on home screen
  void initializeKataLoading() {
    // Only load if we haven't loaded yet and not currently loading
    if (state.katas.isEmpty && !state.isLoading && state.error == null) {
      Future.microtask(() => loadKatas());
    }
  }

  Future<void> loadKatas() async {
    state = state.copyWith(isLoading: true, error: null);

    List<Kata>? cachedKatas;

    // First, try to load from cache if available
    if (_offlineKataService != null) {
      try {
        cachedKatas = await _offlineKataService!.getValidCachedKatas();
        if (cachedKatas != null && cachedKatas.isNotEmpty) {
          // Load cached katas first for immediate UI feedback
          state = state.copyWith(
            katas: cachedKatas,
            filteredKatas: cachedKatas,
            isLoading: true, // Keep loading true while we try to refresh from online
            error: null,
            isOfflineMode: true,
          );

          // Preload images for cached katas
          if (cachedKatas.isNotEmpty) {
            _preloadInitialKataImages(cachedKatas.take(3).toList());
          }
        } else {
          // If SharedPreferences cache is empty/expired, try Hive storage
          try {
            final hiveCachedKatas = app_storage.LocalStorage.getAllKatas();
            if (hiveCachedKatas.isNotEmpty) {
              // Convert CachedKata to Kata with likes data
              cachedKatas = hiveCachedKatas.map((cachedKata) {
                return Kata(
                  id: cachedKata.id,
                  name: cachedKata.name,
                  description: cachedKata.description,
                  style: cachedKata.style ?? '',
                  createdAt: cachedKata.createdAt,
                  imageUrls: cachedKata.imageUrls,
                  videoUrls: [], // Not stored in CachedKata
                  order: 0, // Not stored in CachedKata
                  isLiked: cachedKata.isLiked, // Include cached likes data
                  likeCount: cachedKata.likeCount, // Include cached like count
                );
              }).toList();

              // Load cached katas from Hive for immediate UI feedback
              state = state.copyWith(
                katas: cachedKatas,
                filteredKatas: cachedKatas,
                isLoading: true, // Keep loading true while we try to refresh from online
                error: null,
                isOfflineMode: true,
              );

              // Preload images for cached katas
              if (cachedKatas.isNotEmpty) {
                _preloadInitialKataImages(cachedKatas.take(3).toList());
              }
            }
          } catch (e) {
            debugPrint('Error loading Hive cached katas: $e');
          }
        }
      } catch (e) {
        // Ignore cache errors, continue with online loading
      }
    }

    // Then try to load from online
    try {
      await RetryUtils.executeWithRetry(
        () async {
          final response = await _supabase
              .from("katas")
              .select()
              .order('order', ascending: true);

          final onlineKatas = (response as List)
              .map((data) => Kata.fromMap(data as Map<String, dynamic>))
              .toList();

          // Cache the online data
          if (_offlineKataService != null) {
            await _offlineKataService!.cacheKatas(onlineKatas);
          }

          // Update state with online data
          state = state.copyWith(
            katas: onlineKatas,
            filteredKatas: onlineKatas,
            isLoading: false,
            error: null,
            isOfflineMode: false,
          );

          // Preload images for online katas
          if (onlineKatas.isNotEmpty) {
            _preloadInitialKataImages(onlineKatas.take(3).toList());
          }

          // Preload likes for all katas to ensure offline availability
          await _preloadKataLikes(onlineKatas);
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for loading katas
        },
      );
    } catch (e) {
      // Online loading failed
      if (cachedKatas != null && cachedKatas.isNotEmpty) {
        // We have cached data, show it with offline indicator
        state = state.copyWith(
          isLoading: false,
          error: null,
          isOfflineMode: true,
        );
      } else {
        // No cached data available, show error
        final errorMessage = 'Failed to load katas: ${e.toString()}';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
          isOfflineMode: false,
        );

        // Only report to error boundary if it's not a network error
        if (!_isNetworkError(e)) {
          _errorBoundary.reportNetworkError(errorMessage);
        }
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('socket') ||
           errorString.contains('dns') ||
           errorString.contains('host');
  }

  /// Preload images for initial katas to improve perceived performance
  void _preloadInitialKataImages(List<Kata> initialKatas) {
    // Load images in background without blocking UI
    for (final kata in initialKatas) {
      if (kata.imageUrls?.isEmpty ?? true) {
        Future.microtask(() => loadKataImages(kata.id));
      }
    }
  }

  // Preload likes for all katas to ensure offline availability
  Future<void> _preloadKataLikes(List<Kata> katas) async {
    try {
      // Load likes for all katas in parallel to speed up the process
      final likeFutures = katas.map((kata) async {
        try {
          final likes = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.getKataLikes(kata.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          final isLiked = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.isKataLiked(kata.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          return {
            'kataId': kata.id,
            'likes': likes,
            'isLiked': isLiked,
          };
        } catch (e) {
          // If loading likes fails, return null data
          return {
            'kataId': kata.id,
            'likes': <dynamic>[],
            'isLiked': false,
          };
        }
      });

      final likeResults = await Future.wait(likeFutures);

      // Update cached data with likes information
      for (final result in likeResults) {
        final kataId = result['kataId'] as int;
        final likes = result['likes'] as List;
        final isLiked = result['isLiked'] as bool;

        // Update the cached kata with likes data
        final cachedKata = app_storage.LocalStorage.getKata(kataId);
        if (cachedKata != null) {
          final updatedKata = app_storage.CachedKata(
            id: cachedKata.id,
            name: cachedKata.name,
            description: cachedKata.description,
            createdAt: cachedKata.createdAt,
            lastSynced: DateTime.now(),
            imageUrls: cachedKata.imageUrls,
            style: cachedKata.style,
            isFavorite: cachedKata.isFavorite,
            needsSync: cachedKata.needsSync,
            isLiked: isLiked,
            likeCount: likes.length,
          );
          await app_storage.LocalStorage.saveKata(updatedKata);
        }
      }

      // Reduced spam: Only log if there were errors or significant issues
    } catch (e) {
      debugPrint('⚠️ Failed to preload kata likes: $e');
      // Don't throw - likes preloading failure shouldn't break the app
    }
  }

  /// Lazily load images for a specific kata
  Future<void> loadKataImages(int kataId, {dynamic ref}) async {
    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(kataId, ref: ref);

      // Update the kata with loaded images
      final updatedKatas = state.katas.map((kata) {
        if (kata.id == kataId) {
          return kata.copyWith(imageUrls: imageUrls);
        }
        return kata;
      }).toList();

      state = state.copyWith(
        katas: updatedKatas,
        filteredKatas: _filterKatas(updatedKatas, state.searchQuery, state.selectedCategory),
      );
    } catch (e) {
      // Silently fail - images are not critical for functionality
      debugPrint('⚠️ Failed to load images for kata $kataId: $e');
    }
  }

  Future<void> refreshKatas() async {
    await loadKatas();
  }

  Future<int> _getNextAvailableId() async {
    try {
      final response = await _supabase.from("katas").select("id");
      final katas = List<Map<String, dynamic>>.from(response);

      if (katas.isEmpty) {
        return 1;
      }

      int maxId = 0;
      for (final kata in katas) {
        if (kata.containsKey('id')) {
          final id = kata['id'];
          if (id is int && id > maxId) {
            maxId = id;
          } else if (id is String) {
            final parsedId = int.tryParse(id);
            if (parsedId != null && parsedId > maxId) {
              maxId = parsedId;
            }
          }
        }
      }

      return maxId + 1;
    } catch (e) {
      return 1;
    }
  }

  Future<void> addKata({
    required String name,
    required String description,
    required String style,
    List<File>? images,
    List<String>? videoUrls,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          final nextId = await _getNextAvailableId();
          final nextOrder = state.katas.length; // New kata gets the next order position
          
          final kataData = {
            "id": nextId,
            "name": name,
            "description": description,
            "style": style,
            "created_at": DateTime.now().toIso8601String(),
            "order": nextOrder,
            "video_urls": videoUrls,
          };

          // Insert kata into database
          await _supabase.from("katas").insert(kataData);

          // Upload images if provided
          List<String> imageUrls = [];
          if (images != null && images.isNotEmpty) {
            imageUrls = await ImageUtils.uploadMultipleImagesToSupabase(
              images,
              nextId,
            );
          }

          // Create new kata object with images already loaded (since we just uploaded them)
          final newKata = Kata(
            id: nextId,
            name: name,
            description: description,
            style: style,
            createdAt: DateTime.now(),
            imageUrls: imageUrls,
            videoUrls: videoUrls,
            order: nextOrder,
          );

          // Update state with new kata
          final updatedKatas = [...state.katas, newKata];
          state = state.copyWith(
            katas: updatedKatas,
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery, state.selectedCategory),
            isLoading: false,
            error: null,
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for adding kata
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to add kata: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> deleteKata(int kataId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // First, try to delete images from storage
          // We do this first to ensure images are cleaned up even if kata deletion fails
          try {
            await ImageUtils.deleteAllKataImages(kataId);
          } catch (imageError) {
            // Log the image deletion error but don't fail the entire operation
            // Still continue with kata deletion to avoid orphaned database records
          }

          // Delete kata from database
          await _supabase.from("katas").delete().eq('id', kataId);

          // Update state by removing the kata
          final updatedKatas = state.katas.where((kata) => kata.id != kataId).toList();
          state = state.copyWith(
            katas: updatedKatas,
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery, state.selectedCategory),
            isLoading: false,
            error: null,
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for deleting kata
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to delete kata: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  void searchKatas(String query) {
    final filteredKatas = _filterKatas(state.katas, query, state.selectedCategory);
    state = state.copyWith(
      searchQuery: query,
      filteredKatas: filteredKatas,
    );
  }

  void filterByCategory(KataCategory? category) {
    final filteredKatas = _filterKatas(state.katas, state.searchQuery, category);
    state = state.copyWith(
      selectedCategory: category,
      filteredKatas: filteredKatas,
    );
  }

  List<Kata> _filterKatas(List<Kata> katas, String query, KataCategory? category) {
    var filtered = katas;
    
    // Filter by category first
    if (category != null && category != KataCategory.all) {
      filtered = filtered.where((kata) {
        final kataCategory = KataCategory.fromStyle(kata.style);
        return kataCategory == category;
      }).toList();
    }
    
    // Then filter by search query
    if (query.isNotEmpty) {
      final queryLower = query.toLowerCase();
      
      // Filter katas based on name and description
      filtered = filtered.where((kata) {
        final nameMatch = kata.name.toLowerCase().contains(queryLower);
        final descMatch = kata.description.toLowerCase().contains(queryLower);
        return nameMatch || descMatch;
      }).toList();
      
      // Sort results to prioritize exact matches and name matches over description matches
      filtered.sort((a, b) {
        final aNameLower = a.name.toLowerCase();
        final bNameLower = b.name.toLowerCase();
        final aDescLower = a.description.toLowerCase();
        final bDescLower = b.description.toLowerCase();
        
        // Exact name matches first
        final aExactName = aNameLower == queryLower;
        final bExactName = bNameLower == queryLower;
        if (aExactName && !bExactName) return -1;
        if (!aExactName && bExactName) return 1;
        
        // Name starts with query
        final aStartsWithName = aNameLower.startsWith(queryLower);
        final bStartsWithName = bNameLower.startsWith(queryLower);
        if (aStartsWithName && !bStartsWithName) return -1;
        if (!aStartsWithName && bStartsWithName) return 1;
        
        // Name contains query (already filtered, so both contain it)
        final aNameMatch = aNameLower.contains(queryLower);
        final bNameMatch = bNameLower.contains(queryLower);
        final aDescMatch = aDescLower.contains(queryLower);
        final bDescMatch = bDescLower.contains(queryLower);
        
        // Prioritize name matches over description matches
        if (aNameMatch && !bNameMatch) return -1;
        if (!aNameMatch && bNameMatch) return 1;
        if (aDescMatch && !bDescMatch) return -1;
        if (!aDescMatch && bDescMatch) return 1;
        
        // Finally, sort alphabetically by name
        return aNameLower.compareTo(bNameLower);
      });
    }
    
    return filtered;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  Future<void> updateKata({
    required int kataId,
    required String name,
    required String description,
    required String style,
    List<String>? videoUrls,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Update kata in database - only update specific fields, not user-related fields
          final updateData = <String, dynamic>{
            'name': name,
            'description': description,
            'style': style,
            'video_urls': videoUrls,
          };
          
          await _supabase.from("katas").update(updateData).eq('id', kataId);

          // Update local state
          final updatedKatas = state.katas.map((kata) {
            if (kata.id == kataId) {
              return kata.copyWith(
                name: name,
                description: description,
                style: style,
                videoUrls: videoUrls,
              );
            }
            return kata;
          }).toList();

          state = state.copyWith(
            katas: updatedKatas,
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery, state.selectedCategory),
            isLoading: false,
            error: null,
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for updating kata
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to update kata: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Report to global error boundary
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> updateKataImages(int kataId, List<String> newImageUrls) async {
    final updatedKatas = state.katas.map((kata) {
      if (kata.id == kataId) {
        return kata.copyWith(imageUrls: newImageUrls);
      }
      return kata;
    }).toList();

    state = state.copyWith(
      katas: updatedKatas,
      filteredKatas: _filterKatas(updatedKatas, state.searchQuery, state.selectedCategory),
    );
  }


  Future<void> reorderKatas(int oldIndex, int newIndex) async {
    // Don't reorder if search is active
    if (state.searchQuery.isNotEmpty) {
      return;
    }

    try {
      // Create a copy of the current katas list
      final katas = List<Kata>.from(state.katas);
      
      // Adjust newIndex if moving down
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      
      // Move the item
      final kata = katas.removeAt(oldIndex);
      katas.insert(newIndex, kata);
      
      // Update the order values
      final updatedKatas = <Kata>[];
      for (int i = 0; i < katas.length; i++) {
        updatedKatas.add(katas[i].copyWith(order: i));
      }
      
      // Update local state immediately for smooth UI
      state = state.copyWith(
        katas: updatedKatas,
        filteredKatas: updatedKatas,
      );
      
      // Update database in background
      await _updateKataOrdersInDatabase(updatedKatas);
      
    } catch (e) {
      // If database update fails, reload from database
      await loadKatas();
      
      final errorMessage = 'Failed to reorder katas: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      _errorBoundary.reportNetworkError(errorMessage);
    }
  }

  Future<void> _updateKataOrdersInDatabase(List<Kata> katas) async {
    await RetryUtils.executeWithRetry(
      () async {
        // Update all kata orders in a batch
        for (final kata in katas) {
          await _supabase
              .from("katas")
              .update({'order': kata.order})
              .eq('id', kata.id);
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryError,
      onRetry: (attempt, error) {
        // Retry attempt for updating kata orders
      },
    );
  }

  /// Update cached images for a specific kata
  void updateKataCachedImages(int kataId, List<String> imageUrls) {
    final updatedKatas = state.katas.map((kata) {
      if (kata.id == kataId) {
        return kata.copyWith(imageUrls: imageUrls);
      }
      return kata;
    }).toList();

    final updatedFilteredKatas = state.filteredKatas.map((kata) {
      if (kata.id == kataId) {
        return kata.copyWith(imageUrls: imageUrls);
      }
      return kata;
    }).toList();

    state = state.copyWith(
      katas: updatedKatas,
      filteredKatas: updatedFilteredKatas,
    );
  }

  /// Clean up orphaned images that don't belong to any existing kata
  /// SAFE cleanup function - only removes specific temporary folders
  /// This is much safer than the previous cleanup function
  Future<List<String>> safeCleanupTempFolders() async {
    try {
      // Use the safe cleanup function that only targets known temporary folders
      final deletedPaths = await ImageUtils.safeCleanupTempFolders();

      // Cleanup completed successfully

      return deletedPaths;
    } catch (e) {
      final errorMessage = 'Failed to cleanup temporary folders: ${e.toString()}';
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }
}

// Provider for the KataNotifier
final kataNotifierProvider = StateNotifierProvider<KataNotifier, KataState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  final notifier = KataNotifier(errorBoundary, ref);

  // Initialize offline service if available (catch errors if not initialized yet)
  try {
    final offlineKataService = ref.watch(offlineKataServiceProvider);
    notifier.initializeOfflineService(offlineKataService);
  } catch (e) {
    // Offline service not available yet, will be initialized later
  }

  return notifier;
});

// Convenience providers for specific kata state properties
final katasProvider = Provider<List<Kata>>((ref) {
  return ref.watch(kataNotifierProvider).filteredKatas;
});

final kataLoadingProvider = Provider<bool>((ref) {
  return ref.watch(kataNotifierProvider).isLoading;
});

final kataOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(kataNotifierProvider).isOfflineMode;
});

final kataErrorProvider = Provider<String?>((ref) {
  return ref.watch(kataNotifierProvider).error;
});

final kataSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(kataNotifierProvider).searchQuery;
});

final kataSelectedCategoryProvider = Provider<KataCategory?>((ref) {
  return ref.watch(kataNotifierProvider).selectedCategory;
});

// Family provider for individual kata by ID
final kataByIdProvider = Provider.family<Kata?, int>((ref, kataId) {
  final katas = ref.watch(kataNotifierProvider).katas;
  try {
    return katas.firstWhere((kata) => kata.id == kataId);
  } catch (e) {
    return null;
  }
});

// Family provider for kata images
final kataImagesProvider = FutureProvider.family<List<String>, int>((ref, kataId) async {
  return await ImageUtils.fetchKataImagesFromBucket(kataId, ref: ref);
});
