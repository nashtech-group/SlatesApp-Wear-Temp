import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/utils/status_colors.dart';
import 'package:slates_app_wear/services/date_service.dart';

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
    return widget.onlineColor ?? StatusColors.getConnectionStatusColor(true);
  }

  Color _getOfflineColor() {
    return widget.offlineColor ?? StatusColors.getConnectionStatusColor(false);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    final indicatorSize = widget.size ?? responsive.iconSize;

    if (widget.showLabel) {
      return _buildWithLabel(context, responsive, theme, indicatorSize);
    }

    return _buildIndicatorOnly(context, responsive, indicatorSize);
  }

  Widget _buildIndicatorOnly(
      BuildContext context, ResponsiveUtils responsive, double size) {
    return AnimatedBuilder(
      animation:
          widget.animated ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        return AnimatedBuilder(
          animation: widget.animated
              ? _scaleAnimation
              : const AlwaysStoppedAnimation(1.0),
          builder: (context, child) {
            return Transform.scale(
              scale: widget.animated ? _scaleAnimation.value : 1.0,
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: widget.animated
                      ? (_colorAnimation.value ??
                          (widget.isOnline
                              ? _getOnlineColor()
                              : _getOfflineColor()))
                      : (widget.isOnline
                          ? _getOnlineColor()
                          : _getOfflineColor()),
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
                  StatusColors.getConnectionStatusIcon(widget.isOnline),
                  color: StatusColors.getTextColorForBackground(
                      widget.isOnline ? _getOnlineColor() : _getOfflineColor()),
                  size: size * 0.6,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWithLabel(BuildContext context, ResponsiveUtils responsive,
      ThemeData theme, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicatorOnly(context, responsive, size),
        responsive.smallHorizontalSpacer,
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            StatusColors.getConnectionStatusLabel(widget.isOnline),
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
        color: StatusColors.getConnectionStatusColor(isOnline),
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
    final dateService = DateService();

    // Grab your base caption style once
    final TextStyle? baseCaption = responsive.getCaptionStyle(
      color: StatusColors.getConnectionStatusColor(isOnline),
      fontWeight: FontWeight.w600,
    );

    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        smallMobile: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      ),
      decoration: StatusColors.getStatusIndicatorDecoration(
        color: StatusColors.getConnectionStatusColor(isOnline),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
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
                customMessage ??
                    StatusColors.getConnectionStatusLabel(isOnline),
                style: baseCaption,
              ),

              if (showSyncTime &&
                  lastSyncTime != null &&
                  baseCaption?.fontSize != null)
                Text(
                  'Last sync: ${dateService.formatTimestampSmart(lastSyncTime!)}',
                  style: baseCaption!.copyWith(
                    fontSize: baseCaption.fontSize! - 1,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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
  State<ConnectionQualityIndicator> createState() =>
      _ConnectionQualityIndicatorState();
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
        StatusColors.getSignalStrengthIcon(0),
        size: baseSize,
        color: StatusColors.getSignalStrengthColor(0),
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
                height:
                    barHeight * (isActive ? _barAnimations[index].value : 0.3),
                decoration: BoxDecoration(
                  color: isActive
                      ? StatusColors.getSignalStrengthColor(
                          widget.signalStrength)
                      : StatusColors.getSignalStrengthColor(
                              widget.signalStrength)
                          .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
