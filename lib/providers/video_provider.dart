import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/video_service.dart';
import '../utils/video_utils.dart';
import 'error_boundary_provider.dart';
import 'image_provider.dart';

class VideoState {
  final Map<int, List<String>> kataVideos;
  final Map<String, bool> uploadingVideos;
  final Map<String, bool> deletingVideos;
  final bool isLoading;
  final String? error;

  const VideoState({
    this.kataVideos = const {},
    this.uploadingVideos = const {},
    this.deletingVideos = const {},
    this.isLoading = false,
    this.error,
  });

  VideoState.initial()
      : kataVideos = const {},
        uploadingVideos = const {},
        deletingVideos = const {},
        isLoading = false,
        error = null;

  VideoState copyWith({
    Map<int, List<String>>? kataVideos,
    Map<String, bool>? uploadingVideos,
    Map<String, bool>? deletingVideos,
    bool? isLoading,
    String? error,
  }) {
    return VideoState(
      kataVideos: kataVideos ?? this.kataVideos,
      uploadingVideos: uploadingVideos ?? this.uploadingVideos,
      deletingVideos: deletingVideos ?? this.deletingVideos,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  @override
  String toString() {
    return 'VideoState(kataVideos: ${kataVideos.length}, uploadingVideos: ${uploadingVideos.length}, deletingVideos: ${deletingVideos.length}, isLoading: $isLoading, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VideoState &&
        other.kataVideos == kataVideos &&
        other.uploadingVideos == uploadingVideos &&
        other.deletingVideos == deletingVideos &&
        other.isLoading == isLoading &&
        other.error == error;
  }

  @override
  int get hashCode {
    return kataVideos.hashCode ^
        uploadingVideos.hashCode ^
        deletingVideos.hashCode ^
        isLoading.hashCode ^
        error.hashCode;
  }
}

// StateNotifier for video management
class VideoNotifier extends StateNotifier<VideoState> {
  final ErrorBoundaryNotifier _errorBoundary;
  
  VideoNotifier(this._errorBoundary) : super(VideoState.initial());

  Future<List<String>> loadKataVideos(int kataId) async {
    // Check if we already have cached videos and they're not too old
    final cachedVideos = state.kataVideos[kataId];
    if (cachedVideos != null && cachedVideos.isNotEmpty) {
      // Return cached videos immediately, but still refresh in background
      _refreshKataVideosInBackground(kataId);
      return cachedVideos;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final videoUrls = await VideoService.fetchKataVideosFromBucket(kataId);
      
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      updatedKataVideos[kataId] = videoUrls;

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        isLoading: false,
        error: null,
      );

      return videoUrls;
    } catch (e) {
      final errorMessage = 'Failed to load videos for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      
      // Return empty list but keep any cached videos if available
      return cachedVideos ?? [];
    }
  }

  /// Refresh videos in background without affecting UI state
  Future<void> _refreshKataVideosInBackground(int kataId) async {
    try {
      final videoUrls = await VideoService.fetchKataVideosFromBucket(kataId);
      
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      updatedKataVideos[kataId] = videoUrls;

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        error: null,
      );
    } catch (e) {
      // Silently fail background refresh - don't update error state
      print('Background video refresh failed for kata $kataId: $e');
    }
  }

  /// Force refresh videos for a kata (ignores cache)
  Future<List<String>> forceRefreshKataVideos(int kataId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final videoUrls = await VideoService.fetchKataVideosFromBucket(kataId);
      
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      updatedKataVideos[kataId] = videoUrls;

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        isLoading: false,
        error: null,
      );

