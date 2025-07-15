import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
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

    return WearableScaffold(
      body: Column(
        children: [
          _buildHeader(context, responsive),
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.containerPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildVolumeControls(context, responsive),
                  SizedBox(height: responsive.mediumSpacing),
                  _buildToggleSettings(context, responsive),
                  SizedBox(height: responsive.mediumSpacing),
                  _buildPresetButtons(context, responsive),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive) {
    return Container(
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
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
              color: Colors.white,
            ),
            Expanded(
              child: Text(
                'Audio Settings',
                style: (Theme.of(context).textTheme.titleLarge ?? const TextStyle()).copyWith(
                  color: Colors.white,
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

  Widget _buildVolumeControls(BuildContext context, ResponsiveUtils responsive) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Volume Controls',
              style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            
            // Master Volume
            _buildVolumeSlider(
              context,
              responsive,
              'Master Volume',
              _masterVolume,
              Icons.volume_up,
              (value) => setState(() => _masterVolume = value),
            ),
            
            SizedBox(height: responsive.smallSpacing),
            
            // Notification Volume
            _buildVolumeSlider(
              context,
              responsive,
              'Notifications',
              _notificationVolume,
              Icons.notifications,
              (value) => setState(() => _notificationVolume = value),
            ),
            
            SizedBox(height: responsive.smallSpacing),
            
            // Alert Volume
            _buildVolumeSlider(
              context,
              responsive,
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
            Icon(icon, size: 20),
            SizedBox(width: responsive.smallSpacing),
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: (Theme.of(context).textTheme.bodySmall ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.smallSpacing * 0.5),
        Slider(
          value: value,
          onChanged: onChanged,
          min: 0.0,
          max: 1.0,
          divisions: 10,
          activeColor: Theme.of(context).colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildToggleSettings(BuildContext context, ResponsiveUtils responsive) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audio Options',
              style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            
            // Vibration Toggle
            SwitchListTile(
              title: const Text('Vibration'),
              subtitle: const Text('Enable haptic feedback'),
              value: _isVibrationEnabled,
              onChanged: (value) => setState(() => _isVibrationEnabled = value),
              secondary: const Icon(Icons.vibration),
            ),
            
            // Silent Mode Toggle
            SwitchListTile(
              title: const Text('Silent Mode'),
              subtitle: const Text('Mute all sounds'),
              value: _isSilentModeEnabled,
              onChanged: (value) => setState(() => _isSilentModeEnabled = value),
              secondary: const Icon(Icons.volume_off),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetButtons(BuildContext context, ResponsiveUtils responsive) {
    return Card(
      child: Padding(
        padding: responsive.containerPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Presets',
              style: (Theme.of(context).textTheme.titleMedium ?? const TextStyle()).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: responsive.mediumSpacing),
            
            // Fixed: Removed the double value from Widget list
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setLowVolumePreset,
                    icon: const Icon(Icons.volume_down),
                    label: const Text('Low'),
                  ),
                ),
                SizedBox(width: responsive.smallSpacing),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setMediumVolumePreset,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('Medium'),
                  ),
                ),
                SizedBox(width: responsive.smallSpacing),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _setHighVolumePreset,
                    icon: const Icon(Icons.volume_up),
                    label: const Text('High'),
                  ),
                ),
              ],
            ),
          ],
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
  }

  void _setMediumVolumePreset() {
    setState(() {
      _masterVolume = 0.6;
      _notificationVolume = 0.7;
      _alertVolume = 0.8;
    });
  }

  void _setHighVolumePreset() {
    setState(() {
      _masterVolume = 0.9;
      _notificationVolume = 1.0;
      _alertVolume = 1.0;
    });
  }
}