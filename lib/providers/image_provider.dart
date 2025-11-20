import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/image_utils.dart';
import 'error_boundary_provider.dart';

class ImageState {
  final Map<int, List<String>> kataImages;
  final Map<String, bool> uploadingImages;
  final Map<String, bool> deletingImages;
  final bool isLoading;
  final String? error;

  const ImageState({
    this.kataImages = const {},
    this.uploadingImages = const {},
    this.deletingImages = const {},
    this.isLoading = false,
    this.error,
  });

  ImageState.initial()
      : kataImages = const {},
        uploadingImages = const {},
        deletingImages = const {},
        isLoading = false,
        error = null;

  ImageState copyWith({
    Map<int, List<String>>? kataImages,
    Map<String, bool>? uploadingImages,
    Map<String, bool>? deletingImages,
    bool? isLoading,
    String? error,
  }) {
    return ImageState(
      kataImages: kataImages ?? this.kataImages,
      uploadingImages: uploadingImages ?? this.uploadingImages,
      deletingImages: deletingImages ?? this.deletingImages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  String toString() {
    return 'ImageState(kataImages: ${kataImages.length}, uploadingImages: ${uploadingImages.length}, deletingImages: ${deletingImages.length}, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ImageState &&
        other.kataImages == kataImages &&
        other.uploadingImages == uploadingImages &&
        other.deletingImages == deletingImages &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return kataImages.hashCode ^
        uploadingImages.hashCode ^
        deletingImages.hashCode ^
        isLoading.hashCode ^
        error.hashCode;
  }
}

// StateNotifier for image management
class ImageNotifier extends StateNotifier<ImageState> {
  final ErrorBoundaryNotifier _errorBoundary;

  ImageNotifier(this._errorBoundary) : super(ImageState.initial());

  Future<List<String>> loadKataImages(int kataId) async {
    // Check if we already have cached images and they're not too old
    final cachedImages = state.kataImages[kataId];
    if (cachedImages != null && cachedImages.isNotEmpty) {
      // Return cached images immediately, but still refresh in background
      _refreshKataImagesInBackground(kataId);
      return cachedImages;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(kataId);
      
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      updatedKataImages[kataId] = imageUrls;

      state = state.copyWith(
        kataImages: updatedKataImages,
        isLoading: false,
        error: null,
      );

      return imageUrls;
    } catch (e) {
      final errorMessage = 'Failed to load images for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      
      // Return empty list but keep any cached images if available
      return cachedImages ?? [];
    }
  }

  /// Refresh images in background without affecting UI state
  Future<void> _refreshKataImagesInBackground(int kataId) async {
    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(kataId);
      
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      updatedKataImages[kataId] = imageUrls;

      state = state.copyWith(
        kataImages: updatedKataImages,
        error: null,
      );
    } catch (e) {
      // Silently fail background refresh - don't update error state
      print('Background refresh failed for kata $kataId: $e');
    }
  }

  /// Force refresh images for a kata (ignores cache)
  Future<List<String>> forceRefreshKataImages(int kataId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final imageUrls = await ImageUtils.fetchKataImagesFromBucket(kataId);
      
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      updatedKataImages[kataId] = imageUrls;

      state = state.copyWith(
        kataImages: updatedKataImages,
        isLoading: false,
        error: null,
      );

      return imageUrls;
    } catch (e) {
      final errorMessage = 'Failed to refresh images for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      return [];
    }
  }

