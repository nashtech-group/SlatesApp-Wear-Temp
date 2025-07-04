import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/data/models/api_error_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_duty_summary_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_update_model.dart';
import 'package:slates_app_wear/data/models/sites/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/services/offline_storage_service.dart';
import 'package:slates_app_wear/services/connectivity_service.dart';
import 'package:slates_app_wear/services/sync_service.dart';
import 'package:slates_app_wear/services/date_service.dart';
import 'package:slates_app_wear/services/notification_service.dart';

import 'roster_provider.dart';

class RosterRepository {
  final RosterProvider _rosterProvider;
  final OfflineStorageService _offlineStorage;
  final ConnectivityService _connectivity;
  final SyncService _syncService;
  final DateService _dateService;
  final NotificationService _notificationService;

  RosterRepository({
    required RosterProvider rosterProvider,
    OfflineStorageService? offlineStorage,
    ConnectivityService? connectivity,
    SyncService? syncService,
    DateService? dateService,
    NotificationService? notificationService,
  })  : _rosterProvider = rosterProvider,
        _offlineStorage = offlineStorage ?? OfflineStorageService(),
        _connectivity = connectivity ?? ConnectivityService(),
        _syncService = syncService ?? SyncService(),
        _dateService = dateService ?? DateService(),
        _notificationService = notificationService ?? NotificationService();

  /// Initialize repository and services
  Future<void> initialize() async {
    try {
      // Initialize notification service first
      final notificationInitialized = await _notificationService.initialize();
      if (!notificationInitialized) {
        log('Warning: NotificationService failed to initialize');
      }

      // Initialize other services
      _syncService.initialize();
      await _syncService.scheduleSyncReminders();
      _connectivity.startMonitoring();

      log('RosterRepository initialized successfully');
    } catch (e) {
      log('Failed to initialize RosterRepository: $e');
      rethrow;
    }
  }

