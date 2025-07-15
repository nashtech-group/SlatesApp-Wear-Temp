import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/large_button.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/status_indicator.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/animated_counter.dart';
import 'package:slates_app_wear/services/date_service.dart';

class GuardStatusWidget extends StatefulWidget {
  final int guardId;
  final RosterUserModel? currentDuty;

  const GuardStatusWidget({
    super.key,
    required this.guardId,
    required this.currentDuty,
  });

  @override
  State<GuardStatusWidget> createState() => _GuardStatusWidgetState();
}

class _GuardStatusWidgetState extends State<GuardStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _statusController;
  late AnimationController _pulseController;
  late Animation<double> _statusAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _statusController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _statusController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _statusAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statusController,
      curve: Curves.easeOutBack,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _statusController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final isOnDuty = widget.currentDuty != null && _isCurrentlyOnDuty(widget.currentDuty!);

    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, locationState) {
        final isOffline = locationState is LocationError;
        
        return FadeTransition(
          opacity: _statusAnimation,
          child: Container(
            padding: responsive.containerPadding,
            decoration: BoxDecoration(
              gradient: _getStatusGradient(context, isOnDuty),
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: (isOnDuty ? AppTheme.successGreen : theme.colorScheme.primary)
                      .withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusHeader(context, responsive, theme, isOnDuty, isOffline),
                responsive.mediumSpacer,
                _buildStatusDetails(context, responsive, theme, isOnDuty),
                if (isOnDuty && widget.currentDuty != null) ...[
                  responsive.mediumSpacer,
                  _buildDutyProgress(context, responsive, theme, widget.currentDuty!),
                ],
                responsive.mediumSpacer,
                _buildActionButtons(context, responsive, theme, isOnDuty),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    bool isOnDuty, 
    bool isOffline
  ) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isOnDuty ? _pulseAnimation.value : 1.0,
              child: Container(
                width: responsive.getResponsiveValue(
                  wearable: 20.0,
                  smallMobile: 24.0,
                  mobile: 28.0,
                  tablet: 32.0,
                ),
                height: responsive.getResponsiveValue(
                  wearable: 20.0,
                  smallMobile: 24.0,
                  mobile: 28.0,
                  tablet: 32.0,
                ),
                decoration: BoxDecoration(
                  color: isOnDuty ? AppTheme.successGreen : AppTheme.warningOrange,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isOnDuty ? AppTheme.successGreen : AppTheme.warningOrange)
                          .withValues(alpha: 0.5),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                style: responsive.getTitleStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.currentDuty != null)
                Text(
                  widget.currentDuty!.site.name,
                  style: responsive.getBodyStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
        StatusIndicator(
          isOnline: !isOffline,
          size: responsive.iconSize,
        ),
      ],
    );
  }

  Widget _buildStatusDetails(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    bool isOnDuty
  ) {
    if (!isOnDuty || widget.currentDuty == null) {
      return _buildOffDutyDetails(context, responsive, theme);
    }

    return _buildOnDutyDetails(context, responsive, theme, widget.currentDuty!);
  }

  Widget _buildOffDutyDetails(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    final nextDuty = _getNextDuty();
    
    return Container(
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: responsive.iconSize,
              ),
              responsive.smallHorizontalSpacer,
              Text(
                'Next Duty',
                style: responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          responsive.smallSpacer,
          if (nextDuty != null) ...[
            Text(
              nextDuty.site.name,
              style: responsive.getBodyStyle(color: Colors.white),
            ),
            Text(
              _formatDutyTime(nextDuty),
              style: responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ] else
            Text(
              'No upcoming duties scheduled',
              style: responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnDutyDetails(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    RosterUserModel currentDuty
  ) {
    final timeRemaining = currentDuty.endsAt.difference(DateTime.now());
    final dateService = DateService();
    
    return Container(
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  responsive,
                  'Start Time',
                  dateService.formatTimeForDisplay(currentDuty.startsAt),
                  Icons.play_circle,
                ),
              ),
              responsive.smallHorizontalSpacer,
              Expanded(
                child: _buildDetailItem(
                  context,
                  responsive,
                  'End Time',
                  dateService.formatTimeForDisplay(currentDuty.endsAt),
                  Icons.stop_circle,
                ),
              ),
            ],
          ),
          responsive.smallSpacer,
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  responsive,
                  'Time Remaining',
                  dateService.formatDuration(timeRemaining),
                  Icons.timer,
                ),
              ),
              responsive.smallHorizontalSpacer,
              Expanded(
                child: _buildDetailItem(
                  context,
                  responsive,
                  'Guard Type',
                  currentDuty.timeRequirement.guardPosition.securityGuard.toUpperCase(),
                  Icons.security,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    BuildContext context, 
    ResponsiveUtils responsive, 
    String label, 
    String value, 
    IconData icon
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: responsive.iconSize * 0.8,
            ),
            responsive.smallHorizontalSpacer,
            Text(
              label,
              style: responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        responsive.smallSpacer,
        Text(
          value,
          style: responsive.getBodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDutyProgress(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    RosterUserModel currentDuty
  ) {
    final totalDuration = currentDuty.endsAt.difference(currentDuty.startsAt);
    final elapsed = DateTime.now().difference(currentDuty.startsAt);
    final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duty Progress',
                style: responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedCounter(
                value: progress * 100,
                duration: const Duration(milliseconds: 500),
                suffix: '%',
                textStyle: responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          responsive.smallSpacer,
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(
              progress > 0.8 ? AppTheme.warningOrange : AppTheme.successGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    bool isOnDuty
  ) {
    if (responsive.isWearable) {
      return _buildWearableActions(context, responsive, theme, isOnDuty);
    }

    return _buildMobileActions(context, responsive, theme, isOnDuty);
  }

  Widget _buildWearableActions(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    bool isOnDuty
  ) {
    return Column(
      children: [
        LargeButton(
          text: isOnDuty ? 'End Duty' : 'Start Duty',
          icon: isOnDuty ? Icons.stop_circle : Icons.play_circle_filled,
          backgroundColor: isOnDuty ? AppTheme.errorRed : AppTheme.successGreen,
          onPressed: () => _handleDutyAction(context, isOnDuty),
        ),
        if (isOnDuty) ...[
          responsive.smallSpacer,
          Row(
            children: [
              Expanded(
                child: LargeButton(
                  text: 'Emergency',
                  icon: Icons.emergency,
                  backgroundColor: AppTheme.errorRed,
                  onPressed: () => _handleEmergency(context),
                ),
              ),
              responsive.smallHorizontalSpacer,
              Expanded(
                child: LargeButton(
                  text: 'Map',
                  icon: Icons.map,
                  backgroundColor: AppTheme.primaryTeal,
                  onPressed: () => _openMap(context),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildMobileActions(
    BuildContext context, 
    ResponsiveUtils responsive, 
    ThemeData theme, 
    bool isOnDuty
  ) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: LargeButton(
            text: isOnDuty ? 'End Duty' : 'Start Duty',
            icon: isOnDuty ? Icons.stop_circle : Icons.play_circle_filled,
            backgroundColor: isOnDuty ? AppTheme.errorRed : AppTheme.successGreen,
            onPressed: () => _handleDutyAction(context, isOnDuty),
          ),
        ),
        if (isOnDuty) ...[
          responsive.smallHorizontalSpacer,
          Expanded(
            child: LargeButton(
              text: 'Emergency',
              icon: Icons.emergency,
              backgroundColor: AppTheme.errorRed,
              onPressed: () => _handleEmergency(context),
            ),
          ),
        ],
      ],
    );
  }

  // Helper Methods
  RosterUserModel? _getNextDuty() {
    // This would be implemented with access to roster state
    // For now, return null
    return null;
  }

  bool _isCurrentlyOnDuty(RosterUserModel duty) {
    final now = DateTime.now();
    return duty.startsAt.isBefore(now) && duty.endsAt.isAfter(now);
  }

  LinearGradient _getStatusGradient(BuildContext context, bool isOnDuty) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isOnDuty
          ? [
              AppTheme.successGreen,
              AppTheme.successGreen.withValues(alpha: 0.8),
            ]
          : [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
            ],
    );
  }

  String _formatDutyTime(RosterUserModel duty) {
    final dateService = DateService();
    final start = dateService.formatTimeForDisplay(duty.startsAt);
    final end = dateService.formatTimeForDisplay(duty.endsAt);
    final date = dateService.formatDateSmart(duty.startsAt);
    return '$date • $start - $end';
  }

  // Action Handlers
  void _handleDutyAction(BuildContext context, bool isOnDuty) {
    HapticFeedback.lightImpact();
    
    if (isOnDuty && widget.currentDuty != null) {
      _showEndDutyConfirmation(context);
    } else {
      _showStartDutyDialog(context);
    }
  }

  void _showStartDutyDialog(BuildContext context) {
    final responsive = context.responsive;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: AppTheme.successGreen,
              size: responsive.largeIconSize,
            ),
            responsive.smallHorizontalSpacer,
            const Text('Start Duty'),
          ],
        ),
        content: const Text(
          'Are you ready to start your duty? This will begin location tracking '
          'and activate perimeter monitoring.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LocationBloc>().add(const StartLocationTracking());
              // TODO: Start duty logic
            },
            style: AppTheme.responsivePrimaryButtonStyle(context),
            child: const Text('Start Duty'),
          ),
        ],
      ),
    );
  }

  void _showEndDutyConfirmation(BuildContext context) {
    final responsive = context.responsive;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.stop_circle,
              color: AppTheme.errorRed,
              size: responsive.largeIconSize,
            ),
            responsive.smallHorizontalSpacer,
            const Text('End Duty'),
          ],
        ),
        content: const Text(
          'Are you sure you want to end your duty? This will stop location '
          'tracking and submit your patrol data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.read<LocationBloc>().add(const StopLocationTracking());
              // TODO: End duty logic and submit data
            },
            style: AppTheme.responsiveDestructiveButtonStyle(context),
            child: const Text('End Duty'),
          ),
        ],
      ),
    );
  }

  void _handleEmergency(BuildContext context) {
    HapticFeedback.heavyImpact();
    // TODO: Implement emergency alert
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency feature coming soon'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _openMap(BuildContext context) {
    HapticFeedback.lightImpact();
    // TODO: Navigate to map tab or screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening map...'),
      ),
    );
  }
}