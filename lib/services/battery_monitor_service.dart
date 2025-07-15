import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:slates_app_wear/services/audio_service.dart';

class BatteryMonitorService {
  static final BatteryMonitorService _instance = BatteryMonitorService._internal();
  factory BatteryMonitorService() => _instance;
  BatteryMonitorService._internal();

  final Battery _battery = Battery();
  final AudioService _audioService = AudioService();
  
  bool _hasWarned20 = false;
  bool _hasWarned10 = false;

  void startMonitoring() {
    _battery.onBatteryStateChanged.listen((BatteryState state) {
      _checkBatteryLevel();
    });
    
    // Check every 5 minutes
    Timer.periodic(const Duration(minutes: 5), (timer) {
      _checkBatteryLevel();
    });
  }

  Future<void> _checkBatteryLevel() async {
    final level = await _battery.batteryLevel;
    
    if (level <= 10 && !_hasWarned10) {
      _hasWarned10 = true;
      await _audioService.playEmergencyAlert();
      await _audioService.announceBatteryWarning(level);
    } else if (level <= 20 && !_hasWarned20) {
      _hasWarned20 = true;
      await _audioService.playPositionAlert();
      await _audioService.announceBatteryWarning(level);
    } else if (level > 20) {
      // Reset warnings when battery is charged
      _hasWarned20 = false;
      _hasWarned10 = false;
    }
  }
}