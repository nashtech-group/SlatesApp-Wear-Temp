import 'package:slates_app_wear/services/date_service.dart';

class DateFormatUtils {
  // Private constructor to prevent instantiation
  DateFormatUtils._();

  // Get singleton instance of DateService
  static final DateService _dateService = DateService();

  // ====================
  // UI-SPECIFIC FORMATTING METHODS
  // ====================

  /// Format time for UI display (HH:mm format)
  static String formatTimeForUI(DateTime dateTime) {
    return _dateService.formatTimeForDisplay(dateTime);
  }

  /// Format date for UI display (dd/MM/yyyy format)
  static String formatDateForUI(DateTime date) {
    return _dateService.formatDateForDisplay(date);
  }

  /// Format smart date for UI (Today, Tomorrow, Yesterday, or date)
  static String formatSmartDateForUI(DateTime date) {
    return _dateService.formatDateSmart(date);
  }

  /// Format date and time for UI display
  static String formatDateTimeForUI(DateTime dateTime) {
    return _dateService.formatDateTimeForDisplay(dateTime);
  }

  /// Format timestamp smartly for UI (e.g., "2h ago", "Yesterday 14:30")
  static String formatSmartTimestampForUI(DateTime timestamp) {
    return _dateService.formatTimestampSmart(timestamp);
  }

  /// Format duration for UI display (e.g., "2h 30m")
  static String formatDurationForUI(Duration duration) {
    return _dateService.formatDuration(duration);
  }

  /// Format date range for UI display
  static String formatDateRangeForUI(DateTime startDate, DateTime endDate) {
    return _dateService.getFormattedDateRange(startDate, endDate);
  }

  // ====================
  // DUTY-SPECIFIC FORMATTING
  // ====================

  /// Format duty time display (date • start - end)
  static String formatDutyTimeForUI(DateTime date, DateTime startTime, DateTime endTime) {
    final formattedDate = formatSmartDateForUI(date);
    final formattedStartTime = formatTimeForUI(startTime);
    final formattedEndTime = formatTimeForUI(endTime);
    
    return '$formattedDate • $formattedStartTime - $formattedEndTime';
  }

  /// Format duty duration between start and end times
  static String formatDutyDurationForUI(DateTime startTime, DateTime endTime) {
    final duration = endTime.difference(startTime);
    return formatDurationForUI(duration);
  }

  /// Format remaining time for ongoing duty
  static String formatRemainingTimeForUI(DateTime endTime) {
    final now = DateTime.now();
    final remaining = endTime.difference(now);
    
    if (remaining.isNegative) {
      return 'Overtime';
    }
    
    return formatDurationForUI(remaining);
  }

  // ====================
  // CALENDAR-SPECIFIC FORMATTING
  // ====================

  /// Format month and year for calendar header
  static String formatMonthYearForUI(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${months[date.month - 1]} ${date.year}';
  }

  /// Format abbreviated month for compact display
  static String formatAbbreviatedMonthForUI(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    
    return '${date.day} ${months[date.month - 1]}';
  }

  /// Format day of week for calendar
  static String formatDayOfWeekForUI(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 
      'Friday', 'Saturday', 'Sunday'
    ];
    
