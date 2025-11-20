import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interaction_models.dart';

/// Service for handling conflict resolution in comment operations
class ConflictResolutionService {
  static const String _conflictsKey = 'comment_conflicts';
  final SharedPreferences _prefs;
  final StreamController<List<CommentConflict>> _conflictsController =
      StreamController<List<CommentConflict>>.broadcast();

  ConflictResolutionService(this._prefs) {
    _initializeConflicts();
  }

  Stream<List<CommentConflict>> get conflictsStream =>
      _conflictsController.stream;

  /// Initialize conflicts from storage
  Future<void> _initializeConflicts() async {
    final conflicts = await _loadConflicts();
    _conflictsController.add(conflicts);
  }

  /// Detect conflicts between local and server data
  Future<CommentConflict?> detectConflict({
    required String commentType,
    required int commentId,
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
    required String? userId,
  }) async {
    ConflictType? conflictType;

    // Check for version mismatch
    final localVersion = localData['version'] as int? ?? 1;
    final serverVersion = serverData['version'] as int? ?? 1;

    if (localVersion != serverVersion) {
      // Check if content was modified
      final localContent = localData['content'] as String?;
      final serverContent = serverData['content'] as String?;

      if (localContent != null && serverContent != null && localContent != serverContent) {
        conflictType = ConflictType.concurrentEdit;
      } else {
        conflictType = ConflictType.versionMismatch;
      }
    }

    // Check for deletion conflicts
    final serverDeleted = serverData['deleted'] as bool? ?? false;
    if (serverDeleted && localData.containsKey('content')) {
      conflictType = ConflictType.deletedByAnother;
    }

    // Check for like/dislike conflicts
    if (localData.containsKey('is_liked') || localData.containsKey('is_disliked')) {
      conflictType = await _detectLikeDislikeConflict(commentType, commentId, localData, serverData, userId);
    }

    if (conflictType != null) {
      final conflict = CommentConflict(
        id: '${commentType}_${commentId}_${DateTime.now().millisecondsSinceEpoch}',
        type: conflictType,
        commentType: commentType,
        commentId: commentId,
        localData: localData,
        serverData: serverData,
        detectedAt: DateTime.now(),
        userId: userId,
      );

      await _saveConflict(conflict);
      return conflict;
    }

    return null;
  }

  /// Detect like/dislike conflicts
  Future<ConflictType?> _detectLikeDislikeConflict(
    String commentType,
    int commentId,
    Map<String, dynamic> localData,
    Map<String, dynamic> serverData,
    String? userId,
  ) async {
    if (userId == null) return null;

    try {
      // Get the user's current like/dislike status from server
      final userLikeStatus = await _getUserLikeStatus(commentType, commentId, userId);

      final localIsLiked = localData['is_liked'] as bool? ?? false;
      final localIsDisliked = localData['is_disliked'] as bool? ?? false;
      final serverIsLiked = userLikeStatus['is_liked'] as bool? ?? false;
      final serverIsDisliked = userLikeStatus['is_disliked'] as bool? ?? false;

      // Check for conflicting actions
      if ((localIsLiked && serverIsLiked) || (localIsDisliked && serverIsDisliked)) {
        return ConflictType.likeDislikeConflict; // Already liked/disliked
      }

      // Check for simultaneous like and dislike attempt
      if (localIsLiked && localIsDisliked) {
        return ConflictType.likeDislikeConflict; // Invalid state
      }

      return null; // No conflict
    } catch (e) {
      debugPrint('Error detecting like/dislike conflict: $e');
      return ConflictType.likeDislikeConflict; // Assume conflict on error
    }
  }

  /// Get user's current like/dislike status for a comment
  Future<Map<String, dynamic>> _getUserLikeStatus(String commentType, int commentId, String userId) async {
    // This would need to be implemented to query the server for user's like status
    // For now, return empty status (will be handled by the caller)
    return {'is_liked': false, 'is_disliked': false};
  }

