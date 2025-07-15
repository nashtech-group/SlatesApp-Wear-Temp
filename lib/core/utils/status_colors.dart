// lib/core/utils/status_colors.dart
import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/services/date_service.dart';

/// Centralized utility class for all status-related color logic
/// This follows DRY principles and provides consistent status colors across the app
class StatusColors {
  static final DateService _dateService = DateService();

  // ====================
  // GUARD DUTY STATUS COLORS
  // ====================

  /// Get color for guard duty status
  static Color getGuardDutyStatusColor(int status, {bool isDark = false}) {
    return AppTheme.getGuardStatusColor(status, isDark: isDark);
  }

  /// Get color with opacity for guard duty status backgrounds
  static Color getGuardDutyStatusBackgroundColor(int status,
      {double opacity = 0.1}) {
    return getGuardDutyStatusColor(status).withValues(alpha: opacity);
  }

  /// Get display name for guard duty status
  static String getGuardDutyStatusLabel(int status) {
    return AppConstants.getStatusDisplayName(status);
  }

  /// Get icon for guard duty status
  static IconData getGuardDutyStatusIcon(int status) {
    switch (status) {
      case AppConstants.presentStatus:
        return Icons.check_circle;
      case AppConstants.absentStatus:
        return Icons.cancel;
      case AppConstants.pendingStatus:
        return Icons.pending;
      case AppConstants.presentButLeftEarlyStatus:
        return Icons.exit_to_app;
      case AppConstants.absentWithoutPermissionStatus:
        return Icons.warning;
      case AppConstants.presentButLateStatus:
        return Icons.access_time;
      case AppConstants.presentButLateAndLeftEarlyStatus:
        return Icons.schedule;
      default:
        return Icons.help_outline;
    }
  }

  // ====================
  // CONNECTION STATUS COLORS
  // ====================

  /// Get color for connection status
  static Color getConnectionStatusColor(bool isOnline,
      {bool isConnecting = false}) {
    return AppTheme.getConnectionStatusColor(isOnline,
        isConnecting: isConnecting);
  }

  /// Get icon for connection status
  static IconData getConnectionStatusIcon(bool isOnline,
      {bool isConnecting = false}) {
    if (isConnecting) return Icons.sync;
    return isOnline ? Icons.wifi : Icons.wifi_off;
  }

  /// Get display label for connection status
  static String getConnectionStatusLabel(bool isOnline,
      {bool isConnecting = false}) {
    if (isConnecting) return 'Connecting';
    return isOnline ? 'Online' : 'Offline';
  }

  // ====================
  // BATTERY STATUS COLORS
  // ====================

  /// Get color for battery level
  static Color getBatteryStatusColor(int batteryLevel) {
    return AppTheme.getBatteryStatusColor(batteryLevel);
  }

  /// Get icon for battery level
  static IconData getBatteryStatusIcon(int batteryLevel,
      {bool isCharging = false}) {
    if (isCharging) return Icons.battery_charging_full;

    if (batteryLevel <= 10) return Icons.battery_0_bar;
    if (batteryLevel <= 25) return Icons.battery_1_bar;
    if (batteryLevel <= 40) return Icons.battery_2_bar;
    if (batteryLevel <= 60) return Icons.battery_3_bar;
    if (batteryLevel <= 80) return Icons.battery_4_bar;
    return Icons.battery_full;
  }

  /// Get display label for battery level
  static String getBatteryStatusLabel(int batteryLevel,
      {bool isCharging = false}) {
    final chargeText = isCharging ? ' (Charging)' : '';

    if (batteryLevel <= AppConstants.criticalBatteryThreshold) {
      return 'Critical$chargeText';
    } else if (batteryLevel <= AppConstants.lowBatteryThreshold) {
      return 'Low$chargeText';
    } else if (batteryLevel <= 50) {
      return 'Medium$chargeText';
    } else {
      return 'Good$chargeText';
    }
  }

  // ====================
  // SIGNAL STRENGTH COLORS
  // ====================

  /// Get color for signal strength (0-4 scale)
  static Color getSignalStrengthColor(int signalStrength) {
    return AppTheme.getSignalStrengthColor(signalStrength);
  }

  /// Get icon for signal strength (0–4 scale)
  static IconData getSignalStrengthIcon(int signalStrength) {
    switch (signalStrength) {
      case 0:
        // no signal at all
        return Icons.signal_cellular_off;
      case 1:
        return Icons
            .signal_cellular_alt_1_bar; 
      case 2:
        return Icons
            .signal_cellular_alt_2_bar; 
      case 3:
        return Icons
            .network_wifi_3_bar; 
      case 4:
        // full-strength
        return Icons.signal_cellular_4_bar;
      default:
        return Icons.signal_cellular_off;
    }
  }

