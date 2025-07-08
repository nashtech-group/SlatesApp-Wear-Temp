import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/notification_bloc/notification_bloc.dart';
import 'package:slates_app_wear/core/utils/notification_utils.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';
import 'package:slates_app_wear/services/date_service.dart';

class NotificationCenterPage extends StatefulWidget {
  const NotificationCenterPage({super.key});

  @override
  State<NotificationCenterPage> createState() => _NotificationCenterPageState();
}

class _NotificationCenterPageState extends State<NotificationCenterPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  NotificationType? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Load notification history when page opens
    context.read<NotificationBloc>().add(const GetNotificationHistory());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All', icon: Icon(Icons.notifications)),
            Tab(text: 'Unread', icon: Icon(Icons.notifications_active)),
            Tab(text: 'Urgent', icon: Icon(Icons.priority_high)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter notifications',
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () {
              context.read<NotificationBloc>().add(
                    const MarkAllNotificationsAsRead(),
                  );
            },
            tooltip: 'Mark all as read',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            tooltip: 'More options',
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear All'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 8),
                    Text('Notification Settings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Row(
                  children: [
                    Icon(Icons.schedule),
                    SizedBox(width: 8),
                    Text('View Pending'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: Row(
                  children: [
                    Icon(Icons.analytics),
                    SizedBox(width: 8),
                    Text('Statistics'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(NotificationFilter.all),
          _buildNotificationList(NotificationFilter.unread),
          _buildNotificationList(NotificationFilter.urgent),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showTestNotificationDialog,
        tooltip: 'Test Notification',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNotificationList(NotificationFilter filter) {
    return BlocConsumer<NotificationBloc, NotificationState>(
      listener: (context, state) {
        if (state is NotificationError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Retry',
                onPressed: () {
                  context.read<NotificationBloc>().add(const GetNotificationHistory());
                },
              ),
            ),
          );
        } else if (state is NotificationScheduled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is NotificationLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading notifications...'),
              ],
            ),
          );
        }

        if (state is NotificationHistoryLoaded) {
          List<AppNotification> notifications = state.notifications;

          // Apply filter
          switch (filter) {
            case NotificationFilter.unread:
              notifications =
                  NotificationUtils.filterUnreadNotifications(notifications);
              break;
            case NotificationFilter.urgent:
              notifications =
                  NotificationUtils.filterUrgentNotifications(notifications);
              break;
            case NotificationFilter.all:
            break;
          }

          // Apply type filter if selected
          if (_selectedFilter != null) {
            notifications = NotificationUtils.filterNotificationsByType(
              notifications,
              _selectedFilter!,
            );
          }

          // Sort by priority
          notifications =
              NotificationUtils.sortNotificationsByPriority(notifications);

          if (notifications.isEmpty) {
            return _buildEmptyState(filter);
          }

          // Group notifications by date for better organization
          final groupedNotifications = NotificationUtils.groupNotificationsByDate(notifications);
          
          return Column(
            children: [
              if (state.unreadCount > 0)
                _buildUnreadCountBanner(state.unreadCount),
              if (_selectedFilter != null)
                _buildFilterBanner(),
              Expanded(
                child: groupedNotifications.length <= 3 
                  ? _buildSimpleList(notifications)
                  : _buildGroupedList(groupedNotifications),
              ),
            ],
          );
        }

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Unable to load notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  context.read<NotificationBloc>().add(const GetNotificationHistory());
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSimpleList(List<AppNotification> notifications) {
    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return NotificationListTile(
          notification: notification,
          onTap: () => _handleNotificationTap(notification),
          onMarkRead: () => _markAsRead(notification.id),
          onDelete: () => _deleteNotification(notification.id),
        );
      },
    );
  }

  Widget _buildGroupedList(Map<String, List<AppNotification>> groupedNotifications) {
    return ListView.builder(
      itemCount: groupedNotifications.length,
      itemBuilder: (context, index) {
        final entry = groupedNotifications.entries.elementAt(index);
        final dateGroup = entry.key;
        final notifications = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).dividerColor.withValues(alpha:0.1),
              child: Text(
                dateGroup,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            // Notifications for this date
            ...notifications.map((notification) => NotificationListTile(
              notification: notification,
              onTap: () => _handleNotificationTap(notification),
              onMarkRead: () => _markAsRead(notification.id),
              onDelete: () => _deleteNotification(notification.id),
            )),
          ],
        );
      },
    );
  }

  Widget _buildUnreadCountBanner(int unreadCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha:0.1),
        border: Border(
          bottom: BorderSide(color: Colors.blue.withValues(alpha:0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              context.read<NotificationBloc>().add(
                    const MarkAllNotificationsAsRead(),
                  );
            },
            icon: const Icon(Icons.done_all, size: 16),
            label: const Text('Mark All Read'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha:0.1),
        border: Border(
          bottom: BorderSide(color: Colors.orange.withValues(alpha:0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Text(
            'Filtered by: ${_selectedFilter!.name}',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.orange[700],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              setState(() => _selectedFilter = null);
              _applyFilter();
            },
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String title;
    String subtitle;
    IconData icon;

    switch (filter) {
      case NotificationFilter.unread:
        title = 'No Unread Notifications';
        subtitle = 'All caught up! You have no unread notifications.';
        icon = Icons.notifications_none;
        break;
      case NotificationFilter.urgent:
        title = 'No Urgent Notifications';
        subtitle = 'Everything looks good. No urgent notifications at this time.';
        icon = Icons.check_circle_outline;
        break;
      case NotificationFilter.all:
      default:
        title = 'No Notifications';
        subtitle = 'Notifications will appear here when you receive them.';
        icon = Icons.notifications_off;
        break;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            if (filter == NotificationFilter.all) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showTestNotificationDialog,
                icon: const Icon(Icons.add),
                label: const Text('Create Test Notification'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('All Types'),
                leading: Radio<NotificationType?>(
                  value: null,
                  groupValue: _selectedFilter,
                  onChanged: (value) {
                    setState(() => _selectedFilter = value);
                    Navigator.pop(context);
                    _applyFilter();
                  },
                ),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              ...NotificationType.values.map((type) => ListTile(
                    title: Text(type.name),
                    leading: Radio<NotificationType?>(
                      value: type,
                      groupValue: _selectedFilter,
                      onChanged: (value) {
                        setState(() => _selectedFilter = value);
                        Navigator.pop(context);
                        _applyFilter();
                      },
                    ),
                    trailing: Icon(
                      NotificationUtils.getNotificationIcon(type),
                      color: NotificationUtils.getNotificationColor(type),
                      size: 20,
                    ),
                    contentPadding: EdgeInsets.zero,
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _applyFilter() {
    context.read<NotificationBloc>().add(
          GetNotificationHistory(filterType: _selectedFilter),
        );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'clear_all':
        _showClearAllDialog();
        break;
      case 'settings':
        _navigateToSettings();
        break;
      case 'pending':
        _showPendingNotifications();
        break;
      case 'statistics':
        _showNotificationStatistics();
        break;
    }
  }

  void _showClearAllDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<NotificationBloc>().add(
                    const ClearAllNotifications(),
                  );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All notifications cleared'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/notification_settings');
  }

  void _showPendingNotifications() {
    context.read<NotificationBloc>().add(const GetPendingNotifications());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule),
            SizedBox(width: 8),
            Text('Pending Notifications'),
          ],
        ),
        content: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is PendingNotificationsLoaded) {
              if (state.pendingNotifications.isEmpty) {
                return const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, size: 48, color: Colors.green),
                    SizedBox(height: 16),
                    Text('No pending notifications scheduled.'),
                  ],
                );
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final pending = state.pendingNotifications[index];
                    return Card(
                      child: ListTile(
                        title: Text(pending.title ?? 'No Title'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(pending.body ?? 'No Content'),
                            // if (pending.scheduledDate != null) ...[
                            //   const SizedBox(height: 4),
                            //   Text(
                            //     'Scheduled: ${_dateService.formatTimestampSmart(pending.scheduledDate!)}',
                            //     style: Theme.of(context).textTheme.bodySmall,
                            //   ),
                            // ],
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () {
                            context.read<NotificationBloc>().add(
                                  CancelScheduledNotification(
                                      notificationId: pending.id),
                                );
                          },
                          tooltip: 'Cancel notification',
                        ),
                      ),
                    );
                  },
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showNotificationStatistics() {
    context.read<NotificationBloc>().add(const GetNotificationHistory());

    showDialog(
      context: context,
      builder: (context) => BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state is NotificationHistoryLoaded) {
            final stats = NotificationUtils.getNotificationStatistics(state.notifications);
            
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.analytics),
                  SizedBox(width: 8),
                  Text('Notification Statistics'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem('Total Notifications', '${stats['total']}'),
                    _buildStatItem('Unread', '${stats['unread']}'),
                    _buildStatItem('Urgent', '${stats['urgent']}'),
                    _buildStatItem('Today', '${stats['todaysCount']}'),
                    _buildStatItem('This Week', '${stats['thisWeeksCount']}'),
                    const SizedBox(height: 16),
                    Text(
                      'By Type:',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    ...(stats['byType'] as Map<String, int>).entries.map(
                      (entry) => _buildStatItem(
                        entry.key.replaceAll('_', ' ').toUpperCase(),
                        '${entry.value}',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }
          return const AlertDialog(
            content: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showTestNotificationDialog() {
    showDialog(
      context: context,
      builder: (context) => const TestNotificationDialog(),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    // Handle notification tap based on type
    final actions = NotificationUtils.getNotificationActions(notification);

    if (actions.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => NotificationActionSheet(
          notification: notification,
          actions: actions,
        ),
      );
    }

    // Mark as read
    if (!notification.isRead) {
      _markAsRead(notification.id);
    }
  }

  void _markAsRead(String notificationId) {
    context.read<NotificationBloc>().add(
          MarkNotificationAsRead(notificationId: notificationId),
        );
  }

  void _deleteNotification(String notificationId) {
    context.read<NotificationBloc>().add(
          DeleteNotification(notificationId: notificationId),
        );
  }
}

/// Custom notification list tile widget
class NotificationListTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback? onTap;
  final VoidCallback? onMarkRead;
  final VoidCallback? onDelete;

  const NotificationListTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = NotificationUtils.isNotificationUrgent(notification);
    final color = NotificationUtils.getNotificationColor(notification.type,
        isUrgent: isUrgent);
    final icon = NotificationUtils.getNotificationIcon(notification.type);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white),
            Text('Delete', style: TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Notification'),
            content: const Text(
                'Are you sure you want to delete this notification?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: notification.isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isUrgent 
            ? const BorderSide(color: Colors.red, width: 1)
            : BorderSide.none,
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha:0.2),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                notification.body,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 12,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    NotificationUtils.formatNotificationTimestamp(notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.priority_high,
                        color: Colors.red, size: 14),
                    const Text('Urgent',
                        style: TextStyle(color: Colors.red, fontSize: 11)),
                  ],
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              const SizedBox(height: 4),
              Icon(
                Icons.more_vert,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                NotificationUtils.getNotificationIcon(notification.type),
                color: NotificationUtils.getNotificationColor(notification.type),
              ),
              title: Text(notification.title),
              subtitle: Text(notification.type.name),
            ),
            const Divider(),
            if (!notification.isRead)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  Navigator.pop(context);
                  onMarkRead?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showDetails(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final dateService = DateService();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              NotificationUtils.getNotificationIcon(notification.type),
              color: NotificationUtils.getNotificationColor(notification.type),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(notification.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Type', notification.type.name),
              _buildDetailRow(
                'Time',
                dateService.formatDateTimeForDisplay(notification.timestamp),
              ),
              _buildDetailRow(
                'Status',
                notification.isRead ? 'Read' : 'Unread',
              ),
              if (notification.siteName != null)
                _buildDetailRow('Site', notification.siteName!),
              if (notification.dutyTime != null)
                _buildDetailRow(
                  'Duty Time',
                  dateService.formatDateTimeForDisplay(notification.dutyTime!),
                ),
              const SizedBox(height: 16),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(notification.body),
              if (notification.payload != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Additional Data:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    notification.payload.toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (!notification.isRead)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                onMarkRead?.call();
              },
              icon: const Icon(Icons.mark_email_read),
              label: const Text('Mark as Read'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

/// Test notification dialog for development/testing
class TestNotificationDialog extends StatefulWidget {
  const TestNotificationDialog({super.key});

  @override
  State<TestNotificationDialog> createState() => _TestNotificationDialogState();
}

class _TestNotificationDialogState extends State<TestNotificationDialog> {
  NotificationType _selectedType = NotificationType.system;
  final _titleController = TextEditingController(text: 'Test Notification');
  final _bodyController =
      TextEditingController(text: 'This is a test notification message');
  bool _scheduleForLater = false;
  DateTime? _scheduledTime;
  final DateService _dateService = DateService();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create Test Notification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<NotificationType>(
              value: _selectedType,
              onChanged: (value) => setState(() => _selectedType = value!),
              items: NotificationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        NotificationUtils.getNotificationIcon(type),
                        size: 16,
                        color: NotificationUtils.getNotificationColor(type),
                      ),
                      const SizedBox(width: 8),
                      Text(type.name),
                    ],
                  ),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Schedule for later'),
              value: _scheduleForLater,
              onChanged: (value) => setState(() => _scheduleForLater = value),
              contentPadding: EdgeInsets.zero,
            ),
            if (_scheduleForLater) ...[
              const SizedBox(height: 8),
              ListTile(
                title: Text(_scheduledTime != null 
                  ? _dateService.formatDateTimeForDisplay(_scheduledTime!)
                  : 'Select time'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectScheduledTime,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _canSendNotification() ? _sendTestNotification : null,
          child: Text(_scheduleForLater ? 'Schedule' : 'Send'),
        ),
      ],
    );
  }

  bool _canSendNotification() {
    return _titleController.text.isNotEmpty &&
           _bodyController.text.isNotEmpty &&
           (!_scheduleForLater || _scheduledTime != null);
  }

  void _sendTestNotification() {
    context.read<NotificationBloc>().add(
          ShowLocalNotification(
            title: _titleController.text,
            body: _bodyController.text,
            type: _selectedType,
           // scheduledDate: _scheduleForLater ? _scheduledTime : null,
          ),
        );
    Navigator.pop(context);
  }

  Future<void> _selectScheduledTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      );
      
      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}

/// Action sheet for notification actions
class NotificationActionSheet extends StatelessWidget {
  final AppNotification notification;
  final List<Map<String, String>> actions;

  const NotificationActionSheet({
    super.key,
    required this.notification,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Notification header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: NotificationUtils
                      .getNotificationColor(notification.type)
                      .withValues(alpha:0.2),
                  child: Icon(
                    NotificationUtils.getNotificationIcon(notification.type),
                    color: NotificationUtils.getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Action buttons
          ...actions.map((action) => ListTile(
                leading: _getActionIcon(action['id']!),
                title: Text(action['title']!),
                onTap: () {
                  Navigator.pop(context);
                  _handleAction(context, action['id']!);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Icon _getActionIcon(String actionId) {
    switch (actionId) {
      case 'open_map':
        return const Icon(Icons.map);
      case 'sync_now':
        return const Icon(Icons.sync);
      case 'respond':
        return const Icon(Icons.emergency, color: Colors.red);
      case 'call_emergency':
        return const Icon(Icons.phone, color: Colors.red);
      case 'battery_settings':
        return const Icon(Icons.battery_std);
      case 'view_sync_status':
        return const Icon(Icons.info_outline);
      case 'view_details':
      default:
        return const Icon(Icons.info_outline);
    }
  }

  void _handleAction(BuildContext context, String actionId) {
    switch (actionId) {
      case 'open_map':
        Navigator.pushNamed(
          context,
          '/site_map',
          arguments: {
            'siteId': notification.payload?['siteId'],
            'siteName': notification.siteName,
          },
        );
        break;
      case 'sync_now':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Sync started...'),
              ],
            ),
          ),
        );
        break;
      case 'respond':
        Navigator.pushNamed(context, '/emergency_response');
        break;
      case 'call_emergency':
        _showEmergencyCallDialog(context);
        break;
      case 'view_details':
        _showNotificationDetails(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $actionId')),
        );
        break;
    }
  }

  void _showEmergencyCallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Call'),
          ],
        ),
        content: const Text('Do you want to call emergency services?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement emergency call functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Emergency call initiated'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Text(notification.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Enum for notification filters
enum NotificationFilter {
  all,
  unread,
  urgent,
}