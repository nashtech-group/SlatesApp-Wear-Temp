import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart'; 

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
  final ButtonStyle? style;

  const LargeButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    
    final buttonHeight = height ?? responsive.buttonHeight;
    final loadingIndicatorSize = responsive.iconSize;
    
    // Get theme-aware button colors 
    final buttonColors = AppTheme.getResponsiveButtonColors(
      context,
      customBackgroundColor: backgroundColor,
      customTextColor: textColor,
    );
    
    // Get loading spinner color 
    final loadingSpinnerColor = AppTheme.getResponsiveLoadingSpinnerColor(
      context, 
      isDisabled: isLoading,
    );
    
    return SizedBox(
      width: width ?? double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : () {
          HapticFeedback.lightImpact();
          onPressed?.call();
        },
        style: style ?? AppTheme.getResponsiveButtonStyle(
          context,
          backgroundColor: backgroundColor,
          textColor: textColor,
          borderRadius: borderRadius ?? BorderRadius.circular(responsive.borderRadius),
          padding: responsive.buttonPadding,
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
                  valueColor: AlwaysStoppedAnimation<Color>(loadingSpinnerColor),
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
                        color: buttonColors.textColor,
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