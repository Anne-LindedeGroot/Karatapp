import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ohyo_model.dart';
import '../utils/image_utils.dart';
import '../utils/retry_utils.dart';
import '../supabase_client.dart';
import 'error_boundary_provider.dart';
import 'network_provider.dart';

// StateNotifier for ohyo management
class OhyoNotifier extends StateNotifier<OhyoState> {
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;

  OhyoNotifier(this._errorBoundary, this._ref) : super(OhyoState.initial()) {
    // Don't auto-load ohyos on initialization - wait for explicit call
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
  Future<void> loadOhyoImages(int ohyoId) async {
    try {
      final imageUrls = await ImageUtils.fetchOhyoImagesFromBucket(ohyoId);

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
    } catch (e) {
      debugPrint('Failed to load ohyo images for ohyo $ohyoId: $e');
      // Don't show error for image loading failures - it's not critical
    }
  }

  Future<void> loadOhyos() async {
    // Check network status first
    final networkState = _ref.read(networkProvider);
    if (networkState.isDisconnected) {
      state = state.copyWith(
        isLoading: false,
        error: 'No internet connection',
      );
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await RetryUtils.executeWithRetry(
        () async {
          final response = await _supabase
              .from("ohyo")
              .select()
              .order('order', ascending: true);

          final ohyos = (response as List)
              .map((data) => Ohyo.fromMap(data as Map<String, dynamic>))
              .toList();

          // Load ohyos without images for faster startup
          // Images will be loaded lazily when needed
          state = state.copyWith(
            ohyos: ohyos,
            filteredOhyos: ohyos,
            isLoading: false,
            error: null,
          );

          // Preload images for first 3 ohyos to improve perceived performance
          if (ohyos.isNotEmpty) {
            _preloadInitialOhyoImages(ohyos.take(3).toList());
          }
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for loading ohyos
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to load ohyos: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      // Only report to error boundary if it's not a network error
      // Network errors are handled by the network provider
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
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

    final filtered = state.ohyos.where((ohyo) {
      // Search by exact numbers (order, ID) - highest priority
      final matchesNumericQuery = ohyo.order.toString() == trimmedQuery ||
                                 ohyo.id.toString() == trimmedQuery;

      // Search in text fields with better matching logic
      bool matchesTextQuery = false;
      if (!matchesNumericQuery) {
        // Check if name starts with the query (for "1" -> "ohyo 1" but not "ohyo 2")
        matchesTextQuery = ohyo.name.toLowerCase().startsWith(trimmedQuery);

        // If not, check if any word in the name starts with the query
        if (!matchesTextQuery) {
          final nameWords = ohyo.name.toLowerCase().split(' ');
          matchesTextQuery = nameWords.any((word) => word.startsWith(trimmedQuery));
        }

        // Also check description and style with contains (less strict for these)
        if (!matchesTextQuery) {
          matchesTextQuery = ohyo.description.toLowerCase().contains(trimmedQuery) ||
                           ohyo.style.toLowerCase().contains(trimmedQuery);
        }
      }

      final matchesQuery = matchesTextQuery || matchesNumericQuery;

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

        // Check numeric match first
        final matchesNumericQuery = ohyo.order.toString() == trimmedQuery ||
                                   ohyo.id.toString() == trimmedQuery;

        // Check text match with improved logic
        bool matchesTextQuery = false;
        if (!matchesNumericQuery) {
          // Check if name starts with the query
          matchesTextQuery = ohyo.name.toLowerCase().startsWith(trimmedQuery);

          // If not, check if any word in the name starts with the query
          if (!matchesTextQuery) {
            final nameWords = ohyo.name.toLowerCase().split(' ');
            matchesTextQuery = nameWords.any((word) => word.startsWith(trimmedQuery));
          }

          // Also check description and style with contains (less strict for these)
          if (!matchesTextQuery) {
            matchesTextQuery = ohyo.description.toLowerCase().contains(trimmedQuery) ||
                             ohyo.style.toLowerCase().contains(trimmedQuery);
          }
        }

        final matchesQuery = matchesTextQuery || matchesNumericQuery;
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
          debugPrint('🔄 Retry attempt $attempt for creating ohyo: $error');
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

  void _preloadInitialOhyoImages(List<Ohyo> initialOhyos) {
    // Preload images for better UX - but don't block the main thread
    Future.microtask(() async {
      for (final ohyo in initialOhyos) {
        try {
          await ImageUtils.fetchOhyoImagesFromBucket(ohyo.id);
        } catch (e) {
          // Silently fail - images will be loaded when needed
          debugPrint('Failed to preload ohyo images for ohyo ${ohyo.id}: $e');
        }
      }
    });
  }
}

// Provider for the OhyoNotifier
final ohyoNotifierProvider = StateNotifierProvider<OhyoNotifier, OhyoState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return OhyoNotifier(errorBoundary, ref);
});

// Convenience providers for specific ohyo state properties
final ohyosProvider = Provider<List<Ohyo>>((ref) {
  return ref.watch(ohyoNotifierProvider).filteredOhyos;
});

final ohyoLoadingProvider = Provider<bool>((ref) {
  return ref.watch(ohyoNotifierProvider).isLoading;
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
  return await ImageUtils.fetchOhyoImagesFromBucket(ohyoId);
});
