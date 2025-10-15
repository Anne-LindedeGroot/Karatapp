import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/retry_utils.dart';
import '../utils/video_utils.dart';

class VideoService {
  static final ImagePicker _picker = ImagePicker();
  
  /// Pick a video from gallery
  static Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: Duration(seconds: VideoUtils.maxVideoDurationSeconds),
      );
      if (video != null) {
        final file = File(video.path);
        
        // Validate the video file
        final validation = VideoUtils.validateVideoForUpload(file);
        if (!validation['isValid']) {
          throw Exception(validation['errors'].join(', '));
        }
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking video from gallery: $e');
      rethrow;
    }
  }
  
  /// Record a video with camera
  static Future<File?> recordVideoWithCamera() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: Duration(seconds: VideoUtils.maxVideoDurationSeconds),
      );
      if (video != null) {
        final file = File(video.path);
        
        // Validate the video file
        final validation = VideoUtils.validateVideoForUpload(file);
        if (!validation['isValid']) {
          throw Exception(validation['errors'].join(', '));
        }
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error recording video with camera: $e');
      rethrow;
    }
  }
  
  /// Upload multiple videos to Supabase Storage organized by kata ID
  static Future<List<String>> uploadMultipleVideosToSupabase(List<File> videoFiles, int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        List<String> uploadedUrls = [];
        
        for (int i = 0; i < videoFiles.length; i++) {
          final videoFile = videoFiles[i];
          final fileName = VideoUtils.createOrderedVideoFileName(kataId, i + 1, videoFile.path);
          final url = await uploadVideoToSupabase(videoFile, fileName, kataId);
          
          if (url != null) {
            uploadedUrls.add(url);
          } else {
            throw Exception('Failed to upload video ${i + 1} of ${videoFiles.length}');
          }
        }
        
        return uploadedUrls;
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 5), // Longer delay for videos
      shouldRetry: RetryUtils.shouldRetryImageError, // Reuse image retry logic
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload multiple videos (attempt $attempt): $error');
      },
    );
  }
  
  /// Upload video to Supabase Storage organized by kata ID
  static Future<String?> uploadVideoToSupabase(File videoFile, String fileName, int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Validate file exists and is readable
          if (!await videoFile.exists()) {
            throw Exception('Video file does not exist: ${videoFile.path}');
          }
          
          // Validate video file
          final validation = VideoUtils.validateVideoForUpload(videoFile);
          if (!validation['isValid']) {
            throw Exception('Video validation failed: ${validation['errors'].join(', ')}');
          }
          
          // Try to create the bucket if it doesn't exist (private bucket)
          try {
            await supabase.storage.createBucket(
              'kata_videos',
              BucketOptions(
                public: false, // Private bucket for better security
                allowedMimeTypes: ['video/*'],
                fileSizeLimit: VideoUtils.maxVideoSizeBytes.toString(),
              ),
            );
          } catch (e) {
            // Bucket might already exist, which is fine
            debugPrint('Video bucket creation attempt: $e');
          }
          
          // Create a folder structure: kata_videos/{kata_id}/filename
          final filePath = '$kataId/$fileName';
          
          // Read the file as bytes
          final bytes = await videoFile.readAsBytes();
          
          if (bytes.isEmpty) {
            throw Exception('Video file is empty: ${videoFile.path}');
          }
          
          debugPrint('📹 Uploading video: ${VideoUtils.formatFileSize(bytes.length)} - $fileName');
          
          // Upload to Supabase Storage (in a 'kata_videos' bucket with folder structure)
          await supabase.storage
              .from('kata_videos')
              .uploadBinary(filePath, bytes);
          
          // Get the public URL of the uploaded video
          final publicUrl = supabase.storage
              .from('kata_videos')
              .getPublicUrl(filePath);
          
          debugPrint('✅ Video uploaded successfully: $fileName');
          return publicUrl;
        } catch (e) {
          debugPrint('❌ Error uploading video to Supabase: $e');
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            debugPrint('SOLUTION: The kata_videos bucket does not exist. Please create it in your Supabase dashboard.');
            debugPrint('Go to: Storage → Buckets → New bucket → Name: kata_videos → Make it Public → Create');
            throw Exception('Video storage bucket not found. Please create the kata_videos bucket in your Supabase dashboard.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            debugPrint('SOLUTION: Storage policies are blocking video uploads. Please set up proper RLS policies.');
            throw Exception('Video storage access denied. Please check your storage policies.');
          } else if (e.toString().contains('size') && e.toString().contains('limit')) {
            throw Exception('Video file is too large. Maximum size: ${VideoUtils.formatFileSize(VideoUtils.maxVideoSizeBytes)}');
          }
          rethrow;
        }
      },
      maxRetries: 2, // Fewer retries for large video files
      initialDelay: const Duration(seconds: 5),
      shouldRetry: (error) {
        // Don't retry file size errors
        if (error.toString().contains('size') || error.toString().contains('large')) {
          return false;
        }
        return RetryUtils.shouldRetryImageError(error);
      },
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload video (attempt $attempt): $error');
      },
    );
  }
  
  /// Fetch all videos for a specific kata ID from the bucket
  static Future<List<String>> fetchKataVideosFromBucket(int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // First check if the bucket exists
          try {
            await supabase.storage.getBucket('kata_videos');
          } catch (e) {
            debugPrint('⚠️ kata_videos bucket not found or not accessible: $e');
            // Try to create the bucket if it doesn't exist
            try {
              await supabase.storage.createBucket(
                'kata_videos',
                BucketOptions(
                  public: false, // Private bucket for better security
                  allowedMimeTypes: ['video/*'],
                  fileSizeLimit: VideoUtils.maxVideoSizeBytes.toString(),
                ),
              );
              debugPrint('✅ Created kata_videos bucket (private)');
            } catch (createError) {
              debugPrint('❌ Failed to create kata_videos bucket: $createError');
              throw Exception('Video storage bucket not available. Please check your Supabase configuration.');
            }
          }
          
          // List all files in the kata's folder
          final response = await supabase.storage
              .from('kata_videos')
              .list(path: kataId.toString());
          
          if (response.isEmpty) {
            debugPrint('ℹ️ No videos found for kata $kataId');
            return [];
          }
          
          List<Map<String, String>> videoData = [];
          
          for (final file in response) {
            if (file.name.isNotEmpty && !file.name.startsWith('.') && VideoUtils.isVideoFile(file.name)) {
              try {
                // Create signed URL for better security and access control
                final signedUrl = await supabase.storage
                    .from('kata_videos')
                    .createSignedUrl('$kataId/${file.name}', 7200); // 2 hours expiry for videos
                
                videoData.add({
                  'url': signedUrl,
                  'name': file.name,
                });
                debugPrint('✅ Generated signed URL for video ${file.name}');
              } catch (signedUrlError) {
                debugPrint('⚠️ Failed to create signed URL for ${file.name}, falling back to public URL: $signedUrlError');
                // Fallback to public URL if signed URL fails
                final publicUrl = supabase.storage
                    .from('kata_videos')
                    .getPublicUrl('$kataId/${file.name}');
                videoData.add({
                  'url': publicUrl,
                  'name': file.name,
                });
              }
            }
          }
          
          if (videoData.isEmpty) {
            debugPrint('ℹ️ No valid video files found for kata $kataId');
            return [];
          }
          
          // Sort by filename to maintain order (files with order prefix will be sorted correctly)
          videoData.sort((a, b) => a['name']!.compareTo(b['name']!));
          
          // Extract just the URLs in the correct order
          final urls = videoData.map((data) => data['url']!).toList();
          debugPrint('✅ Successfully fetched ${urls.length} videos for kata $kataId');
          return urls;
        } catch (e) {
          debugPrint('❌ Error fetching kata videos from bucket: $e');
          
          // Provide more specific error messages
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            throw Exception('Video storage bucket not found. Please create the kata_videos bucket in your Supabase dashboard.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            throw Exception('Video storage access denied. Please check your storage policies.');
          } else if (e.toString().contains('network') || e.toString().contains('connection')) {
            throw Exception('Network error. Please check your internet connection.');
          }
          
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying fetch kata videos (attempt $attempt): $error');
      },
    );
  }
  
  /// Delete a specific video from the bucket
  static Future<bool> deleteVideoFromBucket(int kataId, String fileName) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Delete the file from storage
          await supabase.storage
              .from('kata_videos')
              .remove(['$kataId/$fileName']);
          
          debugPrint('✅ Successfully deleted video: $fileName');
          return true;
        } catch (e) {
          debugPrint('❌ Error deleting video from bucket: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete video (attempt $attempt): $error');
      },
    );
  }
  
  /// Delete all videos for a specific kata ID
  static Future<bool> deleteAllKataVideos(int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // First, list all files in the kata's folder
          final response = await supabase.storage
              .from('kata_videos')
              .list(path: kataId.toString());
          
          // Create a list of file paths to delete
          List<String> filesToDelete = [];
          for (final file in response) {
            if (file.name.isNotEmpty && VideoUtils.isVideoFile(file.name)) {
              filesToDelete.add('$kataId/${file.name}');
            }
          }
          
          // Delete all files
          if (filesToDelete.isNotEmpty) {
            debugPrint('🗑️ Deleting ${filesToDelete.length} videos for kata $kataId');
            await supabase.storage
                .from('kata_videos')
                .remove(filesToDelete);
            debugPrint('✅ Successfully deleted ${filesToDelete.length} videos for kata $kataId');
          } else {
            debugPrint('ℹ️ No videos found to delete for kata $kataId');
          }
          
          return true;
        } catch (e) {
          debugPrint('❌ Error deleting all kata videos for kata $kataId: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete all kata videos (attempt $attempt): $error');
      },
    );
  }
  
  /// Move a video from a temporary folder to the correct kata ID folder
  static Future<String?> moveVideoToKataFolder(String currentPath, int newKataId, String fileName) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Create the new path
          final newPath = '$newKataId/$fileName';
          
          // Move the file by copying to the new location and deleting the old one
          // First, get the existing file data
          final fileData = await supabase.storage
              .from('kata_videos')
              .download(currentPath);
          
          // Upload to the new location
          await supabase.storage
              .from('kata_videos')
              .uploadBinary(newPath, fileData);
          
          // Delete the old file
          await supabase.storage
              .from('kata_videos')
              .remove([currentPath]);
          
          // Get the public URL of the moved video
          final publicUrl = supabase.storage
              .from('kata_videos')
              .getPublicUrl(newPath);
          
          return publicUrl;
        } catch (e) {
          debugPrint('Error moving video to kata folder: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying move video (attempt $attempt): $error');
      },
    );
  }
  
  /// Clean up orphaned videos in the storage bucket
  /// SAFE cleanup function - only removes specific temporary video folders
  /// This function is much safer and only targets known temporary folders
  static Future<List<String>> safeCleanupTempVideoFolders() async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          List<String> deletedPaths = [];
          
          // Only target specific temporary folders that are safe to delete
          final safeToDeleteFolders = ['temp_upload', 'temp_processing', 'temp_backup'];
          
          // List all folders in the kata_videos bucket
          final response = await supabase.storage
              .from('kata_videos')
              .list();
          
          for (final folder in response) {
            if (folder.name.isNotEmpty) {
              // Only delete folders that are explicitly in our safe list
              if (safeToDeleteFolders.contains(folder.name)) {
                debugPrint('🧹 Found safe temporary video folder "${folder.name}", cleaning up...');
                
                // List all files in this folder
                final folderFiles = await supabase.storage
                    .from('kata_videos')
                    .list(path: folder.name);
                
                // Delete all video files in the folder
                List<String> filesToDelete = [];
                for (final file in folderFiles) {
                  if (file.name.isNotEmpty && VideoUtils.isVideoFile(file.name)) {
                    filesToDelete.add('${folder.name}/${file.name}');
                  }
                }
                
                if (filesToDelete.isNotEmpty) {
                  await supabase.storage
                      .from('kata_videos')
                      .remove(filesToDelete);
                  deletedPaths.addAll(filesToDelete);
                  debugPrint('✅ Deleted ${filesToDelete.length} temporary videos from folder "${folder.name}"');
                }
              }
            }
          }
          
          if (deletedPaths.isNotEmpty) {
            debugPrint('🎉 Safe video cleanup complete! Deleted ${deletedPaths.length} temporary videos total');
          } else {
            debugPrint('✨ No temporary video folders found - video storage is clean!');
          }
          
          return deletedPaths;
        } catch (e) {
          debugPrint('❌ Error during safe video cleanup: $e');
          rethrow;
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying safe video cleanup (attempt $attempt): $error');
      },
    );
  }
  
  /// Extract file name from a full video URL
  static String? extractFileNameFromUrl(String url) {
    return VideoUtils.extractFileNameFromUrl(url);
  }
}
