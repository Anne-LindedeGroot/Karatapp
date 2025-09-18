import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image/image.dart' as img;
import '../supabase_client.dart';

class AvatarService {
  static const String bucketName = 'user-avatars';
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB
  static const int thumbnailSize = 150;
  static const int avatarSize = 400;
  
  final SupabaseClient _client = SupabaseClientManager().client;

  // Upload avatar with automatic resizing and thumbnail generation
  Future<String?> uploadAvatar(File imageFile) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Validate file size
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSize) {
        throw Exception('File size exceeds 5MB limit');
      }

      // Read and process image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) throw Exception('Invalid image format');

      // Resize main avatar
      final resizedImage = img.copyResize(image, width: avatarSize, height: avatarSize);
      final resizedBytes = Uint8List.fromList(img.encodeJpg(resizedImage, quality: 85));

      // Create thumbnail
      final thumbnail = img.copyResize(image, width: thumbnailSize, height: thumbnailSize);
      final thumbnailBytes = Uint8List.fromList(img.encodeJpg(thumbnail, quality: 80));

      // Upload main avatar
      final avatarPath = '${user.id}/avatar.jpg';
      await _client.storage.from(bucketName).uploadBinary(
        avatarPath,
        resizedBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      // Upload thumbnail
      final thumbnailPath = '${user.id}/avatar_thumb.jpg';
      await _client.storage.from(bucketName).uploadBinary(
        thumbnailPath,
        thumbnailBytes,
        fileOptions: const FileOptions(
          cacheControl: '3600',
          upsert: true,
        ),
      );

      return avatarPath;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading avatar: $e');
      }
      return null;
    }
  }

  // Get signed URL for avatar
  Future<String?> getAvatarUrl(String? userId, {bool thumbnail = false}) async {
    try {
      if (userId == null) return null;
      
      final fileName = thumbnail ? 'avatar_thumb.jpg' : 'avatar.jpg';
      final path = '$userId/$fileName';
      
      final signedUrl = await _client.storage
          .from(bucketName)
          .createSignedUrl(path, 3600); // 1 hour expiry
      
      return signedUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error getting avatar URL: $e');
      }
      return null;
    }
  }

  // Delete user avatar
  Future<bool> deleteAvatar() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client.storage.from(bucketName).remove([
        '${user.id}/avatar.jpg',
        '${user.id}/avatar_thumb.jpg',
      ]);

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting avatar: $e');
      }
      return false;
    }
  }

  // Check if user has custom avatar
  Future<bool> hasCustomAvatar(String? userId) async {
    try {
      if (userId == null) return false;
      
      final files = await _client.storage
          .from(bucketName)
          .list(path: userId);
      
      return files.any((file) => file.name.startsWith('avatar.'));
    } catch (e) {
      return false;
    }
  }

  // Validate image file type
  static bool isValidImageFile(File file) {
    final extension = file.path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp'].contains(extension);
  }
}
