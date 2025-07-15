import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/status_indicator.dart';

class DutyCardWidget extends StatefulWidget {
  final ComprehensiveGuardDutyResponseModel duty;
  final bool isOffline;
  final ResponsiveUtils responsive;
  final VoidCallback? onTap;
  final bool showCheckpoints;
  final bool showActions;
  final bool isCompact;

  const DutyCardWidget({
    super.key,
    required this.duty,
    required this.isOffline,
    required this.responsive,
    this.onTap,
    this.showCheckpoints = true,
    this.showActions = false,
    this.isCompact = false,
  });

  @override
  State<DutyCardWidget> createState() => _DutyCardWidgetState();
}

class _DutyCardWidgetState extends State<DutyCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCurrentDuty = _isCurrentDuty();
    final isUpcoming = _isUpcomingDuty();
    final isPast = _isPastDuty();

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              margin: EdgeInsets.only(bottom: widget.responsive.smallSpacing),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap != null
                      ? () {
                          HapticFeedback.lightImpact();
                          widget.onTap!();
                        }
                      : null,
                  onTapDown: (_) => _animationController.forward(),
                  onTapUp: (_) => _animationController.reverse(),
                  onTapCancel: () => _animationController.reverse(),
                  borderRadius:
                      BorderRadius.circular(widget.responsive.borderRadius),
                  child: Container(
                    padding: widget.responsive.getResponsiveValue(
                      wearable: const EdgeInsets.all(12),
                      smallMobile: const EdgeInsets.all(14),
                      mobile: const EdgeInsets.all(16),
                      tablet: const EdgeInsets.all(18),
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(widget.responsive.borderRadius),
                      border: Border.all(
                        color:
                            _getBorderColor(isCurrentDuty, isUpcoming, isPast),
                        width: isCurrentDuty ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: isCurrentDuty ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: widget.isCompact
                        ? _buildCompactContent(
                            context, theme, isCurrentDuty, isUpcoming, isPast)
                        : _buildFullContent(
                            context, theme, isCurrentDuty, isUpcoming, isPast),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactContent(BuildContext context, ThemeData theme,
      bool isCurrentDuty, bool isUpcoming, bool isPast) {
    return Row(
      children: [
        _buildStatusIndicator(isCurrentDuty, isUpcoming, isPast),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.duty.site?.name ?? 'Unknown Site',
                style: widget.responsive.getBodyStyle(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${_formatTime(widget.duty.startsAt)} - ${_formatTime(widget.duty.endsAt)}',
                style: widget.responsive.getCaptionStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        _buildStatusBadge(isCurrentDuty, isUpcoming, isPast),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context, ThemeData theme,
      bool isCurrentDuty, bool isUpcoming, bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, theme, isCurrentDuty, isUpcoming, isPast),
        widget.responsive.smallSpacer,
        _buildTimeInfo(context, theme),
        if (widget.showCheckpoints) ...[
          widget.responsive.smallSpacer,
          _buildCheckpointInfo(context, theme),
        ],
        widget.responsive.smallSpacer,
        _buildGuardInfo(context, theme),
        if (widget.showActions && isCurrentDuty) ...[
          widget.responsive.mediumSpacer,
          _buildActions(context, theme),
        ],
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, bool isCurrentDuty,
      bool isUpcoming, bool isPast) {
    return Row(
      children: [
        _buildStatusIndicator(isCurrentDuty, isUpcoming, isPast),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.duty.site?.name ?? 'Unknown Site',
                style: widget.responsive.getTitleStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.duty.site?.physicalAddress != null)
                Text(
                  widget.duty.site!.physicalAddress!,
                  style: widget.responsive.getCaptionStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        _buildStatusBadge(isCurrentDuty, isUpcoming, isPast),
      ],
    );
  }

  Widget _buildStatusIndicator(
      bool isCurrentDuty, bool isUpcoming, bool isPast) {
    Color color;
    IconData icon;

    if (isCurrentDuty) {
      color = AppTheme.successGreen;
      icon = Icons.play_circle_filled;
    } else if (isUpcoming) {
      color = AppTheme.warningOrange;
      icon = Icons.schedule;
    } else {
      color = AppTheme.primaryTeal;
      icon = Icons.check_circle;
    }

    return Container(
      width: widget.responsive.getResponsiveValue(
        wearable: 8.0,
        smallMobile: 10.0,
        mobile: 12.0,
        tablet: 14.0,
      ),
      height: widget.responsive.getResponsiveValue(
        wearable: 40.0,
        smallMobile: 50.0,
        mobile: 60.0,
        tablet: 70.0,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
      ),
    );
  }

  Widget _buildStatusBadge(bool isCurrentDuty, bool isUpcoming, bool isPast) {
    String text;
    Color color;

    if (isCurrentDuty) {
      text = 'ACTIVE';
      color = AppTheme.successGreen;
    } else if (isUpcoming) {
      text = 'UPCOMING';
      color = AppTheme.warningOrange;
    } else {
      text = widget.duty.statusLabel ?? 'COMPLETED';
      color = AppTheme.primaryTeal;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.responsive.smallSpacing,
        vertical: widget.responsive.smallSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
      ),
      child: Text(
        text,
        style: widget.responsive.getCaptionStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTimeInfo(BuildContext context, ThemeData theme) {
    final duration = widget.duty.endsAt.difference(widget.duty.startsAt);

    return Container(
      padding: widget.responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeDetail(
              context,
              'Start',
              _formatTime(widget.duty.startsAt),
              Icons.play_circle_outline,
              theme,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            margin: EdgeInsets.symmetric(
                horizontal: widget.responsive.smallSpacing),
          ),
          Expanded(
            child: _buildTimeDetail(
              context,
              'End',
              _formatTime(widget.duty.endsAt),
              Icons.stop_circle_outlined,
              theme,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
            margin: EdgeInsets.symmetric(
                horizontal: widget.responsive.smallSpacing),
          ),
          Expanded(
            child: _buildTimeDetail(
              context,
              'Duration',
              _formatDuration(duration),
              Icons.timer_outlined,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDetail(BuildContext context, String label, String value,
      IconData icon, ThemeData theme) {
    return Column(
      children: [
        Icon(
          icon,
          size: widget.responsive.iconSize,
          color: theme.colorScheme.primary,
        ),
        widget.responsive.smallSpacer,
        Text(
          label,
          style: widget.responsive.getCaptionStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: widget.responsive.getCaptionStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckpointInfo(BuildContext context, ThemeData theme) {
    final checkpointCount = widget.duty.site?.perimeters
            ?.expand((perimeter) => perimeter.checkPoints ?? [])
            .length ??
        0;

    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: widget.responsive.iconSize,
          color: theme.colorScheme.primary,
        ),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Text(
            '$checkpointCount Checkpoints',
            style: widget.responsive.getBodyStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (checkpointCount > 0)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.responsive.smallSpacing,
              vertical: widget.responsive.smallSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(widget.responsive.borderRadius / 3),
            ),
            child: Text(
              _getGuardType(),
              style: widget.responsive.getCaptionStyle(
                color: AppTheme.primaryTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGuardInfo(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.security,
          size: widget.responsive.iconSize,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Text(
            'Guard Position: ${_getGuardType()}',
            style: widget.responsive.getCaptionStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (widget.isOffline)
          CompactStatusIndicator(
            isOnline: false,
            size: widget.responsive.iconSize,
          ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleStartDuty(),
            icon: Icon(
              Icons.play_circle,
              size: widget.responsive.iconSize,
            ),
            label: Text(
              'Start',
              style: widget.responsive.getCaptionStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.successGreen,
              side: const BorderSide(color: AppTheme.successGreen),
            ),
          ),
        ),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleViewMap(),
            icon: Icon(
              Icons.map,
              size: widget.responsive.iconSize,
            ),
            label: Text(
              'Map',
              style: widget.responsive.getCaptionStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getBorderColor(bool isCurrentDuty, bool isUpcoming, bool isPast) {
    if (isCurrentDuty) {
      return AppTheme.successGreen;
    } else if (isUpcoming) {
      return AppTheme.warningOrange;
    } else {
      return Theme.of(context).colorScheme.outline.withValues(alpha: 0.3);
    }
  }

  bool _isCurrentDuty() {
    final now = DateTime.now();
    return widget.duty.startsAt.isBefore(now) &&
        widget.duty.endsAt.isAfter(now);
  }

  bool _isUpcomingDuty() {
    final now = DateTime.now();
    return widget.duty.startsAt.isAfter(now);
  }

  bool _isPastDuty() {
    final now = DateTime.now();
    return widget.duty.endsAt.isBefore(now);
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getGuardType() {
    return widget.duty.timeRequirement?.guardPosition?.securityGuard
            ?.toUpperCase() ??
        'UNKNOWN';
  }

  void _handleStartDuty() {
    HapticFeedback.lightImpact();
    // TODO: Implement start duty logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Start duty functionality coming soon'),
      ),
    );
  }

  void _handleViewMap() {
    HapticFeedback.lightImpact();
    // TODO: Navigate to map view
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map view functionality coming soon'),
      ),
    );
  }
}

/// Compact duty card for list views
class CompactDutyCard extends StatelessWidget {
  final ComprehensiveGuardDutyResponseModel duty;
  final bool isOffline;
  final VoidCallback? onTap;

  const CompactDutyCard({
    super.key,
    required this.duty,
    required this.isOffline,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return DutyCardWidget(
      duty: duty,
      isOffline: isOffline,
      responsive: responsive,
      onTap: onTap,
      isCompact: true,
      showCheckpoints: false,
      showActions: false,
    );
  }
}

/// Duty summary card with minimal information
class DutySummaryCard extends StatelessWidget {
  final ComprehensiveGuardDutyResponseModel duty;
  final bool showSite;
  final bool showTime;
  final VoidCallback? onTap;

  const DutySummaryCard({
    super.key,
    required this.duty,
    this.showSite = true,
    this.showTime = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
        child: Row(
          children: [
            Icon(
              Icons.work_outline,
              size: responsive.iconSize,
              color: theme.colorScheme.primary,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSite)
                    Text(
                      duty.site?.name ?? 'Unknown Site',
                      style: responsive.getCaptionStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showTime)
                    Text(
                      '${_formatTime(duty.startsAt)} - ${_formatTime(duty.endsAt)}',
                      style: responsive.getCaptionStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
