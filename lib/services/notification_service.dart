import 'dart:developer';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  bool _isInitialized = false;
  int _nextNotificationId = 1000;

  // Notification categories
  static const String dutyReminderChannelId = 'duty_reminder_channel';
  static const String syncReminderChannelId = 'sync_reminder_channel';
  static const String checkpointChannelId = 'checkpoint_channel';
  static const String emergencyChannelId = 'emergency_channel';
  static const String systemChannelId = 'system_channel';
  static const String batteryChannelId = 'battery_channel';

  /// Initialize the notification service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Initialize local notifications
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        await _createNotificationChannels();
        await _requestPermissions();
        await _initializeFirebaseMessaging();
        _isInitialized = true;
        log('NotificationService initialized successfully');
        return true;
      }

      log('Failed to initialize local notifications');
      return false;
    } catch (e) {
      log('Failed to initialize NotificationService: $e');
      return false;
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Duty reminder channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          dutyReminderChannelId,
          'Duty Reminders',
          description: 'Notifications for upcoming duties and shift alerts',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Sync reminder channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          syncReminderChannelId,
          'Data Sync Reminders',
          description:
              'Critical notifications for data synchronization requirements',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Checkpoint channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          checkpointChannelId,
          'Checkpoint Alerts',
          description:
              'Notifications for checkpoint completion and position alerts',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );

      // Emergency channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          emergencyChannelId,
          'Emergency Alerts',
          description: 'Critical emergency notifications',
          importance: Importance.max,
          enableVibration: true,
          playSound: true,
        ),
      );

      // System channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          systemChannelId,
          'System Notifications',
          description: 'General system notifications and updates',
          importance: Importance.high,
          enableVibration: false,
          playSound: true,
        ),
      );

      // Battery channel
      await androidImplementation.createNotificationChannel(
        const AndroidNotificationChannel(
          batteryChannelId,
          'Battery Alerts',
          description: 'Battery status and charging reminders',
          importance: Importance.high,
          enableVibration: true,
          playSound: true,
        ),
      );
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    bool permissionGranted = true;

    // Request local notification permissions (Android 13+)
    final androidImplementation =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      permissionGranted =
          await androidImplementation.requestNotificationsPermission() ?? false;
    }

    // Request Firebase messaging permissions
    final firebaseSettings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    return permissionGranted &&
        firebaseSettings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Initialize Firebase messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is terminated
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Get FCM token
      final token = await _firebaseMessaging.getToken();
      log('FCM Token: $token');
    } catch (e) {
      log('Failed to initialize Firebase messaging: $e');
    }
  }

  /// Schedule duty reminder notifications for a roster user
  Future<List<int>> scheduleDutyNotifications({
    required RosterUserModel rosterUser,
    required SiteModel site,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return [];
    }

    try {
      final scheduledIds = <int>[];
      final siteName = site.name;
      final dutyStartTime = rosterUser.startsAt;
      final dutyEndTime = rosterUser.endsAt;

      // 24-hour reminder
      final twentyFourHoursBefore =
          dutyStartTime.subtract(const Duration(days: 1));
      if (twentyFourHoursBefore.isAfter(DateTime.now())) {
        final id24h = _nextNotificationId++;
        await _scheduleNotification(
          id: id24h,
          title: 'Shift Reminder',
          body: 'Tomorrow at ${_formatTime(dutyStartTime)} at $siteName',
          scheduledDate: twentyFourHoursBefore,
          channelId: dutyReminderChannelId,
          payload: {
            'type': 'duty_reminder_24h',
            'rosterId': rosterUser.id,
            'siteId': site.id,
            'siteName': siteName,
            'dutyTime': dutyStartTime.toIso8601String(),
          },
        );
        scheduledIds.add(id24h);
      }

      // 30-minute battery check reminder
      final thirtyMinutesBefore =
          dutyStartTime.subtract(const Duration(minutes: 30));
      if (thirtyMinutesBefore.isAfter(DateTime.now())) {
        final id30m = _nextNotificationId++;
        await _scheduleNotification(
          id: id30m,
          title: 'Battery Check & Shift Alert',
          body:
              'Ensure your device is fully charged. Duty starts in 30 minutes at $siteName',
          scheduledDate: thirtyMinutesBefore,
          channelId: batteryChannelId,
          payload: {
            'type': 'battery_check',
            'rosterId': rosterUser.id,
            'siteId': site.id,
            'siteName': siteName,
            'dutyTime': dutyStartTime.toIso8601String(),
          },
        );
        scheduledIds.add(id30m);
      }

      // 5-minute reminder
      final fiveMinutesBefore =
          dutyStartTime.subtract(const Duration(minutes: 5));
      if (fiveMinutesBefore.isAfter(DateTime.now())) {
        final id5m = _nextNotificationId++;
        await _scheduleNotification(
          id: id5m,
          title: 'Shift Alert',
          body: 'Your duty begins in 5 minutes at $siteName',
          scheduledDate: fiveMinutesBefore,
          channelId: dutyReminderChannelId,
          payload: {
            'type': 'duty_reminder_5m',
            'rosterId': rosterUser.id,
            'siteId': site.id,
            'siteName': siteName,
            'dutyTime': dutyStartTime.toIso8601String(),
          },
        );
        scheduledIds.add(id5m);
      }

      // Duty start notification
      if (dutyStartTime.isAfter(DateTime.now())) {
        final idStart = _nextNotificationId++;
        await _scheduleNotification(
          id: idStart,
          title: 'Duty Started',
          body:
              '$siteName | Period: ${_formatTime(dutyStartTime)} - ${_formatTime(dutyEndTime)}',
          scheduledDate: dutyStartTime,
          channelId: dutyReminderChannelId,
          payload: {
            'type': 'duty_start',
            'rosterId': rosterUser.id,
            'siteId': site.id,
            'siteName': siteName,
            'dutyTime': dutyStartTime.toIso8601String(),
            'action': 'open_site_map',
          },
        );
        scheduledIds.add(idStart);
      }

      log('Scheduled ${scheduledIds.length} duty notifications for $siteName');
      return scheduledIds;
    } catch (e) {
      log('Failed to schedule duty notifications: $e');
      return [];
    }
  }

  /// Show sync reminder notification based on days since last sync
  Future<void> showSyncRequiredNotification(int daysSinceSync) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String title;
      String message;
      Importance importance;

      if (daysSinceSync >= 7) {
        title = 'Critical - Data Sync Required';
        message = AppConstants.noOfflineDataMessage;
        importance = Importance.max;
      } else if (daysSinceSync >= 6) {
        title = 'Sync Required';
        message = 'Please connect to internet within 24 hours';
        importance = Importance.high;
      } else {
        title = 'Sync Recommended';
        message = 'Connect to WiFi to upload duty performance data';
        importance = Importance.high;
      }

      await showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.syncReminder,
        channelId: syncReminderChannelId,
        importance: importance,
        payload: {
          'type': AppConstants.dutyReminderNotification,
          'daysSinceSync': daysSinceSync,
          'priority': daysSinceSync >= 7 ? 'critical' : 'normal',
        },
      );

      log('Sync notification shown: $message');
    } catch (e) {
      log('Failed to show sync notification: $e');
    }
  }

  /// Show sync completed notification
  Future<void> showSyncCompletedNotification(
      int successCount, int failureCount) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String message;

      if (failureCount == 0) {
        message = AppConstants.syncSuccessMessage;
      } else {
        message =
            'Sync completed with $failureCount failures. $successCount items synced successfully.';
      }

      await showLocalNotification(
        title: 'Data Sync Completed',
        body: message,
        type: NotificationType.system,
        channelId: systemChannelId,
        payload: {
          'type': AppConstants.systemUpdateNotification,
          'successCount': successCount,
          'failureCount': failureCount,
        },
      );

      log('Sync completed notification shown: $message');
    } catch (e) {
      log('Failed to show sync completed notification: $e');
    }
  }

  /// Show checkpoint completion notification
  Future<void> showCheckpointCompletionAlert({
    required String checkpointName,
    required String siteName,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Checkpoint Completed',
        body: '$checkpointName at $siteName',
        type: NotificationType.checkpointComplete,
        channelId: checkpointChannelId,
        payload: {
          'type': 'checkpoint_complete',
          'checkpointName': checkpointName,
          'siteName': siteName,
        },
      );

      log('Checkpoint completion notification shown: $checkpointName');
    } catch (e) {
      log('Failed to show checkpoint completion notification: $e');
    }
  }

  /// Show position alert for static duty
  Future<void> showPositionAlert({
    required String message,
    required bool isReturnAlert,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: isReturnAlert ? 'Return to Position' : 'Position Alert',
        body: message,
        type: NotificationType.positionAlert,
        channelId: checkpointChannelId,
        importance: Importance.max,
        payload: {
          'type': 'position_alert',
          'isReturnAlert': isReturnAlert,
        },
      );

      log('Position alert shown: $message');
    } catch (e) {
      log('Failed to show position alert: $e');
    }
  }

  /// Show offline mode notification
  Future<void> showOfflineModeNotification() async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Offline Mode',
        body: 'App is in offline mode. Some features may be limited.',
        type: NotificationType.system,
        channelId: systemChannelId,
        payload: {
          'type': AppConstants.offlineModeNotification,
        },
      );

      log('Offline mode notification shown');
    } catch (e) {
      log('Failed to show offline mode notification: $e');
    }
  }

  /// Show battery alert
  Future<void> showBatteryAlert({
    required String message,
    required int batteryLevel,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      // Determine importance based on battery level and app constants
      Importance importance = Importance.high;
      if (batteryLevel <= AppConstants.criticalBatteryThreshold) {
        importance = Importance.max;
      } else if (batteryLevel <= AppConstants.lowBatteryThreshold) {
        importance = Importance.high;
      }

      await showLocalNotification(
        title: 'Battery Alert',
        body: message,
        type: NotificationType.batteryAlert,
        channelId: batteryChannelId,
        importance: importance,
        payload: {
          'type': AppConstants.batteryLowNotification,
          'batteryLevel': batteryLevel,
          'isCritical': batteryLevel <= AppConstants.criticalBatteryThreshold,
        },
      );

      log('Battery alert shown: $message');
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
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.emergency,
        channelId: emergencyChannelId,
        importance: Importance.max,
        payload: {
          'type': AppConstants.emergencyAlertNotification,
          ...?payload,
        },
      );

      log('Emergency notification shown: $title');
    } catch (e) {
      log('Failed to show emergency notification: $e');
    }
  }

  /// Show notification when sync starts
  Future<void> showSyncStartedNotification() async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Data Sync Started',
        body: 'Synchronizing data with server...',
        type: NotificationType.system,
        channelId: syncReminderChannelId,
        payload: {
          'type': 'sync_started',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Sync started notification shown');
    } catch (e) {
      log('Failed to show sync started notification: $e');
    }
  }

  /// Show notification for sync retry
  Future<void> showSyncRetryNotification() async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Retrying Data Sync',
        body: 'Attempting to sync failed submissions...',
        type: NotificationType.system,
        channelId: syncReminderChannelId,
        payload: {
          'type': 'sync_retry',
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Sync retry notification shown');
    } catch (e) {
      log('Failed to show sync retry notification: $e');
    }
  }

  /// Show notification for partial sync success
  Future<void> showSyncPartialSuccessNotification(
    int successCount,
    int failureCount,
  ) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Partial Sync Complete',
        body:
            '$successCount items synced, $failureCount failed. Will retry automatically.',
        type: NotificationType.system,
        channelId: syncReminderChannelId,
        importance: Importance.high,
        payload: {
          'type': 'sync_partial_success',
          'successCount': successCount,
          'failureCount': failureCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Partial sync success notification shown: $successCount success, $failureCount failed');
    } catch (e) {
      log('Failed to show partial sync success notification: $e');
    }
  }

  /// Show notification for sync failure
  Future<void> showSyncFailedNotification(
    String message,
    int failureCount,
  ) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Data Sync Failed',
        body: '$failureCount items failed to sync. $message',
        type: NotificationType.syncReminder,
        channelId: syncReminderChannelId,
        importance: Importance.high,
        payload: {
          'type': 'sync_failed',
          'failureCount': failureCount,
          'message': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Sync failed notification shown: $message');
    } catch (e) {
      log('Failed to show sync failed notification: $e');
    }
  }

  /// Show notification when data cleanup is completed
  Future<void> showDataCleanupCompletedNotification(int itemsCleared) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String message;
      if (itemsCleared == 0) {
        message = 'No old data found to clean up.';
      } else if (itemsCleared == 1) {
        message = 'Cleaned up old data to free up storage space.';
      } else {
        message = 'Cleared $itemsCleared items to free up storage space.';
      }

      await showLocalNotification(
        title: 'Data Cleanup Complete',
        body: message,
        type: NotificationType.system,
        channelId: systemChannelId,
        payload: {
          'type': 'data_cleanup_completed',
          'itemsCleared': itemsCleared,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Data cleanup completed notification shown: $itemsCleared items');
    } catch (e) {
      log('Failed to show data cleanup completed notification: $e');
    }
  }

  /// Show notification when data cleanup fails
  Future<void> showDataCleanupFailedNotification(String message) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: 'Data Cleanup Failed',
        body: 'Unable to clean up data: $message',
        type: NotificationType.system,
        channelId: systemChannelId,
        importance: Importance.high,
        payload: {
          'type': 'data_cleanup_failed',
          'errorMessage': message,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Data cleanup failed notification shown: $message');
    } catch (e) {
      log('Failed to show data cleanup failed notification: $e');
    }
  }

  /// Show storage warning notification
  Future<void> showStorageWarningNotification(double sizeMB) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String message;
      Importance importance;

      if (sizeMB > 200) {
        message =
            'App database is ${sizeMB.toStringAsFixed(1)}MB. Please clean old data immediately.';
        importance = Importance.max;
      } else if (sizeMB > 150) {
        message =
            'App database is ${sizeMB.toStringAsFixed(1)}MB. Consider cleaning old data soon.';
        importance = Importance.high;
      } else {
        message =
            'App database is ${sizeMB.toStringAsFixed(1)}MB. Consider cleaning old data.';
        importance = Importance.defaultImportance;
      }

      await showLocalNotification(
        title: 'Storage Warning',
        body: message,
        type: NotificationType.system,
        channelId: systemChannelId,
        importance: importance,
        payload: {
          'type': 'storage_warning',
          'databaseSizeMB': sizeMB,
          'isCritical': sizeMB > 200,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Storage warning notification shown: ${sizeMB.toStringAsFixed(1)}MB');
    } catch (e) {
      log('Failed to show storage warning notification: $e');
    }
  }

  /// Show notification for specific sync completion with timing details
  Future<void> showSyncCompletedWithDetailsNotification(
    int successCount,
    int failureCount,
    String duration,
  ) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String message;
      NotificationType type;
      Importance importance;

      if (failureCount == 0) {
        message = 'Successfully synced $successCount items in $duration';
        type = NotificationType.system;
        importance = Importance.defaultImportance;
      } else if (successCount > 0) {
        message =
            'Synced $successCount items, $failureCount failed in $duration';
        type = NotificationType.syncReminder;
        importance = Importance.high;
      } else {
        message = 'All $failureCount items failed to sync in $duration';
        type = NotificationType.syncReminder;
        importance = Importance.high;
      }

      await showLocalNotification(
        title: 'Sync Complete',
        body: message,
        type: type,
        channelId: failureCount == 0 ? systemChannelId : syncReminderChannelId,
        importance: importance,
        payload: {
          'type': 'sync_completed_detailed',
          'successCount': successCount,
          'failureCount': failureCount,
          'duration': duration,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Detailed sync completion notification shown: $message');
    } catch (e) {
      log('Failed to show detailed sync completion notification: $e');
    }
  }

  /// Show progress notification for long-running sync operations
  Future<void> showSyncProgressNotification(
    int current,
    int total,
    String operation,
  ) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      final percentage = total > 0 ? ((current / total) * 100).round() : 0;

      await showLocalNotification(
        title: 'Syncing Data ($percentage%)',
        body: '$operation: $current of $total items processed',
        type: NotificationType.system,
        channelId: syncReminderChannelId,
        importance: Importance.low, // Low importance for progress notifications
        payload: {
          'type': 'sync_progress',
          'current': current,
          'total': total,
          'percentage': percentage,
          'operation': operation,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Sync progress notification shown: $current/$total ($percentage%)');
    } catch (e) {
      log('Failed to show sync progress notification: $e');
    }
  }

  /// Clear all sync-related notifications
  Future<void> clearSyncNotifications() async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      // Get all pending notifications
      final pendingNotifications = await getPendingNotifications();

      // Cancel sync-related notifications based on payload
      int cancelledCount = 0;
      for (final notification in pendingNotifications) {
        if (notification.payload != null) {
          final payload = _decodePayload(notification.payload!);
          final type = payload['type'] as String?;

          if (type != null && _isSyncRelatedNotification(type)) {
            await cancelNotification(notification.id);
            cancelledCount++;
          }
        }
      }

      log('Cleared $cancelledCount sync-related notifications');
    } catch (e) {
      log('Failed to clear sync notifications: $e');
    }
  }

  /// Show critical sync error that requires user attention
  Future<void> showCriticalSyncErrorNotification(
    String title,
    String message,
  ) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      await showLocalNotification(
        title: title,
        body: message,
        type: NotificationType.emergency,
        channelId: emergencyChannelId,
        importance: Importance.max,
        payload: {
          'type': 'critical_sync_error',
          'errorTitle': title,
          'errorMessage': message,
          'requiresUserAction': true,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );

      log('Critical sync error notification shown: $title');
    } catch (e) {
      log('Failed to show critical sync error notification: $e');
    }
  }

  /// Enhanced sync completed notification (replacement for existing method)
  /// This enhances your existing showSyncCompletedNotification method
  Future<void> showEnhancedSyncCompletedNotification({
    required int successCount,
    required int failureCount,
    String? duration,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      String message;
      String title;
      NotificationType type;
      Importance importance;

      if (failureCount == 0 && successCount > 0) {
        title = 'Data Sync Completed';
        message = duration != null
            ? 'Successfully synced $successCount items in $duration'
            : AppConstants.syncSuccessMessage;
        type = NotificationType.system;
        importance = Importance.defaultImportance;
      } else if (failureCount == 0 && successCount == 0) {
        title = 'Sync Complete';
        message = 'No new data to sync';
        type = NotificationType.system;
        importance = Importance.low;
      } else if (successCount > 0) {
        title = 'Partial Sync Complete';
        message = duration != null
            ? 'Synced $successCount items, $failureCount failed in $duration'
            : 'Sync completed with $failureCount failures. $successCount items synced successfully.';
        type = NotificationType.syncReminder;
        importance = Importance.high;
      } else {
        title = 'Sync Failed';
        message = duration != null
            ? 'All $failureCount items failed to sync in $duration'
            : 'Sync failed. $failureCount items could not be synchronized.';
        type = NotificationType.syncReminder;
        importance = Importance.high;
      }

      final payload = {
        'type': AppConstants.systemUpdateNotification,
        'successCount': successCount,
        'failureCount': failureCount,
        'timestamp': DateTime.now().toIso8601String(),
        if (duration != null) 'duration': duration,
        if (additionalData != null) ...additionalData,
      };

      await showLocalNotification(
        title: title,
        body: message,
        type: type,
        channelId: failureCount > 0 ? syncReminderChannelId : systemChannelId,
        importance: importance,
        payload: payload,
      );

      log('Enhanced sync completed notification shown: $message');
    } catch (e) {
      log('Failed to show enhanced sync completed notification: $e');
    }
  }

  /// Check if a notification type is sync-related
  bool _isSyncRelatedNotification(String type) {
    const syncTypes = {
      'sync_started',
      'sync_retry',
      'sync_partial_success',
      'sync_failed',
      'sync_completed_detailed',
      'sync_progress',
      'critical_sync_error',
      AppConstants.dutyReminderNotification, // Your existing constant
      AppConstants.systemUpdateNotification, // Your existing constant
    };

    return syncTypes.contains(type);
  }

  /// Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    required NotificationType type,
    required String channelId,
    Importance importance = Importance.defaultImportance,
    Map<String, dynamic>? payload,
  }) async {
    if (!_isInitialized) {
      log('NotificationService not initialized');
      return;
    }

    try {
      final id = _nextNotificationId++;

      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: importance,
        priority: _getPriority(importance),
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'general',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload != null ? _encodePayload(payload) : null,
      );

      log('Local notification shown: $title');
    } catch (e) {
      log('Failed to show local notification: $e');
    }
  }

  /// Schedule a notification for a future time
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String channelId,
    Map<String, dynamic>? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) {
      log('Cannot schedule notification in the past: $scheduledDate');
      return;
    }

    try {
      final androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        categoryIdentifier: 'general',
      );

      final notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload != null ? _encodePayload(payload) : null,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // FIXED: Removed uiLocalNotificationDateInterpretation parameter
        // This parameter has been removed in newer versions of the plugin
      );

      log('Notification scheduled: $title for ${scheduledDate.toString()}');
    } catch (e) {
      log('Failed to schedule notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    try {
      await _localNotifications.cancel(id);
      log('Cancelled notification: $id');
    } catch (e) {
      log('Failed to cancel notification $id: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _localNotifications.cancelAll();
      log('Cancelled all notifications');
    } catch (e) {
      log('Failed to cancel all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _localNotifications.pendingNotificationRequests();
    } catch (e) {
      log('Failed to get pending notifications: $e');
      return [];
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        final data = _decodePayload(payload);
        log('Notification tapped with payload: $data');

        // Handle different notification types
        final type = data['type'] as String?;
        switch (type) {
          case 'duty_start':
            // Open site map
            _handleDutyStartNotification(data);
            break;
          case 'checkpoint_complete':
            // Show checkpoint details
            _handleCheckpointNotification(data);
            break;
          case 'sync_reminder':
            // Open sync settings
            _handleSyncReminderNotification(data);
            break;
          case 'emergency':
            // Handle emergency notification
            _handleEmergencyNotification(data);
            break;
          case 'sync_started':
          case 'sync_retry':
          case 'sync_progress':
            _handleSyncProgressNotification(data);
            break;
          case 'sync_partial_success':
          case 'sync_failed':
          case 'critical_sync_error':
            _handleSyncErrorNotification(data);
            break;
          case 'data_cleanup_completed':
          case 'data_cleanup_failed':
            _handleDataCleanupNotification(data);
            break;
          case 'storage_warning':
            _handleStorageWarningNotification(data);
            break;
          case 'sync_completed_detailed':
            _handleDetailedSyncNotification(data);
            break;
          default:
            log('Unknown notification type: $type');
        }
      }
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  /// Handle duty start notification tap
  void _handleDutyStartNotification(Map<String, dynamic> data) {
    // Implementation would navigate to site map
    log('Handling duty start notification: ${data['siteName']}');
  }

  /// Handle checkpoint notification tap
  void _handleCheckpointNotification(Map<String, dynamic> data) {
    // Implementation would show checkpoint details
    log('Handling checkpoint notification: ${data['checkpointName']}');
  }

  /// Handle sync reminder notification tap
  void _handleSyncReminderNotification(Map<String, dynamic> data) {
    // Implementation would open sync settings
    log('Handling sync reminder notification');
  }

  /// Handle emergency notification tap
  void _handleEmergencyNotification(Map<String, dynamic> data) {
    // Implementation would open emergency details
    log('Handling emergency notification');
  }

   /// Handle sync progress notification tap
  void _handleSyncProgressNotification(Map<String, dynamic> data) {
    // Implementation would show sync progress details or open sync screen
    log('Handling sync progress notification: ${data['operation']}');
  }

  /// Handle sync error notification tap
  void _handleSyncErrorNotification(Map<String, dynamic> data) {
    // Implementation would show sync error details or retry options
    log('Handling sync error notification: ${data['type']}');
  }

  /// Handle data cleanup notification tap
  void _handleDataCleanupNotification(Map<String, dynamic> data) {
    // Implementation would open storage management screen
    log('Handling data cleanup notification: ${data['type']}');
  }

  /// Handle storage warning notification tap
  void _handleStorageWarningNotification(Map<String, dynamic> data) {
    // Implementation would open storage settings
    final sizeMB = data['databaseSizeMB'];
    log('Handling storage warning notification: ${sizeMB}MB');
  }

  /// Handle detailed sync notification tap
  void _handleDetailedSyncNotification(Map<String, dynamic> data) {
    // Implementation would show detailed sync results
    final successCount = data['successCount'];
    final failureCount = data['failureCount'];
    log('Handling detailed sync notification: $successCount success, $failureCount failed');
  }

  /// Handle foreground Firebase messages
  void _handleForegroundMessage(RemoteMessage message) {
    log('Received foreground message: ${message.messageId}');

    // Show local notification for Firebase message
    if (message.notification != null) {
      showLocalNotification(
        title: message.notification!.title ?? 'Notification',
        body: message.notification!.body ?? '',
        type: NotificationType.system,
        channelId: systemChannelId,
        payload: message.data,
      );
    }
  }

  /// Handle notification tap from Firebase
  void _handleNotificationTap(RemoteMessage message) {
    log('App opened from notification: ${message.messageId}');
    // Handle navigation based on message data
  }

  /// Get channel name from ID
  String _getChannelName(String channelId) {
    switch (channelId) {
      case dutyReminderChannelId:
        return 'Duty Reminders';
      case syncReminderChannelId:
        return 'Data Sync Reminders';
      case checkpointChannelId:
        return 'Checkpoint Alerts';
      case emergencyChannelId:
        return 'Emergency Alerts';
      case systemChannelId:
        return 'System Notifications';
      case batteryChannelId:
        return 'Battery Alerts';
      default:
        return 'General';
    }
  }

  /// Get channel description from ID
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case dutyReminderChannelId:
        return 'Notifications for upcoming duties and shift alerts';
      case syncReminderChannelId:
        return 'Critical notifications for data synchronization requirements';
      case checkpointChannelId:
        return 'Notifications for checkpoint completion and position alerts';
      case emergencyChannelId:
        return 'Critical emergency notifications';
      case systemChannelId:
        return 'General system notifications and updates';
      case batteryChannelId:
        return 'Battery status and charging reminders';
      default:
        return 'General notifications';
    }
  }

  /// Convert importance to priority
  Priority _getPriority(Importance importance) {
    switch (importance) {
      case Importance.min:
        return Priority.min;
      case Importance.low:
        return Priority.low;
      case Importance.defaultImportance:
        return Priority.defaultPriority;
      case Importance.high:
        return Priority.high;
      case Importance.max:
        return Priority.max;
      default:
        return Priority.defaultPriority;
    }
  }

  /// Encode payload to string
  String _encodePayload(Map<String, dynamic> payload) {
    try {
      return payload.entries.map((e) => '${e.key}=${e.value}').join('&');
    } catch (e) {
      log('Failed to encode payload: $e');
      return '';
    }
  }

  /// Decode payload from string
  Map<String, dynamic> _decodePayload(String payload) {
    try {
      final result = <String, dynamic>{};
      for (final pair in payload.split('&')) {
        final parts = pair.split('=');
        if (parts.length == 2) {
          result[parts[0]] = parts[1];
        }
      }
      return result;
    } catch (e) {
      log('Failed to decode payload: $e');
      return {};
    }
  }

  /// Format time for display
  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Dispose the service
  void dispose() {
    log('NotificationService disposed');
  }
}

/// Background message handler for Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  log('Handling background message: ${message.messageId}');
  // Handle background message
}
