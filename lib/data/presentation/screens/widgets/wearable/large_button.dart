import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isWearable = screenSize.width < 250 || screenSize.height < 250;
    
    final buttonHeight = height ?? (isWearable ? 44.0 : 56.0);
    final fontSize = isWearable ? 12.0 : 16.0;
    final iconSize = isWearable ? 16.0 : 20.0;
    final horizontalPadding = isWearable ? 12.0 : 24.0;
    
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
          disabledForegroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha:0.38),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(isWearable ? 12 : 16),
          ),
          elevation: 2,
          shadowColor: Theme.of(context).shadowColor.withValues(alpha:0.2),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          textStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            fontFamily: Theme.of(context).textTheme.labelLarge?.fontFamily,
          ),
        ),
        child: isLoading
            ? SizedBox(
                width: iconSize,
                height: iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
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
                    Icon(icon, size: iconSize),
                    SizedBox(width: isWearable ? 4 : 8),
                  ],
                  Flexible(
                    child: Text(
                      text,
                      style: TextStyle(fontSize: fontSize),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