      return videoUrls;
    } catch (e) {
      final errorMessage = 'Failed to refresh videos for kata $kataId: ${e.toString()}';
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

  Future<List<String>> uploadVideos(List<File> videos, int kataId) async {
    final uploadKey = 'kata_${kataId}_upload';
    
    final updatedUploadingVideos = Map<String, bool>.from(state.uploadingVideos);
    updatedUploadingVideos[uploadKey] = true;
    
    state = state.copyWith(
      uploadingVideos: updatedUploadingVideos,
      error: null,
    );

    try {
      // Validate all videos before uploading
      for (final video in videos) {
        final validation = VideoUtils.validateVideoForUpload(video);
        if (!validation['isValid']) {
          throw Exception('Video validation failed: ${validation['errors'].join(', ')}');
        }
      }

      final videoUrls = await VideoService.uploadMultipleVideosToSupabase(
        videos,
        kataId,
      );

      // Update cached videos for this kata
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      final existingVideos = updatedKataVideos[kataId] ?? [];
      updatedKataVideos[kataId] = [...existingVideos, ...videoUrls];

      // Remove uploading state
      final finalUploadingVideos = Map<String, bool>.from(state.uploadingVideos);
      finalUploadingVideos.remove(uploadKey);

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        uploadingVideos: finalUploadingVideos,
        error: null,
      );

      return videoUrls;
    } catch (e) {
      // Remove uploading state on error
      final finalUploadingVideos = Map<String, bool>.from(state.uploadingVideos);
      finalUploadingVideos.remove(uploadKey);

      final errorMessage = 'Failed to upload videos for kata $kataId: ${e.toString()}';
      state = state.copyWith(
        uploadingVideos: finalUploadingVideos,
        error: errorMessage,
      );
      
      // Only report non-network errors to global error boundary
      if (!_isNetworkError(e)) {
        _errorBoundary.reportNetworkError(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> deleteVideo(String videoUrl, int kataId) async {
    final deleteKey = videoUrl;
    
    final updatedDeletingVideos = Map<String, bool>.from(state.deletingVideos);
    updatedDeletingVideos[deleteKey] = true;
    
    state = state.copyWith(
      deletingVideos: updatedDeletingVideos,
      error: null,
    );

    try {
      // Extract filename from URL and delete from bucket
      final fileName = VideoService.extractFileNameFromUrl(videoUrl);
      if (fileName != null) {
        await VideoService.deleteVideoFromBucket(kataId, fileName);
      }

      // Update cached videos for this kata
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      final existingVideos = updatedKataVideos[kataId] ?? [];
      updatedKataVideos[kataId] = existingVideos.where((url) => url != videoUrl).toList();

      // Remove deleting state
      final finalDeletingVideos = Map<String, bool>.from(state.deletingVideos);
      finalDeletingVideos.remove(deleteKey);

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        deletingVideos: finalDeletingVideos,
        error: null,
      );
    } catch (e) {
      // Remove deleting state on error
      final finalDeletingVideos = Map<String, bool>.from(state.deletingVideos);
      finalDeletingVideos.remove(deleteKey);

      final errorMessage = 'Failed to delete video from kata $kataId: ${e.toString()}';
      state = state.copyWith(
        deletingVideos: finalDeletingVideos,
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

  Future<void> deleteAllKataVideos(int kataId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await VideoService.deleteAllKataVideos(kataId);

      // Remove cached videos for this kata
      final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
      updatedKataVideos.remove(kataId);

      state = state.copyWith(
        kataVideos: updatedKataVideos,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      final errorMessage = 'Failed to delete all videos for kata $kataId: ${e.toString()}';
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

  Future<void> reorderVideos(int kataId, List<String> reorderedVideoUrls) async {
    // Update cached videos with new order
    final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
    updatedKataVideos[kataId] = reorderedVideoUrls;

    state = state.copyWith(
      kataVideos: updatedKataVideos,
      error: null,
    );

    // Note: You might want to implement server-side reordering logic here
    // For now, we just update the local cache
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearKataVideos(int kataId) {
    final updatedKataVideos = Map<int, List<String>>.from(state.kataVideos);
    updatedKataVideos.remove(kataId);
    
    state = state.copyWith(kataVideos: updatedKataVideos);
  }

  bool isUploadingForKata(int kataId) {
    return state.uploadingVideos.containsKey('kata_${kataId}_upload');
  }

  bool isDeletingVideo(String videoUrl) {
    return state.deletingVideos.containsKey(videoUrl);
  }

  List<String> getCachedVideos(int kataId) {
    return state.kataVideos[kataId] ?? [];
  }

  /// Pick and upload a single video
  Future<String?> pickAndUploadVideo(int kataId, {bool fromCamera = false}) async {
    try {
      final File? videoFile = fromCamera 
          ? await VideoService.recordVideoWithCamera()
          : await VideoService.pickVideoFromGallery();
      
      if (videoFile != null) {
        final urls = await uploadVideos([videoFile], kataId);
        return urls.isNotEmpty ? urls.first : null;
      }
      return null;
    } catch (e) {
      final errorMessage = 'Failed to pick and upload video: ${e.toString()}';
      state = state.copyWith(error: errorMessage);
      rethrow;
    }
  }

  /// Get video file size and info
  Future<Map<String, dynamic>?> getVideoInfo(String videoUrl) async {
    try {
      // This would require additional implementation to get video metadata
      // For now, return basic info
      return {
        'url': videoUrl,
        'fileName': VideoService.extractFileNameFromUrl(videoUrl),
        'isValid': VideoUtils.isValidVideoUrl(videoUrl),
      };
    } catch (e) {
      print('Error getting video info: $e');
      return null;
    }
  }
}

// Provider for the VideoNotifier
final videoNotifierProvider = StateNotifierProvider<VideoNotifier, VideoState>((ref) {
  final errorBoundary = ref.watch(errorBoundaryProvider.notifier);
  return VideoNotifier(errorBoundary);
});

// Convenience providers for specific video state properties
final videoLoadingProvider = Provider<bool>((ref) {
  return ref.watch(videoNotifierProvider).isLoading;
});

final videoErrorProvider = Provider<String?>((ref) {
  return ref.watch(videoNotifierProvider).error;
});

// Family provider for kata videos with caching
final cachedKataVideosProvider = Provider.family<List<String>, int>((ref, kataId) {
  final videoState = ref.watch(videoNotifierProvider);
  return videoState.kataVideos[kataId] ?? [];
});

// Family provider for upload status
final isUploadingVideosProvider = Provider.family<bool, int>((ref, kataId) {
  final videoState = ref.watch(videoNotifierProvider);
  return videoState.uploadingVideos.containsKey('kata_${kataId}_upload');
});

// Family provider for delete status
final isDeletingVideoProvider = Provider.family<bool, String>((ref, videoUrl) {
  final videoState = ref.watch(videoNotifierProvider);
  return videoState.deletingVideos.containsKey(videoUrl);
});

// Async provider for fresh kata videos (bypasses cache)
final freshKataVideosProvider = FutureProvider.family<List<String>, int>((ref, kataId) async {
  return await VideoService.fetchKataVideosFromBucket(kataId);
});

// Combined media provider that gives both images and videos
final combinedMediaProvider = Provider.family<Map<String, List<String>>, int>((ref, kataId) {
  final images = ref.watch(cachedKataImagesProvider(kataId));
  final videos = ref.watch(cachedKataVideosProvider(kataId));
  
  return {
    'images': images,
    'videos': videos,
  };
});

// Provider to check if kata has any media
final hasMediaProvider = Provider.family<bool, int>((ref, kataId) {
  final media = ref.watch(combinedMediaProvider(kataId));
  return media['images']!.isNotEmpty || media['videos']!.isNotEmpty;
});

// Provider for total media count
final mediaCountProvider = Provider.family<int, int>((ref, kataId) {
  final media = ref.watch(combinedMediaProvider(kataId));
  return media['images']!.length + media['videos']!.length;
});
