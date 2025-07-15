import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/blocs/checkpoint_bloc/checkpoint_bloc.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/models/roster/comprehensive_guard_duty_response_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/large_button.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/status_indicator.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/common/animated_counter.dart';

class GuardStatusWidget extends StatefulWidget {
  final UserModel user;
  final bool isOffline;
  final RosterState rosterState;
  final LocationState locationState;
  final ResponsiveUtils responsive;

  const GuardStatusWidget({
    super.key,
    required this.user,
    required this.isOffline,
    required this.rosterState,
    required this.locationState,
    required this.responsive,
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
    final theme = Theme.of(context);
    final currentDuty = _getCurrentDuty();
    final isOnDuty = currentDuty != null && _isCurrentlyOnDuty(currentDuty);

    return FadeTransition(
      opacity: _statusAnimation,
      child: Container(
        padding: widget.responsive.containerPadding,
        decoration: BoxDecoration(
          gradient: _getStatusGradient(context, isOnDuty),
          borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
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
            _buildStatusHeader(context, isOnDuty, currentDuty),
            widget.responsive.mediumSpacer,
            _buildStatusDetails(context, isOnDuty, currentDuty),
            if (isOnDuty) ...[
              widget.responsive.mediumSpacer,
              _buildDutyProgress(context, currentDuty!),
            ],
            widget.responsive.mediumSpacer,
            _buildActionButtons(context, isOnDuty, currentDuty),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, bool isOnDuty, 
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isOnDuty ? _pulseAnimation.value : 1.0,
              child: Container(
                width: widget.responsive.getResponsiveValue(
                  wearable: 20.0,
                  smallMobile: 24.0,
                  mobile: 28.0,
                  tablet: 32.0,
                ),
                height: widget.responsive.getResponsiveValue(
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
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                style: widget.responsive.getTitleStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (currentDuty != null)
                Text(
                  currentDuty.site?.name ?? 'Unknown Site',
                  style: widget.responsive.getBodyStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
            ],
          ),
        ),
        StatusIndicator(
          isOnline: !widget.isOffline,
          size: widget.responsive.iconSize,
        ),
      ],
    );
  }

  Widget _buildStatusDetails(BuildContext context, bool isOnDuty,
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    if (!isOnDuty || currentDuty == null) {
      return _buildOffDutyDetails(context);
    }

    return _buildOnDutyDetails(context, currentDuty);
  }

  Widget _buildOffDutyDetails(BuildContext context) {
    final nextDuty = _getNextDuty();
    
    return Container(
      padding: widget.responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: widget.responsive.iconSize,
              ),
              widget.responsive.smallHorizontalSpacer,
              Text(
                'Next Duty',
                style: widget.responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          widget.responsive.smallSpacer,
          if (nextDuty != null) ...[
            Text(
              nextDuty.site?.name ?? 'Unknown Site',
              style: widget.responsive.getBodyStyle(color: Colors.white),
            ),
            Text(
              _formatDutyTime(nextDuty),
              style: widget.responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ] else
            Text(
              'No upcoming duties scheduled',
              style: widget.responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOnDutyDetails(BuildContext context, 
      ComprehensiveGuardDutyResponseModel currentDuty) {
    final timeRemaining = currentDuty.endsAt.difference(DateTime.now());
    
    return Container(
      padding: widget.responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  'Start Time',
                  _formatTime(currentDuty.startsAt),
                  Icons.play_circle,
                ),
              ),
              widget.responsive.smallHorizontalSpacer,
              Expanded(
                child: _buildDetailItem(
                  context,
                  'End Time',
                  _formatTime(currentDuty.endsAt),
                  Icons.stop_circle,
                ),
              ),
            ],
          ),
          widget.responsive.smallSpacer,
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  context,
                  'Time Remaining',
                  _formatDuration(timeRemaining),
                  Icons.timer,
                ),
              ),
              widget.responsive.smallHorizontalSpacer,
              Expanded(
                child: _buildDetailItem(
                  context,
                  'Guard Type',
                  currentDuty.timeRequirement?.guardPosition?.securityGuard?.toUpperCase() ?? 'UNKNOWN',
                  Icons.security,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: widget.responsive.iconSize * 0.8,
            ),
            widget.responsive.smallHorizontalSpacer,
            Text(
              label,
              style: widget.responsive.getCaptionStyle(
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        widget.responsive.smallSpacer,
        Text(
          value,
          style: widget.responsive.getBodyStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDutyProgress(BuildContext context, 
      ComprehensiveGuardDutyResponseModel currentDuty) {
    final totalDuration = currentDuty.endsAt.difference(currentDuty.startsAt);
    final elapsed = DateTime.now().difference(currentDuty.startsAt);
    final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);

    return Container(
      padding: widget.responsive.formPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Duty Progress',
                style: widget.responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedCounter(
                value: progress * 100,
                duration: const Duration(milliseconds: 500),
                suffix: '%',
                textStyle: widget.responsive.getBodyStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          widget.responsive.smallSpacer,
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

  Widget _buildActionButtons(BuildContext context, bool isOnDuty,
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    if (widget.responsive.isWearable) {
      return _buildWearableActions(context, isOnDuty, currentDuty);
    }

    return _buildMobileActions(context, isOnDuty, currentDuty);
  }

  Widget _buildWearableActions(BuildContext context, bool isOnDuty,
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    return Column(
      children: [
        LargeButton(
          text: isOnDuty ? 'End Duty' : 'Start Duty',
          icon: isOnDuty ? Icons.stop_circle : Icons.play_circle_filled,
          backgroundColor: isOnDuty ? AppTheme.errorRed : AppTheme.successGreen,
          onPressed: () => _handleDutyAction(context, isOnDuty, currentDuty),
        ),
        if (isOnDuty) ...[
          widget.responsive.smallSpacer,
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
              widget.responsive.smallHorizontalSpacer,
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

  Widget _buildMobileActions(BuildContext context, bool isOnDuty,
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: LargeButton(
            text: isOnDuty ? 'End Duty' : 'Start Duty',
            icon: isOnDuty ? Icons.stop_circle : Icons.play_circle_filled,
            backgroundColor: isOnDuty ? AppTheme.errorRed : AppTheme.successGreen,
            onPressed: () => _handleDutyAction(context, isOnDuty, currentDuty),
          ),
        ),
        if (isOnDuty) ...[
          widget.responsive.smallHorizontalSpacer,
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
  ComprehensiveGuardDutyResponseModel? _getCurrentDuty() {
    if (widget.rosterState is RosterLoaded) {
      final rosterData = (widget.rosterState as RosterLoaded).data;
      final now = DateTime.now();
      
      for (final duty in rosterData) {
        if (duty.startsAt.isBefore(now) && duty.endsAt.isAfter(now)) {
          return duty;
        }
      }
    }
    return null;
  }

  ComprehensiveGuardDutyResponseModel? _getNextDuty() {
    if (widget.rosterState is RosterLoaded) {
      final rosterData = (widget.rosterState as RosterLoaded).data;
      final now = DateTime.now();
      
      final futureDuties = rosterData
          .where((duty) => duty.startsAt.isAfter(now))
          .toList()
        ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
      
      return futureDuties.isNotEmpty ? futureDuties.first : null;
    }
    return null;
  }

  bool _isCurrentlyOnDuty(ComprehensiveGuardDutyResponseModel duty) {
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

  String _formatDutyTime(ComprehensiveGuardDutyResponseModel duty) {
    final start = _formatTime(duty.startsAt);
    final end = _formatTime(duty.endsAt);
    final date = _formatDate(duty.startsAt);
    return '$date • $start - $end';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final dutyDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (dutyDate == today) {
      return 'Today';
    } else if (dutyDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return 'Overtime';
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  // Action Handlers
  void _handleDutyAction(BuildContext context, bool isOnDuty,
      ComprehensiveGuardDutyResponseModel? currentDuty) {
    HapticFeedback.lightImpact();
    
    if (isOnDuty && currentDuty != null) {
      _showEndDutyConfirmation(context, currentDuty);
    } else {
      _showStartDutyDialog(context);
    }
  }

  void _showStartDutyDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.play_circle_filled,
              color: AppTheme.successGreen,
              size: widget.responsive.largeIconSize,
            ),
            widget.responsive.smallHorizontalSpacer,
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
              context.read<LocationBloc>().add(const StartLocationTrackingEvent());
              // TODO: Start duty logic
            },
            style: AppTheme.responsivePrimaryButtonStyle(context),
            child: const Text('Start Duty'),
          ),
        ],
      ),
    );
  }

  void _showEndDutyConfirmation(BuildContext context,
      ComprehensiveGuardDutyResponseModel currentDuty) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.stop_circle,
              color: AppTheme.errorRed,
              size: widget.responsive.largeIconSize,
            ),
            widget.responsive.smallHorizontalSpacer,
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
              context.read<LocationBloc>().add(const StopLocationTrackingEvent());
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
      SnackBar(
        content: const Text('Emergency feature coming soon'),
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