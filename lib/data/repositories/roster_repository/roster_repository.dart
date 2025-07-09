import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
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
import 'package:slates_app_wear/data/models/sync/sync_result.dart';
import 'package:slates_app_wear/services/offline_storage_service.dart';
import 'package:slates_app_wear/services/connectivity_service.dart';
import 'package:slates_app_wear/services/sync_service.dart';
import 'package:slates_app_wear/services/date_service.dart';
import 'package:slates_app_wear/services/notification_service.dart';
import '../../../core/error/repository_error_mixin.dart';
import '../../../core/error/exceptions.dart';

import 'roster_provider.dart';

class RosterRepository with RepositoryErrorMixin {
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
    return await safeRepositoryCall(
      () async {
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
      },
      'initialize',
    );
  }

  /// Get roster data for a guard from current date
  Future<RosterResponseModel> getRosterData({
    required int guardId,
    String? fromDate,
  }) async {
    final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();
    
    return await executeWithCacheFallback(
      () => _fetchRosterDataOnline(guardId, dateToUse),
      () => _getRosterDataFromCache(guardId),
      'getRosterData',
    );
  }

  /// Fetch roster data online
  Future<RosterResponseModel> _fetchRosterDataOnline(int guardId, String dateToUse) async {
    return await safeRepositoryCall(
      () async {
        final token = await _getAuthToken();
        
        if (!_connectivity.isConnected) {
          throw  NetworkException(
            message: AppConstants.networkErrorMessage,
          );
        }

        log('Fetching roster data online for guard $guardId from $dateToUse');
        final responseData = await _rosterProvider.getRosterData(
          guardId: guardId,
          fromDate: dateToUse,
          token: token,
        );

        log('Roster response received');
        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey(ApiConstants.errorsKey) ||
            (decodedData.containsKey(ApiConstants.statusKey) &&
                decodedData[ApiConstants.statusKey] == ApiConstants.errorStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Cache for offline access
        await _offlineStorage.cacheRosterData(guardId, rosterResponse);
        log('Roster data cached for offline access');

        // Schedule duty notifications for upcoming duties
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      },
      'fetchRosterDataOnline',
    );
  }

  /// Get roster data from cache
  Future<RosterResponseModel> _getRosterDataFromCache(int guardId) async {
    return await safeRepositoryCall(
      () async {
        if (!_connectivity.isConnected) {
          await _notificationService.showOfflineModeNotification();
        }

        log('Attempting to load roster data from cache for guard $guardId');
        final cachedData = await _offlineStorage.getCachedRosterData(guardId);
        
        if (cachedData == null) {
          throw  CacheException(
            message: 'No offline data available',
          );
        }

        log('Loaded roster data from cache');
        return cachedData;
      },
      'getRosterDataFromCache',
    );
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
      throw  ValidationException(
        message: 'No data provided for submission',
      );
    }

    return await executeWithSmartRetry(
      () => _submitGuardDutyOnline(requestData, rosterUpdates, movements, perimeterChecks),
      'submitComprehensiveGuardDuty',
      getCachedData: () => _cacheGuardDutyForOfflineSync(requestData, rosterUpdates, movements, perimeterChecks),
    );
  }

  /// Submit guard duty data online
  Future<ComprehensiveGuardDutyResponseModel> _submitGuardDutyOnline(
    ComprehensiveGuardDutyRequestModel requestData,
    List<RosterUserUpdateModel>? rosterUpdates,
    List<GuardMovementModel>? movements,
    List<PerimeterCheckModel>? perimeterChecks,
  ) async {
    return await safeRepositoryCall(
      () async {
        final token = await _getAuthToken();
        
        if (!_connectivity.isConnected) {
          throw  NetworkException(
            message: AppConstants.networkErrorMessage,
          );
        }

        log('Submitting comprehensive guard duty data online');
        final responseData = await _rosterProvider.submitComprehensiveGuardDuty(
          requestData: requestData,
          token: token,
        );

        log('Comprehensive guard duty response received');
        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey(ApiConstants.errorsKey) ||
            (decodedData.containsKey(ApiConstants.statusKey) &&
                decodedData[ApiConstants.statusKey] == ApiConstants.errorStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final response = ComprehensiveGuardDutyResponseModel.fromJson(decodedData);

        // Cache successful submission
        await _offlineStorage.cacheSubmissionRecord(requestData, response);

        // Show sync completed notification
        final totalItems = (rosterUpdates?.length ?? 0) +
            (movements?.length ?? 0) +
            (perimeterChecks?.length ?? 0);
        await _notificationService.showSyncCompletedNotification(totalItems, 0);

        log('Submission record cached and sync notification shown');
        return response;
      },
      'submitGuardDutyOnline',
    );
  }

  /// Cache guard duty data for offline sync
  Future<ComprehensiveGuardDutyResponseModel> _cacheGuardDutyForOfflineSync(
    ComprehensiveGuardDutyRequestModel requestData,
    List<RosterUserUpdateModel>? rosterUpdates,
    List<GuardMovementModel>? movements,
    List<PerimeterCheckModel>? perimeterChecks,
  ) async {
    return await safeRepositoryCall(
      () async {
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
      },
      'cacheGuardDutyForOfflineSync',
    );
  }

  /// Get roster data with pagination
  Future<RosterResponseModel> getRosterDataPaginated({
    required int guardId,
    String? fromDate,
    int page = 1,
    int perPage = 15,
  }) async {
    final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();

    return await executeWithCacheFallback(
      () => _fetchPaginatedRosterOnline(guardId, dateToUse, page, perPage),
      () => _getPaginatedRosterFromCache(guardId, page, perPage),
      'getRosterDataPaginated',
    );
  }

  /// Fetch paginated roster data online
  Future<RosterResponseModel> _fetchPaginatedRosterOnline(
    int guardId, 
    String dateToUse, 
    int page, 
    int perPage,
  ) async {
    return await safeRepositoryCall(
      () async {
        final token = await _getAuthToken();

        if (!_connectivity.isConnected) {
          throw  NetworkException(
            message: AppConstants.networkErrorMessage,
          );
        }

        log('Fetching paginated roster data online for guard $guardId');
        final responseData = await _rosterProvider.getRosterDataPaginated(
          guardId: guardId,
          fromDate: dateToUse,
          token: token,
          page: page,
          perPage: perPage,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey(ApiConstants.errorsKey) ||
            (decodedData.containsKey(ApiConstants.statusKey) &&
                decodedData[ApiConstants.statusKey] == ApiConstants.errorStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for any new duties found
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      },
      'fetchPaginatedRosterOnline',
    );
  }

  /// Get paginated roster data from cache
  Future<RosterResponseModel> _getPaginatedRosterFromCache(
    int guardId, 
    int page, 
    int perPage,
  ) async {
    return await safeRepositoryCall(
      () async {
        final cachedData = await _offlineStorage.getCachedRosterData(guardId);
        if (cachedData == null) {
          throw  CacheException(
            message: 'No offline data available',
          );
        }
        return _paginateCachedData(cachedData, page, perPage);
      },
      'getPaginatedRosterFromCache',
    );
  }

  /// Get roster data for multiple guards (bulk fetch)
  Future<RosterResponseModel> getBulkRosterData({
    required List<int> guardIds,
    String? fromDate,
  }) async {
    final dateToUse = fromDate ?? _dateService.getTodayFormattedDate();

    return await safeRepositoryCall(
      () async {
        final token = await _getAuthToken();

        if (!_connectivity.isConnected) {
          throw  NetworkException(
            message: 'Bulk roster data requires internet connection',
          );
        }

        log('Fetching bulk roster data for ${guardIds.length} guards');
        final responseData = await _rosterProvider.getBulkRosterData(
          guardIds: guardIds,
          fromDate: dateToUse,
          token: token,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey(ApiConstants.errorsKey) ||
            (decodedData.containsKey(ApiConstants.statusKey) &&
                decodedData[ApiConstants.statusKey] == ApiConstants.errorStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for upcoming duties
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      },
      'getBulkRosterData',
    );
  }

  /// Get roster data for a specific date range
  Future<RosterResponseModel> getRosterDataForDateRange({
    required int guardId,
    required String fromDate,
    required String toDate,
  }) async {
    return await safeRepositoryCall(
      () async {
        final token = await _getAuthToken();

        if (!_connectivity.isConnected) {
          throw  NetworkException(
            message: 'Date range queries require internet connection',
          );
        }

        log('Fetching roster data for date range: $fromDate to $toDate');
        final responseData = await _rosterProvider.getRosterDataForDateRange(
          guardId: guardId,
          fromDate: fromDate,
          toDate: toDate,
          token: token,
        );

        final decodedData = jsonDecode(responseData);

        if (decodedData.containsKey(ApiConstants.errorsKey) ||
            (decodedData.containsKey(ApiConstants.statusKey) &&
                decodedData[ApiConstants.statusKey] == ApiConstants.errorStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final rosterResponse = RosterResponseModel.fromJson(decodedData);

        // Schedule notifications for upcoming duties in the range
        await _scheduleDutyNotificationsFromRoster(rosterResponse);

        return rosterResponse;
      },
      'getRosterDataForDateRange',
    );
  }

  /// Sync pending submissions manually
  Future<bool> syncPendingSubmissions() async {
    return await safeRepositoryCall(
      () async {
        log('Starting manual sync of pending submissions via repository');
        final result = await _syncService.manualSync();

        // Handle UI concerns (notifications) based on SyncResult
        await _showSyncNotification(result);

        return result.success;
      },
      'syncPendingSubmissions',
      fallbackValue: false,
    );
  }

  /// Force sync all pending data
  Future<SyncResult> forceSyncAll() async {
    return await safeRepositoryCall(
      () async {
        log('Starting enhanced force sync via repository');

        // Show starting notification for better UX
        await _notificationService.showSyncStartedNotification();

        final result = await _syncService.forceSyncAll();

        // Handle UI concerns and enhanced reporting
        await _showSyncNotification(result);
        await _logSyncResult(result);

        return result;
      },
      'forceSyncAll',
      fallbackValue: SyncResult.failure(
        message: AppConstants.unknownErrorMessage,
        errors: const ['Failed to execute force sync'],
      ),
    );
  }

  /// Clear sync history
  Future<SyncResult> clearSyncHistory() async {
    return await safeRepositoryCall(
      () async {
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
          await _notificationService.showDataCleanupCompletedNotification(totalCleared);
        }

        return result;
      },
      'clearSyncHistory',
      fallbackValue: SyncResult.failure(
        message: AppConstants.unknownErrorMessage,
        errors: const ['Failed to clear sync history'],
      ),
    );
  }

  /// Retry failed submissions
  Future<SyncResult> retryFailedSubmissions() async {
    return await safeRepositoryCall(
      () async {
        log('Retrying failed submissions via repository');

        // Check connectivity first
        if (!_connectivity.isConnected) {
          await _notificationService.showOfflineModeNotification();
          return SyncResult.failure(
            message: 'Cannot retry: No internet connection',
            metadata: const {'reason': 'no_connectivity'},
          );
        }

        // Show retry notification
        await _notificationService.showSyncRetryNotification();

        final result = await _syncService.retryFailedSubmissions();

        // Handle notifications based on result
        await _showSyncNotification(result);

        return result;
      },
      'retryFailedSubmissions',
      fallbackValue: SyncResult.failure(
        message: AppConstants.networkErrorMessage,
        errors: const ['Network error during retry'],
      ),
    );
  }

  /// Clean old sync data
  Future<SyncResult> cleanOldSyncData() async {
    return await safeRepositoryCall(
      () async {
        log('Starting old sync data cleanup via repository');

        final result = await _syncService.cleanOldSyncData();

        // Show appropriate notifications
        if (result.success) {
          await _notificationService.showDataCleanupCompletedNotification(1);
        } else {
          await _notificationService.showDataCleanupFailedNotification(result.message);
        }

        return result;
      },
      'cleanOldSyncData',
      fallbackValue: SyncResult.failure(
        message: AppConstants.unknownErrorMessage,
        errors: const ['Failed to clean old data'],
      ),
    );
  }

  /// Store guard movement locally
  Future<String> storeGuardMovementLocally(GuardMovementModel movement) async {
    return await safeRepositoryCall(
      () async {
        return await _offlineStorage.storeGuardMovement(movement);
      },
      'storeGuardMovementLocally',
    );
  }

  /// Store perimeter check locally
  Future<String> storePerimeterCheckLocally(PerimeterCheckModel perimeterCheck) async {
    return await safeRepositoryCall(
      () async {
        return await _offlineStorage.storePerimeterCheck(perimeterCheck);
      },
      'storePerimeterCheckLocally',
    );
  }

  /// Get unsynced guard movements
  Future<List<GuardMovementModel>> getUnsyncedGuardMovements({
    int? guardId,
    int? limit,
  }) async {
    return await safeRepositoryCall(
      () async {
        return await _offlineStorage.getUnsyncedGuardMovements(
          guardId: guardId,
          limit: limit,
        );
      },
      'getUnsyncedGuardMovements',
      fallbackValue: [],
    );
  }

  /// Get unsynced perimeter checks
  Future<List<PerimeterCheckModel>> getUnsyncedPerimeterChecks({
    int? guardId,
    int? limit,
  }) async {
    return await safeRepositoryCall(
      () async {
        return await _offlineStorage.getUnsyncedPerimeterChecks(
          guardId: guardId,
          limit: limit,
        );
      },
      'getUnsyncedPerimeterChecks',
      fallbackValue: [],
    );
  }

  /// Clear roster cache
  Future<void> clearRosterCache() async {
    return await safeRepositoryCall(
      () async {
        await _offlineStorage.clearRosterCache();
        log('Roster cache cleared successfully');
      },
      'clearRosterCache',
    );
  }

  /// Clear all cache data
  Future<void> clearAllCache() async {
    return await safeRepositoryCall(
      () async {
        await _offlineStorage.clearAllCache();
        log('All cache data cleared successfully');
      },
      'clearAllCache',
    );
  }

  /// Get comprehensive sync report for UI/debugging
  Future<Map<String, dynamic>> getSyncReport() async {
    return await safeRepositoryCall(
      () async {
        final report = await _syncService.getSyncReport();

        // Add repository-level enhancements
        report['repositoryLevel'] = {
          'lastRefresh': DateTime.now().toIso8601String(),
          'connectivity': _connectivity.isConnected,
          'hasPendingSubmissions': await hasPendingSubmissions(),
        };

        return report;
      },
      'getSyncReport',
      fallbackValue: {
        'error': 'Failed to generate sync report',
        'generatedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get sync status for UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await safeRepositoryCall(
      () async {
        final status = await _syncService.getSyncStatus();

        // Show sync reminder if needed
        final daysSinceSync = status['daysSinceLastSync'] as int? ?? 0;
        if (daysSinceSync >= 5) {
          await _notificationService.showSyncRequiredNotification(daysSinceSync);
        }

        return status;
      },
      'getSyncStatus',
      fallbackValue: {
        'pendingSubmissions': 0,
        'unsyncedMovements': 0,
        'unsyncedPerimeterChecks': 0,
        'daysSinceLastSync': 999,
        'isSyncRequired': true,
        'isConnected': false,
        'isSyncing': false,
      },
    );
  }

  /// Get storage usage with notifications if needed
  Future<Map<String, dynamic>> getStorageUsage() async {
    return await safeRepositoryCall(
      () async {
        final usage = await _offlineStorage.getComprehensiveStorageStats();

        // Check if storage is getting full (example threshold)
        final databaseSizeMB = double.tryParse(usage['databaseSizeMB'] as String? ?? '0') ?? 0;
        if (databaseSizeMB > 100) {
          // 100MB threshold
          await _notificationService.showStorageWarningNotification(databaseSizeMB);
        }

        return usage;
      },
      'getStorageUsage',
      fallbackValue: {},
    );
  }

  /// Show checkpoint completion notification
  Future<void> showCheckpointCompletionNotification({
    required String checkpointName,
    required String siteName,
  }) async {
    return await safeRepositoryCall(
      () async {
        await _notificationService.showCheckpointCompletionAlert(
          checkpointName: checkpointName,
          siteName: siteName,
        );
        log('Checkpoint completion notification shown: $checkpointName at $siteName');
      },
      'showCheckpointCompletionNotification',
    );
  }

  /// Show position alert for static duty
  Future<void> showPositionAlert({
    required String message,
    required bool isReturnAlert,
  }) async {
    return await safeRepositoryCall(
      () async {
        await _notificationService.showPositionAlert(
          message: message,
          isReturnAlert: isReturnAlert,
        );
        log('Position alert shown: $message');
      },
      'showPositionAlert',
    );
  }

  /// Show battery alert
  Future<void> showBatteryAlert({
    required String message,
    required int batteryLevel,
  }) async {
    return await safeRepositoryCall(
      () async {
        await _notificationService.showBatteryAlert(
          message: message,
          batteryLevel: batteryLevel,
        );
        log('Battery alert shown: $message (Battery: $batteryLevel%)');
      },
      'showBatteryAlert',
    );
  }

  /// Show emergency notification
  Future<void> showEmergencyNotification({
    required String title,
    required String message,
    Map<String, dynamic>? payload,
  }) async {
    return await safeRepositoryCall(
      () async {
        await _notificationService.showEmergencyNotification(
          title: title,
          message: message,
          payload: payload,
        );
        log('Emergency notification shown: $title');
      },
      'showEmergencyNotification',
    );
  }

  /// Cancel duty notifications for a specific roster user
  Future<void> cancelDutyNotifications(List<int> notificationIds) async {
    return await safeRepositoryCall(
      () async {
        for (final id in notificationIds) {
          await _notificationService.cancelNotification(id);
        }
        log('Cancelled ${notificationIds.length} duty notifications');
      },
      'cancelDutyNotifications',
    );
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

  /// Check if there are pending submissions
  Future<bool> hasPendingSubmissions() async {
    return await safeRepositoryCall(
      () async {
        final count = await _offlineStorage.getPendingSubmissionsCount();
        return count > 0;
      },
      'hasPendingSubmissions',
      fallbackValue: false,
    );
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
      return rosterUser.startsAt.isAfter(now) && rosterUser.startsAt.isBefore(next24Hours);
    }).toList();
  }

  /// Check connectivity status
  bool get isConnected => _connectivity.isConnected;

  /// Get connectivity stream
  Stream<bool> get connectivityStream => _connectivity.connectivityStream;

  /// Private helper methods

  /// Get authentication token with error handling
  Future<String> _getAuthToken() async {
    final token = await AuthManager().getToken();
    if (token == null) {
      throw  AuthException(
        message: AppConstants.sessionExpiredMessage,
        statusCode: ApiConstants.unauthorizedCode,
      );
    }
    return token;
  }

  /// Schedule duty notifications for upcoming duties in roster
  Future<void> _scheduleDutyNotificationsFromRoster(RosterResponseModel rosterResponse) async {
    return await safeRepositoryCall(
      () async {
        final now = DateTime.now();
        final upcomingDuties = rosterResponse.data.where((rosterUser) {
          // Only schedule for duties that haven't started yet
          return rosterUser.startsAt.isAfter(now);
        }).toList();

        for (final rosterUser in upcomingDuties) {
          final scheduledIds = await _notificationService.scheduleDutyNotifications(
            rosterUser: rosterUser,
            site: rosterUser.site,
          );

          if (scheduledIds.isNotEmpty) {
            log('Scheduled ${scheduledIds.length} notifications for duty at ${rosterUser.site.name}');
          }
        }
      },
      'scheduleDutyNotificationsFromRoster',
    );
  }

  /// Check sync status and show reminder if needed
  Future<void> _checkAndShowSyncReminder() async {
    return await safeRepositoryCall(
      () async {
        final syncStatus = await _syncService.getSyncStatus();
        final daysSinceSync = syncStatus['daysSinceLastSync'] as int? ?? 0;

        // Show sync reminder based on days since last sync
        if (daysSinceSync >= 5) {
          await _notificationService.showSyncRequiredNotification(daysSinceSync);
          log('Sync reminder shown for $daysSinceSync days since last sync');
        }
      },
      'checkAndShowSyncReminder',
    );
  }

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
            endIndex > cachedData.data.length ? cachedData.data.length : endIndex,
          )
        : <RosterUserModel>[];

    return RosterResponseModel(
      data: paginatedItems,
      links: cachedData.links,
      meta: cachedData.meta,
    );
  }

  /// Show appropriate sync notifications
  Future<void> _showSyncNotification(SyncResult result) async {
    return await safeRepositoryCall(
      () async {
        if (result.isCompleteSuccess) {
          // Use enhanced notification with timing if available
          final duration = result.formattedDuration;
          if (duration != 'Unknown') {
            await _notificationService.showSyncCompletedWithDetailsNotification(
              result.successCount,
              result.failureCount,
              duration,
            );
          } else {
            await _notificationService.showSyncCompletedNotification(
              result.successCount,
              result.failureCount,
            );
          }
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
      },
      'showSyncNotification',
    );
  }

  /// Log detailed sync results for monitoring
  Future<void> _logSyncResult(SyncResult result) async {
    return await safeRepositoryCall(
      () async {
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
      },
      'logSyncResult',
    );
  }

  /// Get detailed sync statistics
  Future<Map<String, dynamic>> getSyncStatistics() async {
    return await safeRepositoryCall(
      () async {
        return await _syncService.getSyncStatistics();
      },
      'getSyncStatistics',
      fallbackValue: {},
    );
  }

  /// Get sync history for UI display
  Future<List<Map<String, dynamic>>> getSyncHistory({int limit = 20}) async {
    return await safeRepositoryCall(
      () async {
        return await _syncService.getSyncHistory(limit: limit);
      },
      'getSyncHistory',
      fallbackValue: [],
    );
  }

  /// Export sync data for debugging/support
  Future<Map<String, dynamic>> exportSyncDataForDebug() async {
    return await safeRepositoryCall(
      () async {
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
      },
      'exportSyncDataForDebug',
      fallbackValue: {
        'error': 'Failed to export debug data',
        'exportedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStatistics() async {
    return await safeRepositoryCall(
      () async {
        return await _offlineStorage.getStorageStatistics();
      },
      'getStorageStatistics',
      fallbackValue: {},
    );
  }

  /// Clean old data
  Future<void> cleanOldData() async {
    return await safeRepositoryCall(
      () async {
        await _offlineStorage.cleanOldData();
        log('Old data cleaned successfully');
      },
      'cleanOldData',
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
      log('Error disposing RosterRepository: ${getUserFriendlyMessage(e)}');
    }
  }
}