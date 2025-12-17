import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ohyo_model.dart';
import '../services/offline_ohyo_service.dart';
import '../utils/image_utils.dart';
import '../utils/retry_utils.dart';
import '../supabase_client.dart';
import '../core/storage/local_storage.dart' as app_storage;
import '../services/offline_media_cache_service.dart';
import 'error_boundary_provider.dart';
import 'offline_services_provider.dart';
import 'interaction_provider.dart';

// OfflineOhyoService provider is now imported from offline_services_provider.dart

// StateNotifier for ohyo management
class OhyoNotifier extends StateNotifier<OhyoState> {
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;
  OfflineOhyoService? _offlineOhyoService;

  OhyoNotifier(this._errorBoundary, this._ref) : super(OhyoState.initial()) {
    // Don't auto-load ohyos on initialization - wait for explicit call
  }

  void initializeOfflineService(OfflineOhyoService offlineOhyoService) {
    _offlineOhyoService = offlineOhyoService;
  }

  final SupabaseClient _supabase = SupabaseClientManager().client;

  /// Initialize ohyo loading when user is authenticated and on home screen
  void initializeOhyoLoading() {
    // Only load if we haven't loaded yet and not currently loading
    if (state.ohyos.isEmpty && !state.isLoading && state.error == null) {
      Future.microtask(() => loadOhyos());
    }
  }

  /// Load images for a specific ohyo (lazy loading)
  Future<void> loadOhyoImages(int ohyoId, {dynamic ref}) async {
    try {
      List<String> imageUrls = [];

      // First, check if we're offline and try to load cached images immediately
      try {
        final isOnline = await _checkNetworkConnectivity();
        if (!isOnline) {
          debugPrint('🌐 Offline mode detected for ohyo $ohyoId, loading cached images first');
          final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
          if (cachedImageUrls.isNotEmpty) {
            debugPrint('✅ Found ${cachedImageUrls.length} cached images for ohyo $ohyoId');
            imageUrls = cachedImageUrls;

            // Update the ohyo in the state with cached images
            final updatedOhyos = state.ohyos.map((ohyo) {
              if (ohyo.id == ohyoId) {
                return ohyo.copyWith(imageUrls: imageUrls);
              }
              return ohyo;
            }).toList();

            final updatedFilteredOhyos = state.filteredOhyos.map((ohyo) {
              if (ohyo.id == ohyoId) {
                return ohyo.copyWith(imageUrls: imageUrls);
              }
              return ohyo;
            }).toList();

            state = state.copyWith(
              ohyos: updatedOhyos,
              filteredOhyos: updatedFilteredOhyos,
            );
            return; // Return early if we have cached images and are offline
          } else {
            debugPrint('ℹ️ No cached images available for ohyo $ohyoId');
          }
        }
      } catch (networkCheckError) {
        debugPrint('⚠️ Failed to check network status: $networkCheckError');
      }

      // Try to fetch online images
      try {
        imageUrls = await ImageUtils.fetchOhyoImagesFromBucket(ohyoId, ref: ref);
            // Silent: Online image loading success not logged
            // Silent: Online image URLs not logged
      } catch (e) {
        debugPrint('❌ Online image fetch failed for ohyo $ohyoId: $e');

        // Try to load cached images as fallback when online fetch fails
        try {
          final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
          if (cachedImageUrls.isNotEmpty) {
            debugPrint('🔄 Using ${cachedImageUrls.length} cached images for ohyo $ohyoId as fallback');
            // Reduced spam: Cached image loading is now silent
            imageUrls = cachedImageUrls;
          } else {
            debugPrint('ℹ️ No cached images available for ohyo $ohyoId');
          }
        } catch (cacheError) {
          debugPrint('❌ Failed to load cached images for ohyo $ohyoId: $cacheError');
        }
      }

      if (imageUrls.isNotEmpty) {
        // Update the ohyo in the state with the loaded images
        final updatedOhyos = state.ohyos.map((ohyo) {
          if (ohyo.id == ohyoId) {
            return ohyo.copyWith(imageUrls: imageUrls);
          }
          return ohyo;
        }).toList();

        final updatedFilteredOhyos = state.filteredOhyos.map((ohyo) {
          if (ohyo.id == ohyoId) {
            return ohyo.copyWith(imageUrls: imageUrls);
          }
          return ohyo;
        }).toList();

        state = state.copyWith(
          ohyos: updatedOhyos,
          filteredOhyos: updatedFilteredOhyos,
        );
      }
    } catch (e) {
      debugPrint('Failed to load ohyo images for ohyo $ohyoId: $e');
      // Don't show error for image loading failures - it's not critical
    }
  }

