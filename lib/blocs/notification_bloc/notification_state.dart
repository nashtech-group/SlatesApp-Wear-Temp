part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationInitialized extends NotificationState {
  final bool permissionGranted;

  const NotificationInitialized({required this.permissionGranted});

  @override
  List<Object?> get props => [permissionGranted];
}

class NotificationScheduled extends NotificationState {
  final String message;
  final List<int> scheduledIds;

  const NotificationScheduled({
    required this.message,
    required this.scheduledIds,
  });

  @override
  List<Object?> get props => [message, scheduledIds];
}

class NotificationShown extends NotificationState {
  final AppNotification notification;

  const NotificationShown({required this.notification});

  @override
  List<Object?> get props => [notification];
}

class NotificationHistoryLoaded extends NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final Map<NotificationType, int> typeCounts;

  const NotificationHistoryLoaded({
    required this.notifications,
    required this.unreadCount,
    required this.typeCounts,
  });

  @override
  List<Object?> get props => [notifications, unreadCount, typeCounts];
}

class NotificationUpdated extends NotificationState {
  final AppNotification notification;
  final String action; // 'marked_read', 'deleted', 'cancelled', etc.

  const NotificationUpdated({
    required this.notification,
    required this.action,
  });

  @override
  List<Object?> get props => [notification, action];
}

class NotificationBulkActionCompleted extends NotificationState {
  final String action; // 'cancelled_all', 'marked_all_read', etc.
  final int affectedCount;

  const NotificationBulkActionCompleted({
    required this.action,
    required this.affectedCount,
  });

  @override
  List<Object?> get props => [action, affectedCount];
}

class PendingNotificationsLoaded extends NotificationState {
  final List<PendingNotificationRequest> pendingNotifications;
  final int count;

  const PendingNotificationsLoaded({
    required this.pendingNotifications,
    required this.count,
  });

  @override
  List<Object?> get props => [pendingNotifications, count];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}