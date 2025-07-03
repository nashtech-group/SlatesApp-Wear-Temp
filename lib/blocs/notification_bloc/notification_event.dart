part of 'notification_bloc.dart';

abstract class NotificationEvent extends Equatable {
  const NotificationEvent();

  @override
  List<Object?> get props => [];
}

class InitializeNotifications extends NotificationEvent {
  const InitializeNotifications();
}

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

class ShowLocalNotification extends NotificationEvent {
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic>? payload;

  const ShowLocalNotification({
    required this.title,
    required this.body,
    required this.type,
    this.payload,
  });

  @override
  List<Object?> get props => [title, body, type, payload];
}

class ScheduleBatteryAlert extends NotificationEvent {
  final DateTime dutyStartTime;
  final String siteName;

  const ScheduleBatteryAlert({
    required this.dutyStartTime,
    required this.siteName,
  });

  @override
  List<Object?> get props => [dutyStartTime, siteName];
}

class ShowSyncReminder extends NotificationEvent {
  final int daysSinceSync;

  const ShowSyncReminder({required this.daysSinceSync});

  @override
  List<Object?> get props => [daysSinceSync];
}

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

class AddNotificationToHistory extends NotificationEvent {
  final AppNotification notification;

  const AddNotificationToHistory({required this.notification});

  @override
  List<Object?> get props => [notification];
}

class MarkNotificationAsRead extends NotificationEvent {
  final String notificationId;

  const MarkNotificationAsRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class MarkAllNotificationsAsRead extends NotificationEvent {
  const MarkAllNotificationsAsRead();
}

class DeleteNotification extends NotificationEvent {
  final String notificationId;

  const DeleteNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class ClearAllNotifications extends NotificationEvent {
  const ClearAllNotifications();
}

class GetNotificationHistory extends NotificationEvent {
  final NotificationType? filterType;
  final int? limit;

  const GetNotificationHistory({this.filterType, this.limit});

  @override
  List<Object?> get props => [filterType, limit];
}

class CancelScheduledNotification extends NotificationEvent {
  final int notificationId;

  const CancelScheduledNotification({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
