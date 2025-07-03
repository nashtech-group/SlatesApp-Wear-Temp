import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/services/notification_service.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  final FlutterLocalNotificationsPlugin _localNotifications;
  
  List<AppNotification> _notificationHistory = [];
  int _nextNotificationId = 1000;

  NotificationBloc({
    NotificationService? notificationService,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _notificationService = notificationService ?? NotificationService(),
        _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin(),
        super(NotificationInitial()) {
    
    on<InitializeNotifications>(_onInitializeNotifications);
    on<ScheduleDutyNotifications>(_onScheduleDutyNotifications);
    on<ShowLocalNotification>(_onShowLocalNotification);
    on<ScheduleBatteryAlert>(_onScheduleBatteryAlert);
    on<ShowSyncReminder>(_onShowSyncReminder);
    on<ShowCheckpointCompletionAlert>(_onShowCheckpointCompletionAlert);
    on<ShowPositionAlert>(_onShowPositionAlert);
    on<AddNotificationToHistory>(_onAddNotificationToHistory);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<GetNotificationHistory>(_onGetNotificationHistory);
    on<CancelScheduledNotification>(_onCancelScheduledNotification);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      // Initialize local notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
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

      // Request permissions (Android 13+)
      bool permissionGranted = true;
      final androidImplementation = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidImplementation != null) {
        permissionGranted = await androidImplementation.requestPermission() ?? false;
      }

      emit(NotificationInitialized(permissionGranted: permissionGranted && (initialized ?? false)));

    } catch (e) {
      emit(NotificationError(message: 'Failed to initialize notifications: ${e.toString()}'));
    }
  }

  Future<void> _onScheduleDutyNotifications(
    ScheduleDutyNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final scheduledIds = <int>[];
      final siteName = event.site.name;
      final dutyStartTime = event.rosterUser.startsAt;
      
      // Schedule 24-hour reminder
      final twentyFourHoursBefore = dutyStartTime.subtract(const Duration(days: 1));
      if (twentyFourHoursBefore.isAfter(DateTime.now())) {
        final id24h = _nextNotificationId++;
        await _scheduleNotification(
          id: id24h,
          title: 'Shift Reminder',
          body: 'Tomorrow at ${_formatTime(dutyStartTime)} at $siteName',
          scheduledDate: twentyFourHoursBefore,
          type: NotificationType.dutyReminder,
          payload: {
            'type': 'duty_reminder_24h',
            'rosterId': event.rosterUser.id,
            'siteId': event.site.id,
          },
        );
        scheduledIds.add(id24h);
      }

      // Schedule 30-minute battery check reminder
      final thirtyMinutesBefore = dutyStartTime.subtract(const Duration(minutes: 30));
      if (thirtyMinutesBefore.isAfter(DateTime.now())) {
        final id30m = _nextNotificationId++;
        await _scheduleNotification(
          id: id30m,
          title: 'Battery Check & Shift Alert',
          body: 'Ensure your device is fully charged. Duty starts in 30 minutes at $siteName',
          scheduledDate: thirtyMinutesBefore,
          type: NotificationType.batteryAlert,
          payload: {
            'type': 'battery_check',
            'rosterId': event.rosterUser.id,
            'siteId': event.site.id,
          },
        );
        scheduledIds.add(id30m);
      }

      // Schedule 5-minute reminder
      final fiveMinutesBefore = dutyStartTime.subtract(const Duration(minutes: 5));
      if (fiveMinutesBefore.isAfter(DateTime.now())) {
        final id5m = _nextNotificationId++;
        await _scheduleNotification(
          id: id5m,
          title: 'Shift Alert',
          body: 'Your duty begins in 5 minutes at $siteName',
          scheduledDate: fiveMinutesBefore,
          type: NotificationType.dutyReminder,
          payload: {
            'type': 'duty_reminder_5m',
            'rosterId': event.rosterUser.id,
            'siteId': event.site.id,
          },
        );
        scheduledIds.add(id5m);
      }

      // Schedule duty start notification
      if (dutyStartTime.isAfter(DateTime.now())) {
        final idStart = _nextNotificationId++;
        await _scheduleNotification(
          id: idStart,
          title: 'Duty Started',
          body: '$siteName | Period: ${_formatTime(dutyStartTime)} - ${_formatTime(event.rosterUser.endsAt)}',
          scheduledDate: dutyStartTime,
          type: NotificationType.dutyReminder,
          payload: {
            'type': 'duty_start',
            'rosterId': event.rosterUser.id,
            'siteId': event.site.id,
            'action': 'open_site_map',
          },
        );
        scheduledIds.add(idStart);
      }

      emit(NotificationScheduled(
        message: 'Scheduled ${scheduledIds.length} duty notifications',
        scheduledIds: scheduledIds,
      ));

    } catch (e) {
      emit(NotificationError(message: 'Failed to schedule duty notifications: ${e.toString()}'));
    }
  }

  Future<void> _onShowLocalNotification(
    ShowLocalNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final id = _nextNotificationId++;
      
      await _localNotifications.show(
        id,
        event.title,
        event.body,
        _getNotificationDetails(event.type),
        payload: event.payload != null ? event.payload.toString() : null,
      );

      final notification = AppNotification(
        id: id.toString(),
        title: event.title,
        body: event.body,
        type: event.type,
        timestamp: DateTime.now(),
        payload: event.payload,
      );

      // Add to history
      _notificationHistory.insert(0, notification);
      if (_notificationHistory.length > 100) {
        _notificationHistory.removeLast();
      }

      emit(NotificationShown(notification: notification));

    } catch (e) {
      emit(NotificationError(message: 'Failed to show notification: ${e.toString()}'));
    }
  }

  Future<void> _onScheduleBatteryAlert(
    ScheduleBatteryAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      add(ScheduleBatteryAlert(
        dutyStartTime: event.dutyStartTime,
        siteName: event.siteName,
      ));
    } catch (e) {
      emit(NotificationError(message: 'Failed to schedule battery alert: ${e.toString()}'));
    }
  }

  Future<void> _onShowSyncReminder(
    ShowSyncReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      String message;
      String title;
      
      if (event.daysSinceSync >= 7) {
        title = 'Critical - Data Sync Required';
        message = 'Immediate internet connection required to sync duty data';
      } else if (event.daysSinceSync >= 6) {
        title = 'Sync Required';
        message = 'Please connect to internet within 24 hours';
      } else {
        title = 'Sync Recommended';
        message = 'Connect to WiFi to upload duty performance data';
      }

      add(ShowLocalNotification(
        title: title,
        body: message,
        type: NotificationType.syncReminder,
        payload: {
          'type': 'sync_reminder',
          'daysSinceSync': event.daysSinceSync,
          'priority': event.daysSinceSync >= 7 ? 'critical' : 'normal',
        },
      ));

    } catch (e) {
      emit(NotificationError(message: 'Failed to show sync reminder: ${e.toString()}'));
    }
  }

  Future<void> _onShowCheckpointCompletionAlert(
    ShowCheckpointCompletionAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      add(ShowLocalNotification(
        title: 'Checkpoint Completed',
        body: '${event.checkpointName} at ${event.siteName}',
        type: NotificationType.checkpointComplete,
        payload: {
          'type': 'checkpoint_complete',
          'checkpointName': event.checkpointName,
          'siteName': event.siteName,
        },
      ));
    } catch (e) {
      emit(NotificationError(message: 'Failed to show checkpoint completion alert: ${e.toString()}'));
    }
  }

  Future<void> _onShowPositionAlert(
    ShowPositionAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      add(ShowLocalNotification(
        title: event.isReturnAlert ? 'Return to Position' : 'Position Alert',
        body: event.message,
        type: NotificationType.positionAlert,
        payload: {
          'type': 'position_alert',
          'isReturnAlert': event.isReturnAlert,
        },
      ));
    } catch (e) {
      emit(NotificationError(message: 'Failed to show position alert: ${e.toString()}'));
    }
  }

  Future<void> _onAddNotificationToHistory(
    AddNotificationToHistory event,
    Emitter<NotificationState> emit,
  ) async {
    _notificationHistory.insert(0, event.notification);
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeLast();
    }

    emit(NotificationShown(notification: event.notification));
  }

  Future<void> _onMarkNotificationAsRead(
    MarkNotificationAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final index = _notificationHistory.indexWhere((n) => n.id == event.notificationId);
      if (index != -1) {
        _notificationHistory[index] = _notificationHistory[index].copyWith(isRead: true);
        
        emit(NotificationUpdated(
          notification: _notificationHistory[index],
          action: 'read',
        ));
      }
    } catch (e) {
      emit(NotificationError(message: 'Failed to mark notification as read: ${e.toString()}'));
    }
  }

  Future<void> _onMarkAllNotificationsAsRead(
    MarkAllNotificationsAsRead event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      for (int i = 0; i < _notificationHistory.length; i++) {
        _notificationHistory[i] = _notificationHistory[i].copyWith(isRead: true);
      }

      final unreadCount = _notificationHistory.where((n) => !n.isRead).length;
      final typeCounts = _calculateTypeCounts();

      emit(NotificationHistoryLoaded(
        notifications: List.from(_notificationHistory),
        unreadCount: unreadCount,
        typeCounts: typeCounts,
      ));
    } catch (e) {
      emit(NotificationError(message: 'Failed to mark all notifications as read: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteNotification(
    DeleteNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final index = _notificationHistory.indexWhere((n) => n.id == event.notificationId);
      if (index != -1) {
        final notification = _notificationHistory.removeAt(index);
        
        emit(NotificationUpdated(
          notification: notification,
          action: 'deleted',
        ));
      }
    } catch (e) {
      emit(NotificationError(message: 'Failed to delete notification: ${e.toString()}'));
    }
  }

  Future<void> _onClearAllNotifications(
    ClearAllNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _notificationHistory.clear();
      
      emit(const NotificationHistoryLoaded(
        notifications: [],
        unreadCount: 0,
        typeCounts: {},
      ));
    } catch (e) {
      emit(NotificationError(message: 'Failed to clear notifications: ${e.toString()}'));
    }
  }

  Future<void> _onGetNotificationHistory(
    GetNotificationHistory event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      List<AppNotification> filtered = _notificationHistory;
      
      if (event.filterType != null) {
        filtered = _notificationHistory.where((n) => n.type == event.filterType).toList();
      }
      
      if (event.limit != null && filtered.length > event.limit!) {
        filtered = filtered.take(event.limit!).toList();
      }

      final unreadCount = _notificationHistory.where((n) => !n.isRead).length;
      final typeCounts = _calculateTypeCounts();

      emit(NotificationHistoryLoaded(
        notifications: filtered,
        unreadCount: unreadCount,
        typeCounts: typeCounts,
      ));

    } catch (e) {
      emit(NotificationError(message: 'Failed to get notification history: ${e.toString()}'));
    }
  }

  Future<void> _onCancelScheduledNotification(
    CancelScheduledNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _localNotifications.cancel(event.notificationId);
      log('Cancelled notification ${event.notificationId}');
    } catch (e) {
      emit(NotificationError(message: 'Failed to cancel notification: ${e.toString()}'));
    }
  }

  // Helper Methods

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required NotificationType type,
    Map<String, dynamic>? payload,
  }) async {
    if (scheduledDate.isBefore(DateTime.now())) return;

    await _localNotifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      _getNotificationDetails(type),
      payload: payload?.toString(),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    log('Scheduled notification $id for ${scheduledDate.toString()}');
  }

  NotificationDetails _getNotificationDetails(NotificationType type) {
    const androidDetails = AndroidNotificationDetails(
      'slates_app_channel',
      'SlatesApp Notifications',
      channelDescription: 'Notifications for guard duties and app updates',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    try {
      final payload = response.payload;
      if (payload != null) {
        // Handle notification tap
        log('Notification tapped with payload: $payload');
        
        // Add logic to handle different notification types
        // For example, opening specific screens based on payload
      }
    } catch (e) {
      log('Error handling notification tap: $e');
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Map<NotificationType, int> _calculateTypeCounts() {
    final counts = <NotificationType, int>{};
    for (final notification in _notificationHistory) {
      counts[notification.type] = (counts[notification.type] ?? 0) + 1;
    }
    return counts;
  }

  // Public getters
  List<AppNotification> get notificationHistory => List.from(_notificationHistory);
  int get unreadCount => _notificationHistory.where((n) => !n.isRead).length;

  @override
  Future<void> close() {
    return super.close();
  }
}