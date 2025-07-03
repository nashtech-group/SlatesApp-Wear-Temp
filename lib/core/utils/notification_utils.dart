import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/services/date_service.dart';

/// Notification configuration constants 
class NotificationConfig {
  static const String appName = AppConstants.appTitle;
  
  // Notification IDs ranges
  static const int dutyNotificationIdStart = 1000;
  static const int syncNotificationIdStart = 2000;
  static const int checkpointNotificationIdStart = 3000;
  static const int batteryNotificationIdStart = 4000;
  static const int emergencyNotificationIdStart = 5000;
  static const int systemNotificationIdStart = 6000;
  
  // Notification limits
  static const int maxNotificationHistory = 100;
  static const int maxScheduledNotifications = 50;
  
  // Timing constants (in minutes) - 
  static const int dutyReminder24Hours = 1440;
  static const int dutyReminder30Minutes = AppConstants.checkInReminderMinutes;
  static const int dutyReminder5Minutes = 5;
  static const int batteryCheckTime = 30;
  
  // Sync reminder thresholds (in days)
  static const int syncRecommendedThreshold = 5;
  static const int syncRequiredThreshold = 6;
  static const int syncCriticalThreshold = 7;
  
  // Position monitoring 
  static const double positionToleranceMeters = AppConstants.minimumMovementDistance;
  static const int positionCheckIntervalSeconds = AppConstants.locationUpdateIntervalSeconds;
  
  // Battery thresholds 
  static const int lowBatteryThreshold = AppConstants.lowBatteryThreshold;
  static const int criticalBatteryThreshold = AppConstants.criticalBatteryThreshold;
  
  // Notification channels
  static const Map<String, NotificationChannelConfig> channels = {
    'duty_reminder': NotificationChannelConfig(
      id: 'duty_reminder_channel',
      name: 'Duty Reminders',
      description: 'Notifications for upcoming duties and shift alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ),
    'sync_reminder': NotificationChannelConfig(
      id: 'sync_reminder_channel',
      name: 'Data Sync Reminders',
      description: 'Critical notifications for data synchronization requirements',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    ),
    'checkpoint': NotificationChannelConfig(
      id: 'checkpoint_channel',
      name: 'Checkpoint Alerts',
      description: 'Notifications for checkpoint completion and position alerts',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ),
    'emergency': NotificationChannelConfig(
      id: 'emergency_channel',
      name: 'Emergency Alerts',
      description: 'Critical emergency notifications',
      importance: Importance.max,
      enableVibration: true,
      playSound: true,
    ),
    'system': NotificationChannelConfig(
      id: 'system_channel',
      name: 'System Notifications',
      description: 'General system notifications and updates',
      importance: Importance.high,
      enableVibration: false,
      playSound: true,
    ),
    'battery': NotificationChannelConfig(
      id: 'battery_channel',
      name: 'Battery Alerts',
      description: 'Battery status and charging reminders',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    ),
  };
}

/// Notification channel configuration
class NotificationChannelConfig {
  final String id;
  final String name;
  final String description;
  final Importance importance;
  final bool enableVibration;
  final bool playSound;
  final String? soundFile;

  const NotificationChannelConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.enableVibration,
    required this.playSound,
    this.soundFile,
  });
}

class NotificationUtils {
  // Use DateService instance for all date/time operations
  static final DateService _dateService = DateService();

  /// Generate duty notification messages based on timing
  static Map<String, String> getDutyNotificationMessages({
    required RosterUserModel rosterUser,
    required SiteModel site,
    required int minutesBefore,
  }) {
    final siteName = site.name;
    final dutyTime = rosterUser.startsAt;
    final endTime = rosterUser.endsAt;
    
    switch (minutesBefore) {
      case NotificationConfig.dutyReminder24Hours:
        return {
          'title': 'Shift Reminder',
          'body': 'Tomorrow at ${_dateService.formatTimeForDisplay(dutyTime)} at $siteName',
        };
      case NotificationConfig.dutyReminder30Minutes:
        return {
          'title': 'Battery Check & Shift Alert',
          'body': 'Ensure your device is fully charged. Duty starts in 30 minutes at $siteName',
        };
      case NotificationConfig.dutyReminder5Minutes:
        return {
          'title': 'Shift Alert',
          'body': 'Your duty begins in 5 minutes at $siteName',
        };
      case 0:
        return {
          'title': 'Duty Started',
          'body': '$siteName | Period: ${_dateService.formatTimeForDisplay(dutyTime)} - ${_dateService.formatTimeForDisplay(endTime)}',
        };
      default:
        return {
          'title': 'Duty Reminder',
          'body': '$siteName in $minutesBefore minutes',
        };
    }
  }

  /// Generate sync notification messages based on days since sync 
  static Map<String, String> getSyncNotificationMessages(int daysSinceSync) {
    if (daysSinceSync >= NotificationConfig.syncCriticalThreshold) {
      return {
        'title': 'Critical - Data Sync Required',
        'body': AppConstants.noOfflineDataMessage,
      };
    } else if (daysSinceSync >= NotificationConfig.syncRequiredThreshold) {
      return {
        'title': 'Sync Required',
        'body': 'Please connect to internet within 24 hours',
      };
    } else {
      return {
        'title': 'Sync Recommended',
        'body': 'Connect to WiFi to upload duty performance data',
      };
    }
  }