    return days[date.weekday - 1];
  }

  /// Format abbreviated day of week
  static String formatAbbreviatedDayOfWeekForUI(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  // ====================
  // RELATIVE TIME FORMATTING
  // ====================

  /// Format relative time for notifications and messages
  static String formatRelativeTimeForUI(DateTime dateTime) {
    return _dateService.getRelativeTimeDescription(dateTime);
  }

  /// Format time ago in compact format (e.g., "2h", "5m", "1d")
  static String formatTimeAgoCompactForUI(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d';
    } else {
      return formatAbbreviatedMonthForUI(dateTime);
    }
  }

  // ====================
  // SPECIALIZED UI FORMATS
  // ====================

  /// Format time for 12-hour display with AM/PM
  static String formatTime12HourForUI(DateTime dateTime) {
    return _dateService.formatTimeFor12Hour(dateTime);
  }

  /// Format time with seconds (HH:mm:ss)
  static String formatTimeWithSecondsForUI(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:'
           '${dateTime.minute.toString().padLeft(2, '0')}:'
           '${dateTime.second.toString().padLeft(2, '0')}';
  }

  /// Format date in long format (Monday, January 15, 2024)
  static String formatLongDateForUI(DateTime date) {
    return _dateService.formatDateForLongDisplay(date);
  }

  /// Format ISO date for compact display (15/01)
  static String formatCompactDateForUI(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}';
  }

  // ====================
  // PROGRESS AND STATISTICS FORMATTING
  // ====================

  /// Format progress time elapsed vs total
  static String formatProgressTimeForUI(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    final elapsed = now.difference(startTime);
    
    final elapsedFormatted = formatDurationForUI(elapsed);
    final totalFormatted = formatDurationForUI(totalDuration);
    
    return '$elapsedFormatted / $totalFormatted';
  }

  /// Format percentage completion
  static String formatCompletionPercentageForUI(DateTime startTime, DateTime endTime) {
    final now = DateTime.now();
    final totalDuration = endTime.difference(startTime);
    final elapsed = now.difference(startTime);
    
    final progress = (elapsed.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
    return '${(progress * 100).toInt()}%';
  }

  // ====================
  // VALIDATION AND HELPER METHODS
  // ====================

  /// Check if date is today
  static bool isToday(DateTime date) {
    return _dateService.isToday(date);
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    return _dateService.isTomorrow(date);
  }

  /// Check if date is yesterday
  static bool isYesterday(DateTime date) {
    return _dateService.isYesterday(date);
  }

  /// Check if date is in the current week
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
           date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// Check if date is in the current month
  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  /// Check if date is in the current year
  static bool isThisYear(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year;
  }

  // ====================
  // BUSINESS LOGIC HELPERS
  // ====================

  /// Format shift time display for guards
  static String formatShiftTimeForUI(DateTime shiftStart, DateTime shiftEnd) {
    // Handle overnight shifts
    if (shiftEnd.isBefore(shiftStart)) {
      shiftEnd = shiftEnd.add(const Duration(days: 1));
    }
    
    final startTime = formatTimeForUI(shiftStart);
    final endTime = formatTimeForUI(shiftEnd);
    
    // Check if it's an overnight shift
    if (shiftEnd.day != shiftStart.day) {
      return '$startTime - $endTime (+1)';
    }
    
    return '$startTime - $endTime';
  }

  /// Format break duration for duty tracking
  static String formatBreakDurationForUI(Duration breakDuration) {
    if (breakDuration.inMinutes < 60) {
      return '${breakDuration.inMinutes}min break';
    } else {
      final hours = breakDuration.inHours;
      final minutes = breakDuration.inMinutes % 60;
      if (minutes == 0) {
        return '${hours}h break';
      } else {
        return '${hours}h ${minutes}min break';
      }
    }
  }

  /// Get next business day for scheduling
  static DateTime getNextBusinessDay(DateTime date) {
    return _dateService.getNextBusinessDay(date);
  }

  /// Check if time is within business hours
  static bool isBusinessHours(DateTime dateTime) {
    return _dateService.isBusinessHours(dateTime);
  }

  /// Check if date is weekend
  static bool isWeekend(DateTime date) {
    return _dateService.isWeekend(date);
  }

  // ====================
  // ACCESSIBILITY HELPERS
  // ====================

  /// Format date for screen readers (verbose format)
  static String formatDateForAccessibility(DateTime date) {
    return _dateService.formatDateForLongDisplay(date);
  }

  /// Format time for screen readers
  static String formatTimeForAccessibility(DateTime dateTime) {
    final time12Hour = _dateService.formatTimeFor12Hour(dateTime);
    return time12Hour.replaceAll(':', ' ');
  }

  /// Format duration for screen readers
  static String formatDurationForAccessibility(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    String result = '';
    if (hours > 0) {
      result += '$hours hour${hours == 1 ? '' : 's'}';
      if (minutes > 0) {
        result += ' and ';
      }
    }
    if (minutes > 0) {
      result += '$minutes minute${minutes == 1 ? '' : 's'}';
    }
    
    return result.isEmpty ? '0 minutes' : result;
  }

  // ====================
  // UTILITY CONSTANTS ACCESS
  // ====================

  /// Get current formatted date in API format
  static String getCurrentApiDate() {
    return _dateService.getTodayFormattedDate();
  }

  /// Get current timestamp in API format
  static String getCurrentApiTimestamp() {
    return _dateService.getCurrentApiTimestamp();
  }

  /// Parse API date string
  static DateTime? parseApiDate(String dateString) {
    return _dateService.parseApiDate(dateString);
  }

  /// Parse display date string
  static DateTime? parseDisplayDate(String dateString) {
    return _dateService.parseDisplayDate(dateString);
  }
}