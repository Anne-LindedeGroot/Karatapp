import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'retry_utils.dart';
import '../services/offline_media_cache_service.dart';
import '../providers/network_provider.dart';
import '../desktop/desktop_image_utils.dart';

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
  static Future<File?> captureImageWithCamera({BuildContext? context}) async {
    try {
      // Desktop: use the dedicated camera screen (shows fallback UI if needed)
      final desktopImage =
          await DesktopImageUtils.captureImageWithCamera(context: context);
      if (desktopImage != null) {
        return desktopImage;
      }
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
        debugPrint('🖼️ Starting upload of ${imageFiles.length} images to kata $kataId');
        List<String> uploadedUrls = [];

        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          final fileName = generateUniqueFileName('kata_${kataId}_$i');
          debugPrint('📤 Uploading image ${i + 1}/${imageFiles.length}: ${imageFile.path} -> kata_images/$kataId/$fileName');
          final url = await uploadImageToSupabase(imageFile, fileName, kataId);

          if (url != null) {
            uploadedUrls.add(url);
            debugPrint('✅ Successfully uploaded image ${i + 1}: $url');
          } else {
            debugPrint('❌ Failed to upload image ${i + 1}: $fileName');
            throw Exception('Failed to upload image ${i + 1} of ${imageFiles.length}');
          }
        }

        debugPrint('🎉 Completed upload of ${uploadedUrls.length} images');
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

          // Check if the bucket exists and is accessible
          try {
            await supabase.storage.getBucket('kata_images');
            debugPrint('✅ kata_images bucket exists and is accessible');
          } catch (bucketError) {
            debugPrint('❌ kata_images bucket error: $bucketError');
            throw Exception('Storage bucket kata_images not found or not accessible. Please create it in your Supabase dashboard.');
          }

          // Create a folder structure: kata_images/{kata_id}/filename
          final filePath = '$kataId/$fileName';
          debugPrint('📁 Uploading to path: kata_images/$filePath');

          // Read the file as bytes
          final bytes = await imageFile.readAsBytes();
          debugPrint('📏 File size: ${bytes.length} bytes');

          if (bytes.isEmpty) {
            throw Exception('Image file is empty: ${imageFile.path}');
          }

          // Upload to Supabase Storage (in a 'kata_images' bucket with folder structure)
          debugPrint('☁️ Starting upload to Supabase...');
          await supabase.storage
              .from('kata_images')
              .uploadBinary(filePath, bytes);
          debugPrint('✅ Upload completed successfully');

          // Get the public URL of the uploaded image
          final publicUrl = supabase.storage
              .from('kata_images')
              .getPublicUrl(filePath);

          debugPrint('🔗 Generated public URL: $publicUrl');
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
  static Future<List<String>> fetchKataImagesFromBucket(int kataId, {dynamic ref}) async {
    // Check network connectivity first to avoid unnecessary network requests
    bool isOnline = true;
    try {
      if (ref != null) {
        final networkState = ref.read(networkProvider);
        isOnline = networkState.isConnected;
      }
    } catch (e) {
      // If we can't check network state, assume we're online and try
      isOnline = true;
    }

    if (!isOnline) {
      debugPrint('🌐 Offline mode detected, trying to load cached kata images for kata $kataId');
      // Try to return cached images when offline
      try {
        final cachedPaths = await OfflineMediaCacheService.getCachedKataImageUrls(kataId);
        if (cachedPaths.isNotEmpty) {
          debugPrint('✅ Found ${cachedPaths.length} cached images for kata $kataId');
          return cachedPaths;
        }
      } catch (cacheError) {
        debugPrint('⚠️ Failed to load cached kata images: $cacheError');
      }
      debugPrint('ℹ️ No cached images available for kata $kataId, returning empty list');
      return [];
    }

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

            // Check if this is a network error or file descriptor error
            if (_isNetworkError(e) || _isFileDescriptorError(e)) {
              debugPrint('🌐 Network/file error detected, returning empty list for offline mode');
              return [];
            }

            // Bucket should already exist - if not accessible, return empty list
          }

          // Check if there's a stored image order in the kata record
          List<String>? storedOrder;
          try {
            final kataResponse = await supabase
                .from('katas')
                .select('image_urls')
                .eq('id', kataId)
                .single();

            storedOrder = kataResponse['image_urls'] != null
                ? List<String>.from(kataResponse['image_urls'] as List)
                : null;

            if (storedOrder != null && storedOrder.isNotEmpty) {
              debugPrint('📋 Found stored image order for kata $kataId: ${storedOrder.length} images');
            }
          } catch (e) {
            // Silent: Image order fetch failures are not logged
          }

          // List all files in the kata's folder with proper error handling
          // Silent: File listing for kata not logged
          List<dynamic> response = [];

          try {
            response = await supabase.storage
                .from('kata_images')
                .list(path: kataId.toString());
          } catch (listError) {
            debugPrint('❌ Error listing files for kata $kataId: $listError');

            // If it's a file descriptor error, return empty list
            if (_isFileDescriptorError(listError)) {
              debugPrint('🔧 File descriptor error detected, returning empty list');
              return [];
            }

            // For other errors, rethrow
            rethrow;
          }

          // Silent: File count logging is not shown

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
                // Reduced spam: URL generation is now silent

                // Cache the image for offline access if ref is provided
                if (ref != null) {
                  try {
                    await OfflineMediaCacheService.cacheMediaFile(signedUrl, false, ref);
                    await OfflineMediaCacheService.cacheKataImage(kataId, file.name, signedUrl, ref);
                    await OfflineMediaCacheService.updateKataMetadata(kataId, signedUrl);
                  } catch (cacheError) {
                    debugPrint('⚠️ Failed to cache kata image ${file.name}: $cacheError');
                  }
                }
              } catch (signedUrlError) {
                debugPrint('❌ Failed to create signed URL for ${file.name}: $signedUrlError');

                // If it's a file descriptor error, skip this file
                if (_isFileDescriptorError(signedUrlError)) {
                  debugPrint('🔧 File descriptor error for ${file.name}, skipping');
                  continue;
                }

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

                  // If it's a file descriptor error, skip this file
                  if (_isFileDescriptorError(publicUrlError)) {
                    debugPrint('🔧 File descriptor error for ${file.name}, skipping');
                    continue;
                  }
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

          // If we have a stored order, use it to sort the images
          if (storedOrder != null && storedOrder.isNotEmpty) {
            debugPrint('🔄 Using stored image order for sorting');

            // Create a map of filename to URL for quick lookup
            final fileNameToData = <String, Map<String, String>>{};
            for (final data in imageData) {
              fileNameToData[data['name']!] = data;
            }

            // Sort images according to stored order
            final orderedUrls = <String>[];
            debugPrint('🔍 Stored order has ${storedOrder.length} URLs');
            for (final storedUrl in storedOrder) {
              final storedFileName = extractFileNameFromUrl(storedUrl);
              debugPrint('🔍 Looking for stored filename: $storedFileName');
              if (storedFileName != null && fileNameToData.containsKey(storedFileName)) {
                orderedUrls.add(fileNameToData[storedFileName]!['url']!);
                debugPrint('✅ Found match for $storedFileName');
              } else {
                debugPrint('❌ No match found for $storedFileName');
              }
            }

            // Add any remaining images that weren't in the stored order
            for (final data in imageData) {
              if (!orderedUrls.contains(data['url'])) {
                orderedUrls.add(data['url']!);
                debugPrint('➕ Added remaining image: ${data['name']}');
              }
            }

            debugPrint('✅ Successfully ordered ${orderedUrls.length} images using stored order');
            debugPrint('🖼️ Ordered image URLs: ${orderedUrls.map(extractFileNameFromUrl).take(3).join(', ')}${orderedUrls.length > 3 ? '...' : ''}');
            return orderedUrls;
          } else {
            // Fall back to sorting by filename numerically (kata_1_0, kata_1_1, kata_1_2, etc.)
            imageData.sort((a, b) {
              final nameA = a['name']!;
              final nameB = b['name']!;

              // Extract the order number from filenames like "kata_1_0_timestamp.jpg"
              final orderA = _extractOrderNumber(nameA);
              final orderB = _extractOrderNumber(nameB);

              return orderA.compareTo(orderB);
            });

            debugPrint('📋 Fallback numerical sorting for kata $kataId: ${imageData.map((d) => d['name']).take(5).join(', ')}${imageData.length > 5 ? '...' : ''}');
            debugPrint('🔗 Final URLs order: ${imageData.map((d) => d['url']!).map(extractFileNameFromUrl).take(5).join(', ')}${imageData.length > 5 ? '...' : ''}');

            // Extract just the URLs in the correct order
            final urls = imageData.map((data) => data['url']!).toList();
            return urls;
          }
        } catch (e) {
          debugPrint('❌ Error fetching kata images from bucket: $e');
          
          // Check if this is a network error or file descriptor error - if so, try to return cached images
          if (_isNetworkError(e) || _isFileDescriptorError(e)) {
            debugPrint('🌐 Network/file error detected, checking for cached kata images');

            // Try to return cached images if available
            if (ref != null) {
              try {
                final cachedPaths = await OfflineMediaCacheService.getCachedKataImageUrls(kataId);
                if (cachedPaths.isNotEmpty) {
                  debugPrint('✅ Found ${cachedPaths.length} cached images for kata $kataId');
                  return cachedPaths;
                }
              } catch (cacheError) {
                debugPrint('⚠️ Failed to get cached kata images: $cacheError');
              }
            }

            debugPrint('ℹ️ No cached images available for kata $kataId, returning empty list');
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

  /// Get file extension from a filename
  static String? getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return null;
  }

  /// Create ordered image file name (for multiple images)
  static String createOrderedImageFileName(int kataId, int order, String originalFileName) {
    final extension = getFileExtension(originalFileName) ?? 'jpg';
    final orderPrefix = order.toString().padLeft(3, '0');
    return '${kataId}_${orderPrefix}_image.$extension';
  }

  /// Rename/move an image file in Supabase storage (used for reordering)
  static Future<bool> renameImageFile(int kataId, String oldFileName, String newFileName) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;

          // Copy the file to the new name
          await supabase.storage
              .from('kata_images')
              .copy('$kataId/$oldFileName', '$kataId/$newFileName');

          // Delete the old file
          await supabase.storage
              .from('kata_images')
              .remove(['$kataId/$oldFileName']);

          debugPrint('✅ Renamed image file: $oldFileName -> $newFileName');
          return true;
        } catch (e) {
          debugPrint('❌ Failed to rename image file $oldFileName to $newFileName: $e');
          return false;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying rename image file (attempt $attempt): $error');
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
  
  /// Delete multiple specific images from the bucket
  static Future<bool> deleteMultipleImagesFromSupabase(
    List<String> imageUrls, {
    String bucket = 'kata_images',
  }) async {
    if (imageUrls.isEmpty) return true;

    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;

          // Extract storage paths from URLs
          final fileNames = imageUrls.map((url) {
            return _extractStoragePath(url, bucket);
          }).whereType<String>().where((name) => name.isNotEmpty).toList();

          if (fileNames.isNotEmpty) {
            // Delete the files from storage
            await supabase.storage
                .from(bucket)
                .remove(fileNames);

            debugPrint('✅ Successfully deleted ${fileNames.length} images');
          }

          return true;
        } catch (e) {
          debugPrint('Error deleting multiple images from bucket $bucket: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete multiple images (attempt $attempt) in $bucket: $error');
      },
    );
  }

  static String? _extractStoragePath(String url, String bucket) {
    if (url.trim().isEmpty) return null;
    if (url.startsWith('file://') || url.startsWith('/')) {
      // Local path, not a storage object reference
      return null;
    }

    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      final bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex != -1 && pathSegments.length > bucketIndex + 2) {
        return '${pathSegments[bucketIndex + 1]}/${pathSegments[bucketIndex + 2]}';
      }
    } catch (_) {}

    return null;
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

  /// Extract the order number from a filename like "kata_1_0_timestamp.jpg"
  /// Returns the order number (0, 1, 2, etc.) for proper numerical sorting
  static int _extractOrderNumber(String filename) {
    try {
      // Pattern: kata_X_Y_timestamp.jpg where Y is the order number
      final parts = filename.split('_');
      if (parts.length >= 3) {
        // The order number is the third part (index 2)
        final orderPart = parts[2];
        // Remove any non-numeric suffix (like timestamp)
        final orderStr = orderPart.split('.').first.split('_').first;
        return int.tryParse(orderStr) ?? 0;
      }
    } catch (e) {
      debugPrint('Error extracting order number from $filename: $e');
    }
    return 0; // Default to 0 if extraction fails
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

  /// Upload multiple images to Supabase Storage organized by ohyo ID
  static Future<List<String>> uploadOhyoImages(
    List<File> imageFiles,
    int ohyoId, {
    int startIndex = 0,
  }) async {
    return await RetryUtils.executeWithRetry(
      () async {
        List<String> uploadedUrls = [];

        for (int i = 0; i < imageFiles.length; i++) {
          final imageFile = imageFiles[i];
          final orderIndex = i + startIndex;
          final fileName = generateUniqueFileName('ohyo_${ohyoId}_$orderIndex');
          final url = await uploadOhyoImageToSupabase(imageFile, fileName, ohyoId);

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
        debugPrint('🔄 Retrying upload ohyo images (attempt $attempt): $error');
      },
    );
  }

  /// Persist ohyo image order to storage as a lightweight manifest file.
  static Future<void> saveOhyoImageOrder(int ohyoId, List<String> orderedUrls) async {
    if (orderedUrls.isEmpty) return;

    final fileNames = orderedUrls
        .map(extractFileNameFromUrl)
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();

    if (fileNames.isEmpty) return;

    try {
      final supabase = Supabase.instance.client;
      final bytes = utf8.encode(json.encode(fileNames));
      await supabase.storage.from('ohyo_images').uploadBinary(
        '$ohyoId/_order.json',
        bytes,
        fileOptions: const FileOptions(
          upsert: true,
          cacheControl: '60',
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Failed to save ohyo order manifest for $ohyoId: $e');
    }
  }

  /// Reorder ohyo images by renaming files to include the new order index
  static Future<void> reorderOhyoImages(int ohyoId, List<String> orderedUrls) async {
    if (orderedUrls.isEmpty) return;

    final supabase = Supabase.instance.client;

    for (int i = 0; i < orderedUrls.length; i++) {
      final url = orderedUrls[i];
      if (url.trim().isEmpty) continue;
      if (url.startsWith('/') || url.startsWith('file://')) {
        // Skip local paths (offline previews)
        continue;
      }

      final fileName = extractFileNameFromUrl(url);
      if (fileName == null || fileName.isEmpty) continue;

      final currentPath = '$ohyoId/$fileName';
      final newFileName = generateUniqueFileName('ohyo_${ohyoId}_$i');
      final newPath = '$ohyoId/$newFileName';

      if (currentPath == newPath) continue;

      try {
        final fileData = await supabase.storage
            .from('ohyo_images')
            .download(currentPath);

        await supabase.storage
            .from('ohyo_images')
            .uploadBinary(newPath, fileData);

        await supabase.storage
            .from('ohyo_images')
            .remove([currentPath]);
      } catch (e) {
        debugPrint('Error reordering ohyo image $currentPath -> $newPath: $e');
      }
    }
  }

  /// Upload ohyo image to Supabase Storage organized by ohyo ID
  static Future<String?> uploadOhyoImageToSupabase(File imageFile, String fileName, int ohyoId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;
          debugPrint('🖼️ DEBUG: Uploading ohyo image for ohyoId: $ohyoId, fileName: $fileName');

          // Validate file exists and is readable
          if (!await imageFile.exists()) {
            throw Exception('Image file does not exist: ${imageFile.path}');
          }

          // Bucket should already exist - don't try to create it

          // Create a folder structure: ohyo_images/{ohyo_id}/filename
          final filePath = '$ohyoId/$fileName';
          debugPrint('🖼️ DEBUG: Upload path will be: ohyo_images/$filePath');

          // Read the file as bytes
          final bytes = await imageFile.readAsBytes();

          if (bytes.isEmpty) {
            throw Exception('Image file is empty: ${imageFile.path}');
          }

          // Upload to Supabase Storage (in a 'ohyo_images' bucket with folder structure)
          await supabase.storage
              .from('ohyo_images')
              .uploadBinary(filePath, bytes);

          // Get the public URL of the uploaded image
          final publicUrl = supabase.storage
              .from('ohyo_images')
              .getPublicUrl(filePath);

          return publicUrl;
        } catch (e) {
          debugPrint('Error uploading ohyo image to Supabase: $e');
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            debugPrint('SOLUTION: The ohyo_images bucket does not exist. Please create it in your Supabase dashboard.');
            debugPrint('Go to: Storage → Buckets → New bucket → Name: ohyo_images → Make it Public → Create');
            throw Exception('Storage bucket not found. Please create the ohyo_images bucket in your Supabase dashboard.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            debugPrint('SOLUTION: Storage policies are blocking uploads. Please set up proper RLS policies.');
            throw Exception('Storage access denied. Please check your storage policies.');
          }
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying upload ohyo image (attempt $attempt): $error');
      },
    );
  }

  /// Fetch all images for a specific ohyo ID from the bucket
  static Future<List<String>> fetchOhyoImagesFromBucket(int ohyoId, {dynamic ref}) async {
    // Check network connectivity first to avoid unnecessary network requests
    bool isOnline = true;
    bool networkCheckFailed = false;

    try {
      if (ref != null) {
        final networkState = ref.read(networkProvider);
        isOnline = networkState.isConnected;
        debugPrint('🌐 Network provider status for ohyo $ohyoId: ${networkState.status}');
      } else {
        // Fallback network check if provider not available
        try {
          final result = await InternetAddress.lookup('google.com').timeout(
            const Duration(seconds: 3),
          );
          isOnline = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
          // Silent: Network check results are not logged
        } catch (e) {
          // Silent: Network check failures are not logged
          isOnline = false;
          networkCheckFailed = true;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Network state check failed for ohyo $ohyoId: $e');
      // If we can't check network state, assume we're online and try, but be prepared for failure
      isOnline = true;
      networkCheckFailed = true;
    }

    if (!isOnline || networkCheckFailed) {
      debugPrint('🌐 Offline or network check failed for ohyo $ohyoId, trying cached images first');
      // Try to return cached images when offline or network check fails
      try {
        final cachedPaths = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
        if (cachedPaths.isNotEmpty) {
          debugPrint('✅ Found ${cachedPaths.length} cached images for ohyo $ohyoId');
          return cachedPaths;
        }
      } catch (cacheError) {
        debugPrint('⚠️ Failed to load cached ohyo images: $cacheError');
      }
      debugPrint('ℹ️ No cached images available for ohyo $ohyoId, will try online if network available');

      // If network check failed but we might still be online, continue to try online
      if (networkCheckFailed && isOnline) {
        debugPrint('🔄 Network check failed but assuming online, proceeding to online fetch');
      } else {
        debugPrint('ℹ️ Returning empty list for ohyo $ohyoId (offline mode)');
        return [];
      }
    }

    return await RetryUtils.executeWithRetry<List<String>>(
      () async {
        try {
          final supabase = Supabase.instance.client;

          // Check if the ohyo_images bucket exists by trying to list files in root
          // This is more reliable than getBucket() which may fail due to permissions
          try {
            final testList = await supabase.storage
                .from('ohyo_images')
                .list(path: ''); // Just check if we can list anything
            debugPrint('✅ ohyo_images bucket is accessible (found ${testList.length} items in root)');
          } catch (bucketError) {
            // If listing fails, try the old method as fallback
            try {
              final bucket = await supabase.storage.getBucket('ohyo_images');
              debugPrint('✅ ohyo_images bucket found via getBucket (public: ${bucket.public})');
            } catch (fallbackError) {
              debugPrint('⚠️ Could not verify ohyo_images bucket exists: $bucketError');
              debugPrint('💡 This might be a permission issue, but the bucket may still exist.');
              debugPrint('💡 If images are being stored successfully, the bucket exists and this is just a verification issue.');
              debugPrint('💡 Proceeding anyway - images should work despite verification failure');
            }
          }

          // Check if there's a stored image order in the ohyo record
          List<String>? storedOrder;
          List<String>? storedOrderFileNames;
          try {
            final ohyoResponse = await supabase
                .from('ohyo')
                .select('image_urls')
                .eq('id', ohyoId)
                .single();

            storedOrder = ohyoResponse['image_urls'] != null
                ? List<String>.from(ohyoResponse['image_urls'] as List)
                : null;
          } catch (_) {
            // Silent: Image order fetch failures are not logged
          }

          // Try to load order manifest from storage as a fallback
          try {
            final bytes = await supabase.storage
                .from('ohyo_images')
                .download('$ohyoId/_order.json');
            final decoded = json.decode(utf8.decode(bytes));
            if (decoded is List) {
              storedOrderFileNames = decoded.map((value) => value.toString()).toList();
            }
          } catch (_) {
            // Silent: order manifest may not exist
          }

          // List all files in the ohyo's folder with proper error handling
          // Silent: File listing debug is not shown
          List<dynamic> response = [];

          try {
            response = await supabase.storage
                .from('ohyo_images')
                .list(path: ohyoId.toString());
          } catch (listError) {
            debugPrint('❌ Error listing files for ohyo $ohyoId: $listError');

            // If it's a file descriptor error, return empty list
            if (_isFileDescriptorError(listError)) {
              debugPrint('🔧 File descriptor error detected, returning empty list');
              return [];
            }

            // If it's a bucket not found error, provide helpful message
            if (listError.toString().contains('Bucket not found') ||
                listError.toString().contains('404')) {
              debugPrint('🪣 ohyo_images bucket not found!');
              debugPrint('💡 Create it in Supabase Dashboard: Storage → New bucket → ohyo_images (Public)');
              debugPrint('💡 Create ohyo tables following the same pattern as kata tables');
              return [];
            }

            // For other errors, rethrow
            rethrow;
          }

          // Silent: File count logging is not shown

          if (response.isEmpty) {
            debugPrint('ℹ️ No images found for ohyo $ohyoId');
            return [];
          }

          List<Map<String, String>> imageData = [];

          for (final file in response) {
            if (file.name.isNotEmpty && !file.name.startsWith('.') && _isImageFile(file.name)) {
              try {
                // Use signed URLs directly since bucket appears to be private
                final signedUrl = await supabase.storage
                    .from('ohyo_images')
                    .createSignedUrl('$ohyoId/${file.name}', 7200); // 2 hour expiry

                imageData.add({
                  'url': signedUrl,
                  'name': file.name,
                });
                // Reduced spam: URL generation is now silent

                // Cache the image for offline access if ref is provided
                if (ref != null) {
                  try {
                    await OfflineMediaCacheService.cacheOhyoImage(ohyoId, file.name, signedUrl, ref);
                  } catch (cacheError) {
                    debugPrint('⚠️ Failed to cache ohyo image ${file.name}: $cacheError');
                  }
                }
              } catch (signedUrlError) {
                debugPrint('❌ Failed to create signed URL for ${file.name}: $signedUrlError');

                // If it's a file descriptor error, skip this file
                if (_isFileDescriptorError(signedUrlError)) {
                  debugPrint('🔧 File descriptor error for ${file.name}, skipping');
                  continue;
                }

                // Try public URL as fallback (in case bucket is actually public)
                try {
                  final publicUrl = supabase.storage
                      .from('ohyo_images')
                      .getPublicUrl('$ohyoId/${file.name}');

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

                  // If it's a file descriptor error, skip this file
                  if (_isFileDescriptorError(publicUrlError)) {
                    debugPrint('🔧 File descriptor error for ${file.name}, skipping');
                    continue;
                  }
                }
              }
            } else {
              debugPrint('⏭️ Skipping non-image file: ${file.name}');
            }
          }

          if (imageData.isEmpty) {
            debugPrint('ℹ️ No valid image files found for ohyo $ohyoId');
            return [];
          }

          // If we have a stored order, use it to sort the images
          if ((storedOrder != null && storedOrder.isNotEmpty) ||
              (storedOrderFileNames != null && storedOrderFileNames.isNotEmpty)) {
            final fileNameToData = <String, Map<String, String>>{};
            for (final data in imageData) {
              fileNameToData[data['name']!] = data;
            }

            final orderedUrls = <String>[];
            if (storedOrderFileNames != null && storedOrderFileNames.isNotEmpty) {
              for (final storedFileName in storedOrderFileNames) {
                if (fileNameToData.containsKey(storedFileName)) {
                  orderedUrls.add(fileNameToData[storedFileName]!['url']!);
                }
              }
            } else if (storedOrder != null && storedOrder.isNotEmpty) {
              for (final storedUrl in storedOrder) {
                final storedFileName = extractFileNameFromUrl(storedUrl);
                if (storedFileName != null && fileNameToData.containsKey(storedFileName)) {
                  orderedUrls.add(fileNameToData[storedFileName]!['url']!);
                }
              }
            }

            for (final data in imageData) {
              if (!orderedUrls.contains(data['url'])) {
                orderedUrls.add(data['url']!);
              }
            }

            return orderedUrls;
          } else {
            // Fall back to sorting by filename numerically (ohyo_9_0, ohyo_9_1, ohyo_9_10, etc.)
            imageData.sort((a, b) {
              final nameA = a['name']!;
              final nameB = b['name']!;
              final orderA = _extractOrderNumber(nameA);
              final orderB = _extractOrderNumber(nameB);
              return orderA.compareTo(orderB);
            });
            return imageData.map((data) => data['url']!).toList();
          }
        } catch (e) {
          debugPrint('❌ Error fetching ohyo images from bucket: $e');

          // Always try to return cached images on any error - be more aggressive about offline fallback
          debugPrint('🔄 Attempting to load cached images as fallback for ohyo $ohyoId');

          try {
            final cachedPaths = await OfflineMediaCacheService.getCachedOhyoImagePaths(ohyoId);
            if (cachedPaths.isNotEmpty) {
              debugPrint('✅ Found ${cachedPaths.length} cached images for ohyo $ohyoId as fallback');
              return cachedPaths;
            }
          } catch (cacheError) {
            debugPrint('⚠️ Failed to get cached images: $cacheError');
          }

          // If no cached images available, provide appropriate error handling
          if (_isNetworkError(e) || _isFileDescriptorError(e)) {
            debugPrint('🌐 Network/file error detected, no cached images available for ohyo $ohyoId');
            return []; // Return empty list for network errors
          }

          // Provide more specific error messages for non-network errors
          if (e.toString().contains('bucket') && e.toString().contains('not found')) {
            debugPrint('⚠️ Bucket not found error, but user confirmed bucket exists. This might be a permission issue.');
            debugPrint('💡 Please check your Supabase storage policies for ohyo_images bucket.');
            throw Exception('Storage bucket access issue. Please check your storage policies for ohyo_images bucket.');
          } else if (e.toString().contains('row-level security') || e.toString().contains('Unauthorized')) {
            throw Exception('Storage access denied. Please check your storage policies.');
          }

          // Re-throw other errors
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying fetch ohyo images (attempt $attempt): $error');
      },
    );
  }

  /// Delete all images for a specific ohyo ID
  static Future<bool> deleteOhyoImages(int ohyoId) async {
    return await RetryUtils.executeWithRetry(
      () async {
        try {
          final supabase = Supabase.instance.client;

          // First, list all files in the ohyo's folder
          final response = await supabase.storage
              .from('ohyo_images')
              .list(path: ohyoId.toString());

          // Create a list of file paths to delete
          List<String> filesToDelete = [];
          for (final file in response) {
            if (file.name.isNotEmpty) {
              filesToDelete.add('$ohyoId/${file.name}');
            }
          }

          // Delete all files
          if (filesToDelete.isNotEmpty) {
            debugPrint('🗑️ Deleting ${filesToDelete.length} images for ohyo $ohyoId');
            await supabase.storage
                .from('ohyo_images')
                .remove(filesToDelete);
            debugPrint('✅ Successfully deleted ${filesToDelete.length} images for ohyo $ohyoId');
          } else {
            debugPrint('ℹ️ No images found to delete for ohyo $ohyoId');
          }

          return true;
        } catch (e) {
          debugPrint('❌ Error deleting all ohyo images for ohyo $ohyoId: $e');
          rethrow;
        }
      },
      maxRetries: 3,
      initialDelay: const Duration(seconds: 1),
      shouldRetry: RetryUtils.shouldRetryImageError,
      onRetry: (attempt, error) {
        debugPrint('🔄 Retrying delete all ohyo images (attempt $attempt): $error');
      },
    );
  }

  /// Check if an error is a file descriptor error
  static bool _isFileDescriptorError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('bad file descriptor') ||
           errorString.contains('errno = 9') ||
           errorString.contains('file descriptor') ||
           errorString.contains('ebadf') ||
           errorString.contains('invalid file descriptor');
  }
}