  /// Get roster data for a guard from current date
  Future<RosterResponseModel> getRosterData({
    required int guardId,
    String? fromDate,
  }) async {
    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();

      // Try online first if connected
      if (_connectivity.isConnected) {
        try {
          log('Fetching roster data online for guard $guardId from $dateToUse');
          final responseData = await _rosterProvider.getRosterData(
            guardId: guardId,
            fromDate: dateToUse,
            token: token,
          );

          log('Roster response: $responseData');

          final decodedData = jsonDecode(responseData);

          if (decodedData.containsKey("errors") ||
              (decodedData.containsKey("status") &&
                  decodedData["status"] == "error")) {
            throw ApiErrorModel.fromJson(decodedData);
          }

          final rosterResponse = RosterResponseModel.fromJson(decodedData);

          // Cache for offline access
          await _offlineStorage.cacheRosterData(guardId, rosterResponse);
          log('Roster data cached for offline access');

          // Schedule duty notifications for upcoming duties
          await _scheduleDutyNotificationsFromRoster(rosterResponse);

          return rosterResponse;
        } catch (e) {
          if (e is ApiErrorModel) rethrow;
          log('Online roster fetch failed, trying offline: $e');
        }
      } else {
        // Show offline mode notification
        await _notificationService.showOfflineModeNotification();
      }

      // Try offline cache
      log('Attempting to load roster data from cache for guard $guardId');
      final cachedData = await _offlineStorage.getCachedRosterData(guardId);
      if (cachedData != null) {
        log('Loaded roster data from cache');
        return cachedData;
      }

      // No data available
      throw ApiErrorModel(
        status: 'error',
        message: _connectivity.isConnected
            ? 'Failed to fetch roster data'
            : 'No internet connection and no offline data available',
      );
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Submit comprehensive guard duty data
  Future<ComprehensiveGuardDutyResponseModel> submitComprehensiveGuardDuty({
    List<RosterUserUpdateModel>? rosterUpdates,
    List<GuardMovementModel>? movements,
    List<PerimeterCheckModel>? perimeterChecks,
  }) async {
    final requestData = ComprehensiveGuardDutyRequestModel(
      updates: rosterUpdates,
      movements: movements,
      perimeterChecks: perimeterChecks,
    );

    if (!requestData.hasAnyData) {
      throw ApiErrorModel(
        status: 'error',
        message: 'No data provided for submission',
      );
    }

    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      // Try online submission if connected
      if (_connectivity.isConnected) {
        try {
          log('Submitting comprehensive guard duty data online');
          final responseData =
              await _rosterProvider.submitComprehensiveGuardDuty(
            requestData: requestData,
            token: token,
          );

          log('Comprehensive guard duty response: $responseData');

          final decodedData = jsonDecode(responseData);

          if (decodedData.containsKey("errors") ||
              (decodedData.containsKey("status") &&
                  decodedData["status"] == "error")) {
            throw ApiErrorModel.fromJson(decodedData);
          }

          final response =
              ComprehensiveGuardDutyResponseModel.fromJson(decodedData);

          // Cache successful submission
          await _offlineStorage.cacheSubmissionRecord(requestData, response);

          // Show sync completed notification
          final totalItems = (rosterUpdates?.length ?? 0) +
              (movements?.length ?? 0) +
              (perimeterChecks?.length ?? 0);
          await _notificationService.showSyncCompletedNotification(
              totalItems, 0);

          log('Submission record cached and sync notification shown');

          return response;
        } catch (e) {
          if (e is ApiErrorModel) rethrow;
          log('Online submission failed, caching for offline sync: $e');
        }
      }

      // Cache for later sync
      log('Caching submission for offline sync');
      await _offlineStorage.cachePendingSubmission(requestData);

      // Check days since last sync and show reminder if needed
      await _checkAndShowSyncReminder();

      return ComprehensiveGuardDutyResponseModel(
        message: 'Data cached for sync when online',
        summary: GuardDutySummaryModel(
          rosterUsersUpdated: rosterUpdates?.length ?? 0,
          perimeterChecksCreated: perimeterChecks?.length ?? 0,
          movementsRecorded: movements?.length ?? 0,
        ),
        timestamp: DateTime.now(),
      );
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Schedule duty notifications for upcoming duties in roster
  Future<void> _scheduleDutyNotificationsFromRoster(
      RosterResponseModel rosterResponse) async {
    try {
      final now = DateTime.now();
      final upcomingDuties = rosterResponse.data.where((rosterUser) {
        // Only schedule for duties that haven't started yet
        return rosterUser.startsAt.isAfter(now);
      }).toList();

      for (final rosterUser in upcomingDuties) {
        final scheduledIds =
            await _notificationService.scheduleDutyNotifications(
          rosterUser: rosterUser,
          site: rosterUser.site,
        );

        if (scheduledIds.isNotEmpty) {
          log('Scheduled ${scheduledIds.length} notifications for duty at ${rosterUser.site.name}');
        }
      }
    } catch (e) {
      log('Failed to schedule duty notifications: $e');
    }
  }

  /// Check sync status and show reminder if needed
  Future<void> _checkAndShowSyncReminder() async {
    try {
      final syncStatus = await _syncService.getSyncStatus();
      final daysSinceSync = syncStatus['daysSinceLastSync'] as int? ?? 0;

      // Show sync reminder based on days since last sync
      if (daysSinceSync >= 5) {
        await _notificationService.showSyncRequiredNotification(daysSinceSync);
        log('Sync reminder shown for $daysSinceSync days since last sync');
      }
    } catch (e) {
      log('Failed to check sync status: $e');
    }
  }

  /// Show checkpoint completion notification
  Future<void> showCheckpointCompletionNotification({
    required String checkpointName,
    required String siteName,
  }) async {
    try {
      await _notificationService.showCheckpointCompletionAlert(
        checkpointName: checkpointName,
        siteName: siteName,
      );
      log('Checkpoint completion notification shown: $checkpointName at $siteName');
    } catch (e) {
      log('Failed to show checkpoint completion notification: $e');
    }
  }

  /// Show position alert for static duty
  Future<void> showPositionAlert({
    required String message,
    required bool isReturnAlert,
  }) async {
    try {
      await _notificationService.showPositionAlert(
        message: message,
        isReturnAlert: isReturnAlert,
      );
      log('Position alert shown: $message');
    } catch (e) {
      log('Failed to show position alert: $e');
    }
  }

  /// Show battery alert
  Future<void> showBatteryAlert({
    required String message,
    required int batteryLevel,
  }) async {
    try {
      await _notificationService.showBatteryAlert(
        message: message,
        batteryLevel: batteryLevel,
      );
      log('Battery alert shown: $message (Battery: $batteryLevel%)');
    } catch (e) {
      log('Failed to show battery alert: $e');
    }
  }

  /// Show emergency notification
  Future<void> showEmergencyNotification({
    required String title,
    required String message,
    Map<String, dynamic>? payload,
  }) async {
    try {
      await _notificationService.showEmergencyNotification(
        title: title,
        message: message,
        payload: payload,
      );
      log('Emergency notification shown: $title');
    } catch (e) {
      log('Failed to show emergency notification: $e');
    }
  }

  /// Cancel duty notifications for a specific roster user
  Future<void> cancelDutyNotifications(List<int> notificationIds) async {
    try {
      for (final id in notificationIds) {
        await _notificationService.cancelNotification(id);
      }
      log('Cancelled ${notificationIds.length} duty notifications');
    } catch (e) {
      log('Failed to cancel duty notifications: $e');
    }
  }

  /// Get roster data with pagination
  Future<RosterResponseModel> getRosterDataPaginated({
    required int guardId,
    String? fromDate,
    int page = 1,
    int perPage = 15,
  }) async {
    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();

      if (_connectivity.isConnected) {
        log('Fetching paginated roster data online for guard $guardId');
        final responseData = await _rosterProvider.getRosterDataPaginated(
          guardId: guardId,
          fromDate: dateToUse,
          token: token,
          page: page,
          perPage: perPage,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey("errors") ||
            (decodedData.containsKey("status") &&
                decodedData["status"] == "error")) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for any new duties found
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      }

      // Fallback to cached data with manual pagination
      final cachedData = await _offlineStorage.getCachedRosterData(guardId);
      if (cachedData != null) {
        return _paginateCachedData(cachedData, page, perPage);
      }

      throw ApiErrorModel(
        status: 'error',
        message: 'No internet connection and no offline data available',
      );
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Get roster data for multiple guards (bulk fetch)
  Future<RosterResponseModel> getBulkRosterData({
    required List<int> guardIds,
    String? fromDate,
  }) async {
    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();

      if (_connectivity.isConnected) {
        log('Fetching bulk roster data for ${guardIds.length} guards');
        final responseData = await _rosterProvider.getBulkRosterData(
          guardIds: guardIds,
          fromDate: dateToUse,
          token: token,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey("errors") ||
            (decodedData.containsKey("status") &&
                decodedData["status"] == "error")) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for upcoming duties
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      }

      throw ApiErrorModel(
        status: 'error',
        message: 'Bulk roster data requires internet connection',
      );
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Get roster data for a specific date range
  Future<RosterResponseModel> getRosterDataForDateRange({
    required int guardId,
    required String fromDate,
    required String toDate,
  }) async {
    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      if (_connectivity.isConnected) {
        log('Fetching roster data for date range: $fromDate to $toDate');
        final responseData = await _rosterProvider.getRosterDataForDateRange(
          guardId: guardId,
          fromDate: fromDate,
          toDate: toDate,
          token: token,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey("errors") ||
            (decodedData.containsKey("status") &&
                decodedData["status"] == "error")) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for upcoming duties in the range
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      }

      throw ApiErrorModel(
        status: 'error',
        message: 'Date range queries require internet connection',
      );
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Unexpected error: ${e.toString()}',
      );
    }
  }

  /// Extract unique sites list from roster data
  List<SiteModel> extractSitesFromRoster(RosterResponseModel rosterResponse) {
    final Map<int, SiteModel> sitesMap = {};

    for (final rosterUser in rosterResponse.data) {
      sitesMap[rosterUser.site.id] = rosterUser.site;
    }

    return sitesMap.values.toList();
  }

  /// Get current active duty for a guard
  RosterUserModel? getCurrentActiveDuty(RosterResponseModel rosterResponse) {
    for (final rosterUser in rosterResponse.data) {
      if (rosterUser.isCurrentlyOnDuty) {
        return rosterUser;
      }
    }
    return null;
  }

  /// Get upcoming duties for a guard (within next 24 hours)
  List<RosterUserModel> getUpcomingDuties(RosterResponseModel rosterResponse) {
    final now = DateTime.now();
    final next24Hours = now.add(const Duration(hours: 24));

    return rosterResponse.data.where((rosterUser) {
      return rosterUser.startsAt.isAfter(now) &&
          rosterUser.startsAt.isBefore(next24Hours);
    }).toList();
  }

  /// Sync pending submissions manually
  Future<bool> syncPendingSubmissions() async {
    try {
      log('Starting manual sync of pending submissions');
      final result = await _syncService.manualSync();

      if (result) {
        // Show sync success notification
        await _notificationService.showSyncCompletedNotification(1, 0);
      }

      return result;
    } catch (e) {
      log('Failed to sync pending submissions: $e');
      return false;
    }
  }

  /// Force sync all pending data
  Future<Map<String, dynamic>> forceSyncAll() async {
    try {
      log('Starting force sync of all pending data');
      final result = await _syncService.forceSyncAll();

      final successCount = result['totalSuccess'] as int? ?? 0;
      final failureCount = result['totalFailure'] as int? ?? 0;

      // Show sync completed notification
      await _notificationService.showSyncCompletedNotification(
          successCount, failureCount);

      return result;
    } catch (e) {
      log('Failed to force sync all data: $e');
      return {
        'error': e.toString(),
        'pendingSubmissions': false,
        'totalSuccess': 0,
        'totalFailure': 1,
      };
    }
  }

  /// Clear sync history - facade method with enhanced UX
  Future<SyncResult> clearSyncHistory() async {
    try {
      log('Starting sync history cleanup via repository');

      // Show notification that cleanup is starting
      await _notificationService.showSyncStartedNotification();

      final result = await _syncService.clearSyncHistory();

      // Handle UI concerns and enhanced reporting
      await _showSyncNotification(result);
      await _logSyncResult(result);

      // Additional repository-level logging for sync history clearing
      if (result.success) {
        final totalCleared = result.metadata['total_cleared'] as int? ?? 0;
        final pendingCleared = result.metadata['pending_cleared'] as int? ?? 0;
        final recordsCleared = result.metadata['records_cleared'] as int? ?? 0;

        log('Repository: Sync history cleared - $pendingCleared pending, $recordsCleared records, $totalCleared total');

        // Could also trigger a notification about storage space freed
        await _notificationService
            .showDataCleanupCompletedNotification(totalCleared);
      }

      return result;
    } catch (e) {
      log('Failed to clear sync history via repository: $e');

      final errorResult = SyncResult.failure(
        message: 'Failed to clear sync history: ${e.toString()}',
        errors: [e.toString()],
      );

      await _showSyncNotification(errorResult);
      return errorResult;
    }
  }

  /// Get comprehensive sync report for UI/debugging
  Future<Map<String, dynamic>> getSyncReport() async {
    try {
      final report = await _syncService.getSyncReport();

      // Add repository-level enhancements
      report['repositoryLevel'] = {
        'lastRefresh': DateTime.now().toIso8601String(),
        'connectivity': _connectivity.isConnected,
        'hasPendingSubmissions': await hasPendingSubmissions(),
      };

      return report;
    } catch (e) {
      log('Failed to get sync report: $e');
      return {
        'error': e.toString(),
        'generatedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Clean old sync data - facade method with notifications
  Future<SyncResult> cleanOldSyncData() async {
    try {
      log('Starting old sync data cleanup via repository');

      final result = await _syncService.cleanOldSyncData();

      // Show appropriate notifications
      if (result.success) {
        await _notificationService.showDataCleanupCompletedNotification(1);
      } else {
        await _notificationService
            .showDataCleanupFailedNotification(result.message);
      }

      return result;
    } catch (e) {
      log('Failed to clean old sync data via repository: $e');

      final errorResult = SyncResult.failure(
        message: 'Failed to clean old sync data: ${e.toString()}',
        errors: [e.toString()],
      );

      await _notificationService
          .showDataCleanupFailedNotification(errorResult.message);
      return errorResult;
    }
  }

  /// Get sync history for UI display
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 20}) async {
    try {
      return await _syncService.getSyncHistory(limit: limit);
    } catch (e) {
      log('Failed to get sync history: $e');
      return [];
    }
  }

  /// Retry failed submissions - enhanced facade method
  Future<SyncResult> retryFailedSubmissions() async {
    try {
      log('Retrying failed submissions via repository');

      // Check connectivity first
      if (!_connectivity.isConnected) {
        await _notificationService.showOfflineModeNotification();
        return SyncResult.failure(
          message: 'Cannot retry: No internet connection',
          metadata: {'reason': 'no_connectivity'},
        );
      }

      // Show retry notification
      await _notificationService.showSyncRetryNotification();

      final result = await _syncService.retryFailedSubmissions();

      // Handle notifications based on result
      await _showSyncNotification(result);

      return result;
    } catch (e) {
      log('Failed to retry failed submissions: $e');

      final errorResult = SyncResult.failure(
        message: 'Failed to retry submissions: ${e.toString()}',
        errors: [e.toString()],
      );

      await _showSyncNotification(errorResult);
      return errorResult;
    }
  }

  /// Export sync data for debugging/support
  Future<Map<String, dynamic>> exportSyncDataForDebug() async {
    try {
      // Get data from OfflineStorageService
      final debugData = await _offlineStorage.exportSyncDataForDebug();

      // Add repository-level context
      debugData['repositoryContext'] = {
        'connectivity': _connectivity.isConnected,
        'lastSyncAttempt': await _syncService.getDaysSinceLastSync(),
        'isSyncing': _syncService.isSyncing,
        'exportedFromRepository': true,
      };

      return debugData;
    } catch (e) {
      log('Failed to export sync data for debug: $e');
      return {
        'error': e.toString(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Get storage usage with notifications if needed
  Future<Map<String, dynamic>> getStorageUsage() async {
    try {
      final usage = await _offlineStorage.getComprehensiveStorageStats();

      // Check if storage is getting full (example threshold)
      final databaseSizeMB =
          double.tryParse(usage['databaseSizeMB'] as String? ?? '0') ?? 0;
      if (databaseSizeMB > 100) {
        // 100MB threshold
        await _notificationService
            .showStorageWarningNotification(databaseSizeMB);
      }

      return usage;
    } catch (e) {
      log('Failed to get storage usage: $e');
      return {};
    }
  }

  /// Private helper to show appropriate sync notifications 
  Future<void> _showSyncNotification(SyncResult result) async {
    try {
      if (result.isCompleteSuccess) {
        await _notificationService.showSyncCompletedNotification(
          result.successCount,
          result.failureCount,
        );
      } else if (result.isPartialSuccess) {
        await _notificationService.showSyncPartialSuccessNotification(
          result.successCount,
          result.failureCount,
        );
      } else {
        await _notificationService.showSyncFailedNotification(
          result.message,
          result.failureCount,
        );
      }
    } catch (e) {
      log('Failed to show sync notification: $e');
    }
  }

  /// Enhanced sync result logging
  Future<void> _logSyncResult(SyncResult result) async {
    try {
      final logData = {
        'timestamp': DateTime.now().toIso8601String(),
        'operation': 'sync_result',
        'success': result.success,
        'success_count': result.successCount,
        'failure_count': result.failureCount,
        'total_count': result.totalCount,
        'success_rate': result.successRate,
        'success_percentage': result.successPercentage,
        'duration': result.formattedDuration,
        'errors': result.errors,
        'metadata': result.metadata,
        'result_type': result.isCompleteSuccess
            ? 'complete_success'
            : result.isPartialSuccess
                ? 'partial_success'
                : 'failure',
      };

      // Log to your analytics/monitoring service
      log('Enhanced sync result: ${jsonEncode(logData)}');

      // You could also save to local storage for debugging
      // await _offlineStorage.saveSyncLog(logData);
    } catch (e) {
      log('Failed to log enhanced sync result: $e');
    }
  }

  /// Check if there are pending submissions
  Future<bool> hasPendingSubmissions() async {
    try {
      final count = await _offlineStorage.getPendingSubmissionsCount();
      return count > 0;
    } catch (e) {
      log('Failed to check pending submissions: $e');
      return false;
    }
  }

  /// Get sync status for UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    try {
      final status = await _syncService.getSyncStatus();

      // Show sync reminder if needed
      final daysSinceSync = status['daysSinceLastSync'] as int? ?? 0;
      if (daysSinceSync >= 5) {
        await _notificationService.showSyncRequiredNotification(daysSinceSync);
      }

      return status;
    } catch (e) {
      log('Failed to get sync status: $e');
      return {
        'pendingSubmissions': 0,
        'unsyncedMovements': 0,
        'unsyncedPerimeterChecks': 0,
        'daysSinceLastSync': 999,
        'isSyncRequired': true,
        'isConnected': false,
        'isSyncing': false,
      };
    }
  }

  /// Get detailed sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    try {
      return await _syncService.getSyncStatistics();
    } catch (e) {
      log('Failed to get sync statistics: $e');
      return {};
    }
  }

  /// Get today's roster status
  Future<RosterResponseModel> getTodaysRosterStatus({
    required int guardId,
  }) async {
    return await getRosterData(
      guardId: guardId,
      fromDate: _dateService.getTodayFormattedDate(),
    );
  }

  /// Get upcoming roster duties
  Future<RosterResponseModel> getUpcomingRosterDuties({
    required int guardId,
  }) async {
    return await getRosterData(
      guardId: guardId,
      fromDate: _dateService.getTodayFormattedDate(),
    );
  }

  /// Store guard movement locally
  Future<String> storeGuardMovementLocally(GuardMovementModel movement) async {
    try {
      return await _offlineStorage.storeGuardMovement(movement);
    } catch (e) {
      log('Failed to store guard movement locally: $e');
      rethrow;
    }
  }

  /// Store perimeter check locally
  Future<String> storePerimeterCheckLocally(
      PerimeterCheckModel perimeterCheck) async {
    try {
      return await _offlineStorage.storePerimeterCheck(perimeterCheck);
    } catch (e) {
      log('Failed to store perimeter check locally: $e');
      rethrow;
    }
  }

  /// Get unsynced guard movements
  Future<List<GuardMovementModel>> getUnsyncedGuardMovements({
    int? guardId,
    int? limit,
  }) async {
    try {
      return await _offlineStorage.getUnsyncedGuardMovements(
        guardId: guardId,
        limit: limit,
      );
    } catch (e) {
      log('Failed to get unsynced guard movements: $e');
      return [];
    }
  }

  /// Get unsynced perimeter checks
  Future<List<PerimeterCheckModel>> getUnsyncedPerimeterChecks({
    int? guardId,
    int? limit,
  }) async {
    try {
      return await _offlineStorage.getUnsyncedPerimeterChecks(
        guardId: guardId,
        limit: limit,
      );
    } catch (e) {
      log('Failed to get unsynced perimeter checks: $e');
      return [];
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStatistics() async {
    try {
      return await _offlineStorage.getStorageStatistics();
    } catch (e) {
      log('Failed to get storage statistics: $e');
      return {};
    }
  }

  /// Clear all roster cache
  Future<void> clearRosterCache() async {
    try {
      await _offlineStorage.clearRosterCache();
      log('Roster cache cleared successfully');
    } catch (e) {
      log('Failed to clear roster cache: $e');
      rethrow;
    }
  }

  /// Clear all cache data
  Future<void> clearAllCache() async {
    try {
      await _offlineStorage.clearAllCache();
      log('All cache data cleared successfully');
    } catch (e) {
      log('Failed to clear all cache: $e');
      rethrow;
    }
  }

  /// Clean old data
  Future<void> cleanOldData() async {
    try {
      await _offlineStorage.cleanOldData();
      log('Old data cleaned successfully');
    } catch (e) {
      log('Failed to clean old data: $e');
    }
  }

  /// Check connectivity status
  bool get isConnected => _connectivity.isConnected;

  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivity.connectivityStream;

  /// Private helper methods

  /// Apply pagination to cached data
  RosterResponseModel _paginateCachedData(
    RosterResponseModel cachedData,
    int page,
    int perPage,
  ) {
    final startIndex = (page - 1) * perPage;
    final endIndex = startIndex + perPage;

    final paginatedItems = cachedData.data.length > startIndex
        ? cachedData.data.sublist(
            startIndex,
            endIndex > cachedData.data.length
                ? cachedData.data.length
                : endIndex,
          )
        : <RosterUserModel>[];

    return RosterResponseModel(
      data: paginatedItems,
      links: cachedData.links,
      meta: cachedData.meta,
    );
  }

  /// Dispose resources
  void dispose() {
    try {
      _syncService.dispose();
      _connectivity.dispose();
      _notificationService.dispose();
      log('RosterRepository disposed successfully');
    } catch (e) {
      log('Error disposing RosterRepository: $e');
    }
  }
}
