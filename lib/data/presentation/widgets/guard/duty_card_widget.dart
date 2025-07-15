import 'package:flutter/material.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class DutyCardWidget extends StatelessWidget {
  final RosterUserModel duty;
  final VoidCallback? onTap;
  final bool isCompact;

  const DutyCardWidget({
    super.key,
    required this.duty,
    this.onTap,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        child: Padding(
          padding: responsive.containerPadding,
          child: isCompact ? _buildCompactLayout(context, responsive, theme) : _buildFullLayout(context, responsive, theme),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        _buildStatusIndicator(theme),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                duty.site.name,
                style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatDutyTime(),
                style: theme.textTheme.bodySmall ?? const TextStyle(),
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme, isCompact: true),
      ],
    );
  }

  Widget _buildFullLayout(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with site name and status
        Row(
          children: [
            Expanded(
              child: Text(
                duty.site.name,
                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(theme),
          ],
        ),

        SizedBox(height: responsive.smallSpacing),

        // Duty time and date
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: responsive.iconSize * 0.8,
              color: theme.colorScheme.primary,
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Text(
                _formatDutyTime(),
                style: theme.textTheme.bodyMedium ?? const TextStyle(),
              ),
            ),
          ],
        ),

        SizedBox(height: responsive.smallSpacing),

        // Site location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: responsive.iconSize * 0.8,
              color: theme.colorScheme.secondary,
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Text(
                duty.site.physicalAddress,
                style: theme.textTheme.bodySmall ?? const TextStyle(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (!isCompact) ...[
          SizedBox(height: responsive.smallSpacing),
          _buildDutyDetails(context, responsive, theme),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(theme),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, {bool isCompact = false}) {
    final statusColor = _getStatusColor(theme);
    final textSize = isCompact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border.all(color: statusColor),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
      ),
      child: Text(
        duty.statusLabel,
        style: (textSize ?? const TextStyle()).copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDutyDetails(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        // Duration
        Expanded(
          child: _buildDetailItem(
            context,
            responsive,
            theme,
            Icons.timer,
            'Duration',
            _formatDuration(),
          ),
        ),
        
        // Time requirement type
        Expanded(
          child: _buildDetailItem(
            context,
            responsive,
            theme,
            Icons.work,
            'Type',
            duty.timeRequirement.guardPosition.securityGuard,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    IconData icon,
    String label,
    String value,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: responsive.iconSize * 0.6,
              color: theme.colorScheme.outline,
            ),
            SizedBox(width: responsive.smallSpacing * 0.5),
            Text(
              label,
              style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.smallSpacing * 0.25),
        Text(
          value,
          style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (duty.status) {
      case 1: // Present
        return Colors.green;
      case 0: // Absent
        return Colors.red;
      case -1: // Pending
        return Colors.orange;
      case 2: // Present but left early
        return Colors.yellow.shade700;
      case -2: // Expired
        return Colors.grey;
      case 3: // Present but late
        return Colors.blue;
      case 4: // Present but late and left early
        return Colors.purple;
      default:
        return theme.colorScheme.outline;
    }
  }

  String _formatDutyTime() {
    final startTime = _formatTime(duty.startsAt);
    final endTime = _formatTime(duty.endsAt);
    final date = _formatDate(duty.initialShiftDate);
    
    return '$date • $startTime - $endTime';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]}';
  }

  String _formatDuration() {
    final duration = duty.endsAt.difference(duty.startsAt);
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (minutes == 0) {
      return '${hours}h';
    } else {
      return '${hours}h ${minutes}m';
    }
  }
}

// Compact duty list item for use in lists
class DutyListTile extends StatelessWidget {
  final RosterUserModel duty;
  final VoidCallback? onTap;

  const DutyListTile({
    super.key,
    required this.duty,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: _getStatusColor(theme),
        radius: responsive.iconSize * 0.4,
        child: Text(
          '${duty.initialShiftDate.day}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        duty.site.name,
        style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${_formatTime(duty.startsAt)} - ${_formatTime(duty.endsAt)}',
        style: theme.textTheme.bodySmall ?? const TextStyle(),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(theme).withValues(alpha: 0.1),
          border: Border.all(color: _getStatusColor(theme)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          duty.statusLabel,
          style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
            color: _getStatusColor(theme),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(ThemeData theme) {
    switch (duty.status) {
      case 1: return Colors.green;
      case 0: return Colors.red;
      case -1: return Colors.orange;
      case 2: return Colors.yellow.shade700;
      case -2: return Colors.grey;
      case 3: return Colors.blue;
      case 4: return Colors.purple;
      default: return theme.colorScheme.outline;
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}