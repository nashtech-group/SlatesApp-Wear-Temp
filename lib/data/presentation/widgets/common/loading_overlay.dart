import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class LoadingOverlay extends StatefulWidget {
  final String? message;
  final bool isTransparent;
  final Color? backgroundColor;
  final Color? spinnerColor;
  final double? spinnerSize;
  final bool showProgress;
  final double? progress; // 0.0 to 1.0
  final Widget? customWidget;
  final bool animated;

  const LoadingOverlay({
    super.key,
    this.message,
    this.isTransparent = false,
    this.backgroundColor,
    this.spinnerColor,
    this.spinnerSize,
    this.showProgress = false,
    this.progress,
    this.customWidget,
    this.animated = true,
  });

  @override
  State<LoadingOverlay> createState() => _LoadingOverlayState();
}

class _LoadingOverlayState extends State<LoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.animated) {
      _fadeController.forward();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    Widget content = widget.customWidget ?? _buildDefaultContent(context, responsive, theme);

    if (!widget.animated) {
      return Container(
        color: _getBackgroundColor(theme),
        child: content,
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: _getBackgroundColor(theme),
        child: content,
      ),
    );
  }

  Widget _buildDefaultContent(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Center(
      child: Container(
        padding: responsive.containerPadding,
        decoration: widget.isTransparent
            ? null
            : BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(responsive.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
        child: IntrinsicWidth(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSpinner(responsive, theme),
              if (widget.message != null) ...[
                responsive.mediumSpacer,
                _buildMessage(responsive, theme),
              ],
              if (widget.showProgress && widget.progress != null) ...[
                responsive.mediumSpacer,
                _buildProgressBar(responsive, theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpinner(ResponsiveUtils responsive, ThemeData theme) {
    final spinnerSize = widget.spinnerSize ?? responsive.getResponsiveValue(
      wearable: 24.0,
      smallMobile: 28.0,
      mobile: 32.0,
      tablet: 36.0,
    );

    final spinnerColor = widget.spinnerColor ?? theme.colorScheme.primary;

    if (widget.animated) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: spinnerSize,
              height: spinnerSize,
              child: CircularProgressIndicator(
                strokeWidth: responsive.getResponsiveValue(
                  wearable: 2.0,
                  smallMobile: 2.5,
                  mobile: 3.0,
                  tablet: 3.5,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: responsive.getResponsiveValue(
          wearable: 2.0,
          smallMobile: 2.5,
          mobile: 3.0,
          tablet: 3.5,
        ),
        valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
      ),
    );
  }

  Widget _buildMessage(ResponsiveUtils responsive, ThemeData theme) {
    return Text(
      widget.message!,
      style: responsive.getBodyStyle(
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildProgressBar(ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      children: [
        LinearProgressIndicator(
          value: widget.progress,
          backgroundColor: theme.colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.spinnerColor ?? theme.colorScheme.primary,
          ),
        ),
        responsive.smallSpacer,
        Text(
          '${((widget.progress ?? 0) * 100).toInt()}%',
          style: responsive.getCaptionStyle(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    if (widget.backgroundColor != null) {
      return widget.backgroundColor!;
    }

    if (widget.isTransparent) {
      return Colors.transparent;
    }

    return Colors.black.withValues(alpha: 0.5);
  }
}

/// Simple loading spinner without overlay
class LoadingSpinner extends StatelessWidget {
  final double? size;
  final Color? color;
  final double? strokeWidth;

  const LoadingSpinner({
    super.key,
    this.size,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    final spinnerSize = size ?? responsive.getResponsiveValue(
      wearable: 20.0,
      smallMobile: 24.0,
      mobile: 28.0,
      tablet: 32.0,
    );

    return SizedBox(
      width: spinnerSize,
      height: spinnerSize,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth ?? responsive.getResponsiveValue(
          wearable: 2.0,
          smallMobile: 2.5,
          mobile: 3.0,
          tablet: 3.5,
        ),
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// Loading overlay with skeleton content
class SkeletonLoadingOverlay extends StatefulWidget {
  final int itemCount;
  final double itemHeight;
  final bool showAvatar;

  const SkeletonLoadingOverlay({
    super.key,
    this.itemCount = 3,
    this.itemHeight = 80.0,
    this.showAvatar = true,
  });

  @override
  State<SkeletonLoadingOverlay> createState() => _SkeletonLoadingOverlayState();
}

class _SkeletonLoadingOverlayState extends State<SkeletonLoadingOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _setupShimmerAnimation();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  void _setupShimmerAnimation() {
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _shimmerController.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: responsive.containerPadding,
      child: Column(
        children: List.generate(widget.itemCount, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: responsive.mediumSpacing),
            child: _buildSkeletonItem(responsive),
          );
        }),
      ),
    );
  }

  Widget _buildSkeletonItem(ResponsiveUtils responsive) {
    return Container(
      height: widget.itemHeight,
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
      ),
      child: Row(
        children: [
          if (widget.showAvatar)
            _buildShimmerBox(
              width: responsive.getResponsiveValue(
                wearable: 40.0,
                smallMobile: 45.0,
                mobile: 50.0,
                tablet: 55.0,
              ),
              height: responsive.getResponsiveValue(
                wearable: 40.0,
                smallMobile: 45.0,
                mobile: 50.0,
                tablet: 55.0,
              ),
              isCircle: true,
            ),
          if (widget.showAvatar) responsive.mediumHorizontalSpacer,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildShimmerBox(
                  width: double.infinity,
                  height: responsive.getResponsiveValue(
                    wearable: 12.0,
                    smallMobile: 14.0,
                    mobile: 16.0,
                    tablet: 18.0,
                  ),
                ),
                responsive.smallSpacer,
                _buildShimmerBox(
                  width: responsive.getResponsiveValue(
                    wearable: 100.0,
                    smallMobile: 120.0,
                    mobile: 150.0,
                    tablet: 180.0,
                  ),
                  height: responsive.getResponsiveValue(
                    wearable: 10.0,
                    smallMobile: 12.0,
                    mobile: 14.0,
                    tablet: 16.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerBox({
    required double width,
    required double height,
    bool isCircle = false,
  }) {
    final responsive = context.responsive;

    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: isCircle 
                ? BorderRadius.circular(width / 2)
                : BorderRadius.circular(responsive.borderRadius / 2),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: [
                Colors.grey[300]!,
                Colors.grey[100]!,
                Colors.grey[300]!,
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Compact loading indicator for inline use
class InlineLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;
  final Color? color;

  const InlineLoadingIndicator({
    super.key,
    this.message,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        LoadingSpinner(
          size: size ?? responsive.iconSize,
          color: color ?? theme.colorScheme.primary,
        ),
        if (message != null) ...[
          responsive.smallHorizontalSpacer,
          Text(
            message!,
            style: responsive.getCaptionStyle(
              color: color ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}