  /// Get display label for signal strength
  static String getSignalStrengthLabel(int signalStrength) {
    switch (signalStrength) {
      case 0:
        return 'No Signal';
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  // ====================
  // PRIORITY COLORS
  // ====================

  /// Get color for priority level
  static Color getPriorityColor(String priority) {
    return AppTheme.getPriorityColor(priority);
  }

  /// Get icon for priority level
  static IconData getPriorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'urgent':
      case 'critical':
        return Icons.priority_high;
      case 'medium':
      case 'normal':
        return Icons.flag;
      case 'low':
      default:
        return Icons.flag_outlined;
    }
  }

  // ====================
  // DUTY TIME STATUS COLORS
  // ====================

  /// Get color based on duty timing (upcoming, current, overdue, etc.)
  static Color getDutyTimeStatusColor(DateTime dutyStart, DateTime dutyEnd) {
    final now = DateTime.now();

    if (now.isBefore(dutyStart)) {
      // Upcoming duty
      final timeDiff = dutyStart.difference(now);
      if (timeDiff.inHours < 1) {
        return AppTheme.warningOrange; // Starting soon
      }
      return AppTheme.infoBlue; // Upcoming
    } else if (now.isAfter(dutyEnd)) {
      // Past duty
      return AppTheme.mediumGrey;
    } else {
      // Current duty
      final timeLeft = dutyEnd.difference(now);
      if (timeLeft.inMinutes < 30) {
        return AppTheme.warningOrange; // Ending soon
      }
      return AppTheme.successGreen; // Current
    }
  }

  /// Get icon for duty timing status
  static IconData getDutyTimeStatusIcon(DateTime dutyStart, DateTime dutyEnd) {
    final now = DateTime.now();

    if (now.isBefore(dutyStart)) {
      return Icons.schedule;
    } else if (now.isAfter(dutyEnd)) {
      return Icons.check_circle_outline;
    } else {
      return Icons.play_circle_filled;
    }
  }

  /// Get display label for duty timing
  static String getDutyTimeStatusLabel(DateTime dutyStart, DateTime dutyEnd) {
    final now = DateTime.now();

    if (now.isBefore(dutyStart)) {
      final timeDiff = dutyStart.difference(now);
      if (timeDiff.inHours < 1) {
        return 'Starting in ${timeDiff.inMinutes}m';
      } else if (timeDiff.inDays == 0) {
        return 'Today ${_dateService.formatTimeForDisplay(dutyStart)}';
      } else {
        return _dateService.formatDateSmart(dutyStart);
      }
    } else if (now.isAfter(dutyEnd)) {
      return 'Completed';
    } else {
      final timeLeft = dutyEnd.difference(now);
      if (timeLeft.inMinutes < 60) {
        return '${timeLeft.inMinutes}m remaining';
      } else {
        return '${timeLeft.inHours}h ${timeLeft.inMinutes % 60}m remaining';
      }
    }
  }

  // ====================
  // MOVEMENT TYPE COLORS
  // ====================

  /// Get color for movement type
  static Color getMovementTypeColor(String movementType) {
    switch (movementType.toLowerCase()) {
      case AppConstants.patrolMovement:
        return AppTheme.primaryTeal;
      case AppConstants.checkpointMovement:
        return AppTheme.successGreen;
      case AppConstants.breakMovement:
        return AppTheme.warningOrange;
      case AppConstants.emergencyMovement:
        return AppTheme.errorRed;
      case AppConstants.idleMovement:
        return AppTheme.mediumGrey;
      case AppConstants.transitMovement:
        return AppTheme.infoBlue;
      case AppConstants.shiftStartMovement:
        return AppTheme.successGreen;
      case AppConstants.shiftEndMovement:
        return AppTheme.errorRed;
      default:
        return AppTheme.mediumGrey;
    }
  }

  /// Get icon for movement type
  static IconData getMovementTypeIcon(String movementType) {
    switch (movementType.toLowerCase()) {
      case AppConstants.patrolMovement:
        return Icons.directions_walk;
      case AppConstants.checkpointMovement:
        return Icons.location_on;
      case AppConstants.breakMovement:
        return Icons.pause_circle;
      case AppConstants.emergencyMovement:
        return Icons.emergency;
      case AppConstants.idleMovement:
        return Icons.schedule;
      case AppConstants.transitMovement:
        return Icons.directions;
      case AppConstants.shiftStartMovement:
        return Icons.play_circle_filled;
      case AppConstants.shiftEndMovement:
        return Icons.stop_circle;
      default:
        return Icons.my_location;
    }
  }