  Future<List<String>> uploadImages(List<File> images, int kataId) async {
    final uploadKey = 'kata_${kataId}_upload';
    
    final updatedUploadingImages = Map<String, bool>.from(state.uploadingImages);
    updatedUploadingImages[uploadKey] = true;
    
    state = state.copyWith(
      uploadingImages: updatedUploadingImages,
      error: null,
    );

    try {
      final imageUrls = await ImageUtils.uploadMultipleImagesToSupabase(
        images,
        kataId,
      );

      // Update cached images for this kata
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      final existingImages = updatedKataImages[kataId] ?? [];
      updatedKataImages[kataId] = [...existingImages, ...imageUrls];

      // Remove uploading state
      final finalUploadingImages = Map<String, bool>.from(state.uploadingImages);
      finalUploadingImages.remove(uploadKey);

      state = state.copyWith(
        kataImages: updatedKataImages,
        uploadingImages: finalUploadingImages,
        error: null,
      );

      return imageUrls;
    } catch (e) {
      // Remove uploading state on error
      final finalUploadingImages = Map<String, bool>.from(state.uploadingImages);
      finalUploadingImages.remove(uploadKey);

      final errorMessage = 'Failed to upload images for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        uploadingImages: finalUploadingImages,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> deleteImage(String imageUrl, int kataId) async {
    final deleteKey = imageUrl;
    
    final updatedDeletingImages = Map<String, bool>.from(state.deletingImages);
    updatedDeletingImages[deleteKey] = true;
    
    state = state.copyWith(
      deletingImages: updatedDeletingImages,
      error: null,
    );

    try {
      // Extract filename from URL and delete from bucket
      final fileName = ImageUtils.extractFileNameFromUrl(imageUrl);
      if (fileName != null) {
        await ImageUtils.deleteImageFromBucket(kataId, fileName);
      }

      // Update cached images for this kata
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      final existingImages = updatedKataImages[kataId] ?? [];
      updatedKataImages[kataId] = existingImages.where((url) => url != imageUrl).toList();

      // Remove deleting state
      final finalDeletingImages = Map<String, bool>.from(state.deletingImages);
      finalDeletingImages.remove(deleteKey);

      state = state.copyWith(
        kataImages: updatedKataImages,
        deletingImages: finalDeletingImages,
        error: null,
      );
    } catch (e) {
      // Remove deleting state on error
      final finalDeletingImages = Map<String, bool>.from(state.deletingImages);
      finalDeletingImages.remove(deleteKey);

      final errorMessage = 'Failed to delete image from kata $kataId: ${e.toString()}';
      state = state.copyWith(
        deletingImages: finalDeletingImages,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
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

  Future<void> deleteAllKataImages(int kataId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await ImageUtils.deleteAllKataImages(kataId);

      // Remove cached images for this kata
      final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
      updatedKataImages.remove(kataId);

      state = state.copyWith(
        kataImages: updatedKataImages,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to delete all images for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> reorderImages(int kataId, List<String> reorderedImageUrls) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get current images to compare with new order
      final currentImages = state.kataImages[kataId] ?? [];

      if (currentImages.isEmpty || reorderedImageUrls.isEmpty) {
        // No images to reorder
        return;
      }

      // If the order hasn't actually changed, don't do anything
      if (_areListsEqual(currentImages, reorderedImageUrls)) {
        state = state.copyWith(isLoading: false);
        return;
      }

      debugPrint('🔄 Starting image reordering for kata $kataId');
      debugPrint('📋 Current URLs: $currentImages');
      debugPrint('📋 New URLs: $reorderedImageUrls');
      debugPrint('📋 Current filenames: ${currentImages.map(ImageUtils.extractFileNameFromUrl).toList()}');
      debugPrint('📋 New filenames: ${reorderedImageUrls.map(ImageUtils.extractFileNameFromUrl).toList()}');

      // Create mapping of current URLs to their filenames
      final currentFileNames = <String>[];
      for (final url in currentImages) {
        final fileName = ImageUtils.extractFileNameFromUrl(url);
        if (fileName != null) {
          currentFileNames.add(fileName);
        }
      }

      // Create mapping of new URLs to their positions
      final newUrlToPosition = <String, int>{};
      for (int i = 0; i < reorderedImageUrls.length; i++) {
        newUrlToPosition[reorderedImageUrls[i]] = i;
      }

      // Rename files to reflect new order
      final renamedFiles = <String>[];
      for (final currentUrl in currentImages) {
        final newPosition = newUrlToPosition[currentUrl];
        if (newPosition != null) {
          final currentFileName = ImageUtils.extractFileNameFromUrl(currentUrl);
          if (currentFileName != null) {
            // Check if this file already has the correct order prefix
            final expectedFileName = ImageUtils.createOrderedImageFileName(kataId, newPosition + 1, currentFileName);

            if (currentFileName != expectedFileName) {
              debugPrint('🔄 Renaming: $currentFileName -> $expectedFileName');

              final success = await ImageUtils.renameImageFile(kataId, currentFileName, expectedFileName);
              if (success) {
                renamedFiles.add(expectedFileName);
              } else {
                debugPrint('❌ Failed to rename $currentFileName');
              }
            }
          }
        }
      }

      debugPrint('✅ Image reordering completed for kata $kataId');
      debugPrint('📁 Renamed ${renamedFiles.length} files');

      // Refresh the image URLs from the bucket to get new signed URLs for renamed files
      try {
        final refreshedUrls = await ImageUtils.fetchKataImagesFromBucket(kataId);
        debugPrint('🔄 Refreshed image URLs after reordering: ${refreshedUrls.length} URLs');

        // Update cached images with the refreshed URLs
        final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
        updatedKataImages[kataId] = refreshedUrls;

        state = state.copyWith(
          kataImages: updatedKataImages,
          isLoading: false,
          error: null,
        );

        debugPrint('✅ Cache updated with fresh image URLs');
      } catch (refreshError) {
        debugPrint('⚠️ Failed to refresh image URLs after reordering: $refreshError');
        // Still update with the reordered URLs as fallback
        final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
        updatedKataImages[kataId] = reorderedImageUrls;

        state = state.copyWith(
          kataImages: updatedKataImages,
          isLoading: false,
          error: null,
        );
      }

      // Also update the kata record in the database to store the image order
      // This provides a backup in case file renaming fails
      try {
        // Import the Supabase client
        final supabase = Supabase.instance.client;

        await supabase
            .from('katas')
            .update({'image_urls': reorderedImageUrls})
            .eq('id', kataId);

        debugPrint('✅ Updated kata record with new image order');
      } catch (e) {
        debugPrint('⚠️ Failed to update kata record with image order: $e');
        // Don't fail the whole operation if database update fails
      }

    } catch (e) {
      final errorMessage = 'Failed to reorder images for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );

      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }

      rethrow;
    }
  }

  /// Helper method to check if two lists are equal
  bool _areListsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearKataImages(int kataId) {
    final updatedKataImages = Map<int, List<String>>.from(state.kataImages);
    updatedKataImages.remove(kataId);
    
    state = state.copyWith(kataImages: updatedKataImages);
  }

  bool isUploadingForKata(int kataId) {
    return state.uploadingImages.containsKey('kata_${kataId}_upload');
  }

  bool isDeletingImage(String imageUrl) {
    return state.deletingImages.containsKey(imageUrl);
  }

  List<String> getCachedImages(int kataId) {
    return state.kataImages[kataId] ?? [];
  }
}

// Provider for the ImageNotifier
final imageNotifierProvider = StateNotifierProvider<ImageNotifier, ImageState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return ImageNotifier(errorBoundary);
});

// Convenience providers for specific image state properties
final imageLoadingProvider = Provider<bool>((ref) {
  return ref.watch(imageNotifierProvider).isLoading;
});

final imageErrorProvider = Provider<String?>((ref) {
  return ref.watch(imageNotifierProvider).error;
});

// Family provider for kata images with caching
final cachedKataImagesProvider = Provider.family<List<String>, int>((ref, kataId) {
  final imageState = ref.watch(imageNotifierProvider);
  return imageState.kataImages[kataId] ?? [];
});

// Family provider for upload status
final isUploadingProvider = Provider.family<bool, int>((ref, kataId) {
  final imageState = ref.watch(imageNotifierProvider);
  return imageState.uploadingImages.containsKey('kata_${kataId}_upload');
});

// Family provider for delete status
final isDeletingImageProvider = Provider.family<bool, String>((ref, imageUrl) {
  final imageState = ref.watch(imageNotifierProvider);
  return imageState.deletingImages.containsKey(imageUrl);
});

// Async provider for fresh kata images (bypasses cache)
final freshKataImagesProvider = FutureProvider.family<List<String>, int>((ref, kataId) async {
  return await ImageUtils.fetchKataImagesFromBucket(kataId);
});
