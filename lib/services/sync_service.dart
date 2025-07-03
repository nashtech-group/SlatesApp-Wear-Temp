import 'dart:async';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
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

  /// Manually trigger sync
  Future<bool> manualSync() async {
    if (_isSyncing) {
      log('Sync already in progress');
      return false;
    }

    if (!_connectivity.isConnected) {
      log('No internet connection for sync');
      return false;
    }

    return await _performSync();
  }

  /// Perform the actual sync operation
  Future<bool> _performSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    log('Starting sync operation');

    try {
      final token = await AuthManager().getToken();
      if (token == null) {
        log('No token available for sync');
        return false;
      }

      final pendingSubmissions = await _offlineStorage.getPendingSubmissions();

      if (pendingSubmissions.isEmpty) {
        log('No pending submissions to sync');
        await AuthManager().saveLastOnlineSync(DateTime.now());
        return true;
      }

      log('Syncing ${pendingSubmissions.length} pending submissions');

      int successCount = 0;
      int failureCount = 0;

      for (int i = 0; i < pendingSubmissions.length; i++) {
        final submission = pendingSubmissions[i];

        try {
          final response = await _rosterProvider.submitComprehensiveGuardDuty(
            requestData: submission,
            token: token,
          );

          // If successful, remove from pending
          await _offlineStorage.removePendingSubmission(
              'submission_${DateTime.now().millisecondsSinceEpoch}_$i');
          successCount++;

          log('Successfully synced submission ${i + 1}/${pendingSubmissions.length}');
        } catch (e) {
          log('Failed to sync submission ${i + 1}: $e');
          failureCount++;

          // Update retry count
          await _offlineStorage.updateSubmissionRetryCount(
            'submission_${DateTime.now().millisecondsSinceEpoch}_$i',
            1,
          );
        }
      }

      // Update last sync time if any successful
      if (successCount > 0) {
        await AuthManager().saveLastOnlineSync(DateTime.now());
      }

      log('Sync completed: $successCount successful, $failureCount failed');

      // Show sync notification
      await _notification.showSyncCompletedNotification(
          successCount, failureCount);

      return failureCount == 0;
    } catch (e) {
      log('Sync operation failed: $e');
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync specific guard movements
  Future<bool> syncGuardMovements({int? guardId, int? limit}) async {
    if (!_connectivity.isConnected) {
      log('No internet connection for movement sync');
      return false;
    }

    try {
      final token = await AuthManager().getToken();
      if (token == null) {
        log('No token available for movement sync');
        return false;
      }

      final movements = await _offlineStorage.getUnsyncedGuardMovements(
        guardId: guardId,
        limit: limit,
      );

      if (movements.isEmpty) {
        log('No unsynced movements to sync');
        return true;
      }

      // Convert movements to JSON format for API
      final movementData = movements.map((m) => m.toJson()).toList();

      final response = await _rosterProvider.submitGuardMovements(
        movements: movementData,
        token: token,
      );

      // Mark movements as synced
      final localIds = movements
          .map((m) => 'movement_${m.timestamp.millisecondsSinceEpoch}')
          .toList();
      await _offlineStorage.markGuardMovementsAsSynced(localIds);

      log('Successfully synced ${movements.length} movements');
      return true;
    } catch (e) {
      log('Failed to sync movements: $e');
      return false;
    }
  }

  /// Sync specific perimeter checks
  Future<bool> syncPerimeterChecks({int? guardId, int? limit}) async {
    if (!_connectivity.isConnected) {
      log('No internet connection for perimeter check sync');
      return false;
    }

    try {
      final token = await AuthManager().getToken();
      if (token == null) {
        log('No token available for perimeter check sync');
        return false;
      }

      final checks = await _offlineStorage.getUnsyncedPerimeterChecks(
        guardId: guardId,
        limit: limit,
      );

      if (checks.isEmpty) {
        log('No unsynced perimeter checks to sync');
        return true;
      }

      // Convert checks to JSON format for API
      final checkData = checks.map((c) => c.toJson()).toList();

      final response = await _rosterProvider.submitPerimeterChecks(
        perimeterChecks: checkData,
        token: token,
      );

      // Mark checks as synced
      final localIds = checks
          .map((c) => 'perimeter_${c.passTime.millisecondsSinceEpoch}')
          .toList();
      await _offlineStorage.markPerimeterChecksAsSynced(localIds);

      log('Successfully synced ${checks.length} perimeter checks');
      return true;
    } catch (e) {
      log('Failed to sync perimeter checks: $e');
      return false;
    }
  }

  /// Sync roster user updates
  Future<bool> syncRosterUserUpdates({
    required List<Map<String, dynamic>> updates,
  }) async {
    if (!_connectivity.isConnected) {
      log('No internet connection for roster updates sync');
      return false;
    }

    try {
      final token = await AuthManager().getToken();
      if (token == null) {
        log('No token available for roster updates sync');
        return false;
      }

      final response = await _rosterProvider.submitRosterUserUpdates(
        updates: updates,
        token: token,
      );

      log('Successfully synced ${updates.length} roster updates');
      return true;
    } catch (e) {
      log('Failed to sync roster updates: $e');
      return false;
    }
  }

  /// Force sync all pending data
  Future<Map<String, dynamic>> forceSyncAll() async {
    final results = <String, dynamic>{
      'movements': false,
      'perimeterChecks': false,
      'pendingSubmissions': false,
      'totalSuccess': 0,
      'totalFailure': 0,
    };

    if (!_connectivity.isConnected) {
      results['error'] = 'No internet connection';
      return results;
    }

    try {
      // Sync movements
      results['movements'] = await syncGuardMovements();

      // Sync perimeter checks
      results['perimeterChecks'] = await syncPerimeterChecks();

      // Sync pending submissions
      results['pendingSubmissions'] = await _performSync();

      // Calculate totals
      int successCount = 0;
      if (results['movements'] == true) successCount++;
      if (results['perimeterChecks'] == true) successCount++;
      if (results['pendingSubmissions'] == true) successCount++;

      results['totalSuccess'] = successCount;
      results['totalFailure'] = 3 - successCount;

      return results;
    } catch (e) {
      results['error'] = e.toString();
      return results;
    }
  }

  /// Check if sync is required based on time elapsed
  Future<bool> isSyncRequired() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();

      if (lastSync == null) {
        return true; // Never synced
      }

      final daysSinceSync = DateTime.now().difference(lastSync).inDays;
      return daysSinceSync >= 5; // Sync every 5 days as per app requirements
    } catch (e) {
      return true;
    }
  }

  /// Get days since last sync
  Future<int> getDaysSinceLastSync() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();

      if (lastSync == null) {
        return 999; // Never synced
      }

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

    // Get unsynced counts
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

  /// Get sync history
  Future<List<Map<String, dynamic>>> getSyncHistory({int? limit}) async {
    return await _offlineStorage.getSubmissionRecords(
      limit: limit,
      submissionType: 'comprehensive_guard_duty',
    );
  }

  /// Clear sync history
  Future<void> clearSyncHistory() async {
    // Implementation depends on OfflineStorageService having a method to clear submission records
    // For now, we'll just clear pending submissions
    await _offlineStorage.clearPendingSubmissions();
  }

  /// Retry failed submissions
  Future<bool> retryFailedSubmissions() async {
    if (!_connectivity.isConnected) {
      log('No internet connection for retry');
      return false;
    }

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

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivity.dispose();
  }
}
