import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/services/audio_service.dart';

class AudioSettingsWidget extends StatefulWidget {
  final bool isExpanded;
  final VoidCallback? onExpandToggle;

  const AudioSettingsWidget({
    super.key,
    this.isExpanded = true,
    this.onExpandToggle,
  });

  @override
  State<AudioSettingsWidget> createState() => _AudioSettingsWidgetState();
}

class _AudioSettingsWidgetState extends State<AudioSettingsWidget>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late AnimationController _testController;
  late Animation<double> _expandAnimation;
  late Animation<double> _testAnimation;
  
  final AudioService _audioService = AudioService();
  
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _voiceAnnouncementsEnabled = true;
  double _volume = 0.8;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadAudioSettings();
  }

  @override
  void dispose() {
    _expandController.dispose();
    _testController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _testController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );

    _testAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _testController,
      curve: Curves.elasticOut,
    ));

    if (widget.isExpanded) {
      _expandController.forward();
    }
  }

  void _loadAudioSettings() async {
    await _audioService.initialize();
    
    if (mounted) {
      setState(() {
        _soundEnabled = _audioService.soundEnabled;
        _vibrationEnabled = _audioService.vibrationEnabled;
        _voiceAnnouncementsEnabled = _audioService.voiceAnnouncementsEnabled;
        _volume = _audioService.volume;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: responsive.padding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context, responsive, theme),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildSettingsContent(context, responsive, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return InkWell(
      onTap: widget.onExpandToggle ?? _toggleExpanded,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(responsive.borderRadius),
        bottom: widget.isExpanded 
            ? Radius.zero 
            : Radius.circular(responsive.borderRadius),
      ),
      child: Container(
        padding: responsive.containerPadding,
        child: Row(
          children: [
            Icon(
              Icons.volume_up,
              color: theme.colorScheme.primary,
              size: responsive.largeIconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Audio & Notifications',
                    style: responsive.getTitleStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Sound effects, voice alerts, and vibration',
                    style: responsive.getCaptionStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.onExpandToggle != null)
              AnimatedRotation(
                turns: widget.isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsContent(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.containerPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Master volume control
          _buildVolumeControl(context, responsive, theme),
          
          responsive.mediumSpacer,
          
          // Audio toggles
          _buildAudioToggles(context, responsive, theme),
          
          responsive.mediumSpacer,
          
          // Test audio button
          _buildTestButton(context, responsive, theme),
          
          responsive.smallSpacer,
          
          // Emergency note
          _buildEmergencyNote(context, responsive, theme),
        ],
      ),
    );
  }

  Widget _buildVolumeControl(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.volume_down,
              color: theme.colorScheme.onSurfaceVariant,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                'Volume: ${(_volume * 100).round()}%',
                style: responsive.getBodyStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.volume_up,
              color: theme.colorScheme.onSurfaceVariant,
              size: responsive.iconSize,
            ),
          ],
        ),
        
        responsive.smallSpacer,
        
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: responsive.getResponsiveValue(
              wearable: 4.0,
              smallMobile: 5.0,
              mobile: 6.0,
              tablet: 8.0,
            ),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: responsive.getResponsiveValue(
                wearable: 8.0,
                smallMobile: 10.0,
                mobile: 12.0,
                tablet: 14.0,
              ),
            ),
          ),
          child: Slider(
            value: _volume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            activeColor: theme.colorScheme.primary,
            inactiveColor: theme.colorScheme.surfaceContainerHighest,
            onChanged: _soundEnabled ? (value) {
              HapticFeedback.lightImpact();
              setState(() {
                _volume = value;
              });
            } : null,
            onChangeEnd: (value) async {
              await _audioService.setVolume(value);
              // Play a brief sound to test the new volume
              if (_soundEnabled) {
                await _audioService.playNotification();
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAudioToggles(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Column(
      children: [
        _buildToggleTile(
          context: context,
          responsive: responsive,
          theme: theme,
          title: 'Sound Effects',
          subtitle: 'Checkpoint beeps and alert sounds',
          icon: Icons.music_note,
          value: _soundEnabled,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            setState(() {
              _soundEnabled = value;
            });
            await _audioService.setSoundEnabled(value);
            
            if (value) {
              await _audioService.playCheckpointBeep();
            }
          },
        ),
        
        responsive.smallSpacer,
        
        _buildToggleTile(
          context: context,
          responsive: responsive,
          theme: theme,
          title: 'Vibration',
          subtitle: 'Haptic feedback for alerts and confirmations',
          icon: Icons.vibration,
          value: _vibrationEnabled,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            setState(() {
              _vibrationEnabled = value;
            });
            await _audioService.setVibrationEnabled(value);
            
            if (value) {
              HapticFeedback.mediumImpact();
            }
          },
        ),
        
        responsive.smallSpacer,
        
        _buildToggleTile(
          context: context,
          responsive: responsive,
          theme: theme,
          title: 'Voice Announcements',
          subtitle: 'Spoken checkpoint names and instructions',
          icon: Icons.record_voice_over,
          value: _voiceAnnouncementsEnabled,
          onChanged: (value) async {
            HapticFeedback.lightImpact();
            setState(() {
              _voiceAnnouncementsEnabled = value;
            });
            await _audioService.setVoiceAnnouncementsEnabled(value);
            
            if (value) {
              await _audioService.announceCustom('Voice announcements enabled');
            }
          },
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required BuildContext context,
    required ResponsiveUtils responsive,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
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
            size: responsive.largeIconSize,
          ),
          responsive.mediumHorizontalSpacer,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: responsive.getBodyStyle(
                    fontWeight: FontWeight.w600,
                    color: value ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (!responsive.isWearable)
                  Text(
                    subtitle,
                    style: responsive.getCaptionStyle(
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

  Widget _buildTestButton(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return AnimatedBuilder(
      animation: _testAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isTesting ? _testAnimation.value : 1.0,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTesting ? null : _testAudio,
              icon: Icon(
                _isTesting ? Icons.hearing : Icons.play_circle,
                size: responsive.iconSize,
              ),
              label: Text(
                _isTesting ? 'Testing Audio...' : 'Test Audio Settings',
                style: responsive.getBodyStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTesting 
                    ? theme.colorScheme.surfaceContainerHighest 
                    : AppTheme.primaryTeal,
                foregroundColor: _isTesting 
                    ? theme.colorScheme.onSurfaceVariant 
                    : Colors.white,
                padding: responsive.buttonPadding,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyNote(BuildContext context, ResponsiveUtils responsive, ThemeData theme) {
    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
        border: Border.all(
          color: AppTheme.warningOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber,
            color: AppTheme.warningOrange,
            size: responsive.iconSize,
          ),
          responsive.smallHorizontalSpacer,
          Expanded(
            child: Text(
              'Emergency alerts cannot be disabled and will always play at full volume for safety.',
              style: responsive.getCaptionStyle(
                color: AppTheme.warningOrange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleExpanded() {
    if (widget.isExpanded) {
      _expandController.reverse();
    } else {
      _expandController.forward();
    }
  }

  Future<void> _testAudio() async {
    if (_isTesting) return;
    
    setState(() {
      _isTesting = true;
    });
    
    _testController.forward(from: 0);
    
    try {
      await _audioService.testAudio();
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
    
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isTesting = false;
      });
    }
  }
}

/// Compact audio settings for quick access
class CompactAudioSettings extends StatelessWidget {
  final VoidCallback? onOpenFull;

  const CompactAudioSettings({
    super.key,
    this.onOpenFull,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    return Container(
      padding: responsive.getResponsiveValue(
        wearable: const EdgeInsets.all(8),
        smallMobile: const EdgeInsets.all(10),
        mobile: const EdgeInsets.all(12),
        tablet: const EdgeInsets.all(14),
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
      ),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            color: theme.colorScheme.primary,
            size: responsive.largeIconSize,
          ),
          responsive.smallHorizontalSpacer,
          Expanded(
            child: Text(
              'Audio Settings',
              style: responsive.getBodyStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onOpenFull != null)
            IconButton(
              onPressed: onOpenFull,
              icon: Icon(
                Icons.arrow_forward_ios,
                size: responsive.iconSize,
              ),
            ),
        ],
      ),
    );
  }
}

/// Audio quick toggles for dashboard
class AudioQuickToggles extends StatefulWidget {
  const AudioQuickToggles({super.key});

  @override
  State<AudioQuickToggles> createState() => _AudioQuickTogglesState();
}

class _AudioQuickTogglesState extends State<AudioQuickToggles> {
  final AudioService _audioService = AudioService();
  
  @override
  void initState() {
    super.initState();
    _audioService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickToggle(
          context: context,
          responsive: responsive,
          icon: Icons.volume_up,
          isEnabled: _audioService.soundEnabled,
          onTap: () async {
            await _audioService.setSoundEnabled(!_audioService.soundEnabled);
            setState(() {});
          },
        ),
        _buildQuickToggle(
          context: context,
          responsive: responsive,
          icon: Icons.vibration,
          isEnabled: _audioService.vibrationEnabled,
          onTap: () async {
            await _audioService.setVibrationEnabled(!_audioService.vibrationEnabled);
            setState(() {});
          },
        ),
        _buildQuickToggle(
          context: context,
          responsive: responsive,
          icon: Icons.record_voice_over,
          isEnabled: _audioService.voiceAnnouncementsEnabled,
          onTap: () async {
            await _audioService.setVoiceAnnouncementsEnabled(!_audioService.voiceAnnouncementsEnabled);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildQuickToggle({
    required BuildContext context,
    required ResponsiveUtils responsive,
    required IconData icon,
    required bool isEnabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: EdgeInsets.all(responsive.smallSpacing),
        decoration: BoxDecoration(
          color: isEnabled 
              ? theme.colorScheme.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(responsive.borderRadius / 2),
          border: Border.all(
            color: isEnabled 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Icon(
          icon,
          color: isEnabled 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurfaceVariant,
          size: responsive.largeIconSize,
        ),
      ),
    );
  }
}