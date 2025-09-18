import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kata_model.dart';
import '../utils/image_utils.dart';
import '../utils/retry_utils.dart';
import 'error_boundary_provider.dart';
import 'network_provider.dart';

// StateNotifier for kata management
class KataNotifier extends StateNotifier<KataState> {
  final ErrorBoundaryNotifier _errorBoundary;
  final Ref _ref;
  
  KataNotifier(this._errorBoundary, this._ref) : super(KataState.initial()) {
    // Delay initial load to allow network provider to initialize
    Future.microtask(() => loadKatas());
  }

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> loadKatas() async {
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
              .from("katas")
              .select()
              .order('order', ascending: true);

          final katas = (response as List)
              .map((data) => Kata.fromMap(data as Map<String, dynamic>))
              .toList();

          // Load images for each kata
          final katasWithImages = <Kata>[];
          for (final kata in katas) {
            try {
              final imageUrls = await ImageUtils.fetchKataImagesFromBucket(kata.id);
              katasWithImages.add(kata.copyWith(imageUrls: imageUrls));
            } catch (e) {
              // If image loading fails, add kata without images
              katasWithImages.add(kata);
            }
          }

          state = state.copyWith(
            katas: katasWithImages,
            filteredKatas: katasWithImages,
            isLoading: false,
            error: null,
          );
        },
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        shouldRetry: RetryUtils.shouldRetryError,
        onRetry: (attempt, error) {
          // Retry attempt for loading katas
        },
      );
    } catch (e) {
      final errorMessage = 'Failed to load katas: ${e.toString()}';
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
            "video_urls": videoUrls,
            "order": nextOrder,
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

          // Create new kata object
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
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery),
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
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery),
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
    final filteredKatas = _filterKatas(state.katas, query);
    state = state.copyWith(
      searchQuery: query,
      filteredKatas: filteredKatas,
    );
  }

  List<Kata> _filterKatas(List<Kata> katas, String query) {
    if (query.isEmpty) {
      return katas;
    }
    
    final queryLower = query.toLowerCase();
    
    // Filter katas based on name and description
    final filtered = katas.where((kata) {
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
          };
          
          if (videoUrls != null) {
            updateData['video_urls'] = videoUrls;
          }
          
          await _supabase.from("katas").update(updateData).eq('id', kataId);

          // Update local state
          final updatedKatas = state.katas.map((kata) {
            if (kata.id == kataId) {
              return kata.copyWith(
                name: name,
                description: description,
                style: style,
                videoUrls: videoUrls ?? kata.videoUrls,
              );
            }
            return kata;
          }).toList();

          state = state.copyWith(
            katas: updatedKatas,
            filteredKatas: _filterKatas(updatedKatas, state.searchQuery),
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
      filteredKatas: _filterKatas(updatedKatas, state.searchQuery),
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

  /// Clean up orphaned images that don't belong to any existing kata
  /// This is useful for cleaning up images left behind from failed operations
  Future<List<String>> cleanupOrphanedImages() async {
    try {
      // Get all existing kata IDs
      final existingKataIds = state.katas.map((kata) => kata.id).toList();
      
      // Clean up orphaned images
      final deletedPaths = await ImageUtils.cleanupOrphanedImages(existingKataIds);
      
      // Cleanup completed successfully
      
      return deletedPaths;
    } catch (e) {
      final errorMessage = 'Failed to cleanup orphaned images: ${e.toString()}';
      _errorBoundary.reportNetworkError(errorMessage);
      rethrow;
    }
  }
}

// Provider for the KataNotifier
final kataNotifierProvider = StateNotifierProvider<KataNotifier, KataState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return KataNotifier(errorBoundary, ref);
});

// Convenience providers for specific kata state properties
final katasProvider = Provider<List<Kata>>((ref) {
  return ref.watch(kataNotifierProvider).filteredKatas;
});

final kataLoadingProvider = Provider<bool>((ref) {
  return ref.watch(kataNotifierProvider).isLoading;
});

final kataErrorProvider = Provider<String?>((ref) {
  return ref.watch(kataNotifierProvider).error;
});

final kataSearchQueryProvider = Provider<String>((ref) {
  return ref.watch(kataNotifierProvider).searchQuery;
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
  return await ImageUtils.fetchKataImagesFromBucket(kataId);
});
