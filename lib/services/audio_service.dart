import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  // Audio players
  final AudioPlayer _effectsPlayer = AudioPlayer();
  final AudioPlayer _notificationPlayer = AudioPlayer();
  final AudioPlayer _emergencyPlayer = AudioPlayer();
  
  // Text-to-Speech
  final FlutterTts _tts = FlutterTts();
  
  // Settings
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _voiceAnnouncementsEnabled = true;
  final bool _emergencyAlertsEnabled = true; // Cannot be disabled
  double _volume = 0.8;
  
  // State
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  bool get voiceAnnouncementsEnabled => _voiceAnnouncementsEnabled;
  bool get emergencyAlertsEnabled => _emergencyAlertsEnabled;
  double get volume => _volume;
  bool get isSpeaking => _isSpeaking;

  /// Initialize the audio service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load settings
      await _loadSettings();
      
      // Configure TTS
      await _configureTTS();
      
      // Configure audio players
      await _configureAudioPlayers();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('AudioService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService initialization failed: $e');
      }
    }
  }

  /// Configure Text-to-Speech
  Future<void> _configureTTS() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.6); // Slightly slower for clarity
      await _tts.setVolume(_volume);
      await _tts.setPitch(1.0);

      // Set completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        if (kDebugMode) {
          print('TTS Error: $msg');
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('TTS configuration failed: $e');
      }
    }
  }

  /// Configure audio players
  Future<void> _configureAudioPlayers() async {
    try {
      // Set volume for all players
      await _effectsPlayer.setVolume(_volume);
      await _notificationPlayer.setVolume(_volume);
      await _emergencyPlayer.setVolume(1.0); // Emergency always at full volume
    } catch (e) {
      if (kDebugMode) {
        print('Audio player configuration failed: $e');
      }
    }
  }

  /// Load audio settings from preferences
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _soundEnabled = prefs.getBool('audio_sound_enabled') ?? true;
      _vibrationEnabled = prefs.getBool('audio_vibration_enabled') ?? true;
      _voiceAnnouncementsEnabled = prefs.getBool('audio_voice_enabled') ?? true;
      _volume = prefs.getDouble('audio_volume') ?? 0.8;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load audio settings: $e');
      }
    }
  }

  /// Save audio settings to preferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('audio_sound_enabled', _soundEnabled);
      await prefs.setBool('audio_vibration_enabled', _vibrationEnabled);
      await prefs.setBool('audio_voice_enabled', _voiceAnnouncementsEnabled);
      await prefs.setDouble('audio_volume', _volume);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save audio settings: $e');
      }
    }
  }

  // ====================
  // GUARD DUTY SOUNDS
  // ====================

  /// Play checkpoint completion beep
  Future<void> playCheckpointBeep() async {
    if (!_soundEnabled) return;
    
    await _playSound(
      'checkpoint_beep.mp3',
      player: _effectsPlayer,
      description: 'Checkpoint reached',
    );
    
    if (_vibrationEnabled) {
      await _vibrate(VibrationPattern.checkpoint);
    }
  }

  /// Play position alert (when guard moves >5m from static position)
  Future<void> playPositionAlert() async {
    if (!_soundEnabled) return;
    
    await _playSound(
      'alert_sound.mp3',
      player: _effectsPlayer,
      description: 'Position alert',
    );
    
    if (_vibrationEnabled) {
      await _vibrate(VibrationPattern.alert);
    }
  }

  /// Play return confirmation (when guard returns to position)
  Future<void> playReturnConfirmation() async {
    if (!_soundEnabled) return;
    
    await _playSound(
      'success_chime.mp3',
      player: _effectsPlayer,
      description: 'Position confirmed',
    );
    
    if (_vibrationEnabled) {
      await _vibrate(VibrationPattern.success);
    }
  }

  /// Play notification sound
  Future<void> playNotification() async {
    if (!_soundEnabled) return;
    
    await _playSound(
      'notification.mp3',
      player: _notificationPlayer,
      description: 'Notification',
    );
  }

  /// Play emergency alert (always plays regardless of settings)
  Future<void> playEmergencyAlert() async {
    await _playSound(
      'emergency_alarm.mp3',
      player: _emergencyPlayer,
      description: 'Emergency alert',
      forcePlay: true,
    );
    
    // Emergency vibration always enabled
    await _vibrate(VibrationPattern.emergency);
  }

  // ====================
  // VOICE ANNOUNCEMENTS
  // ====================

  /// Announce checkpoint completion
  Future<void> announceCheckpoint(String checkpointName) async {
    if (!_voiceAnnouncementsEnabled) return;
    
    final message = 'Checkpoint $checkpointName completed';
    await _speak(message);
  }

  /// Announce return to position instruction
  Future<void> announceReturnToPosition() async {
    if (!_voiceAnnouncementsEnabled) return;
    
    const message = 'Please return to your designated checkpoint location';
    await _speak(message);
  }

  /// Announce position confirmation
  Future<void> announcePositionConfirmed() async {
    if (!_voiceAnnouncementsEnabled) return;
    
    const message = 'Position confirmed, thank you';
    await _speak(message);
  }

  /// Announce duty start
  Future<void> announceDutyStart(String siteName) async {
    if (!_voiceAnnouncementsEnabled) return;
    
    final message = 'Duty started at $siteName';
    await _speak(message);
  }

  /// Announce duty end
  Future<void> announceDutyEnd() async {
    if (!_voiceAnnouncementsEnabled) return;
    
    const message = 'Duty completed, thank you for your service';
    await _speak(message);
  }

  /// Announce perimeter check reminder
  Future<void> announcePerimeterCheckReminder(int minutesRemaining) async {
    if (!_voiceAnnouncementsEnabled) return;
    
    final message = minutesRemaining > 0
        ? 'Perimeter check required in $minutesRemaining minutes'
        : 'Perimeter check required now';
    await _speak(message);
  }

  /// Announce battery warning
  Future<void> announceBatteryWarning(int batteryLevel) async {
    if (!_voiceAnnouncementsEnabled) return;
    
    final message = 'Battery level is $batteryLevel percent, please charge your device';
    await _speak(message);
  }

  /// Custom voice announcement
  Future<void> announceCustom(String message) async {
    if (!_voiceAnnouncementsEnabled) return;
    
    await _speak(message);
  }

  // ====================
  // PRIVATE HELPERS
  // ====================

  /// Play a sound file
  Future<void> _playSound(
    String fileName, {
    required AudioPlayer player,
    required String description,
    bool forcePlay = false,
  }) async {
    try {
      if (!forcePlay && !_soundEnabled) return;
      
      final source = AssetSource('sounds/$fileName');
      await player.play(source);
      
      if (kDebugMode) {
        print('Playing sound: $description ($fileName)');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play sound $fileName: $e');
      }
    }
  }

  /// Speak text using TTS
  Future<void> _speak(String text) async {
    try {
      if (_isSpeaking) {
        await _tts.stop();
      }
      
      await _tts.speak(text);
      
      if (kDebugMode) {
        print('Speaking: $text');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to speak text: $e');
      }
    }
  }

  /// Trigger vibration patterns
  Future<void> _vibrate(VibrationPattern pattern) async {
    if (!_vibrationEnabled) return;
    
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (!hasVibrator) return;
      
      switch (pattern) {
        case VibrationPattern.checkpoint:
          await Vibration.vibrate(duration: AppConstants.mediumHapticDuration);
          break;
        case VibrationPattern.alert:
          await Vibration.vibrate(pattern: [0, 200, 100, 200, 100, 200]);
          break;
        case VibrationPattern.success:
          await Vibration.vibrate(duration: AppConstants.lightHapticDuration);
          break;
        case VibrationPattern.emergency:
          await Vibration.vibrate(pattern: [0, 500, 200, 500, 200, 500, 200, 500]);
          break;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Vibration failed: $e');
      }
    }
  }

  // ====================
  // SETTINGS MANAGEMENT
  // ====================

  /// Enable/disable sound effects
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
  }

  /// Enable/disable vibration
  Future<void> setVibrationEnabled(bool enabled) async {
    _vibrationEnabled = enabled;
    await _saveSettings();
  }

  /// Enable/disable voice announcements
  Future<void> setVoiceAnnouncementsEnabled(bool enabled) async {
    _voiceAnnouncementsEnabled = enabled;
    await _saveSettings();
  }

  /// Set volume level (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    
    // Update TTS volume
    await _tts.setVolume(_volume);
    
    // Update audio players volume
    await _effectsPlayer.setVolume(_volume);
    await _notificationPlayer.setVolume(_volume);
    // Emergency player stays at full volume
    
    await _saveSettings();
  }

  /// Test audio setup with sample sounds
  Future<void> testAudio() async {
    await playNotification();
    await Future.delayed(const Duration(milliseconds: 500));
    await playCheckpointBeep();
    await Future.delayed(const Duration(milliseconds: 500));
    await announceCustom('Audio test completed');
  }

  // ====================
  // CLEANUP
  // ====================

  /// Stop all audio and cleanup
  Future<void> dispose() async {
    try {
      await _tts.stop();
      await _effectsPlayer.dispose();
      await _notificationPlayer.dispose();
      await _emergencyPlayer.dispose();
      
      _isInitialized = false;
      
      if (kDebugMode) {
        print('AudioService disposed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService disposal failed: $e');
      }
    }
  }

  /// Stop all currently playing audio
  Future<void> stopAll() async {
    try {
      await _tts.stop();
      await _effectsPlayer.stop();
      await _notificationPlayer.stop();
      // Don't stop emergency player - let it complete
    } catch (e) {
      if (kDebugMode) {
        print('Failed to stop audio: $e');
      }
    }
  }
}

