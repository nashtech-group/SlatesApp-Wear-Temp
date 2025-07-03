import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/notification_bloc/notification_bloc.dart';
import 'package:slates_app_wear/core/utils/notification_utils.dart';
import 'package:slates_app_wear/data/models/notification_model.dart';


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
          ),
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () {
              context.read<NotificationBloc>().add(
                    const MarkAllNotificationsAsRead(),
                  );
            },
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear_all',
                child: Text('Clear All'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Notification Settings'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('View Pending'),
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
        child: const Icon(Icons.add),
        tooltip: 'Test Notification',
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
          return const Center(child: CircularProgressIndicator());
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
            default:
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

          return Column(
            children: [
              if (state.unreadCount > 0)
                _buildUnreadCountBanner(state.unreadCount),
              Expanded(
                child: ListView.builder(
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
                ),
              ),
            ],
          );
        }

        return const Center(child: Text('Loading notifications...'));
      },
    );
  }

  Widget _buildUnreadCountBanner(int unreadCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            '$unreadCount unread notification${unreadCount == 1 ? '' : 's'}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              context.read<NotificationBloc>().add(
                    const MarkAllNotificationsAsRead(),
                  );
            },
            child: const Text('Mark All Read'),
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
        subtitle =
            'Everything looks good. No urgent notifications at this time.';
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Notifications'),
        content: Column(
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
            ),
            ...NotificationType.values.map((type) => ListTile(
                  title: Text(type.displayName),
                  leading: Radio<NotificationType?>(
                    value: type,
                    groupValue: _selectedFilter,
                    onChanged: (value) {
                      setState(() => _selectedFilter = value);
                      Navigator.pop(context);
                      _applyFilter();
                    },
                  ),
                )),
          ],
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
            },
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
        title: const Text('Pending Notifications'),
        content: BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) {
            if (state is PendingNotificationsLoaded) {
              if (state.pendingNotifications.isEmpty) {
                return const Text('No pending notifications scheduled.');
              }

              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final pending = state.pendingNotifications[index];
                    return ListTile(
                      title: Text(pending.title ?? 'No Title'),
                      subtitle: Text(pending.body ?? 'No Content'),
                      trailing: IconButton(
                        icon: const Icon(Icons.cancel),
                        onPressed: () {
                          context.read<NotificationBloc>().add(
                                CancelScheduledNotification(
                                    notificationId: pending.id),
                              );
                        },
                      ),
                    );
                  },
                ),
              );
            }
            return const CircularProgressIndicator();
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
    Key? key,
    required this.notification,
    this.onTap,
    this.onMarkRead,
    this.onDelete,
  }) : super(key: key);

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
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
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
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight:
                  notification.isRead ? FontWeight.normal : FontWeight.bold,
            ),
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
                  Text(
                    NotificationUtils.getRelativeTimeString(
                        notification.timestamp),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (isUrgent) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.priority_high,
                        color: Colors.red, size: 16),
                    const Text('Urgent',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ],
          ),
          trailing: notification.isRead
              ? null
              : Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
              leading: const Icon(Icons.delete),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showDetails(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${notification.type.displayName}'),
              const SizedBox(height: 8),
              Text(
                  'Time: ${NotificationUtils.formatDateTime(notification.timestamp)}'),
              const SizedBox(height: 8),
              Text('Status: ${notification.isRead ? 'Read' : 'Unread'}'),
              if (notification.siteName != null) ...[
                const SizedBox(height: 8),
                Text('Site: ${notification.siteName}'),
              ],
              if (notification.dutyTime != null) ...[
                const SizedBox(height: 8),
                Text(
                    'Duty Time: ${NotificationUtils.formatDateTime(notification.dutyTime!)}'),
              ],
              const SizedBox(height: 16),
              const Text('Message:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(notification.body),
              if (notification.payload != null) ...[
                const SizedBox(height: 16),
                const Text('Additional Data:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(notification.payload.toString()),
              ],
            ],
          ),
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
}

/// Test notification dialog for development/testing
class TestNotificationDialog extends StatefulWidget {
  const TestNotificationDialog({Key? key}) : super(key: key);

  @override
  State<TestNotificationDialog> createState() => _TestNotificationDialogState();
}

class _TestNotificationDialogState extends State<TestNotificationDialog> {
  NotificationType _selectedType = NotificationType.system;
  final _titleController = TextEditingController(text: 'Test Notification');
  final _bodyController =
      TextEditingController(text: 'This is a test notification message');

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Test Notification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<NotificationType>(
            value: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value!),
            items: NotificationType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
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
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            context.read<NotificationBloc>().add(
                  ShowLocalNotification(
                    title: _titleController.text,
                    body: _bodyController.text,
                    type: _selectedType,
                  ),
                );
            Navigator.pop(context);
          },
          child: const Text('Send'),
        ),
      ],
    );
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
    Key? key,
    required this.notification,
    required this.actions,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Icon(
                  NotificationUtils.getNotificationIcon(notification.type),
                  color:
                      NotificationUtils.getNotificationColor(notification.type),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
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
          ...actions.map((action) => ListTile(
                title: Text(action['title']!),
                onTap: () {
                  Navigator.pop(context);
                  _handleAction(context, action['id']!);
                },
              )),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String actionId) {
    switch (actionId) {
      case 'open_map':
        // Navigate to site map
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
        // Trigger sync
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync started...')),
        );
        break;
      case 'respond':
        // Handle emergency response
        Navigator.pushNamed(context, '/emergency_response');
        break;
      case 'view_details':
        // Show notification details
        _showNotificationDetails(context);
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action: $actionId')),
        );
        break;
    }
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
