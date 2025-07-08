import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/models/sites/site_model.dart';
import 'package:slates_app_wear/services/notification_service.dart';
import '../../core/error/bloc_error_mixin.dart';
import '../../core/error/error_handler.dart';

part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> 
    with BlocErrorMixin<NotificationEvent, NotificationState> {
  final NotificationService _notificationService;
  
  List<AppNotification> _notificationHistory = [];
  int _nextNotificationId = 1000;

  NotificationBloc({
    NotificationService? notificationService,
  })  : _notificationService = notificationService ?? NotificationService(),
        super(NotificationInitial()) {
    
    on<InitializeNotifications>(_onInitializeNotifications);
    on<ScheduleDutyNotifications>(_onScheduleDutyNotifications);
    on<ShowLocalNotification>(_onShowLocalNotification);
    on<ShowSyncReminder>(_onShowSyncReminder);
    on<ShowSyncCompleted>(_onShowSyncCompleted);
    on<ShowCheckpointCompletionAlert>(_onShowCheckpointCompletionAlert);
    on<ShowPositionAlert>(_onShowPositionAlert);
    on<ShowBatteryAlert>(_onShowBatteryAlert);
    on<ShowEmergencyAlert>(_onShowEmergencyAlert);
    on<ShowOfflineModeAlert>(_onShowOfflineModeAlert);
    on<AddNotificationToHistory>(_onAddNotificationToHistory);
    on<MarkNotificationAsRead>(_onMarkNotificationAsRead);
    on<MarkAllNotificationsAsRead>(_onMarkAllNotificationsAsRead);
    on<DeleteNotification>(_onDeleteNotification);
    on<ClearAllNotifications>(_onClearAllNotifications);
    on<GetNotificationHistory>(_onGetNotificationHistory);
    on<CancelScheduledNotification>(_onCancelScheduledNotification);
    on<CancelAllScheduledNotifications>(_onCancelAllScheduledNotifications);
    on<GetPendingNotifications>(_onGetPendingNotifications);
  }

  @override
  NotificationState createDefaultErrorState(BlocErrorInfo errorInfo) {
    return NotificationError(errorInfo: errorInfo);
  }

  Future<void> _onInitializeNotifications(
    InitializeNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());
      
      final initialized = await _notificationService.initialize();
      
      if (initialized) {
        emit(const NotificationInitialized(permissionGranted: true));
        log('NotificationBloc: Service initialized successfully');
      } else {
        handleError(
          'Failed to initialize notification service',
          emit,
          context: 'Initialize Notifications',
          customErrorState: (errorInfo) => NotificationError(
            errorInfo: errorInfo.copyWith(
              message: 'Failed to initialize notification service',
              canRetry: true,
            ),
          ),
        );
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Initialize Notifications',
      );
    }
  }

  Future<void> _onScheduleDutyNotifications(
    ScheduleDutyNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      emit(NotificationLoading());
      
      final scheduledIds = await _notificationService.scheduleDutyNotifications(
        rosterUser: event.rosterUser,
        site: event.site,
      );
      
      if (scheduledIds.isNotEmpty) {
        emit(NotificationScheduled(
          message: 'Scheduled ${scheduledIds.length} duty notifications for ${event.site.name}',
          scheduledIds: scheduledIds,
        ));
        
        // Add to history for each scheduled notification
        for (final id in scheduledIds) {
          final notification = _createDutyNotificationRecord(
            id: id.toString(),
            rosterUser: event.rosterUser,
            site: event.site,
          );
          _notificationHistory.insert(0, notification);
        }
        
        _trimHistory();
        log('NotificationBloc: Scheduled ${scheduledIds.length} duty notifications');
      } else {
        handleError(
          'No notifications were scheduled',
          emit,
          context: 'Schedule Duty Notifications',
          additionalData: {
            'rosterId': event.rosterUser.id,
            'siteId': event.site.id,
          },
          customErrorState: (errorInfo) => NotificationError(
            errorInfo: errorInfo.copyWith(
              message: 'No notifications were scheduled',
              canRetry: true,
            ),
          ),
        );
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Schedule Duty Notifications',
        additionalData: {
          'rosterId': event.rosterUser.id,
          'siteId': event.site.id,
        },
      );
    }
  }

  Future<void> _onShowLocalNotification(
    ShowLocalNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showLocalNotification(
        title: event.title,
        body: event.body,
        type: event.type,
        channelId: _getChannelIdForType(event.type),
        importance: event.importance ?? Importance.defaultImportance,
        payload: event.payload,
      );

      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: event.title,
        body: event.body,
        type: event.type,
        timestamp: DateTime.now(),
        payload: event.payload,
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Local notification shown: ${event.title}');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Local Notification',
        additionalData: {
          'title': event.title,
          'type': event.type.toString(),
        },
      );
    }
  }

  Future<void> _onShowSyncReminder(
    ShowSyncReminder event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showSyncRequiredNotification(event.daysSinceSync);
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: _getSyncReminderTitle(event.daysSinceSync),
        body: _getSyncReminderBody(event.daysSinceSync),
        type: NotificationType.syncReminder,
        timestamp: DateTime.now(),
        payload: {
          'daysSinceSync': event.daysSinceSync,
          'priority': event.daysSinceSync >= 7 ? 'critical' : 'normal',
        },
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Sync reminder shown for ${event.daysSinceSync} days');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Sync Reminder',
        additionalData: {'daysSinceSync': event.daysSinceSync},
      );
    }
  }

  Future<void> _onShowSyncCompleted(
    ShowSyncCompleted event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showSyncCompletedNotification(
        event.successCount,
        event.failureCount,
      );
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: 'Data Sync Completed',
        body: event.failureCount == 0 
          ? 'All data synchronized successfully' 
          : 'Sync completed with ${event.failureCount} failures',
        type: NotificationType.system,
        timestamp: DateTime.now(),
        payload: {
          'successCount': event.successCount,
          'failureCount': event.failureCount,
        },
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Sync completed notification shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Sync Completed',
        additionalData: {
          'successCount': event.successCount,
          'failureCount': event.failureCount,
        },
      );
    }
  }

  Future<void> _onShowCheckpointCompletionAlert(
    ShowCheckpointCompletionAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showCheckpointCompletionAlert(
        checkpointName: event.checkpointName,
        siteName: event.siteName,
      );
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: 'Checkpoint Completed',
        body: '${event.checkpointName} at ${event.siteName}',
        type: NotificationType.checkpointComplete,
        timestamp: DateTime.now(),
        payload: {
          'checkpointName': event.checkpointName,
          'siteName': event.siteName,
        },
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Checkpoint completion alert shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Checkpoint Completion Alert',
        additionalData: {
          'checkpointName': event.checkpointName,
          'siteName': event.siteName,
        },
      );
    }
  }

  Future<void> _onShowPositionAlert(
    ShowPositionAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showPositionAlert(
        message: event.message,
        isReturnAlert: event.isReturnAlert,
      );
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: event.isReturnAlert ? 'Return to Position' : 'Position Alert',
        body: event.message,
        type: NotificationType.positionAlert,
        timestamp: DateTime.now(),
        payload: {
          'isReturnAlert': event.isReturnAlert,
        },
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Position alert shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Position Alert',
        additionalData: {
          'message': event.message,
          'isReturnAlert': event.isReturnAlert,
        },
      );
    }
  }

  Future<void> _onShowBatteryAlert(
    ShowBatteryAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showBatteryAlert(
        message: event.message,
        batteryLevel: event.batteryLevel,
      );
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: 'Battery Alert',
        body: event.message,
        type: NotificationType.batteryAlert,
        timestamp: DateTime.now(),
        payload: {
          'batteryLevel': event.batteryLevel,
        },
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Battery alert shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Battery Alert',
        additionalData: {
          'batteryLevel': event.batteryLevel,
          'message': event.message,
        },
      );
    }
  }

  Future<void> _onShowEmergencyAlert(
    ShowEmergencyAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showEmergencyNotification(
        title: event.title,
        message: event.message,
        payload: event.payload,
      );
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: event.title,
        body: event.message,
        type: NotificationType.emergency,
        timestamp: DateTime.now(),
        payload: event.payload,
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Emergency alert shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Emergency Alert',
        additionalData: {
          'title': event.title,
          'message': event.message,
        },
      );
    }
  }

  Future<void> _onShowOfflineModeAlert(
    ShowOfflineModeAlert event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.showOfflineModeNotification();
      
      final notification = AppNotification(
        id: (_nextNotificationId++).toString(),
        title: 'Offline Mode',
        body: 'App is in offline mode. Some features may be limited.',
        type: NotificationType.system,
        timestamp: DateTime.now(),
        payload: const {'type': 'offline_mode'},
      );

      _notificationHistory.insert(0, notification);
      _trimHistory();

      emit(NotificationShown(notification: notification));
      log('NotificationBloc: Offline mode alert shown');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Show Offline Mode Alert',
      );
    }
  }

  Future<void> _onAddNotificationToHistory(
    AddNotificationToHistory event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      _notificationHistory.insert(0, event.notification);
      _trimHistory();

      emit(NotificationShown(notification: event.notification));
      log('NotificationBloc: Notification added to history');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Add Notification To History',
        additionalData: {'notificationId': event.notification.id},
      );
    }
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
          action: 'marked_read',
        ));
        log('NotificationBloc: Notification marked as read');
      } else {
        handleError(
          'Notification not found',
          emit,
          context: 'Mark Notification As Read',
          additionalData: {'notificationId': event.notificationId},
          customErrorState: (errorInfo) => NotificationError(
            errorInfo: errorInfo.copyWith(
              message: 'Notification not found',
              canRetry: false,
            ),
          ),
        );
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Mark Notification As Read',
        additionalData: {'notificationId': event.notificationId},
      );
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
      log('NotificationBloc: All notifications marked as read');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Mark All Notifications As Read',
      );
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
        log('NotificationBloc: Notification deleted');
      } else {
        handleError(
          'Notification not found',
          emit,
          context: 'Delete Notification',
          additionalData: {'notificationId': event.notificationId},
          customErrorState: (errorInfo) => NotificationError(
            errorInfo: errorInfo.copyWith(
              message: 'Notification not found',
              canRetry: false,
            ),
          ),
        );
      }
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Delete Notification',
        additionalData: {'notificationId': event.notificationId},
      );
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
      log('NotificationBloc: All notifications cleared');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Clear All Notifications',
      );
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
      log('NotificationBloc: Notification history loaded (${filtered.length} items)');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Notification History',
        additionalData: {
          'filterType': event.filterType?.toString(),
          'limit': event.limit,
        },
      );
    }
  }

  Future<void> _onCancelScheduledNotification(
    CancelScheduledNotification event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.cancelNotification(event.notificationId);
      
      emit(NotificationUpdated(
        notification: AppNotification(
          id: event.notificationId.toString(),
          title: 'Cancelled',
          body: 'Notification cancelled',
          type: NotificationType.system,
          timestamp: DateTime.now(),
        ),
        action: 'cancelled',
      ));
      log('NotificationBloc: Notification cancelled: ${event.notificationId}');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Cancel Scheduled Notification',
        additionalData: {'notificationId': event.notificationId},
      );
    }
  }

  Future<void> _onCancelAllScheduledNotifications(
    CancelAllScheduledNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      await _notificationService.cancelAllNotifications();
      
      emit(const NotificationBulkActionCompleted(
        action: 'cancelled_all',
        affectedCount: 0, // We don't know the exact count
      ));
      log('NotificationBloc: All scheduled notifications cancelled');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Cancel All Scheduled Notifications',
      );
    }
  }

  Future<void> _onGetPendingNotifications(
    GetPendingNotifications event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      
      emit(PendingNotificationsLoaded(
        pendingNotifications: pending,
        count: pending.length,
      ));
      log('NotificationBloc: Pending notifications loaded (${pending.length} items)');
    } catch (error) {
      handleError(
        error,
        emit,
        context: 'Get Pending Notifications',
      );
    }
  }

  // Helper methods

  String _getChannelIdForType(NotificationType type) {
    switch (type) {
      case NotificationType.dutyReminder:
        return NotificationService.dutyReminderChannelId;
      case NotificationType.batteryAlert:
        return NotificationService.batteryChannelId;
      case NotificationType.checkpointComplete:
        return NotificationService.checkpointChannelId;
      case NotificationType.emergency:
        return NotificationService.emergencyChannelId;
      case NotificationType.syncReminder:
        return NotificationService.syncReminderChannelId;
      case NotificationType.system:
        return NotificationService.systemChannelId;
      case NotificationType.positionAlert:
        return NotificationService.checkpointChannelId;
    }
  }

  String _getSyncReminderTitle(int daysSinceSync) {
    if (daysSinceSync >= 7) {
      return 'Critical - Data Sync Required';
    } else if (daysSinceSync >= 6) {
      return 'Sync Required';
    } else {
      return 'Sync Recommended';
    }
  }

  String _getSyncReminderBody(int daysSinceSync) {
    if (daysSinceSync >= 7) {
      return 'Immediate internet connection required to sync duty data';
    } else if (daysSinceSync >= 6) {
      return 'Please connect to internet within 24 hours';
    } else {
      return 'Connect to WiFi to upload duty performance data';
    }
  }

  AppNotification _createDutyNotificationRecord({
    required String id,
    required RosterUserModel rosterUser,
    required SiteModel site,
  }) {
    return AppNotification(
      id: id,
      title: 'Duty Scheduled',
      body: 'Notifications scheduled for ${site.name}',
      type: NotificationType.dutyReminder,
      timestamp: DateTime.now(),
      siteName: site.name,
      dutyTime: rosterUser.startsAt,
      payload: {
        'rosterId': rosterUser.id,
        'siteId': site.id,
        'siteName': site.name,
      },
    );
  }

  Map<NotificationType, int> _calculateTypeCounts() {
    final counts = <NotificationType, int>{};
    for (final notification in _notificationHistory) {
      counts[notification.type] = (counts[notification.type] ?? 0) + 1;
    }
    return counts;
  }

  void _trimHistory() {
    if (_notificationHistory.length > 100) {
      _notificationHistory = _notificationHistory.take(100).toList();
    }
  }

  // Public getters
  List<AppNotification> get notificationHistory => List.from(_notificationHistory);
  int get unreadCount => _notificationHistory.where((n) => !n.isRead).length;

  @override
  Future<void> close() {
    _notificationService.dispose();
    return super.close();
  }
}