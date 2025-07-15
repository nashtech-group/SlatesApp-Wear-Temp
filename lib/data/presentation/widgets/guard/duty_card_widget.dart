import 'package:flutter/material.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/services/date_service.dart';

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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        child: Padding(
          padding: responsive.containerPadding,
          child: isCompact
              ? _buildCompactLayout(context, responsive, theme)
              : _buildFullLayout(context, responsive, theme),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        _buildStatusIndicator(theme, responsive),
        responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                duty.site.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                _formatDutyTime(),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        _buildStatusBadge(theme, responsive, isCompact: true),
      ],
    );
  }

  Widget _buildFullLayout(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with site name and status
        Row(
          children: [
            Expanded(
              child: Text(
                duty.site.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusBadge(theme, responsive),
          ],
        ),

        responsive.smallSpacer,

        // Duty time and date
        Row(
          children: [
            Icon(
              Icons.schedule,
              size: responsive.iconSize * 0.8,
              color: theme.colorScheme.primary,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                _formatDutyTime(),
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),

        responsive.smallSpacer,

        // Site location
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: responsive.iconSize * 0.8,
              color: theme.colorScheme.secondary,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                duty.site.physicalAddress,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),

        if (!isCompact) ...[
          responsive.smallSpacer,
          _buildDutyDetails(context, responsive, theme),
        ],
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: StatusColors.getGuardDutyStatusColor(duty.status),
      ),
    );
  }

  Widget _buildStatusBadge(ThemeData theme, ResponsiveUtils responsive,
      {bool isCompact = false}) {
    final statusColor = StatusColors.getGuardDutyStatusColor(duty.status);
    final textSize =
        isCompact ? theme.textTheme.labelSmall : theme.textTheme.labelMedium;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: StatusColors.getStatusIndicatorDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
      ),
      child: Text(
        StatusColors.getGuardDutyStatusLabel(duty.status),
        style: textSize?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDutyDetails(
      BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
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
            responsive.smallHorizontalSpacer,
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        responsive.smallSpacer,
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _formatDutyTime() {
    final dateService = DateService();
    final startTime = dateService.formatTimeForDisplay(duty.startsAt);
    final endTime = dateService.formatTimeForDisplay(duty.endsAt);
    final date = dateService.formatDateSmart(duty.initialShiftDate);

    return '$date • $startTime - $endTime';
  }

  String _formatDuration() {
    final dateService = DateService();
    final duration = duty.endsAt.difference(duty.startsAt);
    return dateService.formatDuration(duration);
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
    final dateService = DateService();

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: StatusColors.getGuardDutyStatusColor(duty.status),
        radius: responsive.iconSize * 0.4,
        child: Text(
          '${duty.initialShiftDate.day}',
          style: theme.textTheme.labelMedium?.copyWith(
            color: StatusColors.getTextColorForBackground(
                StatusColors.getGuardDutyStatusColor(duty.status)),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        duty.site.name,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        '${dateService.formatTimeForDisplay(duty.startsAt)} - ${dateService.formatTimeForDisplay(duty.endsAt)}',
        style: theme.textTheme.bodySmall,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: StatusColors.getStatusIndicatorDecoration(
          color: StatusColors.getGuardDutyStatusColor(duty.status),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          StatusColors.getGuardDutyStatusLabel(duty.status),
          style: theme.textTheme.labelSmall?.copyWith(
            color: StatusColors.getGuardDutyStatusColor(duty.status),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
