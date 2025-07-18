part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize notification system
class InitializeNotifications extends NotificationEvent {
  const InitializeNotifications();
}

/// Schedule notifications for a duty
class ScheduleDutyNotifications extends NotificationEvent {
  final RosterUserModel rosterUser;
  final SiteModel site;

  const ScheduleDutyNotifications({
    required this.rosterUser,
    required this.site,
  });

  @override
  List<Object?> get props => [rosterUser, site];
}

/// Show a local notification
class ShowLocalNotification extends NotificationEvent {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;
  final Importance? importance;

  const ShowLocalNotification({
    required this.title,
    required this.body,
    required this.type,
    this.payload,
    this.importance,
  });

  @override
  List<Object?> get props => [title, body, type, payload, importance];
}

/// Show sync reminder notification
class ShowSyncReminder extends NotificationEvent {
  final int daysSinceSync;

  const ShowSyncReminder({required this.daysSinceSync});

  @override
  List<Object?> get props => [daysSinceSync];
}

/// Show sync completed notification
class ShowSyncCompleted extends NotificationEvent {
  final int successCount;
  final int failureCount;

  const ShowSyncCompleted({
    required this.successCount,
    required this.failureCount,
  });

  @override
  List<Object?> get props => [successCount, failureCount];
}

/// Show checkpoint completion alert
class ShowCheckpointCompletionAlert extends NotificationEvent {
  final String checkpointName;
  final String siteName;

  const ShowCheckpointCompletionAlert({
    required this.checkpointName,
    required this.siteName,
  });

  @override
  List<Object?> get props => [checkpointName, siteName];
}

/// Show position alert notification
class ShowPositionAlert extends NotificationEvent {
  final String message;
  final bool isReturnAlert;

  const ShowPositionAlert({
    required this.message,
    required this.isReturnAlert,
  });

  @override
  List<Object?> get props => [message, isReturnAlert];
}

/// Show battery alert notification
class ShowBatteryAlert extends NotificationEvent {
  final String message;
  final int batteryLevel;

  const ShowBatteryAlert({
    required this.message,
    required this.batteryLevel,
  });

  @override
  List<Object?> get props => [message, batteryLevel];
}

/// Show emergency alert notification
class ShowEmergencyAlert extends NotificationEvent {
  final String title;
  final String message;
  final Map<String, dynamic>? payload;

  const ShowEmergencyAlert({
    required this.title,
    required this.message,
    this.payload,
  });

  @override
  List<Object?> get props => [title, message, payload];
}

/// Show offline mode alert
class ShowOfflineModeAlert extends NotificationEvent {
  const ShowOfflineModeAlert();
}

/// Add notification to history
class AddNotificationToHistory extends NotificationEvent {
  final AppNotification notification;

  const AddNotificationToHistory({required this.notification});

  @override
  List<Object?> get props => [notification];
}

/// Mark notification as read
class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Mark all notifications as read
class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

/// Delete a notification
class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Clear all notifications
class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

/// Get notification history
class GetNotificationHistory extends NotificationEvent {
  final NotificationType? filterType;
  final int? limit;

  const GetNotificationHistory({this.filterType, this.limit});

  @override
  List<Object?> get props => [filterType, limit];
}

/// Cancel a scheduled notification
class CancelScheduledNotification extends NotificationEvent {
  final int notificationId;

  const CancelScheduledNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

/// Cancel all scheduled notifications
class CancelAllScheduledNotifications extends NotificationEvent {
  const CancelAllScheduledNotifications();
}

/// Get pending notifications
class GetPendingNotifications extends NotificationEvent {
  const GetPendingNotifications();
}

/// Clear current notification error state 
class ClearNotificationError extends NotificationEvent {
  const ClearNotificationError();
}