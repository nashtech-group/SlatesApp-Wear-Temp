import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/data/presentation/widgets/common/status_indicator.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class GuardStatusWidget extends StatefulWidget {
  final int guardId;
  final RosterUserModel? currentDuty;
  final bool showActions;

  const GuardStatusWidget({
    super.key,
    required this.guardId,
    this.currentDuty,
    this.showActions = true,
  });

  @override
  State<GuardStatusWidget> createState() => _GuardStatusWidgetState();
}

class _GuardStatusWidgetState extends State<GuardStatusWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _pulseAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.currentDuty?.isCurrentlyOnDuty == true) {
      _pulseAnimationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GuardStatusWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Update animations based on duty status
    if (widget.currentDuty?.isCurrentlyOnDuty == true) {
      if (!_pulseAnimationController.isAnimating) {
        _pulseAnimationController.repeat(reverse: true);
      }
    } else {
      _pulseAnimationController.stop();
    }
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
          gradient: _getStatusGradient(theme),
        ),
        child: Padding(
          padding: responsive.containerPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusHeader(context, responsive, theme),
              SizedBox(height: responsive.mediumSpacing),
              _buildStatusContent(context, responsive, theme),
              if (widget.showActions && widget.currentDuty != null) ...[
                SizedBox(height: responsive.mediumSpacing),
                _buildStatusActions(context, responsive, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusHeader(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: widget.currentDuty?.isCurrentlyOnDuty == true 
                  ? _pulseAnimation.value 
                  : 1.0,
              child: StatusIndicator(
                status: _getStatusType(),
                showAnimation: widget.currentDuty?.isCurrentlyOnDuty == true,
                size: responsive.iconSize,
              ),
            );
          },
        ),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getStatusTitle(),
                style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.currentDuty != null)
                Text(
                  widget.currentDuty!.site.name,
                  style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                    color: Colors.white70,
                  ),
                ),
            ],
          ),
        ),
        _buildConnectionStatus(context, responsive, theme),
      ],
    );
  }

  Widget _buildConnectionStatus(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return BlocBuilder<LocationBloc, LocationState>(
      builder: (context, locationState) {
        final isConnected = locationState is LocationTrackingActive;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.smallSpacing,
            vertical: responsive.smallSpacing * 0.5,
          ),
          decoration: BoxDecoration(
            color: isConnected 
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(responsive.borderRadius * 0.5),
            border: Border.all(
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isConnected ? Icons.cloud_done : Icons.cloud_off,
                size: responsive.iconSize * 0.6,
                color: isConnected ? Colors.green : Colors.red,
              ),
              SizedBox(width: responsive.smallSpacing * 0.5),
              Text(
                isConnected ? 'Online' : 'Offline',
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  color: isConnected ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusContent(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    if (widget.currentDuty == null) {
      return _buildNoDutyContent(context, responsive, theme);
    }

    return Column(
      children: [
        _buildDutyTimeInfo(context, responsive, theme),
        SizedBox(height: responsive.smallSpacing),
        _buildDutyProgress(context, responsive, theme),
      ],
    );
  }

  Widget _buildNoDutyContent(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        children: [
          Icon(
            Icons.free_breakfast,
            size: responsive.iconSize * 1.5,
            color: Colors.white70,
          ),
          SizedBox(height: responsive.smallSpacing),
          Text(
            'No Active Duty',
            style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'You are currently off duty',
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDutyTimeInfo(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    final duty = widget.currentDuty!;
    
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Colors.white,
                size: responsive.iconSize * 0.8,
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duty Hours',
                      style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${_formatTime(duty.startsAt)} - ${_formatTime(duty.endsAt)}',
                      style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: responsive.smallSpacing),
          
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.white,
                size: responsive.iconSize * 0.8,
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      duty.site.physicalAddress,
                      style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDutyProgress(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    final duty = widget.currentDuty!;
    final now = DateTime.now();
    
    if (!duty.isCurrentlyOnDuty) {
      return Container(
        padding: responsive.containerPadding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        child: Row(
          children: [
            Icon(
              duty.isDutyUpcoming ? Icons.upcoming : Icons.history,
              color: Colors.white,
              size: responsive.iconSize * 0.8,
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: Text(
                duty.isDutyUpcoming 
                    ? 'Duty starts in ${_getTimeUntil(duty.startsAt)}'
                    : 'Duty ended ${_getTimeSince(duty.endsAt)} ago',
                style: (theme.textTheme.bodyMedium ?? const TextStyle()).copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Calculate progress
    final totalDuration = duty.endsAt.difference(duty.startsAt);
    final elapsed = now.difference(duty.startsAt);
    final progress = (elapsed.inMinutes / totalDuration.inMinutes).clamp(0.0, 1.0);
    
    return Container(
      padding: responsive.containerPadding,
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
                style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  color: Colors.white70,
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: responsive.smallSpacing * 0.5),
          
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          
          SizedBox(height: responsive.smallSpacing * 0.5),
          
          Text(
            'Time remaining: ${_getTimeRemaining(duty.endsAt)}',
            style: (theme.textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActions(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: BlocBuilder<LocationBloc, LocationState>(
            builder: (context, locationState) {
              final isTracking = locationState is LocationTrackingActive;
              
              return ElevatedButton.icon(
                onPressed: () => _toggleLocationTracking(context),
                icon: Icon(
                  isTracking ? Icons.location_off : Icons.my_location,
                ),
                label: Text(
                  isTracking ? 'Stop Tracking' : 'Start Tracking',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isTracking 
                      ? theme.colorScheme.error 
                      : Colors.green,
                  foregroundColor: Colors.white,
                ),
              );
            },
          ),
        ),
        
        SizedBox(width: responsive.smallSpacing),
        
        ElevatedButton.icon(
          onPressed: () => _checkInOut(context),
          icon: Icon(
            widget.currentDuty!.withinPerimeter 
                ? Icons.check_circle 
                : Icons.location_searching,
          ),
          label: Text(
            widget.currentDuty!.withinPerimeter ? 'Checked In' : 'Check In',
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.currentDuty!.withinPerimeter 
                ? Colors.green 
                : theme.colorScheme.secondary,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  LinearGradient _getStatusGradient(ThemeData theme) {
    if (widget.currentDuty == null) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          theme.colorScheme.outline,
          theme.colorScheme.outline.withValues(alpha: 0.8),
        ],
      );
    }

    if (widget.currentDuty!.isCurrentlyOnDuty) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.green,
          Color(0xFF4CAF50),
        ],
      );
    }

    if (widget.currentDuty!.isDutyUpcoming) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.orange,
          Colors.orange.withValues(alpha: 0.8),
        ],
      );
    }

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        theme.colorScheme.outline,
        theme.colorScheme.outline.withValues(alpha: 0.8),
      ],
    );
  }

  StatusType _getStatusType() {
    if (widget.currentDuty == null) {
      return StatusType.offDuty;
    }

    if (widget.currentDuty!.isCurrentlyOnDuty) {
      return StatusType.onDuty;
    }

    if (widget.currentDuty!.isDutyUpcoming) {
      return StatusType.pending;
    }

    return StatusType.offDuty;
  }

  String _getStatusTitle() {
    if (widget.currentDuty == null) {
      return 'Off Duty';
    }

    if (widget.currentDuty!.isCurrentlyOnDuty) {
      return 'On Duty';
    }

    if (widget.currentDuty!.isDutyUpcoming) {
      return 'Upcoming Duty';
    }

    return 'Duty Completed';
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getTimeUntil(DateTime future) {
    final difference = future.difference(DateTime.now());
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _getTimeSince(DateTime past) {
    final difference = DateTime.now().difference(past);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _getTimeRemaining(DateTime future) {
    final difference = future.difference(DateTime.now());
    
    if (difference.isNegative) {
      return 'Duty ended';
    }
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  void _toggleLocationTracking(BuildContext context) {
    final locationBloc = context.read<LocationBloc>();
    final locationState = locationBloc.state;

    if (locationState is LocationTrackingActive) {
      locationBloc.add(const StopLocationTracking());
      setState(() {
      });
    } else if (widget.currentDuty != null) {
      locationBloc.add(
        StartLocationTracking(
          guardId: widget.currentDuty!.guardId,
          rosterUserId: widget.currentDuty!.id,
          site: widget.currentDuty!.site,
          isDutyActive: widget.currentDuty!.isCurrentlyOnDuty,
        ),
      );
      setState(() {
      });
    }
  }

  void _checkInOut(BuildContext context) {
    if (widget.currentDuty == null) return;

    // Trigger location check and update roster status
    context.read<RosterBloc>().add(
      RefreshRosterData(guardId: widget.guardId),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              widget.currentDuty!.withinPerimeter 
                  ? 'Location verified' 
                  : 'Checking location...',
            ),
          ],
        ),
        backgroundColor: widget.currentDuty!.withinPerimeter 
            ? Colors.green 
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}