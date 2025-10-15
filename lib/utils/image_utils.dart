import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'retry_utils.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  /// Pick an image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90, // High quality (0-100, where 100 is original quality)
        maxWidth: 1920,   // Max width for better performance while maintaining quality
        maxHeight: 1920,  // Max height for better performance while maintaining quality
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      return null;
    }
  }
  
  /// Pick multiple images from gallery
  static Future<List<File>> pickMultipleImagesFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 90, // High quality (0-100, where 100 is original quality)
        maxWidth: 1920,   // Max width for better performance while maintaining quality
        maxHeight: 1920,  // Max height for better performance while maintaining quality
      );
      return images.map((image) => File(image.path)).toList();
    } catch (e) {
      debugPrint('Error picking images from gallery: $e');
      return [];
    }
  }
  
  /// Capture an image with camera
  static Future<File?> captureImageWithCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90, // High quality (0-100, where 100 is original quality)
        maxWidth: 1920,   // Max width for better performance while maintaining quality
        maxHeight: 1920,  // Max height for better performance while maintaining quality
      );
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error capturing image with camera: $e');
      return null;
    }
  }
  
  /// Upload multiple images to Supabase Storage organized by kata ID
  static Future<List<String>> uploadMultipleImagesToSupabase(List<File> imageFiles, int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        List<String> uploadedUrls = [];
        
        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          final fileName = generateUniqueFileName('kata_${kataId}_$i');
          final url = await uploadImageToSupabase(imageFile, fileName, kataId);
          
          if (url != null) {
            uploadedUrls.add(url);
          } else {
            throw Exception('Failed to upload image ${i + 1} of ${imageFiles.length}');
          }
        }
        
        return uploadedUrls;
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 2),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload multiple images (attempt $attempt): $error');
      },
    );
  }
  
  /// Upload image to Supabase Storage organized by kata ID
  static Future<String?> uploadImageToSupabase(File imageFile, String fileName, int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Validate file exists and is readable
          if (!await imageFile.exists()) {
            throw Exception('Image file does not exist: ${imageFile.path}');
          }
          
          // Try to create the bucket if it doesn't exist
          try {
            await supabase.storage.createBucket('kata_images');
          } catch (e) {
            // Bucket might already exist, which is fine
            debugPrint('Bucket creation attempt: $e');
          }
          
          // Create a folder structure: kata_images/{kata_id}/filename
          final filePath = '$kataId/$fileName';
          
          // Read the file as bytes
          final bytes = await imageFile.readAsBytes();
          
          if (bytes.isEmpty) {
            throw Exception('Image file is empty: ${imageFile.path}');
          }
          
          // Upload to Supabase Storage (in a 'kata_images' bucket with folder structure)
          await supabase.storage
              .from('kata_images')
              .uploadBinary(filePath, bytes);
          
          // Get the public URL of the uploaded image
          final publicUrl = supabase.storage
              .from('kata_images')
              .getPublicUrl(filePath);
          
          return publicUrl;
        } catch (e) {
          debugPrint('Error uploading image to Supabase: $e');
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            debugPrint('SOLUTION: The kata_images bucket does not exist. Please create it in your Supabase dashboard.');
            debugPrint('Go to: Storage → Buckets → New bucket → Name: kata_images → Make it Public → Create');
            throw Exception('Storage bucket not found. Please create the kata_images bucket in your Supabase dashboard.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            debugPrint('SOLUTION: Storage policies are blocking uploads. Please set up proper RLS policies.');
            debugPrint('See README.md for detailed setup instructions.');
            throw Exception('Storage access denied. Please check your storage policies.');
          }
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 2),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload image (attempt $attempt): $error');
      },
    );
  }
  
  /// Move an image from a temporary folder to the correct kata ID folder
  static Future<String?> moveImageToKataFolder(String currentPath, int newKataId, String fileName) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Create the new path
          final newPath = '$newKataId/$fileName';
          
          // Move the file by copying to the new location and deleting the old one
          // First, get the existing file data
          final fileData = await supabase.storage
              .from('kata_images')
              .download(currentPath);
          
          // Upload to the new location
          await supabase.storage
              .from('kata_images')
              .uploadBinary(newPath, fileData);
          
          // Delete the old file
          await supabase.storage
              .from('kata_images')
              .remove([currentPath]);
          
          // Get the public URL of the moved image
          final publicUrl = supabase.storage
              .from('kata_images')
              .getPublicUrl(newPath);
          
          return publicUrl;
        } catch (e) {
          debugPrint('Error moving image to kata folder: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying move image (attempt $attempt): $error');
      },
    );
  }
  
  /// Generate a unique file name for the image
  static String generateUniqueFileName(String baseName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp.jpg';
  }
  
  /// Fetch all images for a specific kata ID from the bucket
  static Future<List<String>> fetchKataImagesFromBucket(int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // First check if the bucket exists
          try {
            await supabase.storage.getBucket('kata_images');
            debugPrint('✅ kata_images bucket found');
          } catch (e) {
            debugPrint('⚠️ kata_images bucket not found or not accessible: $e');
            
            // Check if this is a network error
            if (_isNetworkError(e)) {
              debugPrint('🌐 Network error detected, returning empty list for offline mode');
              return [];
            }
            
            // Try to create the bucket if it doesn't exist (only if we have network)
            try {
              await supabase.storage.createBucket('kata_images', 
                BucketOptions(public: true, allowedMimeTypes: ['image/*']));
              debugPrint('✅ Created kata_images bucket');
            } catch (createError) {
              debugPrint('❌ Failed to create kata_images bucket: $createError');
              
              // If it's a network error, return empty list instead of throwing
              if (_isNetworkError(createError)) {
                debugPrint('🌐 Network error during bucket creation, returning empty list');
                return [];
              }
              
              throw Exception('Storage bucket not available. Please check your Supabase configuration.');
            }
          }
          
          // List all files in the kata's folder
          debugPrint('🔍 Listing files for kata $kataId...');
          final response = await supabase.storage
              .from('kata_images')
              .list(path: kataId.toString());
          
          debugPrint('📁 Found ${response.length} files in kata $kataId folder');
          
          if (response.isEmpty) {
            debugPrint('ℹ️ No images found for kata $kataId');
            return [];
          }
          
          List<Map<String, String>> imageData = [];
          
          for (final file in response) {
            if (file.name.isNotEmpty && !file.name.startsWith('.') && _isImageFile(file.name)) {
              try {
                // Use signed URLs directly since bucket appears to be private
                final signedUrl = await supabase.storage
                    .from('kata_images')
                    .createSignedUrl('$kataId/${file.name}', 7200); // 2 hour expiry
                
                imageData.add({
                  'url': signedUrl,
                  'name': file.name,
                });
                debugPrint('✅ Generated signed URL for ${file.name}');
              } catch (signedUrlError) {
                debugPrint('❌ Failed to create signed URL for ${file.name}: $signedUrlError');
                // Try public URL as fallback (in case bucket is actually public)
                try {
                  final publicUrl = supabase.storage
                      .from('kata_images')
                      .getPublicUrl('$kataId/${file.name}');
                  
                  if (publicUrl.isNotEmpty) {
                    imageData.add({
                      'url': publicUrl,
                      'name': file.name,
                    });
                    debugPrint('✅ Generated public URL for ${file.name}');
                  } else {
                    debugPrint('⚠️ Empty public URL for ${file.name}');
                  }
                } catch (publicUrlError) {
                  debugPrint('❌ Failed to create any URL for ${file.name}: $publicUrlError');
                }
              }
            } else {
              debugPrint('⏭️ Skipping non-image file: ${file.name}');
            }
          }
          
          if (imageData.isEmpty) {
            debugPrint('ℹ️ No valid image files found for kata $kataId');
            return [];
          }
          
          // Sort by filename to maintain order (files with order prefix will be sorted correctly)
          imageData.sort((a, b) => a['name']!.compareTo(b['name']!));
          
          // Extract just the URLs in the correct order
          final urls = imageData.map((data) => data['url']!).toList();
          debugPrint('✅ Successfully fetched ${urls.length} images for kata $kataId');
          debugPrint('🖼️ Image URLs: ${urls.take(3).join(', ')}${urls.length > 3 ? '...' : ''}');
          return urls;
        } catch (e) {
          debugPrint('❌ Error fetching kata images from bucket: $e');
          
          // Check if this is a network error - if so, return empty list for offline mode
          if (_isNetworkError(e)) {
            debugPrint('🌐 Network error detected, returning empty list for offline mode');
            return [];
          }
          
          // Provide more specific error messages for non-network errors
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            throw Exception('Storage bucket not found. Please create the kata_images bucket in your Supabase dashboard.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            throw Exception('Storage access denied. Please check your storage policies.');
          }
          
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying fetch kata images (attempt $attempt): $error');
      },
    );
  }

  /// Check if a file is an image based on its extension
  static bool _isImageFile(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);
  }

  /// Create signed URLs for private kata images
  static Future<List<String>> fetchPrivateKataImages(int kataId, {int expiresIn = 3600}) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // List all files in the kata's folder
          final response = await supabase.storage
              .from('kata_images')
              .list(path: kataId.toString());
          
          List<Map<String, String>> imageData = [];
          
          for (final file in response) {
            if (file.name.isNotEmpty) {
              // Create signed URL for private access
              final signedUrl = await supabase.storage
                  .from('kata_images')
                  .createSignedUrl('$kataId/${file.name}', expiresIn);
              imageData.add({
                'url': signedUrl,
                'name': file.name,
              });
            }
          }
          
          // Sort by filename to maintain order
          imageData.sort((a, b) => a['name']!.compareTo(b['name']!));
          
          // Extract just the URLs in the correct order
          return imageData.map((data) => data['url']!).toList();
        } catch (e) {
          debugPrint('Error fetching private kata images: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying fetch private kata images (attempt $attempt): $error');
      },
    );
  }
  
  /// Delete a specific image from the bucket
  static Future<bool> deleteImageFromBucket(int kataId, String fileName) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // Delete the file from storage
          await supabase.storage
              .from('kata_images')
              .remove(['$kataId/$fileName']);
          
          return true;
        } catch (e) {
          debugPrint('Error deleting image from bucket: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete image (attempt $attempt): $error');
      },
    );
  }
  
  /// Delete all images for a specific kata ID
  static Future<bool> deleteAllKataImages(int kataId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          
          // First, list all files in the kata's folder
          final response = await supabase.storage
              .from('kata_images')
              .list(path: kataId.toString());
          
          // Create a list of file paths to delete
          List<String> filesToDelete = [];
          for (final file in response) {
            if (file.name.isNotEmpty) {
              filesToDelete.add('$kataId/${file.name}');
            }
          }
          
          // Delete all files
          if (filesToDelete.isNotEmpty) {
            debugPrint('🗑️ Deleting ${filesToDelete.length} images for kata $kataId');
            await supabase.storage
                .from('kata_images')
                .remove(filesToDelete);
            debugPrint('✅ Successfully deleted ${filesToDelete.length} images for kata $kataId');
          } else {
            debugPrint('ℹ️ No images found to delete for kata $kataId');
          }
          
          return true;
        } catch (e) {
          debugPrint('❌ Error deleting all kata images for kata $kataId: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete all kata images (attempt $attempt): $error');
      },
    );
  }

  /// SAFE cleanup function - only removes specific temporary folders with confirmation
  /// This function is much safer and only targets known temporary folders
  static Future<List<String>> safeCleanupTempFolders() async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          List<String> deletedPaths = [];
          
          // Only target specific temporary folders that are safe to delete
          final safeToDeleteFolders = ['temp_upload', 'temp_processing', 'temp_backup'];
          
          // List all folders in the kata_images bucket
          final response = await supabase.storage
              .from('kata_images')
              .list();
          
          for (final folder in response) {
            if (folder.name.isNotEmpty) {
              // Only delete folders that are explicitly in our safe list
              if (safeToDeleteFolders.contains(folder.name)) {
                debugPrint('🧹 Found safe temporary folder "${folder.name}", cleaning up...');
                
                // List all files in this folder
                final folderFiles = await supabase.storage
                    .from('kata_images')
                    .list(path: folder.name);
                
                // Delete all files in the folder
                List<String> filesToDelete = [];
                for (final file in folderFiles) {
                  if (file.name.isNotEmpty) {
                    filesToDelete.add('${folder.name}/${file.name}');
                  }
                }
                
                if (filesToDelete.isNotEmpty) {
                  await supabase.storage
                      .from('kata_images')
                      .remove(filesToDelete);
                  deletedPaths.addAll(filesToDelete);
                  debugPrint('✅ Deleted ${filesToDelete.length} temporary files from folder "${folder.name}"');
                }
              }
            }
          }
          
          if (deletedPaths.isNotEmpty) {
            debugPrint('🎉 Safe cleanup complete! Deleted ${deletedPaths.length} temporary files total');
          } else {
            debugPrint('✨ No temporary folders found - storage is clean!');
          }
          
          return deletedPaths;
        } catch (e) {
          debugPrint('❌ Error during safe cleanup: $e');
          rethrow;
        }
      },
      maxRetries: 2,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying safe cleanup (attempt $attempt): $error');
      },
    );
  }
  
  /// Extract file name from a full URL
  static String? extractFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
      return null;
    } catch (e) {
      debugPrint('Error extracting file name from URL: $e');
      return null;
    }
  }

  /// Check if an error is a network-related error
  static bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
           errorString.contains('failed host lookup') ||
           errorString.contains('no address associated with hostname') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('dns') ||
           errorString.contains('host') ||
           errorString.contains('no internet') ||
           errorString.contains('unreachable');
  }
}
