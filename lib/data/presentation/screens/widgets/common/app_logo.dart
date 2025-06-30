import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool showSubtitle;

  const AppLogo({
    Key? key,
    this.size = 80,
    this.showText = true,
    this.showSubtitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
          // App name with theme-aware color
          Text(
            'SlatesApp',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getLogoTextColor(context),
                ),
          ),

          if (showSubtitle) ...[
            SizedBox(height: size * 0.05),
            Text(
              'Security Management',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: size * 0.15,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ],
    );
  }
}
