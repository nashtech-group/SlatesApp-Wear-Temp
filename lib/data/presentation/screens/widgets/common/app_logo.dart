import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;

  const AppLogo({
    super.key,
    this.size = 80,
    this.showText = true,
    this.showSubtitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image with theme-aware background
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * 0.2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                blurRadius: responsive.getResponsiveValue(
                  wearable: 6.0,
                  smallMobile: 8.0,
                  mobile: 10.0,
                  tablet: 12.0,
                ),
                offset: Offset(
                    0,
                    responsive.getResponsiveValue(
                      wearable: 2.0,
                      smallMobile: 3.0,
                      mobile: 4.0,
                      tablet: 5.0,
                    )),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.15),
          child: Image.asset(
            'assets/images/applogo.png',
            fit: BoxFit.contain,
          ),
        ),

        if (showText) ...[
          SizedBox(height: size * 0.15),
          // App name with responsive text
          Text(
            'SlatesApp',
            style: responsive.getHeadlineStyle(
              color: AppTheme.getLogoTextColor(context),
              fontWeight: FontWeight.bold,
              baseFontSize: size * 0.25,
            ),
          ),

          if (showSubtitle) ...[
            SizedBox(height: size * 0.05),
            Text(
              'Security Operations Platform',
              style: responsive.getBodyStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                baseFontSize: size * 0.15,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