  /// Generate battery notification messages 
  static Map<String, String> getBatteryNotificationMessages({
    required int batteryLevel,
    required bool isDutyStartingSoon,
    required bool isOnDuty,
  }) {
    if (isDutyStartingSoon && batteryLevel < 90) {
      return {
        'title': 'Pre-Duty Battery Check',
        'body': 'Battery is at $batteryLevel%. Please charge to at least 90% before duty starts.',
      };
    } else if (isOnDuty && batteryLevel <= AppConstants.criticalBatteryThreshold) {
      return {
        'title': 'Critical Battery Alert',
        'body': 'Battery level is critically low ($batteryLevel%). Find a charging point immediately.',
      };
    } else if (batteryLevel <= AppConstants.lowBatteryThreshold) {
      return {
        'title': 'Low Battery',
        'body': 'Battery level is low ($batteryLevel%). Please charge your device.',
      };
    } else {
      return {
        'title': 'Battery Status',
        'body': 'Battery level is at $batteryLevel%.',
      };
    }
  }

  /// Generate position alert messages for static duty
  static Map<String, String> getPositionAlertMessages({
    required double distanceFromCheckpoint,
    required String checkpointName,
    required bool isReturnAlert,
  }) {
    if (isReturnAlert) {
      return {
        'title': 'Return to Position',
        'body': 'Please return to your designated checkpoint location: $checkpointName',
      };
    } else {
      return {
        'title': 'Position Alert',
        'body': 'You are ${distanceFromCheckpoint.toStringAsFixed(1)}m from $checkpointName',
      };
    }
  }

