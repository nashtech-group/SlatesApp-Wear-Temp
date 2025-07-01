import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/data/models/roster/roster_response_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_request_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';

class OfflineStorageService {
  static const String _rosterCachePrefix = 'roster_data_guard_';
  static const String _pendingSubmissionsKey = 'pending_submissions';
  static const String _lastSubmissionKey = 'last_submission';
  static const int _cacheValidityHours = 24;

  /// Cache roster data for offline access
  Future<void> cacheRosterData(int guardId, RosterResponseModel rosterResponse) async {
    try {
      final cacheKey = '$_rosterCachePrefix$guardId';
      final cacheData = {
        'data': rosterResponse.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'guardId': guardId,
      };
      
      await AuthManager().saveUserSpecificData(cacheKey, jsonEncode(cacheData));
      log('Roster data cached for guard $guardId');
    } catch (e) {
      log('Failed to cache roster data: $e');
      rethrow;
    }
  }

  /// Get cached roster data
  Future<RosterResponseModel?> getCachedRosterData(int guardId) async {
    try {
      final cacheKey = '$_rosterCachePrefix$guardId';
      final cachedDataString = await AuthManager().getUserSpecificData(cacheKey);
      
      if (cachedDataString == null) {
        return null;
      }
      
      final cachedData = jsonDecode(cachedDataString);
      final cacheTimestamp = DateTime.parse(cachedData['timestamp']);
      
      // Check if cache is still valid
      if (DateTime.now().difference(cacheTimestamp).inHours > _cacheValidityHours) {
        log('Cached roster data expired for guard $guardId');
        return null;
      }
      
      return RosterResponseModel.fromJson(cachedData['data']);
    } catch (e) {
      log('Failed to get cached roster data: $e');
      return null;
    }
  }

  /// Check if cached data exists and is valid
  Future<bool> hasCachedRosterData(int guardId) async {
    final cachedData = await getCachedRosterData(guardId);
    return cachedData != null;
  }

  /// Cache pending submission for later sync
  Future<void> cachePendingSubmission(ComprehensiveGuardDutyRequestModel submission) async {
    try {
      final pendingSubmissions = await getPendingSubmissions();
      
      // Add submission with metadata
      final submissionWithMeta = {
        'data': submission.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      pendingSubmissions.add(submissionWithMeta);
      
      final cacheData = {
        'submissions': pendingSubmissions,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await AuthManager().saveUserSpecificData(_pendingSubmissionsKey, jsonEncode(cacheData));
      log('Pending submission cached');
    } catch (e) {
      log('Failed to cache pending submission: $e');
      rethrow;
    }
  }

  /// Get all pending submissions
  Future<List<ComprehensiveGuardDutyRequestModel>> getPendingSubmissions() async {
    try {
      final cachedDataString = await AuthManager().getUserSpecificData(_pendingSubmissionsKey);
      
      if (cachedDataString == null) {
        return [];
      }
      
      final cachedData = jsonDecode(cachedDataString);
      final submissions = cachedData['submissions'] as List<dynamic>;
      
      return submissions
          .map((s) => ComprehensiveGuardDutyRequestModel.fromJson(s['data']))
          .toList();
    } catch (e) {
      log('Failed to get pending submissions: $e');
      return [];
    }
  }

  /// Remove a specific pending submission
  Future<void> removePendingSubmission(String submissionId) async {
    try {
      final cachedDataString = await AuthManager().getUserSpecificData(_pendingSubmissionsKey);
      
      if (cachedDataString == null) return;
      
      final cachedData = jsonDecode(cachedDataString);
      final submissions = (cachedData['submissions'] as List<dynamic>)
          .where((s) => s['id'] != submissionId)
          .toList();
      
      final updatedCacheData = {
        'submissions': submissions,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      await AuthManager().saveUserSpecificData(_pendingSubmissionsKey, jsonEncode(updatedCacheData));
      log('Pending submission removed: $submissionId');
    } catch (e) {
      log('Failed to remove pending submission: $e');
    }
  }

  /// Clear all pending submissions
  Future<void> clearPendingSubmissions() async {
    try {
      await AuthManager().saveUserSpecificData(_pendingSubmissionsKey, '');
      log('All pending submissions cleared');
    } catch (e) {
      log('Failed to clear pending submissions: $e');
    }
  }

  /// Get count of pending submissions
  Future<int> getPendingSubmissionsCount() async {
    try {
      final submissions = await getPendingSubmissions();
      return submissions.length;
    } catch (e) {
      return 0;
    }
  }

  /// Cache successful submission record
  Future<void> cacheSubmissionRecord(
    ComprehensiveGuardDutyRequestModel request,
    ComprehensiveGuardDutyResponseModel response,
  ) async {
    try {
      final recordData = {
        'request': request.toJson(),
        'response': response.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await AuthManager().saveUserSpecificData(_lastSubmissionKey, jsonEncode(recordData));
      log('Submission record cached');
    } catch (e) {
      log('Failed to cache submission record: $e');
    }
  }

  /// Clear all roster cache
  Future<void> clearRosterCache() async {
    try {
      await AuthManager().clearOfflineData();
      log('Roster cache cleared');
    } catch (e) {
      log('Failed to clear roster cache: $e');
    }
  }
}