  /// Resolve a conflict with the specified resolution strategy
  Future<void> resolveConflict(String conflictId, ConflictResolution resolution) async {
    final conflicts = await _loadConflicts();
    final index = conflicts.indexWhere((c) => c.id == conflictId);

    if (index != -1) {
      final resolvedConflict = conflicts[index].copyWith(
        resolution: resolution,
        resolved: true,
      );

      conflicts[index] = resolvedConflict;
      await _saveConflicts(conflicts);
      _conflictsController.add(conflicts);
    }
  }

  /// Apply conflict resolution to get the final data
  Map<String, dynamic> applyResolution(CommentConflict conflict) {
    if (!conflict.resolved || conflict.resolution == null) {
      return conflict.serverData; // Default to server data if not resolved
    }

    switch (conflict.resolution!) {
      case ConflictResolution.keepLocal:
        return conflict.localData;

      case ConflictResolution.keepServer:
        return conflict.serverData;

      case ConflictResolution.merge:
        // For like/dislike conflicts, merge is not applicable - use server state
        if (conflict.type == ConflictType.likeDislikeConflict) {
          return conflict.serverData;
        }
        return _mergeCommentData(conflict.localData, conflict.serverData);

      case ConflictResolution.discard:
        return conflict.serverData; // Discard local changes
    }
  }

  /// Merge comment data intelligently
  Map<String, dynamic> _mergeCommentData(
    Map<String, dynamic> local,
    Map<String, dynamic> server,
  ) {
    final merged = Map<String, dynamic>.from(server);

    // For comment edits, prefer local content but keep server metadata
    if (local.containsKey('content')) {
      merged['content'] = local['content'];
      merged['updated_at'] = DateTime.now().toIso8601String();
    }

    // Use the higher version number
    final localVersion = local['version'] as int? ?? 1;
    final serverVersion = server['version'] as int? ?? 1;
    merged['version'] = localVersion > serverVersion ? localVersion : serverVersion + 1;

    return merged;
  }

  /// Get unresolved conflicts for a specific comment
  Future<List<CommentConflict>> getUnresolvedConflictsForComment(
    String commentType,
    int commentId,
  ) async {
    final conflicts = await _loadConflicts();
    return conflicts
        .where((c) =>
            c.commentType == commentType &&
            c.commentId == commentId &&
            !c.resolved)
        .toList();
  }

  /// Get all unresolved conflicts
  Future<List<CommentConflict>> getUnresolvedConflicts() async {
    final conflicts = await _loadConflicts();
    return conflicts.where((c) => !c.resolved).toList();
  }

  /// Remove resolved conflicts older than specified days
  Future<void> cleanupResolvedConflicts({int daysOld = 7}) async {
    final conflicts = await _loadConflicts();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    conflicts.removeWhere((c) =>
        c.resolved &&
        c.detectedAt.isBefore(cutoffDate));

    await _saveConflicts(conflicts);
    _conflictsController.add(conflicts);
  }

  /// Save a new conflict
  Future<void> _saveConflict(CommentConflict conflict) async {
    final conflicts = await _loadConflicts();
    conflicts.add(conflict);
    await _saveConflicts(conflicts);
    _conflictsController.add(conflicts);
  }

  /// Load conflicts from storage
  Future<List<CommentConflict>> _loadConflicts() async {
    final conflictsJson = _prefs.getStringList(_conflictsKey) ?? [];

    return conflictsJson.map((json) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return CommentConflict.fromJson(map);
      } catch (e) {
        debugPrint('Error parsing conflict: $e');
        return null;
      }
    }).whereType<CommentConflict>().toList();
  }

  /// Save conflicts to storage
  Future<void> _saveConflicts(List<CommentConflict> conflicts) async {
    final conflictsJson = conflicts.map((c) => jsonEncode(c.toJson())).toList();
    await _prefs.setStringList(_conflictsKey, conflictsJson);
  }

  /// Get conflict statistics
  Future<Map<String, dynamic>> getConflictStats() async {
    final conflicts = await _loadConflicts();

    return {
      'total': conflicts.length,
      'resolved': conflicts.where((c) => c.resolved).length,
      'unresolved': conflicts.where((c) => !c.resolved).length,
      'by_type': {
        for (final type in ConflictType.values)
          type.name: conflicts.where((c) => c.type == type).length,
      },
    };
  }

  void dispose() {
    _conflictsController.close();
  }
}
