import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/interaction_models.dart';

/// Service for managing offline operations queue
class OfflineQueueService {
  static const String _operationsKey = 'offline_operations';
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 30);

  final SharedPreferences _prefs;
  final StreamController<List<OfflineOperation>> _operationsController =
      StreamController<List<OfflineOperation>>.broadcast();

  OfflineQueueService(this._prefs) {
    _initializeOperations();
  }

  Stream<List<OfflineOperation>> get operationsStream =>
      _operationsController.stream;

  /// Initialize operations from storage
  Future<void> _initializeOperations() async {
    final operations = await _loadOperations();
    _operationsController.add(operations);
  }

  /// Add an operation to the queue
  Future<void> addOperation(OfflineOperation operation) async {
    final operations = await _loadOperations();
    operations.add(operation);

    await _saveOperations(operations);
    _operationsController.add(operations);

    debugPrint('Added offline operation: ${operation.type} for user ${operation.userId}');
  }

  /// Remove a completed operation
  Future<void> removeOperation(String operationId) async {
    final operations = await _loadOperations();
    operations.removeWhere((op) => op.id == operationId);

    await _saveOperations(operations);
    _operationsController.add(operations);
  }

  /// Update an operation's status
  Future<void> updateOperation(String operationId, {
    OfflineOperationStatus? status,
    DateTime? processedAt,
    int? retryCount,
    String? error,
  }) async {
    final operations = await _loadOperations();
    final index = operations.indexWhere((op) => op.id == operationId);

    if (index != -1) {
      operations[index] = operations[index].copyWith(
        status: status,
        processedAt: processedAt,
        retryCount: retryCount,
        error: error,
      );

      await _saveOperations(operations);
      _operationsController.add(operations);
    }
  }

  /// Get operations for a specific user
  Future<List<OfflineOperation>> getOperationsForUser(String userId) async {
    final operations = await _loadOperations();
    return operations.where((op) => op.userId == userId).toList();
  }

  /// Get pending operations (not completed or failed)
  Future<List<OfflineOperation>> getPendingOperations() async {
    final operations = await _loadOperations();
    return operations.where((op) =>
      op.status == OfflineOperationStatus.pending ||
      op.status == OfflineOperationStatus.processing
    ).toList();
  }

  /// Get failed operations that can be retried
  Future<List<OfflineOperation>> getRetryableOperations() async {
    final operations = await _loadOperations();
    return operations.where((op) =>
      op.status == OfflineOperationStatus.failed &&
      op.retryCount < _maxRetries
    ).toList();
  }

  /// Mark operation as failed with retry
  Future<void> markOperationFailed(String operationId, String error) async {
    final operations = await _loadOperations();
    final index = operations.indexWhere((op) => op.id == operationId);

    if (index != -1) {
      final operation = operations[index];
      final newRetryCount = operation.retryCount + 1;
      final newStatus = newRetryCount >= _maxRetries
          ? OfflineOperationStatus.failed
          : OfflineOperationStatus.pending;

      operations[index] = operation.copyWith(
        status: newStatus,
        retryCount: newRetryCount,
        error: error,
      );

      await _saveOperations(operations);
      _operationsController.add(operations);

      debugPrint('Operation $operationId failed ($newRetryCount/$_maxRetries): $error');
    }
  }

  /// Clear all operations for a user (e.g., when logging out)
  Future<void> clearOperationsForUser(String userId) async {
    final operations = await _loadOperations();
    operations.removeWhere((op) => op.userId == userId);

    await _saveOperations(operations);
    _operationsController.add(operations);
  }

  /// Clear old completed operations (older than specified days)
  Future<void> clearOldOperations({int daysOld = 7}) async {
    final operations = await _loadOperations();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    operations.removeWhere((op) =>
      op.status == OfflineOperationStatus.completed &&
      op.processedAt != null &&
      op.processedAt!.isBefore(cutoffDate)
    );

    await _saveOperations(operations);
    _operationsController.add(operations);
  }

  /// Get retry delay for an operation based on retry count
  Duration getRetryDelay(int retryCount) {
    // Exponential backoff: 30s, 1m, 2m, 4m, 8m
    return Duration(seconds: _baseRetryDelay.inSeconds * (1 << retryCount));
  }

  /// Load operations from storage
  Future<List<OfflineOperation>> _loadOperations() async {
    final operationsJson = _prefs.getStringList(_operationsKey) ?? [];

    return operationsJson.map((json) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        return OfflineOperation.fromJson(map);
      } catch (e) {
        debugPrint('Error parsing offline operation: $e');
        return null;
      }
    }).whereType<OfflineOperation>().toList();
  }

  /// Save operations to storage
  Future<void> _saveOperations(List<OfflineOperation> operations) async {
    final operationsJson = operations.map((op) => jsonEncode(op.toJson())).toList();
    await _prefs.setStringList(_operationsKey, operationsJson);
  }

  /// Get statistics about operations
  Future<Map<String, int>> getOperationsStats() async {
    final operations = await _loadOperations();

    return {
      'total': operations.length,
      'pending': operations.where((op) => op.status == OfflineOperationStatus.pending).length,
      'processing': operations.where((op) => op.status == OfflineOperationStatus.processing).length,
      'completed': operations.where((op) => op.status == OfflineOperationStatus.completed).length,
      'failed': operations.where((op) => op.status == OfflineOperationStatus.failed).length,
    };
  }

  void dispose() {
    _operationsController.close();
  }
}
