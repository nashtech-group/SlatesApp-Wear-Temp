import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/data/models/api_error_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/models/roster/guard_movement_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_update_model.dart';
import 'package:slates_app_wear/data/models/site/perimeter_check_model.dart';
import 'package:slates_app_wear/data/models/site/site_model.dart';

import 'roster_provider.dart';

class RosterRepository {
  final RosterProvider rosterProvider;

  RosterRepository({required this.rosterProvider});

  /// Get roster data for a guard from current date
  /// Returns roster data with extracted sites list
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

      // Use provided date or default to today
      final dateToUse = fromDate ?? _getTodayFormattedDate();

      final responseData = await rosterProvider.getRosterData(
        guardId: guardId,
        fromDate: dateToUse,
        token: token,
      );

      log('Roster response: $responseData');

      final decodedData = jsonDecode(responseData);

      // Check for errors in response
      if (decodedData.containsKey("errors") ||
          (decodedData.containsKey("status") &&
              decodedData["status"] == "error")) {
        throw ApiErrorModel.fromJson(decodedData);
      }

      final rosterResponse = RosterResponseModel.fromJson(decodedData);

      // Cache roster data for offline access
      await _cacheRosterData(guardId, rosterResponse);

      return rosterResponse;
    } catch (e) {
      // If online fetch fails, try offline cache
      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Network error')) {
        return await _getOfflineRosterData(guardId);
      }
      rethrow;
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

      final dateToUse = fromDate ?? _getTodayFormattedDate();

      final responseData = await rosterProvider.getRosterDataPaginated(
        guardId: guardId,
        fromDate: dateToUse,
        token: token,
        page: page,
        perPage: perPage,
      );

      log('Paginated roster response: $responseData');

      final decodedData = jsonDecode(responseData);

      if (decodedData.containsKey("errors") ||
          (decodedData.containsKey("status") &&
              decodedData["status"] == "error")) {
        throw ApiErrorModel.fromJson(decodedData);
      }

      return RosterResponseModel.fromJson(decodedData);
    } catch (e) {
      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Network error')) {
        // For pagination, return cached data if available
        final cachedData = await _getOfflineRosterData(guardId);
        // Apply pagination to cached data
        return _paginateCachedData(cachedData, page, perPage);
      }
      rethrow;
    }
  }

  /// Submit comprehensive guard duty data (roster updates, movements, perimeter checks)
  Future<ComprehensiveGuardDutyResponseModel> submitComprehensiveGuardDuty({
    List<RosterUserUpdateModel>? rosterUpdates,
    List<GuardMovementModel>? movements,
    List<PerimeterCheckModel>? perimeterChecks,
  }) async {
    try {
      final token = await AuthManager().getToken();

      if (token == null) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No authentication token available',
        );
      }

      final requestData = ComprehensiveGuardDutyRequestModel(
        updates: rosterUpdates,
        movements: movements,
        perimeterChecks: perimeterChecks,
      );

      // Validate that we have some data to submit
      if (!requestData.hasAnyData) {
        throw ApiErrorModel(
          status: 'error',
          message: 'No data provided for submission',
        );
      }

      final responseData = await rosterProvider.submitComprehensiveGuardDuty(
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

      // Cache successful submission for sync tracking
      await _cacheSubmissionRecord(requestData, response);

      return response;
    } catch (e) {
      // If submission fails due to network, cache for later sync
      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Network error')) {
        final requestData = ComprehensiveGuardDutyRequestModel(
          updates: rosterUpdates,
          movements: movements,
          perimeterChecks: perimeterChecks,
        );

        await _cachePendingSubmission(requestData);

        throw ApiErrorModel(
          status: 'error',
          message: 'No internet connection. Data cached for sync when online.',
        );
      }
      rethrow;
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

  /// Get today's roster status for a guard
  Future<RosterResponseModel> getTodaysRosterStatus({
    required int guardId,
  }) async {
    return await getRosterData(
      guardId: guardId,
      fromDate: _getTodayFormattedDate(),
    );
  }

  /// Get upcoming roster duties (from today onwards)
  Future<RosterResponseModel> getUpcomingRosterDuties({
    required int guardId,
  }) async {
    return await getRosterData(
      guardId: guardId,
      fromDate: _getTodayFormattedDate(),
    );
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

      final responseData = await rosterProvider.getRosterDataForDateRange(
        guardId: guardId,
        fromDate: fromDate,
        toDate: toDate,
        token: token,
      );

      log('Date range roster response: $responseData');

      final decodedData = jsonDecode(responseData);

      if (decodedData.containsKey("errors") ||
          (decodedData.containsKey("status") &&
              decodedData["status"] == "error")) {
        throw ApiErrorModel.fromJson(decodedData);
      }

      return RosterResponseModel.fromJson(decodedData);
    } catch (e) {
      if (e.toString().contains('No internet connection') ||
          e.toString().contains('Network error')) {
        return await _getOfflineRosterData(guardId);
      }
      rethrow;
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
    final now = DateTime.now();

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

  /// Sync pending submissions when internet is available
  Future<List<ComprehensiveGuardDutyResponseModel>>
      syncPendingSubmissions() async {
    try {
      final pendingSubmissions = await _getPendingSubmissions();
      final results = <ComprehensiveGuardDutyResponseModel>[];

      for (final submission in pendingSubmissions) {
        try {
          final result = await submitComprehensiveGuardDuty(
            rosterUpdates: submission.updates,
            movements: submission.movements,
            perimeterChecks: submission.perimeterChecks,
          );
          results.add(result);

          // Remove successfully synced submission
          await _removePendingSubmission(submission);
        } catch (e) {
          log('Failed to sync submission: $e');
          // Keep in pending list for next sync attempt
        }
      }

      return results;
    } catch (e) {
      log('Sync pending submissions failed: $e');
      return [];
    }
  }

  /// Check if there are pending submissions waiting for sync
  Future<bool> hasPendingSubmissions() async {
    try {
      final pending = await _getPendingSubmissions();
      return pending.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get count of pending submissions
  Future<int> getPendingSubmissionsCount() async {
    try {
      final pending = await _getPendingSubmissions();
      return pending.length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all cached roster data
  Future<void> clearRosterCache() async {
    try {
      await AuthManager().clearOfflineData();
      log('Roster cache cleared');
    } catch (e) {
      log('Failed to clear roster cache: $e');
    }
  }

  // Private helper methods

  /// Get today's date in dd-MM-yyyy format
  String _getTodayFormattedDate() {
    final today = DateTime.now();
    return '${today.day.toString().padLeft(2, '0')}-${today.month.toString().padLeft(2, '0')}-${today.year}';
  }

  /// Cache roster data for offline access
  Future<void> _cacheRosterData(
      int guardId, RosterResponseModel rosterResponse) async {
    try {
      final cacheKey = 'roster_data_guard_$guardId';
      final cacheData = {
        'data': rosterResponse.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'guardId': guardId,
      };

      await AuthManager().saveUserSpecificData(cacheKey, jsonEncode(cacheData));
      log('Roster data cached for guard $guardId');
    } catch (e) {
      log('Failed to cache roster data: $e');
    }
  }

  /// Get offline roster data from cache
  Future<RosterResponseModel> _getOfflineRosterData(int guardId) async {
    try {
      final cacheKey = 'roster_data_guard_$guardId';
      final cachedDataString =
          await AuthManager().getUserSpecificData(cacheKey);

      if (cachedDataString == null) {
        throw ApiErrorModel(
          status: 'error',
          message:
              'No offline roster data available. Please connect to internet.',
        );
      }

      final cachedData = jsonDecode(cachedDataString);
      final cacheTimestamp = DateTime.parse(cachedData['timestamp']);

      // Check if cache is still valid (within 24 hours)
      if (DateTime.now().difference(cacheTimestamp).inHours > 24) {
        throw ApiErrorModel(
          status: 'error',
          message:
              'Cached roster data is outdated. Please connect to internet.',
        );
      }

      return RosterResponseModel.fromJson(cachedData['data']);
    } catch (e) {
      if (e is ApiErrorModel) rethrow;

      throw ApiErrorModel(
        status: 'error',
        message: 'Failed to load offline roster data.',
      );
    }
  }

  /// Cache pending submission for later sync
  Future<void> _cachePendingSubmission(
      ComprehensiveGuardDutyRequestModel submission) async {
    try {
      final pendingSubmissions = await _getPendingSubmissions();
      pendingSubmissions.add(submission);

      final cacheData = {
        'submissions': pendingSubmissions.map((s) => s.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AuthManager()
          .saveUserSpecificData('pending_submissions', jsonEncode(cacheData));
      log('Pending submission cached');
    } catch (e) {
      log('Failed to cache pending submission: $e');
    }
  }

  /// Get pending submissions from cache
  Future<List<ComprehensiveGuardDutyRequestModel>>
      _getPendingSubmissions() async {
    try {
      final cachedDataString =
          await AuthManager().getUserSpecificData('pending_submissions');

      if (cachedDataString == null) {
        return [];
      }

      final cachedData = jsonDecode(cachedDataString);
      final submissions = cachedData['submissions'] as List<dynamic>;

      return submissions
          .map((s) => ComprehensiveGuardDutyRequestModel.fromJson(s))
          .toList();
    } catch (e) {
      log('Failed to get pending submissions: $e');
      return [];
    }
  }

  /// Remove a pending submission after successful sync
  Future<void> _removePendingSubmission(
      ComprehensiveGuardDutyRequestModel submission) async {
    try {
      final pendingSubmissions = await _getPendingSubmissions();
      // Note: This is a simple removal based on JSON comparison
      // In production, you might want a more sophisticated matching mechanism
      pendingSubmissions.removeWhere(
          (s) => jsonEncode(s.toJson()) == jsonEncode(submission.toJson()));

      final cacheData = {
        'submissions': pendingSubmissions.map((s) => s.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AuthManager()
          .saveUserSpecificData('pending_submissions', jsonEncode(cacheData));
      log('Pending submission removed');
    } catch (e) {
      log('Failed to remove pending submission: $e');
    }
  }

  /// Cache successful submission record
  Future<void> _cacheSubmissionRecord(
    ComprehensiveGuardDutyRequestModel request,
    ComprehensiveGuardDutyResponseModel response,
  ) async {
    try {
      final recordData = {
        'request': request.toJson(),
        'response': response.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Save last submission record
      await AuthManager()
          .saveUserSpecificData('last_submission', jsonEncode(recordData));

      // Update last sync time
      await AuthManager().saveLastOnlineSync(DateTime.now());

      log('Submission record cached');
    } catch (e) {
      log('Failed to cache submission record: $e');
    }
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
            endIndex > cachedData.data.length
                ? cachedData.data.length
                : endIndex,
          )
        : <RosterUserModel>[];

    // Create a simple paginated response (this is a basic implementation)
    return RosterResponseModel(
      data: paginatedItems,
      links: cachedData.links, // Keep original links
      meta: cachedData
          .meta, // Keep original meta - in production you'd update this
    );
  }

  /// Check if guard has internet connection and sync requirements
  Future<bool> shouldSyncData() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();

      if (lastSync == null) {
        return true; // Never synced, should sync
      }

      final daysSinceSync = DateTime.now().difference(lastSync).inDays;

      // Sync if it's been more than 5 days (based on app requirements)
      return daysSinceSync >= AppConstants.maxOfflineDataAgeHours ~/ 24;
    } catch (e) {
      return true; // Default to sync if uncertain
    }
  }

  /// Get days since last sync for UI display
  Future<int> getDaysSinceLastSync() async {
    try {
      final lastSync = await AuthManager().getLastOnlineSync();

      if (lastSync == null) {
        return 999; // Large number to indicate never synced
      }

      return DateTime.now().difference(lastSync).inDays;
    } catch (e) {
      return 999;
    }
  }
}
