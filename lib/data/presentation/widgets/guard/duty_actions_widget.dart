import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/notification_bloc/notification_bloc.dart';
import 'package:slates_app_wear/data/models/roster/roster_user_model.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';

class DutyActionsWidget extends StatelessWidget {
  final RosterUserModel duty;
  final bool isCompact;

  const DutyActionsWidget({
    super.key,
    required this.duty,
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
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duty Actions',
              style: (theme.textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            
            if (isCompact) 
              _buildCompactActions(context, responsive, theme)
            else 
              _buildFullActions(context, responsive, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActions(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            responsive,
            theme,
            icon: Icons.qr_code_scanner,
            label: 'Scan',
            onPressed: () => _navigateToCheckpoints(context),
            isPrimary: true,
          ),
        ),
        SizedBox(width: responsive.smallSpacing),
        Expanded(
          child: _buildActionButton(
            context,
            responsive,
            theme,
            icon: Icons.map,
            label: 'Map',
            onPressed: () => _navigateToMapView(context),
          ),
        ),
        SizedBox(width: responsive.smallSpacing),
        _buildEmergencyButton(context, responsive, theme, isCompact: true),
      ],
    );
  }

  Widget _buildFullActions(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      children: [
        // Primary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                responsive,
                theme,
                icon: Icons.qr_code_scanner,
                label: 'Checkpoints',
                subtitle: 'Scan QR codes',
                onPressed: () => _navigateToCheckpoints(context),
                isPrimary: true,
              ),
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: _buildActionButton(
                context,
                responsive,
                theme,
                icon: Icons.map,
                label: 'Map View',
                subtitle: 'Site navigation',
                onPressed: () => _navigateToMapView(context),
              ),
            ),
          ],
        ),

        SizedBox(height: responsive.smallSpacing),

        // Secondary Actions Row
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                responsive,
                theme,
                icon: Icons.calendar_today,
                label: 'Calendar',
                subtitle: 'View schedule',
                onPressed: () => _navigateToGuardCalendar(context),
              ),
            ),
            SizedBox(width: responsive.smallSpacing),
            Expanded(
              child: _buildEmergencyButton(context, responsive, theme),
            ),
          ],
        ),

        if (duty.isCurrentlyOnDuty) ...[
          SizedBox(height: responsive.mediumSpacing),
          _buildDutyStatusActions(context, responsive, theme),
        ],
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme, {
    required IconData icon,
    required String label,
    String? subtitle,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: isCompact ? 60 : (subtitle != null ? 80 : 60),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? theme.colorScheme.primary 
              : theme.colorScheme.surface,
          foregroundColor: isPrimary 
              ? theme.colorScheme.onPrimary 
              : theme.colorScheme.onSurface,
          elevation: isPrimary ? 2 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
            side: isPrimary 
                ? BorderSide.none 
                : BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
          ),
          padding: EdgeInsets.all(responsive.smallSpacing),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isCompact ? responsive.iconSize * 0.8 : responsive.iconSize,
            ),
            if (!isCompact) ...[
              SizedBox(height: responsive.smallSpacing * 0.5),
              Text(
                label,
                style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall ?? const TextStyle(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ] else
              Text(
                label,
                style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme, {
    bool isCompact = false,
  }) {
    return SizedBox(
      height: isCompact ? 60 : 80,
      width: isCompact ? 60 : double.infinity,
      child: ElevatedButton(
        onPressed: () => _showEmergencyAlert(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.error,
          foregroundColor: theme.colorScheme.onError,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
          padding: EdgeInsets.all(responsive.smallSpacing),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning,
              size: isCompact ? responsive.iconSize * 0.8 : responsive.iconSize,
            ),
            if (!isCompact) ...[
              SizedBox(height: responsive.smallSpacing * 0.5),
              Text(
                'Emergency',
                style: (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Alert',
                style: theme.textTheme.labelSmall ?? const TextStyle(),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDutyStatusActions(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'On Duty Actions',
            style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: responsive.smallSpacing),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _startPerimeterCheck(context),
                  icon: const Icon(Icons.route),
                  label: const Text('Start Check'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                  ),
                ),
              ),
              SizedBox(width: responsive.smallSpacing),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _recordMovement(context),
                  icon: const Icon(Icons.my_location),
                  label: const Text('Record Move'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                    side: BorderSide(color: theme.colorScheme.secondary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Navigation methods
  void _navigateToCheckpoints(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteConstants.checkpoints,
      arguments: duty,
    );
  }

  void _navigateToMapView(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteConstants.mapView,
      arguments: duty,
    );
  }

  void _navigateToGuardCalendar(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteConstants.guardCalendar,
      arguments: duty.guardId,
    );
  }

  // Action methods
  void _showEmergencyAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Alert'),
        content: const Text(
          'Are you sure you want to send an emergency alert? This will notify all supervisors and emergency contacts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _sendEmergencyAlert(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );
  }

  void _sendEmergencyAlert(BuildContext context) {
    context.read<NotificationBloc>().add(
      ShowEmergencyAlert(
        title: 'Emergency Alert',
        message: 'Emergency alert sent from ${duty.site.name}',
        payload: {
          'dutyId': duty.id,
          'siteId': duty.site.id,
          'guardId': duty.guardId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Emergency alert sent successfully'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _startPerimeterCheck(BuildContext context) {
    Navigator.of(context).pushNamed(
      RouteConstants.checkpoints,
      arguments: {
        'duty': duty,
        'mode': 'perimeter_check',
      },
    );
  }

  void _recordMovement(BuildContext context) {
    // Record current movement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.my_location, color: Colors.white),
            SizedBox(width: 8),
            Text('Movement recorded'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}