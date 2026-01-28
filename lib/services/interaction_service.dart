import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/interaction_models.dart';
import '../models/forum_models.dart';
import 'role_service.dart';
import 'offline_queue_service.dart';
import 'comment_cache_service.dart';

class InteractionService {
  late final SupabaseClient _client = Supabase.instance.client;
  final RoleService _roleService = RoleService();
  final Uuid _uuid = const Uuid();
  static const List<String> _kataCommentImagesBucketCandidates = [
    'kata_comment_images',
    'KATA_COMMENT_IMAGES',
  ];
  static const List<String> _ohyoCommentImagesBucketCandidates = [
    'ohyo_comment_images',
    'OHYO_COMMENT_IMAGES',
  ];
  static const List<String> _kataCommentFilesBucketCandidates = [
    'KATA_COMMENT_FILES',
    'KATA_COMMENT_FILE',
    'kata_comment_files',
    'kata_comment_file',
  ];
  static const List<String> _ohyoCommentFilesBucketCandidates = [
    'OHYO_COMMENT_FILES',
    'OHYO_COMMENT_FILE',
    'ohyo_comment_files',
    'ohyo_comment_file',
  ];
  static const List<String> _commentFilesAllowedMimeTypes = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'text/plain',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
    'video/mp4',
    'audio/mpeg',
    'audio/mp4',
  ];
  static const int _signedUrlExpirySeconds = 31536000; // 1 year
  String? _resolvedKataCommentImagesBucket;
  String? _resolvedOhyoCommentImagesBucket;
  String? _resolvedKataCommentFilesBucket;
  String? _resolvedOhyoCommentFilesBucket;

  // Offline services - will be injected
  OfflineQueueService? _offlineQueueService;
  CommentCacheService? _commentCacheService;

  // Helper function to get user avatar from metadata
  // Returns avatar URL for custom avatars, or avatar ID for preset avatars
  String? _getUserAvatarFromMetadata(Map<String, dynamic>? metadata) {
    if (metadata == null) return null;
    
    final avatarType = metadata['avatar_type'] as String?;
    
    // For custom avatars, return the URL
    if (avatarType == 'custom') {
      return metadata['avatar_url'] as String?;
    }
    
    // For preset avatars, return the ID (check both avatar_id and preset_avatar_id for compatibility)
    if (avatarType == 'preset' || avatarType == null) {
      return metadata['avatar_id'] as String? ?? 
             metadata['preset_avatar_id'] as String?;
    }
    
    // Fallback: check if avatar_url exists (for backward compatibility)
    return metadata['avatar_url'] as String?;
  }

  String _getImageContentType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.heic')) return 'image/heic';
    if (path.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
  }

  String _getContentTypeForFile(File file) {
    final extension = _getFileExtensionFromPath(file.path).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.txt':
        return 'text/plain';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.m4a':
        return 'audio/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  String _getFileExtensionFromPath(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filePath.length - 1) {
      return '';
    }
    return filePath.substring(dotIndex);
  }

  String _getBaseName(String filePath) {
    final normalized = filePath.replaceAll('\\', '/');
    final slashIndex = normalized.lastIndexOf('/');
    if (slashIndex == -1 || slashIndex == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(slashIndex + 1);
  }

  String _sanitizeFileName(String name) {
    final trimmed = name.trim();
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  String _getFileExtension(File file) {
    final path = file.path;
    final dotIndex = path.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == path.length - 1) {
      return '.jpg';
    }
    return path.substring(dotIndex);
  }

  Future<String> _resolveKataCommentImagesBucket() async {
    if (_resolvedKataCommentImagesBucket != null) {
      return _resolvedKataCommentImagesBucket!;
    }
    for (final bucket in _kataCommentImagesBucketCandidates) {
      try {
        await _client.storage.getBucket(bucket);
        _resolvedKataCommentImagesBucket = bucket;
        return bucket;
      } catch (_) {
        // Ignore lookup failures; try next candidate.
      }
    }
    throw Exception(
      'Kata comment images bucket not found. Expected one of: '
      '${_kataCommentImagesBucketCandidates.join(', ')}',
    );
  }

  Future<String?> _tryResolveKataCommentImagesBucket() async {
    try {
      return await _resolveKataCommentImagesBucket();
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveOhyoCommentImagesBucket() async {
    if (_resolvedOhyoCommentImagesBucket != null) {
      return _resolvedOhyoCommentImagesBucket!;
    }
    for (final bucket in _ohyoCommentImagesBucketCandidates) {
      try {
        await _client.storage.getBucket(bucket);
        _resolvedOhyoCommentImagesBucket = bucket;
        return bucket;
      } catch (_) {
        // Ignore lookup failures; try next candidate.
      }
    }
    throw Exception(
      'Ohyo comment images bucket not found. Expected one of: '
      '${_ohyoCommentImagesBucketCandidates.join(', ')}',
    );
  }

  Future<String> _resolveKataCommentFilesBucket() async {
    if (_resolvedKataCommentFilesBucket != null) {
      return _resolvedKataCommentFilesBucket!;
    }
    for (final bucket in _kataCommentFilesBucketCandidates) {
      try {
        _resolvedKataCommentFilesBucket = bucket;
        return bucket;
      } catch (_) {
        // Ignore lookup failures; try next candidate.
      }
    }
    _resolvedKataCommentFilesBucket = _kataCommentFilesBucketCandidates.first;
    return _resolvedKataCommentFilesBucket!;
  }

  Future<String?> _tryResolveKataCommentFilesBucket() async {
    try {
      return await _resolveKataCommentFilesBucket();
    } catch (_) {
      return null;
    }
  }

  Future<String> _resolveOhyoCommentFilesBucket() async {
    if (_resolvedOhyoCommentFilesBucket != null) {
      return _resolvedOhyoCommentFilesBucket!;
    }
    for (final bucket in _ohyoCommentFilesBucketCandidates) {
      try {
        _resolvedOhyoCommentFilesBucket = bucket;
        return bucket;
      } catch (_) {
        // Ignore lookup failures; try next candidate.
      }
    }
    _resolvedOhyoCommentFilesBucket = _ohyoCommentFilesBucketCandidates.first;
    return _resolvedOhyoCommentFilesBucket!;
  }

  Future<String?> _tryResolveOhyoCommentFilesBucket() async {
    try {
      return await _resolveOhyoCommentFilesBucket();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _tryResolveOhyoCommentImagesBucket() async {
    try {
      return await _resolveOhyoCommentImagesBucket();
    } catch (_) {
      return null;
    }
  }

  Future<List<String>> _uploadCommentImages({
    required String bucket,
    required String folder,
    required String prefix,
    required int id,
    required List<File> imageFiles,
  }) async {
    if (imageFiles.isEmpty) return [];
    final uploadedUrls = <String>[];
    for (var i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      if (!await file.exists()) continue;
      final extension = _getFileExtension(file);
      final fileName =
          '${prefix}_${id}_${DateTime.now().millisecondsSinceEpoch}_$i$extension';
      final filePath = '$folder/$fileName';
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;

      await _client.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: _getImageContentType(file),
            ),
          );
      String url;
      try {
        url = await _client.storage
            .from(bucket)
            .createSignedUrl(filePath, _signedUrlExpirySeconds);
      } catch (_) {
        url = _client.storage.from(bucket).getPublicUrl(filePath);
      }
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  Future<List<String>> _uploadCommentFiles({
    required String bucket,
    required String folder,
    required String prefix,
    required int id,
    required List<File> files,
  }) async {
    if (files.isEmpty) return [];
    final uploadedUrls = <String>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (!await file.exists()) continue;
      final originalName = _getBaseName(file.path);
      final safeOriginalName = _sanitizeFileName(originalName);
      final fileName =
          '${prefix}_${id}_${DateTime.now().millisecondsSinceEpoch}_${i}__$safeOriginalName';
      final filePath = '$folder/$fileName';
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) continue;
      final contentType = _getContentTypeForFile(file);
      if (!_commentFilesAllowedMimeTypes.contains(contentType)) {
        throw Exception(
          'File type "$contentType" is not allowed for comment attachments.',
        );
      }

      await _client.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
            ),
          );
      String url;
      try {
        url = await _client.storage
            .from(bucket)
            .createSignedUrl(filePath, _signedUrlExpirySeconds);
      } catch (_) {
        url = _client.storage.from(bucket).getPublicUrl(filePath);
      }
      uploadedUrls.add(url);
    }
    return uploadedUrls;
  }

  String? _extractStoragePathFromUrl(String url, String bucket) {
    try {
      final uri = Uri.parse(url);
      final segments = uri.pathSegments;
      final bucketIndex = segments.indexOf(bucket);
      if (bucketIndex == -1 || bucketIndex + 1 >= segments.length) {
        return null;
      }
      return segments.sublist(bucketIndex + 1).join('/');
    } catch (_) {
      return null;
    }
  }

  String? _extractBucketFromUrl(String url) {
    try {
      final segments = Uri.parse(url).pathSegments;
      final publicIndex = segments.indexOf('public');
      if (publicIndex != -1 && publicIndex + 1 < segments.length) {
        return segments[publicIndex + 1];
      }
      final signIndex = segments.indexOf('sign');
      if (signIndex != -1 && signIndex + 1 < segments.length) {
        return segments[signIndex + 1];
      }
    } catch (_) {}
    return null;
  }

  Future<String> _maybeSignUrl(String url, String bucket) async {
    final isHttpUrl = url.startsWith('http://') || url.startsWith('https://');
    if (!isHttpUrl) {
      try {
        return await _client.storage.from(bucket).createSignedUrl(
              url,
              _signedUrlExpirySeconds,
            );
      } catch (_) {
        return url;
      }
    }
    if (!url.contains('/storage/v1/object/')) {
      return url;
    }

    final resolvedBucket = _extractBucketFromUrl(url) ?? bucket;
    final path = _extractStoragePathFromUrl(url, resolvedBucket);
    if (path == null || path.isEmpty) return url;
    try {
      return await _client.storage.from(resolvedBucket).createSignedUrl(
            path,
            _signedUrlExpirySeconds,
          );
    } catch (_) {
      return url;
    }
  }

  Future<String> _maybeSignUrlWithCandidates(
    String url,
    List<String> bucketCandidates,
  ) async {
    final isHttpUrl = url.startsWith('http://') || url.startsWith('https://');
    if (isHttpUrl) {
      if (!url.contains('/storage/v1/object/')) {
        return url;
      }
      final bucketFromUrl = _extractBucketFromUrl(url);
      if (bucketFromUrl != null) {
        return _maybeSignUrl(url, bucketFromUrl);
      }
      return url;
    }

    for (final bucket in bucketCandidates) {
      try {
        return await _client.storage
            .from(bucket)
            .createSignedUrl(url, _signedUrlExpirySeconds);
      } catch (_) {
        // Try next bucket
      }
    }
    return _client.storage.from(bucketCandidates.first).getPublicUrl(url);
  }

  Future<List<String>> _ensureSignedUrlsWithCandidates(
    List<String> urls,
    List<String> bucketCandidates,
  ) async {
    if (urls.isEmpty) return urls;
    return Future.wait(urls.map(
      (url) => _maybeSignUrlWithCandidates(url, bucketCandidates),
    ));
  }

  Future<void> _deleteCommentImages(String bucket, List<String> urls) async {
    if (urls.isEmpty) return;
    final paths = urls
        .map((url) => _extractStoragePathFromUrl(url, bucket))
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup only
    }
  }

  Future<void> _deleteCommentFiles(String bucket, List<String> urls) async {
    if (urls.isEmpty) return;
    final paths = urls
        .map((url) => _extractStoragePathFromUrl(url, bucket))
        .whereType<String>()
        .toList();
    if (paths.isEmpty) return;
    try {
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // Best-effort cleanup only
    }
  }

  void initializeOfflineServices(
    OfflineQueueService queueService,
    CommentCacheService cacheService,
  ) {
    _offlineQueueService = queueService;
    _commentCacheService = cacheService;
  }

  // KATA COMMENTS
  
  // Get comments for a specific kata with pagination
  Future<List<KataComment>> getKataCommentsPaginated({
    required int kataId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('kata_comments')
          .select('*')
          .eq('kata_id', kataId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      final bucket = await _tryResolveKataCommentImagesBucket();
      final comments = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((comment) async {
          final parsed = KataComment.fromJson(comment);
          final imageUrls = await _ensureSignedUrlsWithCandidates(
            parsed.imageUrls,
            bucket == null
                ? _kataCommentImagesBucketCandidates
                : <String>[bucket],
          );
          final filesBucket = await _tryResolveKataCommentFilesBucket();
          final fileUrls = await _ensureSignedUrlsWithCandidates(
            parsed.fileUrls,
            filesBucket == null
                ? _kataCommentFilesBucketCandidates
                : <String>[filesBucket],
          );
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

      return comments;
    } catch (e) {
      throw Exception('Failed to load kata comments: $e');
    }
  }

  // Get comments for a specific kata (legacy method - loads all)
  Future<List<KataComment>> getKataComments(int kataId) async {
    try {
      final response = await _client
          .from('kata_comments')
          .select('*')
          .eq('kata_id', kataId)
          .order('created_at', ascending: true);

      final bucket = await _tryResolveKataCommentImagesBucket();
      final comments = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((comment) async {
          final parsed = KataComment.fromJson(comment);
          final imageUrls = await _ensureSignedUrlsWithCandidates(
            parsed.imageUrls,
            bucket == null
                ? _kataCommentImagesBucketCandidates
                : <String>[bucket],
          );
          final filesBucket = await _tryResolveKataCommentFilesBucket();
          final fileUrls = await _ensureSignedUrlsWithCandidates(
            parsed.fileUrls,
            filesBucket == null
                ? _kataCommentFilesBucketCandidates
                : <String>[filesBucket],
          );
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

      return comments;
    } catch (e) {
      throw Exception('Failed to load kata comments: $e');
    }
  }

  // Add a comment to a kata
  Future<KataComment> addKataComment({
    required int kataId,
    required String content,
    int? parentCommentId,
    List<String> imageUrls = const [],
    List<String> fileUrls = const [],
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = _getUserAvatarFromMetadata(user.userMetadata);

      final commentData = {
        'kata_id': kataId,
        'content': content,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
        if (fileUrls.isNotEmpty) 'file_urls': fileUrls,
      };

      final response = await _client
          .from('kata_comments')
          .insert(commentData)
          .select()
          .single();

      return KataComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add kata comment: $e');
    }
  }

  // Update a kata comment (author, mediator, or host can do this)
  Future<KataComment> updateKataComment({
    required int commentId,
    required String content,
    List<String>? imageUrls,
    List<String>? fileUrls,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get comment details and check permissions
      final existingComment = await _client
          .from('kata_comments')
          .select('author_id, kata_id')
          .eq('id', commentId)
          .single();

      // Check if user is the comment author
      bool canEdit = existingComment['author_id'] == user.id;

      // If not the author, check if user is a mediator or host using RoleService
      if (!canEdit) {
        try {
          final userRole = await _roleService.getCurrentUserRole();
          canEdit = userRole == UserRole.mediator || userRole == UserRole.host;
        } catch (e) {
          // If role check fails, fall back to author-only permission
          canEdit = false;
        }
      }

      if (!canEdit) {
        throw Exception('You do not have permission to edit this comment');
      }

      final Map<String, dynamic> updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      if (fileUrls != null) {
        updateData['file_urls'] = fileUrls;
      }

      final response = await _client
          .from('kata_comments')
          .update(updateData)
          .eq('id', commentId)
          .select()
          .single();

      return KataComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update kata comment: $e');
    }
  }

  // Delete a kata comment (author, mediator, or host can do this)
  Future<void> deleteKataComment(int commentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get comment details and check permissions
      final existingComment = await _client
          .from('kata_comments')
          .select('author_id, kata_id, image_urls, file_urls')
          .eq('id', commentId)
          .single();

      // Check if user is the comment author
      bool canDelete = existingComment['author_id'] == user.id;

      // If not the author, check if user is a mediator or host using RoleService
      if (!canDelete) {
        try {
          final userRole = await _roleService.getCurrentUserRole();
          canDelete = userRole == UserRole.mediator || userRole == UserRole.host;
        } catch (e) {
          // If role check fails, fall back to author-only permission
          canDelete = false;
        }
      }

      if (!canDelete) {
        throw Exception('You do not have permission to delete this comment');
      }

      await _client
          .from('kata_comments')
          .delete()
          .eq('id', commentId);
      final imageUrls =
          (existingComment['image_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
      final fileUrls =
          (existingComment['file_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
      await _deleteCommentImages(await _resolveKataCommentImagesBucket(), imageUrls);
      await _deleteCommentFiles(await _resolveKataCommentFilesBucket(), fileUrls);
    } catch (e) {
      throw Exception('Failed to delete kata comment: $e');
    }
  }

  Future<List<String>> uploadKataCommentImages({
    required int commentId,
    required List<File> imageFiles,
  }) async {
    final bucketsToTry = <String>{
      if (_resolvedKataCommentImagesBucket != null)
        _resolvedKataCommentImagesBucket!,
      ..._kataCommentImagesBucketCandidates,
    }.toList();
    Object? lastError;

    for (final bucket in bucketsToTry) {
      try {
        final uploadedUrls = await _uploadCommentImages(
          bucket: bucket,
          folder: 'comments/$commentId',
          prefix: 'kata_comment',
          id: commentId,
          imageFiles: imageFiles,
        );
        _resolvedKataCommentImagesBucket ??= bucket;
        return uploadedUrls;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw Exception('Failed to upload kata comment images: $lastError');
    }
    return [];
  }

  Future<List<String>> uploadKataCommentFiles({
    required int commentId,
    required List<File> files,
  }) async {
    final bucketsToTry = <String>{
      if (_resolvedKataCommentFilesBucket != null)
        _resolvedKataCommentFilesBucket!,
      ..._kataCommentFilesBucketCandidates,
    }.toList();
    Object? lastError;

    for (final bucket in bucketsToTry) {
      try {
        final uploadedUrls = await _uploadCommentFiles(
          bucket: bucket,
          folder: 'comments/$commentId',
          prefix: 'kata_comment_file',
          id: commentId,
          files: files,
        );
        _resolvedKataCommentFilesBucket ??= bucket;
        return uploadedUrls;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw Exception('Failed to upload kata comment files: $lastError');
    }
    return [];
  }

  // LIKES

  // Get likes for a kata
  Future<List<Like>> getKataLikes(int kataId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load kata likes: $e');
    }
  }

  // Get likes for a forum post
  Future<List<Like>> getForumPostLikes(int forumPostId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load forum post likes: $e');
    }
  }

  // Toggle like for a kata (offline-first)
  Future<bool> toggleKataLike(int kataId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('🔄 Toggling like for kata $kataId');

    final operationId = _uuid.v4();

    // Create offline operation
    final operation = OfflineOperation(
      id: operationId,
      type: OfflineOperationType.toggleKataLike,
      status: OfflineOperationStatus.pending,
      data: {
        'kata_id': kataId,
      },
      createdAt: DateTime.now(),
      userId: user.id,
    );

    // Add to offline queue
    if (_offlineQueueService != null) {
      await _offlineQueueService!.addOperation(operation);
    }

    try {
      // Try to execute immediately
      final result = await executeToggleKataLike(kataId, user.id);
      debugPrint('✅ Kata like toggled successfully: $result');

      // Update cache if available
      if (_commentCacheService != null) {
        await _updateKataLikeCache(kataId, result);
      }

      // Mark operation as completed
      if (_offlineQueueService != null) {
        await _offlineQueueService!.removeOperation(operationId);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error toggling kata like: $e');
      // If offline, operation stays in queue for later retry
      // Update operation status
      if (_offlineQueueService != null) {
        await _offlineQueueService!.markOperationFailed(operationId, e.toString());
      }

      // For immediate UI feedback, try to update cache optimistically
      if (_commentCacheService != null) {
        await _optimisticUpdateKataLikeCache(kataId);
      }

      rethrow;
    }
  }

  // Toggle like for a forum post
  Future<bool> toggleForumPostLike(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already liked this forum post
      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike - remove the like
        await _client
            .from('likes')
            .delete()
            .eq('id', existingLike['id']);
        return false; // Not liked anymore
      } else {
        // Like - add the like
        await _client
            .from('likes')
            .insert({
              'user_id': user.id,
              'target_type': 'forum_post',
              'target_id': forumPostId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now liked
      }
    } catch (e) {
      throw Exception('Failed to toggle forum post like: $e');
    }
  }

  // Check if user liked a kata
  Future<bool> isKataLiked(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // Check if user liked a forum post
  Future<bool> isForumPostLiked(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // FAVORITES

  // Get favorites for a kata
  Future<List<Favorite>> getKataFavorites(int kataId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load kata favorites: $e');
    }
  }

  // Get favorites for a forum post
  Future<List<Favorite>> getForumPostFavorites(int forumPostId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load forum post favorites: $e');
    }
  }

  // Toggle favorite for a kata
  Future<bool> toggleKataFavorite(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already favorited this kata
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite - remove the favorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false; // Not favorited anymore
      } else {
        // Favorite - add the favorite
        await _client
            .from('favorites')
            .insert({
              'user_id': user.id,
              'target_type': 'kata',
              'target_id': kataId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now favorited
      }
    } catch (e) {
      throw Exception('Failed to toggle kata favorite: $e');
    }
  }

  // Toggle favorite for a forum post
  Future<bool> toggleForumPostFavorite(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if user already favorited this forum post
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite - remove the favorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false; // Not favorited anymore
      } else {
        // Favorite - add the favorite
        await _client
            .from('favorites')
            .insert({
              'user_id': user.id,
              'target_type': 'forum_post',
              'target_id': forumPostId,
              'created_at': DateTime.now().toIso8601String(),
            });
        return true; // Now favorited
      }
    } catch (e) {
      throw Exception('Failed to toggle forum post favorite: $e');
    }
  }

  // Check if user favorited a kata
  Future<bool> isKataFavorited(int kataId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'kata')
          .eq('target_id', kataId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingFavorite != null;
    } catch (e) {
      return false;
    }
  }

  // Check if user favorited a forum post
  Future<bool> isForumPostFavorited(int forumPostId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('target_type', 'forum_post')
          .eq('target_id', forumPostId)
          .eq('user_id', user.id)
          .maybeSingle();

      return existingFavorite != null;
    } catch (e) {
      return false;
    }
  }

  // Get user's favorite katas
  Future<List<int>> getUserFavoriteKatas() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'kata');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get user's favorite forum posts
  Future<List<int>> getUserFavoriteForumPosts() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'forum_post');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // OHYO COMMENTS

  // Get comments for a specific ohyo with pagination
  Future<List<OhyoComment>> getOhyoCommentsPaginated({
    required int ohyoId,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('ohyo_comments')
          .select('*')
          .eq('ohyo_id', ohyoId)
          .order('created_at', ascending: true)
          .range(offset, offset + limit - 1)
          .timeout(const Duration(seconds: 10), onTimeout: () => throw TimeoutException('Connection timeout - server not responding'));

      final bucket = await _tryResolveOhyoCommentImagesBucket();
      final comments = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((comment) async {
          final parsed = OhyoComment.fromJson(comment);
          final imageUrls = await _ensureSignedUrlsWithCandidates(
            parsed.imageUrls,
            bucket == null
                ? _ohyoCommentImagesBucketCandidates
                : <String>[bucket],
          );
          final filesBucket = await _tryResolveOhyoCommentFilesBucket();
          final fileUrls = await _ensureSignedUrlsWithCandidates(
            parsed.fileUrls,
            filesBucket == null
                ? _ohyoCommentFilesBucketCandidates
                : <String>[filesBucket],
          );
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

      return comments;
    } catch (e) {
      throw Exception('Failed to load ohyo comments: $e');
    }
  }

  // Get comments for a specific ohyo (legacy method - loads all)
  Future<List<OhyoComment>> getOhyoComments(int ohyoId) async {
    try {
      final response = await _client
          .from('ohyo_comments')
          .select('*')
          .eq('ohyo_id', ohyoId)
          .order('created_at', ascending: true);

      final bucket = await _tryResolveOhyoCommentImagesBucket();
      final comments = await Future.wait(
        List<Map<String, dynamic>>.from(response).map((comment) async {
          final parsed = OhyoComment.fromJson(comment);
          final imageUrls = await _ensureSignedUrlsWithCandidates(
            parsed.imageUrls,
            bucket == null
                ? _ohyoCommentImagesBucketCandidates
                : <String>[bucket],
          );
          final filesBucket = await _tryResolveOhyoCommentFilesBucket();
          final fileUrls = await _ensureSignedUrlsWithCandidates(
            parsed.fileUrls,
            filesBucket == null
                ? _ohyoCommentFilesBucketCandidates
                : <String>[filesBucket],
          );
          return parsed.copyWith(imageUrls: imageUrls, fileUrls: fileUrls);
        }),
      );

      return comments;
    } catch (e) {
      throw Exception('Failed to load ohyo comments: $e');
    }
  }

  // Add a comment to an ohyo
  Future<OhyoComment> addOhyoComment({
    required int ohyoId,
    required String content,
    int? parentCommentId,
    List<String> imageUrls = const [],
    List<String> fileUrls = const [],
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final userAvatar = _getUserAvatarFromMetadata(user.userMetadata);

      final commentData = {
        'ohyo_id': ohyoId,
        'content': content,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': userAvatar,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        if (parentCommentId != null) 'parent_comment_id': parentCommentId,
        if (imageUrls.isNotEmpty) 'image_urls': imageUrls,
        if (fileUrls.isNotEmpty) 'file_urls': fileUrls,
      };

      final response = await _client
          .from('ohyo_comments')
          .insert(commentData)
          .select()
          .single();

      return OhyoComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add ohyo comment: $e');
    }
  }

  // Update an ohyo comment
  Future<OhyoComment> updateOhyoComment({
    required int commentId,
    required String content,
    List<String>? imageUrls,
    List<String>? fileUrls,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get comment details and check permissions
      final existingComment = await _client
          .from('ohyo_comments')
          .select('author_id, ohyo_id')
          .eq('id', commentId)
          .single();

      // Check if user is the comment author
      bool canEdit = existingComment['author_id'] == user.id;

      // If not the author, check if user is a mediator or host using RoleService
      if (!canEdit) {
        try {
          final userRole = await _roleService.getCurrentUserRole();
          canEdit = userRole == UserRole.mediator || userRole == UserRole.host;
        } catch (e) {
          // If role check fails, fall back to author-only permission
          canEdit = false;
        }
      }

      if (!canEdit) {
        throw Exception('You do not have permission to edit this comment');
      }

      final Map<String, dynamic> updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      if (fileUrls != null) {
        updateData['file_urls'] = fileUrls;
      }

      final response = await _client
          .from('ohyo_comments')
          .update(updateData)
          .eq('id', commentId)
          .select()
          .single();

      return OhyoComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update ohyo comment: $e');
    }
  }

  // Delete an ohyo comment
  Future<void> deleteOhyoComment(int commentId) async {
    try {
      final existingComment = await _client
          .from('ohyo_comments')
          .select('image_urls, file_urls')
          .eq('id', commentId)
          .maybeSingle();

      await _client
          .from('ohyo_comments')
          .delete()
          .eq('id', commentId);

      final imageUrls =
          (existingComment?['image_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
      final fileUrls =
          (existingComment?['file_urls'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const <String>[];
      await _deleteCommentImages(await _resolveOhyoCommentImagesBucket(), imageUrls);
      await _deleteCommentFiles(await _resolveOhyoCommentFilesBucket(), fileUrls);
    } catch (e) {
      throw Exception('Failed to delete ohyo comment: $e');
    }
  }

  Future<List<String>> uploadOhyoCommentImages({
    required int commentId,
    required List<File> imageFiles,
  }) async {
    final bucketsToTry = <String>{
      if (_resolvedOhyoCommentImagesBucket != null)
        _resolvedOhyoCommentImagesBucket!,
      ..._ohyoCommentImagesBucketCandidates,
    }.toList();
    Object? lastError;

    for (final bucket in bucketsToTry) {
      try {
        final uploadedUrls = await _uploadCommentImages(
          bucket: bucket,
          folder: 'comments/$commentId',
          prefix: 'ohyo_comment',
          id: commentId,
          imageFiles: imageFiles,
        );
        _resolvedOhyoCommentImagesBucket ??= bucket;
        return uploadedUrls;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw Exception('Failed to upload ohyo comment images: $lastError');
    }
    return [];
  }

  Future<List<String>> uploadOhyoCommentFiles({
    required int commentId,
    required List<File> files,
  }) async {
    final bucketsToTry = <String>{
      if (_resolvedOhyoCommentFilesBucket != null)
        _resolvedOhyoCommentFilesBucket!,
      ..._ohyoCommentFilesBucketCandidates,
    }.toList();
    Object? lastError;

    for (final bucket in bucketsToTry) {
      try {
        final uploadedUrls = await _uploadCommentFiles(
          bucket: bucket,
          folder: 'comments/$commentId',
          prefix: 'ohyo_comment_file',
          id: commentId,
          files: files,
        );
        _resolvedOhyoCommentFilesBucket ??= bucket;
        return uploadedUrls;
      } catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) {
      throw Exception('Failed to upload ohyo comment files: $lastError');
    }
    return [];
  }

  // OHYO LIKES

  // Get likes for a specific ohyo
  Future<List<Like>> getOhyoLikes(int ohyoId) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ohyo likes: $e');
    }
  }

  // Check if current user liked an ohyo
  Future<bool> isOhyoLiked(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('likes')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle like on an ohyo (offline-first)
  Future<bool> toggleOhyoLike(int ohyoId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('🔄 Toggling like for ohyo $ohyoId');

    final operationId = _uuid.v4();

    // Create offline operation
    final operation = OfflineOperation(
      id: operationId,
      type: OfflineOperationType.toggleOhyoLike,
      status: OfflineOperationStatus.pending,
      data: {
        'ohyo_id': ohyoId,
      },
      createdAt: DateTime.now(),
      userId: user.id,
    );

    // Add to offline queue
    if (_offlineQueueService != null) {
      await _offlineQueueService!.addOperation(operation);
    }

    try {
      // Try to execute immediately
      final result = await executeToggleOhyoLike(ohyoId, user.id);
      debugPrint('✅ Ohyo like toggled successfully: $result');

      // Update cache if available
      if (_commentCacheService != null) {
        await _updateOhyoLikeCache(ohyoId, result);
      }

      // Mark operation as completed
      if (_offlineQueueService != null) {
        await _offlineQueueService!.removeOperation(operationId);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error toggling ohyo like: $e');
      // If offline, operation stays in queue for later retry
      // Update operation status
      if (_offlineQueueService != null) {
        await _offlineQueueService!.markOperationFailed(operationId, e.toString());
      }

      // For immediate UI feedback, try to update cache optimistically
      if (_commentCacheService != null) {
        await _optimisticUpdateOhyoLikeCache(ohyoId);
      }

      rethrow;
    }
  }

  // OHYO FAVORITES

  // Get favorites for a specific ohyo
  Future<List<Favorite>> getOhyoFavorites(int ohyoId) async {
    try {
      final response = await _client
          .from('favorites')
          .select('*')
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => Favorite.fromJson(favorite))
          .toList();
    } catch (e) {
      throw Exception('Failed to load ohyo favorites: $e');
    }
  }

  // Check if current user favorited an ohyo
  Future<bool> isOhyoFavorited(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite on an ohyo
  Future<bool> toggleOhyoFavorite(int ohyoId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Check if already favorited
      final existingFavorite = await _client
          .from('favorites')
          .select('id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo')
          .eq('target_id', ohyoId)
          .maybeSingle();

      if (existingFavorite != null) {
        // Unfavorite
        await _client
            .from('favorites')
            .delete()
            .eq('id', existingFavorite['id']);
        return false;
      } else {
        // Favorite
        final favoriteData = {
          'user_id': user.id,
          'target_type': 'ohyo',
          'target_id': ohyoId,
          'created_at': DateTime.now().toIso8601String(),
        };

        await _client
            .from('favorites')
            .insert(favoriteData);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle ohyo favorite: $e');
    }
  }

  // Get user's favorite ohyos
  Future<List<int>> getUserFavoriteOhyos() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('favorites')
          .select('target_id')
          .eq('user_id', user.id)
          .eq('target_type', 'ohyo');

      return List<Map<String, dynamic>>.from(response)
          .map((favorite) => favorite['target_id'] as int)
          .toList();
    } catch (e) {
      return [];
    }
  }

  // COMMENT LIKES

  // Get likes for a specific comment
  Future<List<Like>> getCommentLikes(int commentId, String commentType) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('is_dislike', false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((like) => Like.fromJson(like))
          .toList();
    } catch (e) {
      throw Exception('Failed to load comment likes: $e');
    }
  }

  Future<List<Like>> getCommentDislikes(int commentId, String commentType) async {
    try {
      final response = await _client
          .from('likes')
          .select('*')
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('is_dislike', true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response)
          .map((dislike) => Like.fromJson(dislike))
          .toList();
    } catch (e) {
      throw Exception('Failed to load comment dislikes: $e');
    }
  }

  // Check if current user liked a comment
  Future<bool> isCommentLiked(int commentId, String commentType) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingLike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('user_id', user.id)
          .eq('is_dislike', false)
          .maybeSingle();

      return existingLike != null;
    } catch (e) {
      return false;
    }
  }

  // Check if current user disliked a comment
  Future<bool> isCommentDisliked(int commentId, String commentType) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final existingDislike = await _client
          .from('likes')
          .select('id')
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('user_id', user.id)
          .eq('is_dislike', true)
          .maybeSingle();

      return existingDislike != null;
    } catch (e) {
      return false;
    }
  }

  // Toggle like on a comment (offline-first)
  Future<bool> toggleCommentLike(int commentId, String commentType) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    debugPrint('🔄 Toggling like for comment $commentId of type $commentType');

    final operationId = _uuid.v4();

    // Create offline operation
    final operation = OfflineOperation(
      id: operationId,
      type: OfflineOperationType.toggleLike,
      status: OfflineOperationStatus.pending,
      data: {
        'comment_id': commentId,
        'comment_type': commentType,
      },
      createdAt: DateTime.now(),
      userId: user.id,
    );

    // Add to offline queue
    if (_offlineQueueService != null) {
      await _offlineQueueService!.addOperation(operation);
    }

    try {
      // Try to execute immediately
      final result = await executeToggleCommentLike(commentId, commentType, user.id);
      debugPrint('✅ Like toggled successfully: $result');

      // Update cache if available
      if (_commentCacheService != null) {
        await _updateCommentLikeCache(commentId, commentType, result);
      }

      // Mark operation as completed
      if (_offlineQueueService != null) {
        await _offlineQueueService!.removeOperation(operationId);
      }

      return result;
    } catch (e) {
      debugPrint('❌ Error toggling like: $e');
      // If offline, operation stays in queue for later retry
      // Update operation status
      if (_offlineQueueService != null) {
        await _offlineQueueService!.markOperationFailed(operationId, e.toString());
      }

      // For immediate UI feedback, try to update cache optimistically
      if (_commentCacheService != null) {
        await _optimisticUpdateCommentLikeCache(commentId, commentType);
      }

      rethrow;
    }
  }

  Future<bool> toggleCommentDislike(int commentId, String commentType) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final operationId = _uuid.v4();

    // Create offline operation
    final operation = OfflineOperation(
      id: operationId,
      type: OfflineOperationType.toggleDislike,
      status: OfflineOperationStatus.pending,
      data: {
        'comment_id': commentId,
        'comment_type': commentType,
      },
      createdAt: DateTime.now(),
      userId: user.id,
    );

    // Add to offline queue
    if (_offlineQueueService != null) {
      await _offlineQueueService!.addOperation(operation);
    }

    try {
      // Try to execute immediately
      final result = await executeToggleCommentDislike(commentId, commentType, user.id);

      // Update cache if available
      if (_commentCacheService != null) {
        await _updateCommentDislikeCache(commentId, commentType, result);
      }

      // Mark operation as completed
      if (_offlineQueueService != null) {
        await _offlineQueueService!.removeOperation(operationId);
      }

      return result;
    } catch (e) {
      // If offline, operation stays in queue for later retry
      // Update operation status
      if (_offlineQueueService != null) {
        await _offlineQueueService!.markOperationFailed(operationId, e.toString());
      }

      // For immediate UI feedback, try to update cache optimistically
      if (_commentCacheService != null) {
        await _optimisticUpdateCommentDislikeCache(commentId, commentType);
      }

      rethrow;
    }
  }

  // Helper method to execute toggle like
  Future<bool> executeToggleCommentLike(int commentId, String commentType, String userId) async {
    debugPrint('🔍 Checking existing like for comment $commentId of type $commentType');

    // Check if already liked (not disliked)
    final existingLike = await _client
        .from('likes')
        .select('id')
        .eq('target_type', commentType)
        .eq('target_id', commentId)
        .eq('user_id', userId)
        .eq('is_dislike', false)
        .maybeSingle();

    if (existingLike != null) {
      debugPrint('👍 Unlike: removing existing like');
      // Unlike - remove the like
      await _client
          .from('likes')
          .delete()
          .eq('id', existingLike['id']);
      return false; // Not liked anymore
    } else {
      debugPrint('❤️ Like: adding new like');
      // Remove any existing dislike first
      await _client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('is_dislike', true);

      // Like - add the like
      final user = _client.auth.currentUser!;
      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final likeData = {
        'user_id': userId,
        'user_name': userName,
        'target_type': commentType,
        'target_id': commentId,
        'is_dislike': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('likes')
          .insert(likeData);
      return true; // Now liked
    }
  }

  // Helper method to execute toggle dislike
  Future<bool> executeToggleCommentDislike(int commentId, String commentType, String userId) async {
    // Check if already disliked
    final existingDislike = await _client
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('target_type', commentType)
        .eq('target_id', commentId)
        .eq('is_dislike', true)
        .maybeSingle();

    if (existingDislike != null) {
      // Remove dislike
      await _client
          .from('likes')
          .delete()
          .eq('id', existingDislike['id']);
      return false; // Not disliked anymore
    } else {
      // Remove any existing like first
      await _client
          .from('likes')
          .delete()
          .eq('user_id', userId)
          .eq('target_type', commentType)
          .eq('target_id', commentId)
          .eq('is_dislike', false);

      // Dislike - add the dislike
      final user = _client.auth.currentUser!;
      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final dislikeData = {
        'user_id': userId,
        'user_name': userName,
        'target_type': commentType,
        'target_id': commentId,
        'is_dislike': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('likes')
          .insert(dislikeData);
      return true; // Now disliked
    }
  }

  // Update comment like cache
  Future<void> _updateCommentLikeCache(int commentId, String commentType, bool isLiked) async {
    if (_commentCacheService == null) return;

    final existingState = await _commentCacheService!.getCachedCommentState(commentId, commentType);
    if (existingState != null) {
      await _commentCacheService!.updateCachedLikeState(
        commentId,
        commentType,
        isLiked: isLiked,
        isDisliked: false, // When liking, ensure disliked is false
        likeCount: existingState.likeCount + (isLiked ? 1 : -1),
        dislikeCount: existingState.isDisliked ? existingState.dislikeCount - 1 : existingState.dislikeCount,
      );
    }
  }

  // Update comment dislike cache
  Future<void> _updateCommentDislikeCache(int commentId, String commentType, bool isDisliked) async {
    if (_commentCacheService == null) return;

    final existingState = await _commentCacheService!.getCachedCommentState(commentId, commentType);
    if (existingState != null) {
      await _commentCacheService!.updateCachedLikeState(
        commentId,
        commentType,
        isLiked: false, // When disliking, ensure liked is false
        isDisliked: isDisliked,
        likeCount: existingState.isLiked ? existingState.likeCount - 1 : existingState.likeCount,
        dislikeCount: existingState.dislikeCount + (isDisliked ? 1 : -1),
      );
    }
  }

  // Optimistic cache updates for offline scenarios
  Future<void> _optimisticUpdateCommentLikeCache(int commentId, String commentType) async {
    if (_commentCacheService == null) return;

    final existingState = await _commentCacheService!.getCachedCommentState(commentId, commentType);
    if (existingState != null) {
      final newIsLiked = !existingState.isLiked;
      await _commentCacheService!.updateCachedLikeState(
        commentId,
        commentType,
        isLiked: newIsLiked,
        isDisliked: false,
        likeCount: existingState.likeCount + (newIsLiked ? 1 : -1),
        dislikeCount: existingState.isDisliked ? existingState.dislikeCount - 1 : existingState.dislikeCount,
      );
    }
  }

  Future<void> _optimisticUpdateCommentDislikeCache(int commentId, String commentType) async {
    if (_commentCacheService == null) return;

    final existingState = await _commentCacheService!.getCachedCommentState(commentId, commentType);
    if (existingState != null) {
      final newIsDisliked = !existingState.isDisliked;
      await _commentCacheService!.updateCachedLikeState(
        commentId,
        commentType,
        isLiked: false,
        isDisliked: newIsDisliked,
        likeCount: existingState.isLiked ? existingState.likeCount - 1 : existingState.likeCount,
        dislikeCount: existingState.dislikeCount + (newIsDisliked ? 1 : -1),
      );
    }
  }

  // Helper method to execute toggle kata like
  Future<bool> executeToggleKataLike(int kataId, String userId) async {
    debugPrint('🔍 Checking existing like for kata $kataId');

    // Check if already liked
    final existingLike = await _client
        .from('likes')
        .select('id')
        .eq('target_type', 'kata')
        .eq('target_id', kataId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingLike != null) {
      debugPrint('👍 Unlike: removing existing like');
      // Unlike - remove the like
      await _client
          .from('likes')
          .delete()
          .eq('id', existingLike['id']);
      return false; // Not liked anymore
    } else {
      debugPrint('❤️ Like: adding new like');
      // Like - add the like
      final user = _client.auth.currentUser!;
      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final likeData = {
        'user_id': userId,
        'user_name': userName,
        'target_type': 'kata',
        'target_id': kataId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('likes')
          .insert(likeData);
      return true; // Now liked
    }
  }

  // Update kata like cache
  Future<void> _updateKataLikeCache(int kataId, bool isLiked) async {
    // For kata likes, we need to update the local storage
    // This would typically be handled by the provider when syncing
    debugPrint('Kata like cache update: kata $kataId, liked: $isLiked');
  }

  // Optimistic cache update for kata likes
  Future<void> _optimisticUpdateKataLikeCache(int kataId) async {
    // For optimistic updates, we'd update the local state immediately
    debugPrint('Optimistic kata like cache update: kata $kataId');
  }

  // Execute toggle ohyo like (actual server operation)
  Future<bool> executeToggleOhyoLike(int ohyoId, String userId) async {
    debugPrint('🔍 Checking existing like for ohyo $ohyoId');

    // Check if already liked
    final existingLike = await _client
        .from('likes')
        .select('id')
        .eq('target_type', 'ohyo')
        .eq('target_id', ohyoId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingLike != null) {
      debugPrint('👍 Unlike: removing existing like');
      // Unlike - remove the like
      await _client
          .from('likes')
          .delete()
          .eq('id', existingLike['id']);
      return false; // Not liked anymore
    } else {
      debugPrint('❤️ Like: adding new like');
      // Like - add the like
      final user = _client.auth.currentUser!;
      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final likeData = {
        'user_id': userId,
        'user_name': userName,
        'target_type': 'ohyo',
        'target_id': ohyoId,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client
          .from('likes')
          .insert(likeData);
      return true; // Now liked
    }
  }

  // Update ohyo like cache
  Future<void> _updateOhyoLikeCache(int ohyoId, bool isLiked) async {
    // For ohyo likes, we need to update the local storage
    // This would typically be handled by the provider when syncing
    debugPrint('Ohyo like cache update: ohyo $ohyoId, liked: $isLiked');
  }

  // Optimistic cache update for ohyo likes
  Future<void> _optimisticUpdateOhyoLikeCache(int ohyoId) async {
    // For optimistic updates, we'd update the local state immediately
    debugPrint('Optimistic ohyo like cache update: ohyo $ohyoId');
  }

  // FORUM COMMENTS

  Future<ForumComment> addForumComment({
    required int postId,
    required String content,
    int? parentCommentId,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userName = user.userMetadata?['full_name'] ?? user.email ?? 'Anonymous';
      final avatarUrl = _getUserAvatarFromMetadata(user.userMetadata);

      final commentData = {
        'post_id': postId,
        'content': content,
        'author_id': user.id,
        'author_name': userName,
        'author_avatar': avatarUrl,
        'parent_comment_id': parentCommentId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _client
          .from('forum_comments')
          .insert(commentData)
          .select()
          .single();

      return ForumComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add forum comment: $e');
    }
  }

  Future<ForumComment> updateForumComment({
    required int commentId,
    required String content,
    List<String>? imageUrls,
    List<String>? fileUrls,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final Map<String, dynamic> updateData = {
        'content': content,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (imageUrls != null) {
        updateData['image_urls'] = imageUrls;
      }
      if (fileUrls != null) {
        updateData['file_urls'] = fileUrls;
      }

      final response = await _client
          .from('forum_comments')
          .update(updateData)
          .eq('id', commentId)
          .eq('author_id', user.id) // Ensure user can only update their own comments
          .select()
          .single();

      return ForumComment.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update forum comment: $e');
    }
  }

  Future<void> deleteForumComment(int commentId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      await _client
          .from('forum_comments')
          .delete()
          .eq('id', commentId)
          .eq('author_id', user.id); // Ensure user can only delete their own comments
    } catch (e) {
      throw Exception('Failed to delete forum comment: $e');
    }
  }
}