// ====================
// ENUMS AND CONSTANTS
// ====================

enum VibrationPattern {
  checkpoint,
  alert,
  success,
  emergency,
}

// ====================
// AUDIO SETTINGS DATA CLASS
// ====================

class AudioSettings {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool voiceAnnouncementsEnabled;
  final bool emergencyAlertsEnabled;
  final double volume;

  const AudioSettings({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.voiceAnnouncementsEnabled,
    required this.emergencyAlertsEnabled,
    required this.volume,
  });

  AudioSettings copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? voiceAnnouncementsEnabled,
    bool? emergencyAlertsEnabled,
    double? volume,
  }) {
    return AudioSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      voiceAnnouncementsEnabled: voiceAnnouncementsEnabled ?? this.voiceAnnouncementsEnabled,
      emergencyAlertsEnabled: emergencyAlertsEnabled ?? this.emergencyAlertsEnabled,
      volume: volume ?? this.volume,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'voiceAnnouncementsEnabled': voiceAnnouncementsEnabled,
      'emergencyAlertsEnabled': emergencyAlertsEnabled,
      'volume': volume,
    };
  }

  factory AudioSettings.fromJson(Map<String, dynamic> json) {
    return AudioSettings(
      soundEnabled: json['soundEnabled'] ?? true,
      vibrationEnabled: json['vibrationEnabled'] ?? true,
      voiceAnnouncementsEnabled: json['voiceAnnouncementsEnabled'] ?? true,
      emergencyAlertsEnabled: json['emergencyAlertsEnabled'] ?? true,
      volume: (json['volume'] ?? 0.8).toDouble(),
    );
  }

  static const AudioSettings defaultSettings = AudioSettings(
    soundEnabled: true,
    vibrationEnabled: true,
    voiceAnnouncementsEnabled: true,
    emergencyAlertsEnabled: true,
    volume: 0.8,
  );
}