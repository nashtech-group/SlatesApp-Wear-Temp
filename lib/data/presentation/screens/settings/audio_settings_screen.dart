import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/data/presentation/widgets/wearable/wearable_scaffold.dart';

class AudioSettingsScreen extends StatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  State<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends State<AudioSettingsScreen> {
  double _masterVolume = 0.7;
  double _notificationVolume = 0.8;
  double _alertVolume = 0.9;
  bool _isVibrationEnabled = true;
  bool _isSilentModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return WearableScaffold(
      body: Column(
        children: [
          _buildHeader(context, responsive, theme),
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVolumeControls(context, responsive, theme),
                  responsive.mediumSpacer,
                  _buildToggleSettings(context, responsive, theme),
                  responsive.mediumSpacer,
                  _buildPresetButtons(context, responsive, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(responsive.borderRadius),
          bottomRight: Radius.circular(responsive.borderRadius),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              color: theme.colorScheme.onPrimary,
            ),
            Expanded(
              child: Text(
                'Audio Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 48), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeControls(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.volume_up,
                  color: theme.colorScheme.primary,
                  size: responsive.iconSize,
                ),
                responsive.smallHorizontalSpacer,
                Text(
                  'Volume Controls',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            responsive.mediumSpacer,
            
            // Master Volume
            _buildVolumeSlider(
              context,
              responsive,
              theme,
              'Master Volume',
              _masterVolume,
              Icons.volume_up,
              (value) => setState(() => _masterVolume = value),
            ),
            
            responsive.smallSpacer,
            
            // Notification Volume
            _buildVolumeSlider(
              context,
              responsive,
              theme,
              'Notifications',
              _notificationVolume,
              Icons.notifications,
              (value) => setState(() => _notificationVolume = value),
            ),
            
            responsive.smallSpacer,
            
            // Alert Volume
            _buildVolumeSlider(
              context,
              responsive,
              theme,
              'Alerts',
              _alertVolume,
              Icons.warning,
              (value) => setState(() => _alertVolume = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeSlider(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String label,
    double value,
    IconData icon,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon, 
              size: responsive.iconSize * 0.8,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            responsive.smallHorizontalSpacer,
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
              ),
              child: Text(
                '${(value * 100).round()}%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        responsive.smallSpacer,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
            thumbColor: theme.colorScheme.primary,
            overlayColor: theme.colorScheme.primary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSettings(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: theme.colorScheme.primary,
                  size: responsive.iconSize,
                ),
                responsive.smallHorizontalSpacer,
                Text(
                  'Audio Options',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            responsive.mediumSpacer,
            
            // Vibration Toggle
            _buildToggleTile(
              context,
              responsive,
              theme,
              'Vibration',
              'Enable haptic feedback',
              Icons.vibration,
              _isVibrationEnabled,
              (value) => setState(() => _isVibrationEnabled = value),
            ),
            
            responsive.smallSpacer,
            
            // Silent Mode Toggle
            _buildToggleTile(
              context,
              responsive,
              theme,
              'Silent Mode',
              'Mute all sounds',
              Icons.volume_off,
              _isSilentModeEnabled,
              (value) => setState(() => _isSilentModeEnabled = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: value ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            size: responsive.iconSize,
          ),
          responsive.mediumHorizontalSpacer,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: value ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!responsive.isWearable)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButtons(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.equalizer,
                  color: theme.colorScheme.primary,
                  size: responsive.iconSize,
                ),
                responsive.smallHorizontalSpacer,
                Text(
                  'Quick Presets',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            responsive.mediumSpacer,
            
            Row(
              children: [
                Expanded(
                  child: _buildPresetButton(
                    context,
                    responsive,
                    theme,
                    'Low',
                    Icons.volume_down,
                    _setLowVolumePreset,
                  ),
                ),
                responsive.smallHorizontalSpacer,
                Expanded(
                  child: _buildPresetButton(
                    context,
                    responsive,
                    theme,
                    'Medium',
                    Icons.volume_up,
                    _setMediumVolumePreset,
                  ),
                ),
                responsive.smallHorizontalSpacer,
                Expanded(
                  child: _buildPresetButton(
                    context,
                    responsive,
                    theme,
                    'High',
                    Icons.volume_up,
                    _setHighVolumePreset,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButton(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    String label,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        padding: responsive.getResponsiveValue(
          wearable: const EdgeInsets.symmetric(vertical: 8),
          smallMobile: const EdgeInsets.symmetric(vertical: 10),
          mobile: const EdgeInsets.symmetric(vertical: 12),
          tablet: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
      icon: Icon(
        icon,
        size: responsive.iconSize * 0.8,
      ),
      label: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _setLowVolumePreset() {
    setState(() {
      _masterVolume = 0.3;
      _notificationVolume = 0.4;
      _alertVolume = 0.5;
    });
    _showPresetAppliedSnackBar('Low volume preset applied');
  }

  void _setMediumVolumePreset() {
    setState(() {
      _masterVolume = 0.6;
      _notificationVolume = 0.7;
      _alertVolume = 0.8;
    });
    _showPresetAppliedSnackBar('Medium volume preset applied');
  }

  void _setHighVolumePreset() {
    setState(() {
      _masterVolume = 0.9;
      _notificationVolume = 1.0;
      _alertVolume = 1.0;
    });
    _showPresetAppliedSnackBar('High volume preset applied');
  }

  void _showPresetAppliedSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppTheme.successGreen,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}