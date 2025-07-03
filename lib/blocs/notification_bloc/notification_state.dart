part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

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
  final String action; // 'read', 'deleted', etc.

  const NotificationUpdated({
    required this.notification,
    required this.action,
  });

  @override
  List<Object?> get props => [notification, action];
}

class NotificationError extends NotificationState {
  final String message;

  const NotificationError({required this.message});

  @override
  List<Object?> get props => [message];
}