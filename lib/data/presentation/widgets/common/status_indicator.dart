import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

enum StatusType {
  online,
  offline,
  onDuty,
  offDuty,
  warning,
  error,
  success,
  pending,
}

class StatusIndicator extends StatefulWidget {
  final StatusType status;
  final String? label;
  final bool showAnimation;
  final double? size;
  final EdgeInsets? padding;

  const StatusIndicator({
    super.key,
    required this.status,
    this.label,
    this.showAnimation = true,
    this.size,
    this.padding,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    if (widget.showAnimation) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final statusInfo = _getStatusInfo(context);

    return Container(
      padding: widget.padding ?? EdgeInsets.all(responsive.smallSpacing),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIndicator(context, responsive, statusInfo),
          if (widget.label != null) ...[
            SizedBox(width: responsive.smallSpacing),
            Text(
              widget.label!,
              style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                color: statusInfo.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(BuildContext context, ResponsiveUtils responsive, StatusInfo statusInfo) {
    final indicatorSize = widget.size ?? responsive.iconSize * 0.6;

    if (widget.showAnimation && statusInfo.shouldAnimate) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: _buildCircularIndicator(indicatorSize, statusInfo),
            ),
          );
        },
      );
    }

    return _buildCircularIndicator(indicatorSize, statusInfo);
  }

  Widget _buildCircularIndicator(double size, StatusInfo statusInfo) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: statusInfo.color,
        boxShadow: [
          BoxShadow(
            color: statusInfo.color.withValues(alpha: 0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: statusInfo.icon != null
          ? Icon(
              statusInfo.icon,
              size: size * 0.6,
              color: Colors.white,
            )
          : null,
    );
  }

  StatusInfo _getStatusInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (widget.status) {
      case StatusType.online:
        return StatusInfo(
          color: Colors.green,
          shouldAnimate: true,
          icon: Icons.circle,
        );

      case StatusType.offline:
        return StatusInfo(
          color: Colors.red,
          shouldAnimate: false,
          icon: Icons.circle,
        );

      case StatusType.onDuty:
        return StatusInfo(
          color: theme.colorScheme.primary,
          shouldAnimate: true,
          icon: Icons.security,
        );

      case StatusType.offDuty:
        return StatusInfo(
          color: Colors.grey,
          shouldAnimate: false,
          icon: Icons.security,
        );

      case StatusType.warning:
        return StatusInfo(
          color: Colors.orange,
          shouldAnimate: true,
          icon: Icons.warning,
        );

      case StatusType.error:
        return StatusInfo(
          color: Colors.red,
          shouldAnimate: true,
          icon: Icons.error,
        );

      case StatusType.success:
        return StatusInfo(
          color: Colors.green,
          shouldAnimate: false,
          icon: Icons.check_circle,
        );

      case StatusType.pending:
        return StatusInfo(
          color: Colors.amber,
          shouldAnimate: true,
          icon: Icons.pending,
        );
    }
  }
}

class StatusInfo {
  final Color color;
  final bool shouldAnimate;
  final IconData? icon;

  StatusInfo({
    required this.color,
    required this.shouldAnimate,
    this.icon,
  });
}

// Battery Status Widget 
class BatteryStatusIndicator extends StatelessWidget {
  final int batteryLevel;
  final bool isCharging;
  final double? size;

  const BatteryStatusIndicator({
    super.key,
    required this.batteryLevel,
    required this.isCharging,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final indicatorSize = size ?? responsive.iconSize;

    return Container(
      padding: EdgeInsets.all(responsive.smallSpacing * 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getBatteryIcon(),
            size: indicatorSize,
            color: _getBatteryColor(),
          ),
          SizedBox(width: responsive.smallSpacing * 0.5),
          Text(
            '$batteryLevel%',
            style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
              color: _getBatteryColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getBatteryIcon() {
    if (isCharging) return Icons.battery_charging_full;
    
    if (batteryLevel >= 90) return Icons.battery_full;
    if (batteryLevel >= 60) return Icons.battery_6_bar;
    if (batteryLevel >= 40) return Icons.battery_4_bar;
    if (batteryLevel >= 20) return Icons.battery_2_bar;
    return Icons.battery_alert;
  }

  Color _getBatteryColor() {
    if (isCharging) return Colors.green;
    if (batteryLevel <= 15) return Colors.red;
    if (batteryLevel <= 30) return Colors.orange;
    return Colors.green;
  }
}

// Connection Status Widget
class ConnectionStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final String? connectionType;
  final double? size;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.connectionType,
    this.size,
  });

  @override
  Widget build(BuildContext context) {

    return StatusIndicator(
      status: isConnected ? StatusType.online : StatusType.offline,
      label: connectionType ?? (isConnected ? 'Connected' : 'Offline'),
      size: size,
      showAnimation: !isConnected,
    );
  }
}

// Sync Status Widget  
class SyncStatusIndicator extends StatelessWidget {
  final bool isSyncing;
  final DateTime? lastSyncTime;
  final bool hasPendingSync;

  const SyncStatusIndicator({
    super.key,
    required this.isSyncing,
    this.lastSyncTime,
    this.hasPendingSync = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    if (isSyncing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: responsive.iconSize * 0.6,
            height: responsive.iconSize * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          SizedBox(width: responsive.smallSpacing),
          Text(
            'Syncing...',
            style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return StatusIndicator(
      status: hasPendingSync ? StatusType.warning : StatusType.success,
      label: _getSyncLabel(),
      showAnimation: hasPendingSync,
    );
  }

  String _getSyncLabel() {
    if (hasPendingSync) return 'Sync Pending';
    if (lastSyncTime == null) return 'Never Synced';
    
    final now = DateTime.now();
    final difference = now.difference(lastSyncTime!);
    
    // Fixed: Added null check before subtraction
    if (difference.inMinutes < 1) {
      return 'Just synced';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}