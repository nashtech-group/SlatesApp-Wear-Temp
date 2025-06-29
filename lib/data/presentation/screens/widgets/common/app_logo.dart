import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final isWearable = screenSize.width < 250 || screenSize.height < 250;

    // Adjust sizes for wearables
    final logoSize = isWearable ? size * 0.8 : size;
    final textSize = isWearable ? size * 0.2 : size * 0.25;
    final subtitleSize = isWearable ? size * 0.12 : size * 0.15;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo image with theme-aware background
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(logoSize * 0.2),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withValues(alpha:0.1),
                blurRadius: isWearable ? 6 : 10,
                offset: Offset(0, isWearable ? 2 : 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(logoSize * 0.15),
          child: _buildLogoContent(logoSize),
        ),

        if (showText && !isWearable) ...[
          SizedBox(height: logoSize * 0.15),
          // App name with theme-aware color
          Text(
            'SlatesApp',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getLogoTextColor(context),
                ),
          ),

          if (showSubtitle) ...[
            SizedBox(height: logoSize * 0.05),
            Text(
              'Security Management',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: subtitleSize,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],

        // Simplified text for wearables
        if (showText && isWearable) ...[
          SizedBox(height: logoSize * 0.1),
          Text(
            'SlatesApp',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: textSize,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getLogoTextColor(context),
                ),
          ),
        ],
      ],
    );
  }

  Widget _buildLogoContent(double logoSize) {
    // For now, using a placeholder. In real app, this would be:
    Image.asset('assets/images/applogo.png', fit: BoxFit.contain);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryTeal,
            AppTheme.primaryTealLight,
          ],
        ),
        borderRadius: BorderRadius.circular(logoSize * 0.1),
      ),
      child: Center(
        child: Icon(
          Icons.security,
          color: Colors.white,
          size: logoSize * 0.4,
        ),
      ),
    );
  }
}