  // ====================
  // COMPLETION RATE COLORS
  // ====================

  /// Get color for completion percentage
  static Color getCompletionRateColor(double percentage) {
    if (percentage >= 90) return AppTheme.successGreen;
    if (percentage >= 70) return AppTheme.warningOrange;
    if (percentage >= 50) return AppTheme.warningOrangeDark;
    return AppTheme.errorRed;
  }

  /// Get icon for completion rate
  static IconData getCompletionRateIcon(double percentage) {
    if (percentage >= 90) return Icons.check_circle;
    if (percentage >= 70) return Icons.schedule;
    if (percentage >= 50) return Icons.warning;
    return Icons.error;
  }

  // ====================
  // NOTIFICATION TYPE COLORS
  // ====================

  /// Get color for notification type
  static Color getNotificationTypeColor(String notificationType) {
    switch (notificationType.toLowerCase()) {
      case AppConstants.dutyReminderNotification:
        return AppTheme.infoBlue;
      case AppConstants.checkInReminderNotification:
        return AppTheme.warningOrange;
      case AppConstants.emergencyAlertNotification:
        return AppTheme.errorRed;
      case AppConstants.systemUpdateNotification:
        return AppTheme.primaryTeal;
      case AppConstants.batteryLowNotification:
        return AppTheme.warningOrange;
      case AppConstants.offlineModeNotification:
        return AppTheme.mediumGrey;
      default:
        return AppTheme.infoBlue;
    }
  }

  /// Get icon for notification type
  static IconData getNotificationTypeIcon(String notificationType) {
    switch (notificationType.toLowerCase()) {
      case AppConstants.dutyReminderNotification:
        return Icons.schedule;
      case AppConstants.checkInReminderNotification:
        return Icons.location_on;
      case AppConstants.emergencyAlertNotification:
        return Icons.warning;
      case AppConstants.systemUpdateNotification:
        return Icons.system_update;
      case AppConstants.batteryLowNotification:
        return Icons.battery_alert;
      case AppConstants.offlineModeNotification:
        return Icons.wifi_off;
      default:
        return Icons.notifications;
    }
  }

  // ====================
  // LOCATION ACCURACY COLORS
  // ====================

  /// Get color for GPS accuracy
  static Color getLocationAccuracyColor(double accuracyInMeters) {
    if (accuracyInMeters <= AppConstants.highAccuracyThreshold) {
      return AppTheme.successGreen;
    } else if (accuracyInMeters <= AppConstants.mediumAccuracyThreshold) {
      return AppTheme.warningOrange;
    } else {
      return AppTheme.errorRed;
    }
  }

  /// Get icon for location accuracy
  static IconData getLocationAccuracyIcon(double accuracyInMeters) {
    if (accuracyInMeters <= AppConstants.highAccuracyThreshold) {
      return Icons.gps_fixed;
    } else if (accuracyInMeters <= AppConstants.mediumAccuracyThreshold) {
      return Icons.gps_not_fixed;
    } else {
      return Icons.gps_off;
    }
  }

  /// Get display label for location accuracy
  static String getLocationAccuracyLabel(double accuracyInMeters) {
    if (accuracyInMeters <= AppConstants.highAccuracyThreshold) {
      return 'High Accuracy';
    } else if (accuracyInMeters <= AppConstants.mediumAccuracyThreshold) {
      return 'Medium Accuracy';
    } else {
      return 'Low Accuracy';
    }
  }

  // ====================
  // THEME-AWARE HELPERS
  // ====================

  /// Get appropriate text color for a given background color
  static Color getTextColorForBackground(Color backgroundColor) {
    return AppTheme.getTextColorForBackground(backgroundColor);
  }

  /// Get status indicator decoration
  static BoxDecoration getStatusIndicatorDecoration({
    required Color color,
    required BorderRadius borderRadius,
    double opacity = 0.1,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: borderRadius,
      border: Border.all(color: color.withValues(alpha: 0.3)),
    );
  }

  /// Get pulsing decoration for active status
  static BoxDecoration getPulsingStatusDecoration({
    required Color color,
    required BorderRadius borderRadius,
    bool isActive = true,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: 0.1),
      borderRadius: borderRadius,
      border: Border.all(color: color),
      boxShadow: isActive
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ]
          : null,
    );
  }
}
