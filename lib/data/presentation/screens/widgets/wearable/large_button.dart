import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class LargeButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const LargeButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    final buttonHeight = height ?? responsive.buttonHeight;
    final loadingIndicatorSize = responsive.iconSize;
    
    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
          foregroundColor: textColor ?? Colors.white,
          disabledBackgroundColor: Theme.of(context).colorScheme.outline,
          disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.38),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(responsive.borderRadius),
          ),
          elevation: 2,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha: 0.2),
          padding: responsive.buttonPadding,
          textStyle: responsive.getBodyStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: loadingIndicatorSize,
                height: loadingIndicatorSize,
                child: CircularProgressIndicator(
                  strokeWidth: responsive.getResponsiveValue(
                    wearable: 2.0,
                    smallMobile: 2.5,
                    mobile: 3.0,
                    tablet: 3.5,
                  ),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    textColor ?? Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: responsive.iconSize),
                    SizedBox(width: responsive.smallSpacing),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: responsive.getBodyStyle(
                        color: textColor ?? Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}