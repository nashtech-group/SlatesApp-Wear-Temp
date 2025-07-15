import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class StatusIndicator extends StatefulWidget {
  final bool isOnline;
  final double? size;
  final bool showLabel;
  final Color? onlineColor;
  final Color? offlineColor;
  final bool animated;

  const StatusIndicator({
    super.key,
    required this.isOnline,
    this.size,
    this.showLabel = false,
    this.onlineColor,
    this.offlineColor,
    this.animated = true,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _transitionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _transitionController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isOnline != widget.isOnline && widget.animated) {
      _transitionController.forward(from: 0);
    }
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.elasticOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getOfflineColor(),
      end: _getOnlineColor(),
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOut,
    ));

    if (widget.isOnline && widget.animated) {
      _pulseController.repeat(reverse: true);
    }
  }

  Color _getOnlineColor() {
    return widget.onlineColor ?? AppTheme.successGreen;
  }

  Color _getOfflineColor() {
    return widget.offlineColor ?? AppTheme.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final indicatorSize = widget.size ?? responsive.iconSize;

    if (widget.showLabel) {
      return _buildWithLabel(context, responsive, indicatorSize);
    }

    return _buildIndicatorOnly(context, responsive, indicatorSize);
  }

  Widget _buildIndicatorOnly(BuildContext context, ResponsiveUtils responsive, double size) {
    return AnimatedBuilder(
      animation: widget.animated ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return AnimatedBuilder(
          animation: widget.animated ? _scaleAnimation : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.animated ? _scaleAnimation.value : 1.0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: widget.animated 
                      ? (_colorAnimation.value ?? (widget.isOnline ? _getOnlineColor() : _getOfflineColor()))
                      : (widget.isOnline ? _getOnlineColor() : _getOfflineColor()),
                  shape: BoxShape.circle,
                  boxShadow: widget.isOnline && widget.animated
                      ? [
                          BoxShadow(
                            color: _getOnlineColor().withValues(alpha: 0.4),
                            blurRadius: 8 * _pulseAnimation.value,
                            spreadRadius: 2 * _pulseAnimation.value,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  widget.isOnline ? Icons.wifi : Icons.wifi_off,
                  color: Colors.white,
                  size: size * 0.6,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithLabel(BuildContext context, ResponsiveUtils responsive, double size) {
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicatorOnly(context, responsive, size),
        responsive.smallHorizontalSpacer,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            widget.isOnline ? 'Online' : 'Offline',
            key: ValueKey(widget.isOnline),
            style: responsive.getCaptionStyle(
              color: widget.isOnline ? _getOnlineColor() : _getOfflineColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact status indicator for minimal space usage
class CompactStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final double? size;

  const CompactStatusIndicator({
    super.key,
    required this.isOnline,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final indicatorSize = size ?? (responsive.iconSize * 0.7);

    return Container(
      width: indicatorSize,
      height: indicatorSize,
      decoration: BoxDecoration(
        color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Status indicator with detailed information
class DetailedStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final String? customMessage;
  final DateTime? lastSyncTime;
  final bool showSyncTime;

  const DetailedStatusIndicator({
    super.key,
    required this.isOnline,
    this.customMessage,
    this.lastSyncTime,
    this.showSyncTime = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        smallMobile: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      ),
      decoration: BoxDecoration(
        color: (isOnline ? AppTheme.successGreen : AppTheme.errorRed)
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
        border: Border.all(
          color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompactStatusIndicator(
            isOnline: isOnline,
            size: responsive.iconSize * 0.8,
          ),
          responsive.smallHorizontalSpacer,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                customMessage ?? (isOnline ? 'Connected' : 'Offline'),
                style: responsive.getCaptionStyle(
                  color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showSyncTime && lastSyncTime != null)
                Text(
                  'Last sync: ${_formatSyncTime(lastSyncTime!)}',
                  style: responsive.getCaptionStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                  )?.copyWith(fontSize: responsive.getCaptionStyle()?.fontSize! - 1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Status indicator for connection quality
class ConnectionQualityIndicator extends StatefulWidget {
  final bool isOnline;
  final int signalStrength; // 0-4 (0 = offline, 1-4 = signal strength)
  final double? size;

  const ConnectionQualityIndicator({
    super.key,
    required this.isOnline,
    required this.signalStrength,
    this.size,
  });

  @override
  State<ConnectionQualityIndicator> createState() => _ConnectionQualityIndicatorState();
}

class _ConnectionQualityIndicatorState extends State<ConnectionQualityIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late List<Animation<double>> _barAnimations;

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _barAnimations = List.generate(4, (index) {
      final start = index * 0.1;
      final end = start + 0.3;
      
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Interval(start, end, curve: Curves.easeOut),
      ));
    });

    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final baseSize = widget.size ?? responsive.iconSize;

    if (!widget.isOnline) {
      return Icon(
        Icons.signal_wifi_off,
        size: baseSize,
        color: AppTheme.errorRed,
      );
    }

    return SizedBox(
      width: baseSize,
      height: baseSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final isActive = index < widget.signalStrength;
          final barHeight = (baseSize * 0.2) + (index * (baseSize * 0.2));
          
          return AnimatedBuilder(
            animation: _barAnimations[index],
            builder: (context, child) {
              return Container(
                width: baseSize * 0.15,
                height: barHeight * (isActive ? _barAnimations[index].value : 0.3),
                decoration: BoxDecoration(
                  color: isActive 
                      ? _getSignalColor(widget.signalStrength)
                      : _getSignalColor(widget.signalStrength).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  Color _getSignalColor(int strength) {
    switch (strength) {
      case 1:
        return AppTheme.errorRed;
      case 2:
        return AppTheme.warningOrange;
      case 3:
        return AppTheme.warningOrange;
      case 4:
        return AppTheme.successGreen;
      default:
        return AppTheme.errorRed;
    }
  }
}