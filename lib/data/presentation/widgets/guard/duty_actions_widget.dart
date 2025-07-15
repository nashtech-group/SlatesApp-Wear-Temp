import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/roster_bloc/roster_bloc.dart';
import 'package:slates_app_wear/blocs/location_bloc/location_bloc.dart';
import 'package:slates_app_wear/blocs/checkpoint_bloc/checkpoint_bloc.dart';
import 'package:slates_app_wear/blocs/notification_bloc/notification_bloc.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/large_button.dart';

class DutyActionsWidget extends StatefulWidget {
  final UserModel user;
  final bool isOffline;
  final RosterState rosterState;
  final LocationState locationState;
  final ResponsiveUtils responsive;

  const DutyActionsWidget({
    super.key,
    required this.user,
    required this.isOffline,
    required this.rosterState,
    required this.locationState,
    required this.responsive,
  });

  @override
  State<DutyActionsWidget> createState() => _DutyActionsWidgetState();
}

class _DutyActionsWidgetState extends State<DutyActionsWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _actionAnimations;

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
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Create staggered animations for action buttons
    _actionAnimations = List.generate(6, (index) {
      final start = index * 0.1;
      final end = start + 0.4;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ));
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOnDuty = _isCurrentlyOnDuty();

    return Container(
      padding: widget.responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isOnDuty),
          widget.responsive.mediumSpacer,
          if (widget.responsive.isWearable)
            _buildWearableActions(context, isOnDuty)
          else
            _buildMobileActions(context, isOnDuty),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isOnDuty) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.flash_on,
          color: theme.colorScheme.primary,
          size: widget.responsive.largeIconSize,
        ),
        widget.responsive.smallHorizontalSpacer,
        Expanded(
          child: Text(
            'Quick Actions',
            style: widget.responsive.getTitleStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (isOnDuty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.responsive.smallSpacing,
              vertical: widget.responsive.smallSpacing / 2,
            ),
            decoration: BoxDecoration(
              color: AppTheme.successGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
            ),
            child: Text(
              'ACTIVE',
              style: widget.responsive.getCaptionStyle(
                color: AppTheme.successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWearableActions(BuildContext context, bool isOnDuty) {
    final actions = _getWearableActions(context, isOnDuty);

    return Column(
      children: [
        // Primary actions (most important)
        Row(
          children: [
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(_actionAnimations[0]),
                child: _buildActionCard(
                  context,
                  actions[0],
                  isPrimary: true,
                ),
              ),
            ),
            widget.responsive.smallHorizontalSpacer,
            Expanded(
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(_actionAnimations[1]),
                child: _buildActionCard(
                  context,
                  actions[1],
                  isPrimary: true,
                ),
              ),
            ),
          ],
        ),
        widget.responsive.smallSpacer,
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: FadeTransition(
                opacity: _actionAnimations[2],
                child: _buildActionCard(context, actions[2]),
              ),
            ),
            widget.responsive.smallHorizontalSpacer,
            Expanded(
              child: FadeTransition(
                opacity: _actionAnimations[3],
                child: _buildActionCard(context, actions[3]),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileActions(BuildContext context, bool isOnDuty) {
    final actions = _getMobileActions(context, isOnDuty);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.responsive.isTablet ? 4 : 3,
        crossAxisSpacing: widget.responsive.smallSpacing,
        mainAxisSpacing: widget.responsive.smallSpacing,
        childAspectRatio: 1.0,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        if (index >= _actionAnimations.length) return const SizedBox.shrink();
        
        return ScaleTransition(
          scale: _actionAnimations[index],
          child: _buildActionCard(context, actions[index]),
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    DutyAction action, {
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final isEnabled = action.isEnabled && (!action.requiresOnline || !widget.isOffline);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? () => _handleAction(context, action) : null,
        borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        child: Container(
          padding: widget.responsive.getResponsiveValue(
            wearable: const EdgeInsets.all(8),
            smallMobile: const EdgeInsets.all(10),
            mobile: const EdgeInsets.all(12),
            tablet: const EdgeInsets.all(16),
          ),
          decoration: BoxDecoration(
            color: isEnabled
                ? (isPrimary ? action.color.withValues(alpha: 0.1) : theme.colorScheme.surfaceVariant)
                : theme.colorScheme.surfaceVariant.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
            border: isPrimary
                ? Border.all(
                    color: isEnabled ? action.color : theme.colorScheme.outline,
                    width: 1.5,
                  )
                : Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                action.icon,
                color: isEnabled ? action.color : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: widget.responsive.getResponsiveValue(
                  wearable: 16.0,
                  smallMobile: 18.0,
                  mobile: 20.0,
                  tablet: 24.0,
                ),
              ),
              widget.responsive.smallSpacer,
              Text(
                action.title,
                style: widget.responsive.getCaptionStyle(
                  color: isEnabled
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: widget.responsive.isWearable ? 1 : 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (action.badge != null) ...[
                widget.responsive.smallSpacer,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.responsive.smallSpacing,
                    vertical: widget.responsive.smallSpacing / 2,
                  ),
                  decoration: BoxDecoration(
                    color: action.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(widget.responsive.borderRadius / 2),
                  ),
                  child: Text(
                    action.badge!,
                    style: widget.responsive.getCaptionStyle(
                      color: action.color,
                      fontWeight: FontWeight.w600,
                    )?.copyWith(fontSize: 9),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  List<DutyAction> _getWearableActions(BuildContext context, bool isOnDuty) {
    return [
      DutyAction(
        title: 'Checkpoints',
        icon: Icons.location_on,
        color: AppTheme.primaryTeal,
        isEnabled: isOnDuty,
        requiresOnline: false,
        action: DutyActionType.checkpoints,
        badge: _getPendingCheckpointCount(),
      ),
      DutyAction(
        title: 'Emergency',
        icon: Icons.emergency,
        color: AppTheme.errorRed,
        isEnabled: true,
        requiresOnline: true,
        action: DutyActionType.emergency,
      ),
      DutyAction(
        title: 'Map View',
        icon: Icons.map,
        color: AppTheme.successGreen,
        isEnabled: isOnDuty,
        requiresOnline: false,
        action: DutyActionType.map,
      ),
      DutyAction(
        title: 'Sync Data',
        icon: Icons.sync,
        color: AppTheme.warningOrange,
        isEnabled: true,
        requiresOnline: true,
        action: DutyActionType.sync,
      ),
    ];
  }

  List<DutyAction> _getMobileActions(BuildContext context, bool isOnDuty) {
    return [
      DutyAction(
        title: 'Checkpoints',
        icon: Icons.location_on,
        color: AppTheme.primaryTeal,
        isEnabled: isOnDuty,
        requiresOnline: false,
        action: DutyActionType.checkpoints,
        badge: _getPendingCheckpointCount(),
      ),
      DutyAction(
        title: 'Map View',
        icon: Icons.map,
        color: AppTheme.successGreen,
        isEnabled: isOnDuty,
        requiresOnline: false,
        action: DutyActionType.map,
      ),
      DutyAction(
        title: 'Calendar',
        icon: Icons.calendar_today,
        color: AppTheme.secondaryBlue,
        isEnabled: true,
        requiresOnline: false,
        action: DutyActionType.calendar,
      ),
      DutyAction(
        title: 'Movements',
        icon: Icons.my_location,
        color: AppTheme.accentCyan,
        isEnabled: isOnDuty,
        requiresOnline: false,
        action: DutyActionType.movements,
      ),
      DutyAction(
        title: 'Emergency',
        icon: Icons.emergency,
        color: AppTheme.errorRed,
        isEnabled: true,
        requiresOnline: true,
        action: DutyActionType.emergency,
      ),
      DutyAction(
        title: 'Sync Data',
        icon: Icons.sync,
        color: AppTheme.warningOrange,
        isEnabled: true,
        requiresOnline: true,
        action: DutyActionType.sync,
      ),
    ];
  }

  void _handleAction(BuildContext context, DutyAction action) {
    HapticFeedback.lightImpact();

    switch (action.action) {
      case DutyActionType.checkpoints:
        _handleCheckpoints(context);
        break;
      case DutyActionType.map:
        _handleMapView(context);
        break;
      case DutyActionType.calendar:
        _handleCalendar(context);
        break;
      case DutyActionType.movements:
        _handleMovements(context);
        break;
      case DutyActionType.emergency:
        _handleEmergency(context);
        break;
      case DutyActionType.sync:
        _handleSync(context);
        break;
    }
  }

  void _handleCheckpoints(BuildContext context) {
    if (!_isCurrentlyOnDuty()) {
      _showNotOnDutyMessage(context, 'You must be on duty to access checkpoints');
      return;
    }

    Navigator.of(context).pushNamed(RouteConstants.checkpoints);
  }

  void _handleMapView(BuildContext context) {
    if (!_isCurrentlyOnDuty()) {
      _showNotOnDutyMessage(context, 'You must be on duty to access the map');
      return;
    }

    Navigator.of(context).pushNamed(RouteConstants.mapView);
  }

  void _handleCalendar(BuildContext context) {
    Navigator.of(context).pushNamed(RouteConstants.guardCalendar);
  }

  void _handleMovements(BuildContext context) {
    if (!_isCurrentlyOnDuty()) {
      _showNotOnDutyMessage(context, 'You must be on duty to view movements');
      return;
    }

    Navigator.of(context).pushNamed(RouteConstants.movements);
  }

  void _handleEmergency(BuildContext context) {
    if (widget.isOffline) {
      _showOfflineMessage(context, 'Emergency alerts require internet connection');
      return;
    }

    _showEmergencyDialog(context);
  }

  void _handleSync(BuildContext context) {
    if (widget.isOffline) {
      _showOfflineMessage(context, 'Data sync requires internet connection');
      return;
    }

    _showSyncDialog(context);
  }

  void _showEmergencyDialog(BuildContext context) {
    HapticFeedback.heavyImpact();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.responsive.borderRadius),
        ),
        backgroundColor: AppTheme.errorRed,
        title: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.white,
            ),
            widget.responsive.smallHorizontalSpacer,
            Text(
              'EMERGENCY ALERT',
              style: widget.responsive.getTitleStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'This will immediately alert your supervisors and emergency services. '
          'Only use in case of actual emergency.',
          style: widget.responsive.getBodyStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _triggerEmergencyAlert(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.errorRed,
            ),
            child: const Text('SEND ALERT'),
          ),
        ],
      ),
    );
  }

  void _showSyncDialog(BuildContext context) {
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
              Icons.sync,
              color: AppTheme.warningOrange,
            ),
            widget.responsive.smallHorizontalSpacer,
            const Text('Sync Data'),
          ],
        ),
        content: const Text(
          'This will upload your patrol data and download the latest '
          'roster information. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _triggerDataSync(context);
            },
            child: const Text('Sync Now'),
          ),
        ],
      ),
    );
  }

  void _showNotOnDutyMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOfflineMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.white),
            widget.responsive.smallHorizontalSpacer,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.errorRed,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _triggerEmergencyAlert(BuildContext context) {
    // TODO: Implement emergency alert logic
    context.read<NotificationBloc>().add(const SendEmergencyAlertEvent());
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Emergency alert sent to supervisors'),
        backgroundColor: AppTheme.errorRed,
      ),
    );
  }

  void _triggerDataSync(BuildContext context) {
    // TODO: Implement data sync logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing data...'),
      ),
    );
  }

  bool _isCurrentlyOnDuty() {
    // TODO: Implement logic to check if guard is currently on duty
    // This should check the roster state and current time
    return false; // Placeholder
  }

  String? _getPendingCheckpointCount() {
    // TODO: Implement logic to get pending checkpoint count
    // This should check the checkpoint state
    return null; // Placeholder - could return "3" if there are 3 pending checkpoints
  }
}

// Data classes for duty actions
class DutyAction {
  final String title;
  final IconData icon;
  final Color color;
  final bool isEnabled;
  final bool requiresOnline;
  final DutyActionType action;
  final String? badge;

  const DutyAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.isEnabled,
    required this.requiresOnline,
    required this.action,
    this.badge,
  });
}

enum DutyActionType {
  checkpoints,
  map,
  calendar,
  movements,
  emergency,
  sync,
}