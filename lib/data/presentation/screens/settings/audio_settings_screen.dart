import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/settings/audio_settings_widget.dart';
import 'package:slates_app_wear/data/presentation/screens/widgets/wearable/wearable_scaffold.dart';

class AudioSettingsScreen extends StatelessWidget {
  const AudioSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return WearableScaffold(
      isRoundScreen: responsive.isRoundScreen,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Audio Settings',
            style: responsive.getTitleStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: responsive.containerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header description
                Container(
                  padding: responsive.containerPadding,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: responsive.iconSize,
                          ),
                          responsive.smallHorizontalSpacer,
                          Text(
                            'Guard Audio System',
                            style: responsive.getBodyStyle(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      responsive.smallSpacer,
                      Text(
                        'Configure sound effects, voice announcements, and vibration feedback for your guard duties. These settings help you stay informed during patrol and static duty assignments.',
                        style: responsive.getCaptionStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                responsive.mediumSpacer,
                
                // Main audio settings widget
                const AudioSettingsWidget(isExpanded: true),
                
                responsive.extraLargeSpacing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

