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
import 'package:slates_app_wear/data/models/site/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/site/site_model.dart';
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
  }) : _rosterProvider = rosterProvider,
       _offlineStorage = offlineStorage ?? OfflineStorageService(),
       _connectivity = connectivity ?? ConnectivityService(),
       _syncService = syncService ?? SyncService(),
       _dateService = dateService ?? DateService(),
       _notificationService = notificationService ?? NotificationService();

  /// Initialize repository and services
  Future<void> initialize() async {
    _syncService.initialize();
    await _syncService.scheduleSyncReminders();
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
          final responseData = await _rosterProvider.getRosterData(
            guardId: guardId,
            fromDate: dateToUse,
            token: token,
          );

          log('Roster response: $responseData');
          
          final decodedData = jsonDecode(responseData);
          
          if (decodedData.containsKey("errors") || 
              (decodedData.containsKey("status") && decodedData["status"] == "error")) {
            throw ApiErrorModel.fromJson(decodedData);
          }

          final rosterResponse = RosterResponseModel.fromJson(decodedData);
          
          // Cache for offline access
          await _offlineStorage.cacheRosterData(guardId, rosterResponse);

          return rosterResponse;
        } catch (e) {
          if (e is ApiErrorModel) rethrow;
          log('Online roster fetch failed, trying offline: $e');
        }
      }

      // Try offline cache
      final cachedData = await _offlineStorage.getCachedRosterData(guardId);
      if (cachedData != null) {
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
          final responseData = await _rosterProvider.submitComprehensiveGuardDuty(
            requestData: requestData,
            token: token,
          );

          log('Comprehensive guard duty response: $responseData');
          
          final decodedData = jsonDecode(responseData);
          
          if (decodedData.containsKey("errors") || 
              (decodedData.containsKey("status") && decodedData["status"] == "error")) {
            throw ApiErrorModel.fromJson(decodedData);
          }

          final response = ComprehensiveGuardDutyResponseModel.fromJson(decodedData);

          // Cache successful submission
          await _offlineStorage.cacheSubmissionRecord(requestData, response);

          return response;
        } catch (e) {
          if (e is ApiErrorModel) rethrow;
          log('Online submission failed, caching for offline sync: $e');
        }
      }

      // Cache for later sync
      await _offlineStorage.cachePendingSubmission(requestData);
      
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

  /// Submit only roster user status updates
  Future<ComprehensiveGuardDutyResponseModel> submitRosterUserUpdates({
    required List<RosterUserUpdateModel> updates,
  }) async {
    return await submitComprehensiveGuardDuty(rosterUpdates: updates);
  }

  /// Submit only guard movements
  Future<ComprehensiveGuardDutyResponseModel> submitGuardMovements({
    required List<GuardMovementModel> movements,
  }) async {
    return await submitComprehensiveGuardDuty(movements: movements);
  }

  /// Submit only perimeter checks
  Future<ComprehensiveGuardDutyResponseModel> submitPerimeterChecks({
    required List<PerimeterCheckModel> perimeterChecks,
  }) async {
    return await submitComprehensiveGuardDuty(perimeterChecks: perimeterChecks);
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
        final responseData = await _rosterProvider.getRosterDataPaginated(
          guardId: guardId,
          fromDate: dateToUse,
          token: token,
          page: page,
          perPage: perPage,
        );

        final decodedData = jsonDecode(responseData);
        
        if (decodedData.containsKey("errors") || 
            (decodedData.containsKey("status") && decodedData["status"] == "error")) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        return RosterResponseModel.fromJson(decodedData);
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
    return await _syncService.manualSync();
  }

  /// Check if there are pending submissions
  Future<bool> hasPendingSubmissions() async {
    final count = await _offlineStorage.getPendingSubmissionsCount();
    return count > 0;
  }

  /// Get sync status for UI
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _syncService.getSyncStatus();
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

  /// Clear all roster cache
  Future<void> clearRosterCache() async {
    await _offlineStorage.clearRosterCache();
  }

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
            endIndex > cachedData.data.length ? cachedData.data.length : endIndex,
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
    _syncService.dispose();
  }
}