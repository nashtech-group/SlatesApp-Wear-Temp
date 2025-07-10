part of 'notification_bloc.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {
  const NotificationInitial();
}

class NotificationLoading extends NotificationState {
  const NotificationLoading();
}

class NotificationInitialized extends NotificationState {
  final bool permissionGranted;

  const NotificationInitialized({required this.permissionGranted});

  @override
  List<Object?> get props => [permissionGranted];

  /// Get initialization status message
  String get statusMessage => permissionGranted 
      ? 'Notifications initialized successfully' 
      : 'Notification permission not granted';
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

  /// Get count of scheduled notifications
  int get scheduledCount => scheduledIds.length;

  /// Check if any notifications were scheduled
  bool get hasScheduledNotifications => scheduledIds.isNotEmpty;
}

class NotificationShown extends NotificationState {
  final AppNotification notification;

  const NotificationShown({required this.notification});

  @override
  List<Object?> get props => [notification];

  /// Get notification type display name
  String get typeDisplayName {
    switch (notification.type) {
      case NotificationType.dutyReminder:
        return 'Duty Reminder';
      case NotificationType.batteryAlert:
        return 'Battery Alert';
      case NotificationType.checkpointComplete:
        return 'Checkpoint Complete';
      case NotificationType.emergency:
        return 'Emergency';
      case NotificationType.syncReminder:
        return 'Sync Reminder';
      case NotificationType.system:
        return 'System';
      case NotificationType.positionAlert:
        return 'Position Alert';
    }
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(notification.timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
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

  /// Check if there are notifications
  bool get hasNotifications => notifications.isNotEmpty;

  /// Check if there are unread notifications
  bool get hasUnreadNotifications => unreadCount > 0;

  /// Get total notifications count
  int get totalCount => notifications.length;

  /// Get read count
  int get readCount => totalCount - unreadCount;

  /// Get unread percentage
  double get unreadPercentage => 
      totalCount > 0 ? (unreadCount / totalCount) * 100 : 0;

  /// Get most common notification type
  NotificationType? get mostCommonType {
    if (typeCounts.isEmpty) return null;
    
    var maxCount = 0;
    NotificationType? mostCommon;
    
    typeCounts.forEach((type, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommon = type;
      }
    });
    
    return mostCommon;
  }

  /// Get notifications by type
  List<AppNotification> getNotificationsByType(NotificationType type) {
    return notifications.where((n) => n.type == type).toList();
  }

  /// Get recent notifications (last 24 hours)
  List<AppNotification> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return notifications.where((n) => n.timestamp.isAfter(yesterday)).toList();
  }
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

  /// Get action display name
  String get actionDisplayName {
    switch (action) {
      case 'marked_read':
        return 'Marked as Read';
      case 'deleted':
        return 'Deleted';
      case 'cancelled':
        return 'Cancelled';
      case 'archived':
        return 'Archived';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get success message for the action
  String get successMessage => 
      'Notification ${actionDisplayName.toLowerCase()} successfully';
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

  /// Get action display name
  String get actionDisplayName {
    switch (action) {
      case 'cancelled_all':
        return 'Cancelled All';
      case 'marked_all_read':
        return 'Marked All as Read';
      case 'deleted_all':
        return 'Deleted All';
      case 'archived_all':
        return 'Archived All';
      default:
        return action.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Get success message for the bulk action
  String get successMessage => 
      '$actionDisplayName - $affectedCount notifications affected';
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

  /// Check if there are pending notifications
  bool get hasPendingNotifications => count > 0;

  /// Get pending notifications by type
  List<PendingNotificationRequest> getPendingByType(NotificationType type) {
    return pendingNotifications;
  }

  /// Get summary message
  String get summaryMessage => count > 0 
      ? '$count pending notifications scheduled'
      : 'No pending notifications';
}

class NotificationError extends NotificationState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const NotificationError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  @override
  String get errorTitle => 'Notification Error';

  @override
  String get errorIcon => 'notifications_off';

  /// Create copy with updated error info
  NotificationError copyWith({BlocErrorInfo? errorInfo}) {
    return NotificationError(errorInfo: errorInfo ?? this.errorInfo);
  }
}