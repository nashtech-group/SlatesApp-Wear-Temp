import 'package:intl/intl.dart';

class DateService {
  static final DateService _instance = DateService._internal();
  factory DateService() => _instance;
  DateService._internal();

  // ===================================
  // DATE FORMAT CONSTANTS
  // ===================================
  static const String dateFormat = 'dd-MM-yyyy';              // API format
  static const String timeFormat = 'HH:mm';                   // 24-hour time
  static const String dateTimeFormat = 'dd-MM-yyyy HH:mm';    // Combined
  static const String shortDateFormat = 'dd/MM/yyyy';         // Display format
  static const String longDateFormat = 'EEEE, MMMM dd, yyyy'; // Full date
  
  // Additional formats
  static const String apiDateTimeFormat = 'yyyy-MM-dd HH:mm:ss';
  static const String iso8601Format = 'yyyy-MM-ddTHH:mm:ss.SSSZ';
  static const String monthYearFormat = 'MMMM yyyy';
  static const String twelveHourTimeFormat = 'h:mm a';

  // ===================================
  // CACHED FORMATTERS
  // ===================================
  static final DateFormat _apiDateFormatter = DateFormat(dateFormat);
  static final DateFormat _displayDateFormatter = DateFormat(shortDateFormat);
  static final DateFormat _timeFormatter = DateFormat(timeFormat);
  static final DateFormat _dateTimeFormatter = DateFormat(dateTimeFormat);
  static final DateFormat _longDateFormatter = DateFormat(longDateFormat);
  static final DateFormat _apiDateTimeFormatter = DateFormat(apiDateTimeFormat);
  static final DateFormat _twelveHourFormatter = DateFormat(twelveHourTimeFormat);

  // ===================================
  // CORE FORMATTING METHODS
  // ===================================
  
  /// Format date for API (dd-MM-yyyy)
  String formatDateForApi(DateTime date) => _apiDateFormatter.format(date);

  /// Format date for display (dd/MM/yyyy)
  String formatDateForDisplay(DateTime date) => _displayDateFormatter.format(date);

  /// Format date for long display (Monday, January 15, 2024)
  String formatDateForLongDisplay(DateTime date) => _longDateFormatter.format(date);

  /// Format time for display (HH:mm)
  String formatTimeForDisplay(DateTime dateTime) => _timeFormatter.format(dateTime);

  /// Format time in 12-hour format (2:30 PM)
  String formatTimeFor12Hour(DateTime dateTime) => _twelveHourFormatter.format(dateTime);

  /// Format date and time for display
  String formatDateTimeForDisplay(DateTime dateTime) => _dateTimeFormatter.format(dateTime);

  /// Format date and time for API
  String formatDateTimeForApi(DateTime dateTime) => _apiDateTimeFormatter.format(dateTime);

  /// Get today's date in API format
  String getTodayFormattedDate() => formatDateForApi(DateTime.now());

  /// Get current timestamp in API format
  String getCurrentApiTimestamp() => formatDateTimeForApi(DateTime.now());

  // ===================================
  // PARSING METHODS
  // ===================================
  
