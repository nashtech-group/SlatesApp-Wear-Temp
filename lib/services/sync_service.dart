import 'dart:async';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
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
    _connectivitySubscription = _connectivity.connectivityStream.listen(_onConnectivityChanged);
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
          await _offlineStorage.removePendingSubmission(i.toString());
          successCount++;
          
          log('Successfully synced submission ${i + 1}/${pendingSubmissions.length}');
        } catch (e) {
          log('Failed to sync submission ${i + 1}: $e');
          failureCount++;
        }
      }

      // Update last sync time if any successful
      if (successCount > 0) {
        await AuthManager().saveLastOnlineSync(DateTime.now());
      }

      log('Sync completed: $successCount successful, $failureCount failed');
      
      // Show sync notification
      await _notification.showSyncCompletedNotification(successCount, failureCount);
      
      return failureCount == 0;
    } catch (e) {
      log('Sync operation failed: $e');
      return false;
    } finally {
      _isSyncing = false;
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
    
    return {
      'pendingSubmissions': pendingCount,
      'daysSinceLastSync': daysSinceSync,
      'isSyncRequired': isRequired,
      'isConnected': _connectivity.isConnected,
      'isSyncing': _isSyncing,
    };
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivity.dispose();
  }
}