  Future<void> loadOhyos() async {
    state = state.copyWith(isLoading: true, error: null);

    List<Ohyo>? cachedOhyos;

    // First, try to load from cache if available
    if (_offlineOhyoService != null) {
      try {
        cachedOhyos = await _offlineOhyoService!.getValidCachedOhyos();
        if (cachedOhyos != null && cachedOhyos.isNotEmpty) {
          // Load cached ohyos first for immediate UI feedback
          state = state.copyWith(
            ohyos: cachedOhyos,
            filteredOhyos: cachedOhyos,
            isLoading: true, // Keep loading true while we try to refresh from online
            error: null,
            isOfflineMode: true,
          );

          // Preload images for cached ohyos (try cached images first, especially when offline)
          if (cachedOhyos.isNotEmpty) {
            await _preloadInitialOhyoImagesWithCache(cachedOhyos.take(3).toList());
          }

          // Preload likes for all ohyos to ensure offline availability
          await _preloadOhyoLikes(cachedOhyos);
        } else {
          // If SharedPreferences cache is empty/expired, try Hive storage
          try {
            final hiveCachedOhyos = app_storage.LocalStorage.getAllOhyos();
            if (hiveCachedOhyos.isNotEmpty) {
              // Convert CachedOhyo to Ohyo with likes data
              cachedOhyos = hiveCachedOhyos.map((cachedOhyo) {
                return Ohyo(
                  id: cachedOhyo.id,
                  name: cachedOhyo.name,
                  description: cachedOhyo.description,
                  style: cachedOhyo.style ?? '',
                  createdAt: cachedOhyo.createdAt,
                  imageUrls: cachedOhyo.imageUrls,
                  videoUrls: [], // Not stored in CachedOhyo
                  order: 0, // Not stored in CachedOhyo
                  isLiked: cachedOhyo.isLiked, // Include cached likes data
                  likeCount: cachedOhyo.likeCount, // Include cached like count
                );
              }).toList();

              // Load cached ohyos from Hive for immediate UI feedback
              state = state.copyWith(
                ohyos: cachedOhyos,
                filteredOhyos: cachedOhyos,
                isLoading: true, // Keep loading true while we try to refresh from online
                error: null,
                isOfflineMode: true,
              );

              // Preload images for cached ohyos
              if (cachedOhyos.isNotEmpty) {
                await _preloadInitialOhyoImagesWithCache(cachedOhyos.take(3).toList());
              }
            }
          } catch (e) {
            debugPrint('Error loading Hive cached ohyos: $e');
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
              .from("ohyo")
              .select()
              .order('order', ascending: true);

          final onlineOhyos = (response as List)
              .map((data) => Ohyo.fromMap(data as Map<String, dynamic>))
              .toList();

          // Cache the online data
          if (_offlineOhyoService != null) {
            await _offlineOhyoService!.cacheOhyos(onlineOhyos);
          }

          // Update state with online data
          state = state.copyWith(
            ohyos: onlineOhyos,
            filteredOhyos: onlineOhyos,
            isLoading: false,
            error: null,
            isOfflineMode: false,
          );

          // Preload images for online ohyos
          if (onlineOhyos.isNotEmpty) {
            await _preloadInitialOhyoImagesWithCache(onlineOhyos.take(3).toList());
          }

          // Preload likes for all ohyos to ensure offline availability
          await _preloadOhyoLikes(onlineOhyos);
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for loading ohyos
        },
      );
    } catch (e) {
      // Online loading failed
      if (cachedOhyos != null && cachedOhyos.isNotEmpty) {
        // We have cached data, show it with offline indicator
        state = state.copyWith(
          isLoading: false,
          error: null,
          isOfflineMode: true,
        );
      } else {
        // No cached data available, show error
        final errorMessage = 'Failed to load ohyos: ${e.toString()}';
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

  /// Check network connectivity more reliably
  Future<bool> _checkNetworkConnectivity() async {
    try {
      // Use a simple connectivity check by trying to resolve a hostname
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      debugPrint('Network connectivity check failed: $e');
      return false;
    }
  }

  void searchOhyos(String query) {
    final trimmedQuery = query.trim().toLowerCase();
    state = state.copyWith(searchQuery: query);

    if (trimmedQuery.isEmpty) {
      // If search is empty, show all filtered by category
      if (state.selectedCategory != null && state.selectedCategory != OhyoCategory.all) {
        final filtered = state.ohyos.where((ohyo) {
          final category = OhyoCategory.fromStyle(ohyo.style);
          return category == state.selectedCategory;
        }).toList();
        state = state.copyWith(filteredOhyos: filtered);
      } else {
        state = state.copyWith(filteredOhyos: state.ohyos);
      }
      return;
    }

    // Check if query is purely numeric (contains only digits)
    final isNumericQuery = RegExp(r'^\d+$').hasMatch(trimmedQuery);

    final filtered = state.ohyos.where((ohyo) {
      bool matchesQuery = false;

      if (isNumericQuery) {
        // For numeric queries, match exact order, ID, or exact Ohyo number
        matchesQuery = ohyo.order.toString() == trimmedQuery ||
                       ohyo.id.toString() == trimmedQuery ||
                       ohyo.name.toLowerCase() == 'ohyo $trimmedQuery' ||
                       ohyo.name.toLowerCase().endsWith(' $trimmedQuery');
      } else {
        // For text queries, search in text fields with better matching logic
        // Check if name starts with the query
        matchesQuery = ohyo.name.toLowerCase().startsWith(trimmedQuery);

        // If not, check if any word in the name starts with the query
        if (!matchesQuery) {
          final nameWords = ohyo.name.toLowerCase().split(' ');
          matchesQuery = nameWords.any((word) => word.startsWith(trimmedQuery));
        }

        // Also check description and style with contains (less strict for these)
        if (!matchesQuery) {
          matchesQuery = ohyo.description.toLowerCase().contains(trimmedQuery) ||
                         ohyo.style.toLowerCase().contains(trimmedQuery);
        }
      }

      if (state.selectedCategory != null && state.selectedCategory != OhyoCategory.all) {
        final category = OhyoCategory.fromStyle(ohyo.style);
        return matchesQuery && category == state.selectedCategory;
      }

      return matchesQuery;
    }).toList();

    state = state.copyWith(filteredOhyos: filtered);
  }

  void filterByCategory(OhyoCategory? category) {
    state = state.copyWith(selectedCategory: category);

    if (category == null || category == OhyoCategory.all) {
      // Show all, but still apply search filter if present
      if (state.searchQuery.isNotEmpty) {
        searchOhyos(state.searchQuery);
      } else {
        state = state.copyWith(filteredOhyos: state.ohyos);
      }
      return;
    }

    final filtered = state.ohyos.where((ohyo) {
      final ohyoCategory = OhyoCategory.fromStyle(ohyo.style);
      final matchesCategory = ohyoCategory == category;

      // Also apply search filter if present
      if (state.searchQuery.isNotEmpty) {
        final trimmedQuery = state.searchQuery.toLowerCase().trim();
        // Check if query is purely numeric (contains only digits)
        final isNumericQuery = RegExp(r'^\d+$').hasMatch(trimmedQuery);

        bool matchesQuery = false;
        if (isNumericQuery) {
          // For numeric queries, match exact order, ID, or exact Ohyo number
          matchesQuery = ohyo.order.toString() == trimmedQuery ||
                         ohyo.id.toString() == trimmedQuery ||
                         ohyo.name.toLowerCase() == 'ohyo $trimmedQuery' ||
                         ohyo.name.toLowerCase().endsWith(' $trimmedQuery');
        } else {
          // For text queries, search in text fields with improved logic
          // Check if name starts with the query
          matchesQuery = ohyo.name.toLowerCase().startsWith(trimmedQuery);

          // If not, check if any word in the name starts with the query
          if (!matchesQuery) {
            final nameWords = ohyo.name.toLowerCase().split(' ');
            matchesQuery = nameWords.any((word) => word.startsWith(trimmedQuery));
          }

          // Also check description and style with contains (less strict for these)
          if (!matchesQuery) {
            matchesQuery = ohyo.description.toLowerCase().contains(trimmedQuery) ||
                           ohyo.style.toLowerCase().contains(trimmedQuery);
          }
        }

        return matchesCategory && matchesQuery;
      }

      return matchesCategory;
    }).toList();

    state = state.copyWith(filteredOhyos: filtered);
  }

  Future<void> createOhyo({
    required String name,
    required String description,
    required String style,
    List<File>? images,
    List<String>? videoUrls,
  }) async {
    debugPrint('🔄 Starting ohyo creation process...');
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          debugPrint('📝 Inserting ohyo into database...');
          debugPrint('  Data: {name: $name, description: $description, style: $style, video_urls: $videoUrls, order: ${state.ohyos.length}}');

          // Insert ohyo into database
          debugPrint('🔍 About to make database insert call...');

          // Force refresh the client connection
          debugPrint('🔄 Refreshing Supabase client...');
          final freshClient = SupabaseClientManager().client;

          // Prepare the insert data explicitly
          final insertData = <String, dynamic>{
            'name': name,
            'description': description,
            'style': style,
            'video_urls': videoUrls ?? [],
            'order': state.ohyos.length,
          };

          debugPrint('📤 Insert data prepared: $insertData');

          final response = await freshClient
              .from("ohyo")
              .insert(insertData)
              .select()
              .single();

          debugPrint('📥 Raw response received: $response');

          debugPrint('✅ Database insert successful: $response');
          final newOhyo = Ohyo.fromMap(response);
          debugPrint('📦 Created ohyo object: ${newOhyo.toString()}');

          // Upload images if provided
          if (images != null && images.isNotEmpty) {
            debugPrint('🖼️ Uploading ${images.length} images...');
            await ImageUtils.uploadOhyoImages(images, newOhyo.id);
            debugPrint('✅ Images uploaded successfully');
          }

          // Reload ohyos to get the updated list
          debugPrint('🔄 Reloading ohyos list...');
          await loadOhyos();
          debugPrint('✅ Ohyos reloaded successfully');
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Silent: Retry attempts are not logged to reduce spam
        },
      );
      debugPrint('🎉 Ohyo creation completed successfully!');
    } catch (e) {
      debugPrint('💥 Error during ohyo creation: $e');
      final errorMessage = 'Failed to create ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> updateOhyo(
    int ohyoId, {
    String? name,
    String? description,
    String? style,
    List<File>? newImages,
    List<String>? videoUrls,
    bool? removeAllImages,
    List<String>? deletedImageUrls,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Prepare update data - only update specific fields, not user-related fields
          final updateData = <String, dynamic>{};
          if (name != null) updateData['name'] = name;
          if (description != null) updateData['description'] = description;
          if (style != null) updateData['style'] = style;
          if (videoUrls != null) updateData['video_urls'] = videoUrls;

          // Update database
          await _supabase
              .from("ohyo")
              .update(updateData)
              .eq('id', ohyoId);

          // Handle image operations
          if (removeAllImages == true) {
            await ImageUtils.deleteOhyoImages(ohyoId);
          }

          // Delete specific images if provided
          if (deletedImageUrls != null && deletedImageUrls.isNotEmpty) {
            // Extract filenames from URLs for deletion
            final filenamesToDelete = deletedImageUrls.map((url) {
              final uri = Uri.parse(url);
              final segments = uri.pathSegments;
              if (segments.length >= 2) {
                return '${segments[segments.length - 2]}/${segments.last}';
              }
              return '';
            }).where((name) => name.isNotEmpty).toList();

            if (filenamesToDelete.isNotEmpty) {
              await ImageUtils.deleteMultipleImagesFromSupabase(filenamesToDelete);
            }
          }

          if (newImages != null && newImages.isNotEmpty) {
            await ImageUtils.uploadOhyoImages(newImages, ohyoId);
          }

          // Reload ohyos to get the updated list
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for updating ohyo
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to update ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> deleteOhyo(int ohyoId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Delete images first
          await ImageUtils.deleteOhyoImages(ohyoId);

          // Delete ohyo from database
          await _supabase
              .from("ohyo")
              .delete()
              .eq('id', ohyoId);

          // Reload ohyos to get the updated list
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for deleting ohyo
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to delete ohyo: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset the ohyo tab to its initial state (clear search, filters, etc.)
  void resetOhyoTab() {
    state = state.copyWith(
      searchQuery: '',
      selectedCategory: null,
      filteredOhyos: state.ohyos, // Reset to show all ohyos
    );
  }

  Future<void> reorderOhyos(List<Ohyo> reorderedOhyos) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          // Update local state first for immediate UI feedback
          final updatedOhyos = List<Ohyo>.from(reorderedOhyos);
          state = state.copyWith(
            ohyos: updatedOhyos,
            filteredOhyos: updatedOhyos,
            isLoading: false,
          );

          // Update database in background
          await _updateOhyoOrdersInDatabase(updatedOhyos);

          // If database update fails, reload from database
          await loadOhyos();
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for reordering ohyos
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to reorder ohyos: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }

  Future<void> _updateOhyoOrdersInDatabase(List<Ohyo> ohyos) async {
    await RetryUtils.executeWithRetry(
      () async {
        for (final ohyo in ohyos) {
          await _supabase
              .from("ohyo")
              .update({'order': ohyo.order})
              .eq('id', ohyo.id);
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryError,
      onRetry: (attempt, error) {
        // Retry attempt for updating ohyo orders
      },
    );
  }

  /// Clean up orphaned images that don't belong to any existing ohyo
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

  Future<void> _preloadInitialOhyoImagesWithCache(List<Ohyo> initialOhyos) async {
    // Preload images for better UX - prioritize cached images when offline
    for (final ohyo in initialOhyos) {
      try {
        // First, try to load cached images immediately
        final cachedImageUrls = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyo.id);
        if (cachedImageUrls.isNotEmpty) {
          debugPrint('🏠 Preloaded ${cachedImageUrls.length} cached images for ohyo ${ohyo.id}');

          // Update the ohyo in the state with cached images
          final updatedOhyos = state.ohyos.map((o) {
            if (o.id == ohyo.id) {
              return o.copyWith(imageUrls: cachedImageUrls);
            }
            return o;
          }).toList();

          final updatedFilteredOhyos = state.filteredOhyos.map((o) {
            if (o.id == ohyo.id) {
              return o.copyWith(imageUrls: cachedImageUrls);
            }
            return o;
          }).toList();

          state = state.copyWith(
            ohyos: updatedOhyos,
            filteredOhyos: updatedFilteredOhyos,
          );
          continue; // Skip online fetch if we have cached images
        }

        // If no cached images, try online fetch (will cache them)
        await ImageUtils.fetchOhyoImagesFromBucket(ohyo.id);
      } catch (e) {
        // Silently fail - images will be loaded when needed
        debugPrint('Failed to preload ohyo images for ohyo ${ohyo.id}: $e');
      }
    }
  }

  // Preload likes for all ohyos to ensure offline availability
  Future<void> _preloadOhyoLikes(List<Ohyo> ohyos) async {
    try {
      // Load likes for all ohyos in parallel to speed up the process
      final likeFutures = ohyos.map((ohyo) async {
        try {
          final likes = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.getOhyoLikes(ohyo.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          final isLiked = await RetryUtils.executeWithRetry(
            () async {
              final interactionService = _ref.read(interactionServiceProvider);
              return await interactionService.isOhyoLiked(ohyo.id);
            },
            maxRetries: 2,
            initialDelay: const Duration(milliseconds: 100),
          );

          return {
            'ohyoId': ohyo.id,
            'likes': likes,
            'isLiked': isLiked,
          };
        } catch (e) {
          // If loading likes fails, return null data
          return {
            'ohyoId': ohyo.id,
            'likes': <dynamic>[],
            'isLiked': false,
          };
        }
      });

      final likeResults = await Future.wait(likeFutures);

      // Update cached data with likes information
      for (final result in likeResults) {
        final ohyoId = result['ohyoId'] as int;
        final likes = result['likes'] as List;
        final isLiked = result['isLiked'] as bool;

        // Update the cached ohyo with likes data
        final cachedOhyo = app_storage.LocalStorage.getOhyo(ohyoId);
        if (cachedOhyo != null) {
          final updatedOhyo = app_storage.CachedOhyo(
            id: cachedOhyo.id,
            name: cachedOhyo.name,
            description: cachedOhyo.description,
            createdAt: cachedOhyo.createdAt,
            lastSynced: DateTime.now(),
            imageUrls: cachedOhyo.imageUrls,
            style: cachedOhyo.style,
            isFavorite: cachedOhyo.isFavorite,
            needsSync: cachedOhyo.needsSync,
            isLiked: isLiked,
            likeCount: likes.length,
          );
          await app_storage.LocalStorage.saveOhyo(updatedOhyo);
        }
      }

      // Reduced spam: Only log if there were errors or significant issues
    } catch (e) {
      debugPrint('⚠️ Failed to preload ohyo likes: $e');
      // Don't throw - likes preloading failure shouldn't break the app
    }
  }
}

// Provider for the OhyoNotifier
final ohyoNotifierProvider = StateNotifierProvider<OhyoNotifier, OhyoState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  final notifier = OhyoNotifier(errorBoundary, ref);

  // Initialize offline service if available (catch errors if not initialized yet)
  try {
    final offlineOhyoService = ref.watch(offlineOhyoServiceProvider);
    notifier.initializeOfflineService(offlineOhyoService);
  } catch (e) {
    // Offline service not available yet, will be initialized later
  }

  return notifier;
});

// Convenience providers for specific ohyo state properties
final ohyosProvider = Provider<List<Ohyo>>((ref) {
  return ref.watch(ohyoNotifierProvider).filteredOhyos;
});

final ohyoLoadingProvider = Provider<bool>((ref) {
  return ref.watch(ohyoNotifierProvider).isLoading;
});

final ohyoOfflineModeProvider = Provider<bool>((ref) {
  return ref.watch(ohyoNotifierProvider).isOfflineMode;
});

final ohyoErrorProvider = Provider<String?>((ref) {
  return ref.watch(ohyoNotifierProvider).error;
});

final ohyoSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(ohyoNotifierProvider).searchQuery;
});

final ohyoSelectedCategoryProvider = Provider<OhyoCategory?>((ref) {
  return ref.watch(ohyoNotifierProvider).selectedCategory;
});

// Family provider for individual ohyo by ID
final ohyoByIdProvider = Provider.family<Ohyo?, int>((ref, ohyoId) {
  final ohyos = ref.watch(ohyoNotifierProvider).ohyos;
  try {
    return ohyos.firstWhere((ohyo) => ohyo.id == ohyoId);
  } catch (e) {
    return null;
  }
});

// Family provider for ohyo images
final ohyoImagesProvider = FutureProvider.family<List<String>, int>((ref, ohyoId) async {
  return await ImageUtils.fetchOhyoImagesFromBucket(ohyoId, ref: ref);
});
