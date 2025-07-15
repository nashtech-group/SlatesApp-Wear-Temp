
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/services/audio_service.dart';

class AudioTestWidget extends StatefulWidget {
  const AudioTestWidget({super.key});

  @override
  State<AudioTestWidget> createState() => _AudioTestWidgetState();
}

class _AudioTestWidgetState extends State<AudioTestWidget> {
  final AudioService _audioService = AudioService();
  bool _isInitialized = false;
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioService.initialize();
      setState(() {
        _isInitialized = true;
        _status = 'Audio service ready';
      });
    } catch (e) {
      setState(() {
        _status = 'Audio initialization failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Container(
      margin: responsive.containerPadding,
      padding: responsive.containerPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.bug_report,
                color: AppTheme.warningOrange,
                size: responsive.largeIconSize,
              ),
              responsive.smallHorizontalSpacer,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Audio System Test',
                      style: responsive.getTitleStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _status,
                      style: responsive.getCaptionStyle(
                        color: _isInitialized 
                            ? AppTheme.successGreen 
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          responsive.mediumSpacer,

          if (_isInitialized) ...[
            // Sound Effect Tests
            _buildTestSection(
              context: context,
              responsive: responsive,
              theme: theme,
              title: 'Sound Effects',
              tests: [
                _AudioTest(
                  'Checkpoint Beep',
                  Icons.location_on,
                  AppTheme.primaryTeal,
                  () => _audioService.playCheckpointBeep(),
                ),
                _AudioTest(
                  'Position Alert',
                  Icons.warning,
                  AppTheme.warningOrange,
                  () => _audioService.playPositionAlert(),
                ),
                _AudioTest(
                  'Return Confirmation',
                  Icons.check_circle,
                  AppTheme.successGreen,
                  () => _audioService.playReturnConfirmation(),
                ),
                _AudioTest(
                  'Notification',
                  Icons.notifications,
                  AppTheme.secondaryBlue,
                  () => _audioService.playNotification(),
                ),
                _AudioTest(
                  'Emergency Alert',
                  Icons.emergency,
                  AppTheme.errorRed,
                  () => _audioService.playEmergencyAlert(),
                ),
              ],
            ),

            responsive.mediumSpacer,

            // Voice Announcement Tests
            _buildTestSection(
              context: context,
              responsive: responsive,
              theme: theme,
              title: 'Voice Announcements',
              tests: [
                _AudioTest(
                  'Checkpoint Complete',
                  Icons.record_voice_over,
                  AppTheme.primaryTeal,
                  () => _audioService.announceCheckpoint('Gate A Post'),
                ),
                _AudioTest(
                  'Return to Position',
                  Icons.my_location,
                  AppTheme.warningOrange,
                  () => _audioService.announceReturnToPosition(),
                ),
                _AudioTest(
                  'Position Confirmed',
                  Icons.verified,
                  AppTheme.successGreen,
                  () => _audioService.announcePositionConfirmed(),
                ),
                _AudioTest(
                  'Duty Start',
                  Icons.play_circle,
                  AppTheme.primaryTeal,
                  () => _audioService.announceDutyStart('Test Site'),
                ),
                _AudioTest(
                  'Duty End',
                  Icons.stop_circle,
                  AppTheme.secondaryBlue,
                  () => _audioService.announceDutyEnd(),
                ),
                _AudioTest(
                  'Perimeter Check',
                  Icons.timer,
                  AppTheme.warningOrange,
                  () => _audioService.announcePerimeterCheckReminder(5),
                ),
                _AudioTest(
                  'Battery Warning',
                  Icons.battery_alert,
                  AppTheme.errorRed,
                  () => _audioService.announceBatteryWarning(15),
                ),
              ],
            ),

            responsive.mediumSpacer,

            // Audio Settings Info
            _buildSettingsInfo(context, responsive, theme),

            responsive.mediumSpacer,

            // Complete Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _runCompleteTest,
                icon: Icon(Icons.play_arrow, size: responsive.iconSize),
                label: Text(
                  'Run Complete Test',
                  style: responsive.getBodyStyle(fontWeight: FontWeight.w600),
                ),
                style: AppTheme.responsivePrimaryButtonStyle(context),
              ),
            ),
          ] else ...[
            // Loading state
            Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  responsive.mediumSpacer,
                  Text(
                    'Initializing audio service...',
                    style: responsive.getBodyStyle(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestSection({
    required BuildContext context,
    required ResponsiveUtils responsive,
    required ThemeData theme,
    required String title,
    required List<_AudioTest> tests,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: responsive.getBodyStyle(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.primary,
          ),
        ),
        responsive.smallSpacer,
        
        if (responsive.isWearable) ...[
          // Vertical layout for wearables
          ...tests.map((test) => Padding(
            padding: EdgeInsets.only(bottom: responsive.smallSpacing),
            child: _buildTestButton(context, responsive, theme, test),
          )),
        ] else ...[
          // Grid layout for larger screens
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsive.isTablet ? 3 : 2,
              crossAxisSpacing: responsive.smallSpacing,
              mainAxisSpacing: responsive.smallSpacing,
              childAspectRatio: 2.5,
            ),
            itemCount: tests.length,
            itemBuilder: (context, index) => _buildTestButton(
              context, responsive, theme, tests[index]
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTestButton(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
    _AudioTest test,
  ) {
    return OutlinedButton.icon(
      onPressed: () async {
        HapticFeedback.lightImpact();
        try {
          await test.action();
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Test failed: $e'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      },
      icon: Icon(
        test.icon,
        size: responsive.iconSize,
        color: test.color,
      ),
      label: Text(
        test.name,
        style: responsive.getCaptionStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: test.color,
        side: BorderSide(color: test.color),
        padding: responsive.getResponsiveValue(
          wearable: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          smallMobile: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          mobile: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          tablet: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSettingsInfo(
    BuildContext context,
    ResponsiveUtils responsive,
    ThemeData theme,
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
                'Current Audio Settings',
                style: responsive.getBodyStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          responsive.smallSpacer,
          _buildSettingItem('Sound Effects', _audioService.soundEnabled),
          _buildSettingItem('Vibration', _audioService.vibrationEnabled),
          _buildSettingItem('Voice Announcements', _audioService.voiceAnnouncementsEnabled),
          _buildSettingItem('Volume', '${(_audioService.volume * 100).round()}%'),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String label, dynamic value) {
    final theme = Theme.of(context);
    final responsive = context.responsive;

    return Padding(
      padding: EdgeInsets.only(bottom: responsive.smallSpacing / 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: responsive.getCaptionStyle(),
          ),
          Text(
            value is bool 
                ? (value ? 'Enabled' : 'Disabled')
                : value.toString(),
            style: responsive.getCaptionStyle(
              color: value is bool 
                  ? (value ? AppTheme.successGreen : AppTheme.errorRed)
                  : theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runCompleteTest() async {
    try {
      HapticFeedback.heavyImpact();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Running complete audio test...'),
          duration: Duration(seconds: 10),
        ),
      );

      // Run the built-in test sequence
      await _audioService.testAudio();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio test completed successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Audio test failed: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}

class _AudioTest {
  final String name;
  final IconData icon;
  final Color color;
  final Future<void> Function() action;

  const _AudioTest(this.name, this.icon, this.color, this.action);
}

// How to add this test widget to your app:
// 
// 1. Add to your home screen for quick testing:
//    In your _DashboardTab or similar, add:
//    
//    if (kDebugMode) ...[
//      responsive.mediumSpacer,
//      const AudioTestWidget(),
//    ],
//
// 2. Or create a debug/test screen and add a route for it
//
// 3. Or add as a temporary floating action button:
//    floatingActionButton: kDebugMode ? FloatingActionButton(
//      onPressed: () => showDialog(
//        context: context,
//        builder: (context) => Dialog(
//          child: Container(
//            height: MediaQuery.of(context).size.height * 0.8,
//            child: const AudioTestWidget(),
//          ),
//        ),
//      ),
//      child: const Icon(Icons.volume_up),
//    ) : null,