  /// Get notification icon based on type
  static IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.dutyReminder:
        return Icons.schedule;
      case NotificationType.batteryAlert:
        return Icons.battery_alert;
      case NotificationType.checkpointComplete:
        return Icons.check_circle;
      case NotificationType.emergency:
        return Icons.emergency;
      case NotificationType.syncReminder:
        return Icons.sync_problem;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.positionAlert:
        return Icons.location_on;
      default:
        return Icons.notifications;
    }
  }

  /// Get notification color based on type and priority
  static Color getNotificationColor(NotificationType type, {bool isUrgent = false}) {
    if (isUrgent) {
      return Colors.red;
    }
    
    switch (type) {
      case NotificationType.dutyReminder:
        return Colors.blue;
      case NotificationType.batteryAlert:
        return Colors.orange;
      case NotificationType.checkpointComplete:
        return Colors.green;
      case NotificationType.emergency:
        return Colors.red;
      case NotificationType.syncReminder:
        return Colors.amber;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.positionAlert:
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  /// Check if notification is urgent based on type and content 
  static bool isNotificationUrgent(AppNotification notification) {
    switch (notification.type) {
      case NotificationType.emergency:
        return true;
      case NotificationType.syncReminder:
        final daysSinceSync = notification.payload?['daysSinceSync'] as int? ?? 0;
        return daysSinceSync >= NotificationConfig.syncCriticalThreshold;
      case NotificationType.batteryAlert:
        final batteryLevel = notification.payload?['batteryLevel'] as int? ?? 100;
        return batteryLevel <= AppConstants.criticalBatteryThreshold;
      case NotificationType.positionAlert:
        return notification.payload?['isReturnAlert'] as bool? ?? false;
      default:
        return false;
    }
  }

  /// Calculate notification priority score for sorting
  static int getNotificationPriority(AppNotification notification) {
    int priority = 0;
    
    // Base priority by type
    switch (notification.type) {
      case NotificationType.emergency:
        priority += 1000;
        break;
      case NotificationType.syncReminder:
        priority += 800;
        break;
      case NotificationType.batteryAlert:
        priority += 600;
        break;
      case NotificationType.positionAlert:
        priority += 500;
        break;
      case NotificationType.dutyReminder:
        priority += 400;
        break;
      case NotificationType.checkpointComplete:
        priority += 200;
        break;
      case NotificationType.system:
        priority += 100;
        break;
    }
    
    // Boost urgent notifications
    if (isNotificationUrgent(notification)) {
      priority += 500;
    }
    
    // Boost unread notifications
    if (!notification.isRead) {
      priority += 100;
    }
    
    // Recency bonus (newer notifications get higher priority)
    final hoursSinceCreation = DateTime.now().difference(notification.timestamp).inHours;
    priority += (24 - hoursSinceCreation.clamp(0, 24)) * 10;
    
    return priority;
  }

  /// Sort notifications by priority
  static List<AppNotification> sortNotificationsByPriority(List<AppNotification> notifications) {
    final sorted = List<AppNotification>.from(notifications);
    sorted.sort((a, b) => getNotificationPriority(b).compareTo(getNotificationPriority(a)));
    return sorted;
  }

  /// Filter notifications by type
  static List<AppNotification> filterNotificationsByType(
    List<AppNotification> notifications,
    NotificationType type,
  ) {
    return notifications.where((notification) => notification.type == type).toList();
  }

  /// Filter unread notifications
  static List<AppNotification> filterUnreadNotifications(List<AppNotification> notifications) {
    return notifications.where((notification) => !notification.isRead).toList();
  }

  /// Filter urgent notifications
  static List<AppNotification> filterUrgentNotifications(List<AppNotification> notifications) {
    return notifications.where((notification) => isNotificationUrgent(notification)).toList();
  }

  /// Group notifications by date using DateService
  static Map<String, List<AppNotification>> groupNotificationsByDate(
    List<AppNotification> notifications,
  ) {
    final grouped = <String, List<AppNotification>>{};
    
    for (final notification in notifications) {
      String dateKey;
      final notificationDate = notification.timestamp;
      
      if (_dateService.isToday(notificationDate)) {
        dateKey = 'Today';
      } else if (_dateService.isYesterday(notificationDate)) {
        dateKey = 'Yesterday';
      } else {
        dateKey = _dateService.formatDateForLongDisplay(notificationDate);
      }
      
      grouped.putIfAbsent(dateKey, () => []).add(notification);
    }
    
    return grouped;
  }

  /// Get notification summary statistics
  static Map<String, dynamic> getNotificationStatistics(List<AppNotification> notifications) {
    final stats = <String, dynamic>{
      'total': notifications.length,
      'unread': filterUnreadNotifications(notifications).length,
      'urgent': filterUrgentNotifications(notifications).length,
      'byType': <String, int>{},
      'todaysCount': 0,
      'thisWeeksCount': 0,
    };
    
    final today = DateTime.now();
    final weekAgo = today.subtract(const Duration(days: 7));
    final todayStart = DateTime(today.year, today.month, today.day);
    
    for (final notification in notifications) {
      // Count by type
      final typeKey = notification.type.toString().split('.').last;
      stats['byType'][typeKey] = (stats['byType'][typeKey] as int? ?? 0) + 1;
      
      // Count today's notifications
      if (notification.timestamp.isAfter(todayStart)) {
        stats['todaysCount']++;
      }
      
      // Count this week's notifications
      if (notification.timestamp.isAfter(weekAgo)) {
        stats['thisWeeksCount']++;
      }
    }
    
    return stats;
  }

  /// Validate notification payload
  static bool isValidNotificationPayload(Map<String, dynamic>? payload) {
    if (payload == null) return true;
    
    // Check for required keys based on notification type
    if (payload.containsKey('type')) {
      final type = payload['type'] as String?;
      switch (type) {
        case 'duty_reminder_24h':
        case 'duty_reminder_5m':
        case 'duty_start':
          return payload.containsKey('rosterId') && 
                 payload.containsKey('siteId');
        case 'battery_check':
          return payload.containsKey('batteryLevel');
        case 'sync_reminder':
          return payload.containsKey('daysSinceSync');
        case 'checkpoint_complete':
          return payload.containsKey('checkpointName') && 
                 payload.containsKey('siteName');
        case 'position_alert':
          return payload.containsKey('isReturnAlert');
        default:
          return true;
      }
    }
    
    return true;
  }

  /// Create notification action buttons based on type
  static List<Map<String, String>> getNotificationActions(AppNotification notification) {
    final actions = <Map<String, String>>[];
    
    switch (notification.type) {
      case NotificationType.dutyReminder:
        if (notification.payload?['type'] == 'duty_start') {
          actions.add({'id': 'open_map', 'title': 'Open Site Map'});
        }
        actions.add({'id': 'view_details', 'title': 'View Details'});
        break;
      case NotificationType.syncReminder:
        actions.add({'id': 'sync_now', 'title': 'Sync Now'});
        actions.add({'id': 'view_sync_status', 'title': 'View Status'});
        break;
      case NotificationType.batteryAlert:
        actions.add({'id': 'battery_settings', 'title': 'Battery Settings'});
        break;
      case NotificationType.emergency:
        actions.add({'id': 'respond', 'title': 'Respond'});
        actions.add({'id': 'call_emergency', 'title': 'Call Emergency'});
        break;
      default:
        actions.add({'id': 'view_details', 'title': 'View Details'});
        break;
    }
    
    return actions;
  }

  // ===================================
  // DELEGATE METHODS TO DATESERVICE
  // ===================================
  
  /// Format time for notification display
  static String formatTime(DateTime dateTime) => _dateService.formatTimeForDisplay(dateTime);

  /// Format date for notification display
  static String formatDate(DateTime dateTime) => _dateService.formatDateForDisplay(dateTime);

  /// Format date and time for notification display
  static String formatDateTime(DateTime dateTime) => _dateService.formatDateTimeForDisplay(dateTime);

  /// Get relative time string (e.g., "in 2 hours", "5 minutes ago")
  static String getRelativeTimeString(DateTime dateTime) => _dateService.getRelativeTimeDescription(dateTime);

  /// Format notification timestamp with smart context
  static String formatNotificationTimestamp(DateTime timestamp) => _dateService.formatTimestampSmart(timestamp);
}