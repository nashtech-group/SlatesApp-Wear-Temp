import 'dart:developer';
import 'package:slates_app_wear/core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Show sync reminder notification
  Future<void> showSyncRequiredNotification(int daysSinceSync) async {
    try {
      String message;
      
      if (daysSinceSync >= 7) {
        message = AppConstants.noOfflineDataMessage;
      } else if (daysSinceSync >= 6) {
        message = 'Sync required - Please connect to internet within 24 hours';
      } else {
        message = 'Sync recommended - Connect to WiFi to upload duty performance data';
      }

      // In a real implementation, you would use flutter_local_notifications
      // For now, we'll just log
      log('Sync notification: $message');
      
      // TODO: Implement actual notification using flutter_local_notifications
      // await _scheduleNotification(
      //   id: daysSinceSync >= 7 ? 1001 : (daysSinceSync >= 6 ? 1002 : 1003),
      //   title: 'Data Sync Required',
      //   body: message,
      //   category: 'sync_reminder',
      // );
    } catch (e) {
      log('Failed to show sync notification: $e');
    }
  }

  /// Show sync completed notification
  Future<void> showSyncCompletedNotification(int successCount, int failureCount) async {
    try {
      String message;
      
      if (failureCount == 0) {
        message = AppConstants.syncSuccessMessage;
      } else {
        message = 'Sync completed with $failureCount failures. $successCount items synced successfully.';
      }

      log('Sync completed notification: $message');
      
      // TODO: Implement actual notification
      // await _scheduleNotification(
      //   id: 1004,
      //   title: 'Data Sync Completed',
      //   body: message,
      //   category: 'sync_status',
      // );
    } catch (e) {
      log('Failed to show sync completed notification: $e');
    }
  }

  /// Show duty reminder notification
  Future<void> showDutyReminderNotification({
    required String siteName,
    required DateTime dutyTime,
    required int minutesBefore,
  }) async {
    try {
      String message;
      
      if (minutesBefore == 1440) { // 24 hours
        message = 'Shift reminder - Tomorrow at ${_formatTime(dutyTime)} at $siteName';
      } else if (minutesBefore == 30) {
        message = 'Battery Check & Shift Alert - Ensure your device is fully charged. Duty starts in 30 minutes at $siteName';
      } else if (minutesBefore == 5) {
        message = 'Shift alert - Your duty begins in 5 minutes at $siteName';
      } else {
        message = 'Duty reminder - $siteName in $minutesBefore minutes';
      }

      log('Duty reminder notification: $message');
      
      // TODO: Implement actual notification
    } catch (e) {
      log('Failed to show duty reminder notification: $e');
    }
  }

  /// Show offline mode notification
  Future<void> showOfflineModeNotification() async {
    try {
      const message = 'App is in offline mode. Some features may be limited.';
      log('Offline mode notification: $message');
      
      // TODO: Implement actual notification
    } catch (e) {
      log('Failed to show offline mode notification: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// lib/services/date_service.dart