  /// Parse API date string to DateTime
  DateTime? parseApiDate(String dateString) {
    try {
      return _apiDateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse display date string to DateTime
  DateTime? parseDisplayDate(String dateString) {
    try {
      return _displayDateFormatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Parse date time string to DateTime
  DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormatter.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  // ===================================
  // DATE COMPARISON UTILITIES
  // ===================================
  
  /// Check if date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if date is tomorrow
  bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// Check if date is yesterday
  bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  /// Check if date is in the future
  bool isFuture(DateTime date) => date.isAfter(DateTime.now());

  /// Check if date is in the past
  bool isPast(DateTime date) => date.isBefore(DateTime.now());

  /// Check if two dates are the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month && date1.day == date2.day;
  }

  // ===================================
  // RELATIVE TIME & DURATION
  // ===================================
  
  /// Get relative time description (e.g., "2 hours ago", "in 5 minutes")
  String getRelativeTimeDescription(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 1) {
        return 'just now';
      } else if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes} minutes ago';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours} hours ago';
      } else {
        return '${absDifference.inDays} days ago';
      }
    } else {
      // Future
      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inMinutes < 60) {
        return 'in ${difference.inMinutes} minutes';
      } else if (difference.inHours < 24) {
        return 'in ${difference.inHours} hours';
      } else {
        return 'in ${difference.inDays} days';
      }
    }
  }

  /// Format duration in human readable format
  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  /// Get time difference string between two dates
  String getTimeDifference(DateTime startTime, DateTime endTime) {
    final difference = endTime.difference(startTime);
    return formatDuration(difference);
  }

  // ===================================
  // SMART FORMATTING WITH CONTEXT
  // ===================================
  
  /// Smart date formatting based on context
  String formatDateSmart(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isTomorrow(date)) {
      return 'Tomorrow';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDateForDisplay(date);
    }
  }

  /// Smart timestamp formatting for notifications/messages
  String formatTimestampSmart(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (isToday(timestamp)) {
      return 'Today ${formatTimeForDisplay(timestamp)}';
    } else if (isYesterday(timestamp)) {
      return 'Yesterday ${formatTimeForDisplay(timestamp)}';
    } else {
      return formatDateTimeForDisplay(timestamp);
    }
  }

  /// Get formatted date range string
  String getFormattedDateRange(DateTime startDate, DateTime endDate) {
    if (isSameDay(startDate, endDate)) {
      return formatDateSmart(startDate);
    } else {
      return '${formatDateForDisplay(startDate)} - ${formatDateForDisplay(endDate)}';
    }
  }

  // ===================================
  // BUSINESS LOGIC METHODS
  // ===================================
  
  /// Get date range for roster queries
  Map<String, String> getDateRangeForRoster({int daysFromNow = 0, int daysRange = 7}) {
    final startDate = DateTime.now().add(Duration(days: daysFromNow));
    final endDate = startDate.add(Duration(days: daysRange));
    
    return {
      'fromDate': formatDateForApi(startDate),
      'toDate': formatDateForApi(endDate),
    };
  }

  /// Get weekly date range
  Map<String, String> getWeeklyRange([DateTime? baseDate]) {
    final base = baseDate ?? DateTime.now();
    final startOfWeek = base.subtract(Duration(days: base.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return {
      'startDate': formatDateForApi(startOfWeek),
      'endDate': formatDateForApi(endOfWeek),
    };
  }

  /// Get monthly date range
  Map<String, String> getMonthlyRange([DateTime? baseDate]) {
    final base = baseDate ?? DateTime.now();
    final startOfMonth = DateTime(base.year, base.month, 1);
    final endOfMonth = DateTime(base.year, base.month + 1, 0);
    
    return {
      'startDate': formatDateForApi(startOfMonth),
      'endDate': formatDateForApi(endOfMonth),
    };
  }

  // ===================================
  // VALIDATION METHODS
  // ===================================
  
  /// Validate if date string matches expected format
  bool isValidApiDateFormat(String dateString) {
    try {
      parseApiDate(dateString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if date is within business hours (9 AM - 6 PM)
  bool isBusinessHours(DateTime dateTime) {
    final hour = dateTime.hour;
    return hour >= 9 && hour < 18;
  }

  /// Check if date is a weekend
  bool isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Get next business day
  DateTime getNextBusinessDay(DateTime date) {
    DateTime nextDay = date.add(const Duration(days: 1));
    while (isWeekend(nextDay)) {
      nextDay = nextDay.add(const Duration(days: 1));
    }
    return nextDay;
  }

  // ===================================
  // CONSTANTS ACCESS (for backward compatibility)
  // ===================================
  
  /// Get all available date formats
  static Map<String, String> getAvailableFormats() {
    return {
      'dateFormat': dateFormat,
      'timeFormat': timeFormat,
      'dateTimeFormat': dateTimeFormat,
      'shortDateFormat': shortDateFormat,
      'longDateFormat': longDateFormat,
      'apiDateTimeFormat': apiDateTimeFormat,
      'iso8601Format': iso8601Format,
      'monthYearFormat': monthYearFormat,
      'twelveHourTimeFormat': twelveHourTimeFormat,
    };
  }
}