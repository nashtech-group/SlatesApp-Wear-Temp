import 'dart:async';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/data/models/sync/sync_result.dart';
import 'package:slates_app_wear/data/repositories/roster_repository/roster_provider.dart';
import 'offline_storage_service.dart';
import 'connectivity_service.dart';
import 'notification_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final OfflineStorageService _offlineStorage = OfflineStorageService();
  final ConnectivityService _connectivity = ConnectivityService();
  final NotificationService _notification = NotificationService();
  final RosterProvider _rosterProvider = RosterProvider();

  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Initialize sync service
  void initialize() {
    _connectivity.startMonitoring();
    _connectivitySubscription =
        _connectivity.connectivityStream.listen(_onConnectivityChanged);
    _startPeriodicSync();
  }

  /// Start automatic sync when connected
  void _onConnectivityChanged(bool isConnected) {
    if (isConnected && !_isSyncing) {
      _performSync();
    }
  }

  /// Start periodic sync checks
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (_connectivity.isConnected && !_isSyncing) {
        _performSync();
      }
    });
  }

  /// Manually trigger sync - returns standardized result
  Future<SyncResult> manualSync() async {
    if (_isSyncing) {
      return SyncResult.failure(
        message: 'Sync already in progress',
        metadata: const {'reason': 'sync_in_progress'},
      );
    }

    if (!_connectivity.isConnected) {
      return SyncResult.failure(
        message: 'No internet connection available',
        metadata: const {'reason': 'no_connectivity'},
      );
    }

    return await _performSync();
  }

  /// Core sync operation - single source of truth
  Future<SyncResult> _performSync() async {
    if (_isSyncing) {
      return SyncResult.failure(message: 'Sync already in progress');
    }

    _isSyncing = true;
    final stopwatch = Stopwatch()..start();
    
    try {
      log('Starting sync operation');

      final token = await AuthManager().getToken();
      if (token == null) {
        return SyncResult.failure(
          message: 'Authentication token not available',
          metadata: const {'reason': 'no_auth_token'},
        );
      }

      final pendingSubmissions = await _offlineStorage.getPendingSubmissions();

      if (pendingSubmissions.isEmpty) {
        await AuthManager().saveLastOnlineSync(DateTime.now());
        return SyncResult.success(
          message: 'No pending submissions to sync',
          successCount: 0,
          metadata: {'sync_duration_ms': stopwatch.elapsedMilliseconds},
        );
      }

      log('Syncing ${pendingSubmissions.length} pending submissions');

      int successCount = 0;
      int failureCount = 0;
      final List<String> errors = [];

      for (int i = 0; i < pendingSubmissions.length; i++) {
        final submission = pendingSubmissions[i];
        final submissionId = 'submission_${DateTime.now().millisecondsSinceEpoch}_$i';

        try {
          final response = await _rosterProvider.submitComprehensiveGuardDuty(
            requestData: submission,
            token: token,
          );

          // If successful, remove from pending
          await _offlineStorage.removePendingSubmission(submissionId);
          successCount++;

          log('Successfully synced submission ${i + 1}/${pendingSubmissions.length}');
        } catch (e) {
          log('Failed to sync submission ${i + 1}: $e');
          failureCount++;
          errors.add('Submission ${i + 1}: ${e.toString()}');

          // Update retry count
          await _offlineStorage.updateSubmissionRetryCount(submissionId, 1);
        }
      }

      // Update last sync time if any successful
      if (successCount > 0) {
        await AuthManager().saveLastOnlineSync(DateTime.now());
      }

      stopwatch.stop();

      final result = SyncResult(
        success: failureCount == 0,
        message: failureCount == 0 
            ? 'All submissions synced successfully'
            : '$successCount successful, $failureCount failed',
        successCount: successCount,
        failureCount: failureCount,
        errors: errors,
        metadata: {
          'sync_duration_ms': stopwatch.elapsedMilliseconds,
          'total_submissions': pendingSubmissions.length,
        },
      );

      log('Sync completed: ${result.toString()}');
      return result;

    } catch (e) {
      stopwatch.stop();
      log('Sync operation failed: $e');
      
      return SyncResult.failure(
        message: 'Sync operation failed: ${e.toString()}',
        errors: [e.toString()],
        metadata: {'sync_duration_ms': stopwatch.elapsedMilliseconds},
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// Force sync all pending data - delegates to core sync logic
  Future<SyncResult> forceSyncAll() async {
    log('Force sync all initiated');
    return await manualSync(); // DRY - reuse the manual sync logic
  }

  /// Check if sync is required based on time elapsed
  Future<bool> isSyncRequired() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();
      if (lastSync == null) return true;

      final daysSinceSync = DateTime.now().difference(lastSync).inDays;
      return daysSinceSync >= 5;
    } catch (e) {
      return true;
    }
  }

  /// Get days since last sync
  Future<int> getDaysSinceLastSync() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();
      if (lastSync == null) return 999;
      return DateTime.now().difference(lastSync).inDays;
    } catch (e) {
      return 999;
    }
  }

  /// Schedule sync reminder notifications
  Future<void> scheduleSyncReminders() async {
    final daysSinceSync = await getDaysSinceLastSync();

    if (daysSinceSync >= 5) {
      await _notification.showSyncRequiredNotification(daysSinceSync);
    }
  }

  /// Check sync status for UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    final pendingCount = await _offlineStorage.getPendingSubmissionsCount();
    final daysSinceSync = await getDaysSinceLastSync();
    final isRequired = await isSyncRequired();

    final unsyncedMovements = await _offlineStorage.getUnsyncedGuardMovements();
    final unsyncedChecks = await _offlineStorage.getUnsyncedPerimeterChecks();

    return {
      'pendingSubmissions': pendingCount,
      'unsyncedMovements': unsyncedMovements.length,
      'unsyncedPerimeterChecks': unsyncedChecks.length,
      'daysSinceLastSync': daysSinceSync,
      'isSyncRequired': isRequired,
      'isConnected': _connectivity.isConnected,
      'isSyncing': _isSyncing,
    };
  }

  /// Get detailed sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    final stats = await _offlineStorage.getStorageStatistics();
    final syncStatus = await getSyncStatus();

    return {
      ...stats,
      ...syncStatus,
      'lastSyncTime': await AuthManager().getLastOnlineSync(),
      'syncEnabled': true,
      'autoSyncEnabled': true,
    };
  }

  /// Enable/disable automatic sync
  void setAutoSyncEnabled(bool enabled) {
    if (enabled) {
      _startPeriodicSync();
    } else {
      _syncTimer?.cancel();
    }
  }

  /// Get sync history using OfflineStorageService
  Future<List<Map<String, dynamic>>> getSyncHistory({int? limit}) async {
    try {
      return await _offlineStorage.getSubmissionRecords(
        limit: limit,
        submissionType: 'comprehensive_guard_duty',
      );
    } catch (e) {
      log('Failed to get sync history: $e');
      return [];
    }
  }

  /// Clear sync history - properly handles both pending submissions and submission records
  Future<SyncResult> clearSyncHistory() async {
    try {
      log('Starting sync history cleanup');
      final stopwatch = Stopwatch()..start();

      // Use OfflineStorageService's comprehensive clear method
      final clearedCounts = await _offlineStorage.clearAllSyncData();

      stopwatch.stop();

      final totalCleared = clearedCounts['totalCleared'] ?? 0;
      final pendingCleared = clearedCounts['pendingSubmissions'] ?? 0;
      final recordsCleared = clearedCounts['submissionRecords'] ?? 0;
      
      log('Sync history cleared: $pendingCleared pending + $recordsCleared records = $totalCleared total');

      return SyncResult.success(
        message: 'Sync history cleared successfully',
        successCount: totalCleared,
        metadata: {
          'pending_cleared': pendingCleared,
          'records_cleared': recordsCleared,
          'total_cleared': totalCleared,
          'operation_duration_ms': stopwatch.elapsedMilliseconds,
        },
      );
    } catch (e) {
      log('Failed to clear sync history: $e');
      return SyncResult.failure(
        message: 'Failed to clear sync history: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Retry failed submissions
  Future<SyncResult> retryFailedSubmissions() async {
    if (!_connectivity.isConnected) {
      return SyncResult.failure(
        message: 'No internet connection for retry',
        metadata: const {'reason': 'no_connectivity'},
      );
    }

    log('Retrying failed submissions');
    return await _performSync();
  }

  /// Check network connectivity and sync if needed
  Future<void> checkAndSync() async {
    if (_connectivity.isConnected && !_isSyncing) {
      final isRequired = await isSyncRequired();
      if (isRequired) {
        await _performSync();
      }
    }
  }

  /// Get comprehensive sync report
  Future<Map<String, dynamic>> getSyncReport() async {
    try {
      final status = await getSyncStatus();
      final statistics = await getSyncStatistics();
      final history = await getSyncHistory(limit: 10); // Last 10 sync records
      
      return {
        'status': status,
        'statistics': statistics,
        'recentHistory': history,
        'generatedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      log('Failed to generate sync report: $e');
      return {
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Clean old sync data based on retention policies
  Future<SyncResult> cleanOldSyncData() async {
    try {
      log('Starting old sync data cleanup');
      final stopwatch = Stopwatch()..start();

      // Use OfflineStorageService's cleanOldData method
      await _offlineStorage.cleanOldData();

      stopwatch.stop();

      return SyncResult.success(
        message: 'Old sync data cleaned successfully',
        successCount: 1, // Indicates successful cleanup operation
        metadata: {
          'operation_duration_ms': stopwatch.elapsedMilliseconds,
          'operation_type': 'data_cleanup',
        },
      );
    } catch (e) {
      log('Failed to clean old sync data: $e');
      return SyncResult.failure(
        message: 'Failed to clean old sync data: ${e.toString()}',
        errors: [e.toString()],
      );
    }
  }

  /// Get current sync state
  bool get isSyncing => _isSyncing;
  bool get isConnected => _connectivity.isConnected;

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivity.dispose();
  }
}