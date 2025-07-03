import 'package:intl/intl.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';

class DateService {
  static final DateService _instance = DateService._internal();
  factory DateService() => _instance;
  DateService._internal();

  // Date formatters 
  static final DateFormat _apiDateFormatter = DateFormat(AppConstants.dateFormat);
  static final DateFormat _displayDateFormatter = DateFormat(AppConstants.shortDateFormat);
  static final DateFormat _timeFormatter = DateFormat(AppConstants.timeFormat);
  static final DateFormat _dateTimeFormatter = DateFormat(AppConstants.dateTimeFormat);
  static final DateFormat _longDateFormatter = DateFormat(AppConstants.longDateFormat);

  /// Get today's date in API format (dd-MM-yyyy)
  String getTodayFormattedDate() {
    final today = DateTime.now();
    return formatDateForApi(today);
  }

  /// Format date for API using AppConstants.dateFormat (dd-MM-yyyy)
  String formatDateForApi(DateTime date) {
    return _apiDateFormatter.format(date);
  }

  /// Format date for display using AppConstants.shortDateFormat (dd/MM/yyyy)
  String formatDateForDisplay(DateTime date) {
    return _displayDateFormatter.format(date);
  }

  /// Format date for long display using AppConstants.longDateFormat
  String formatDateForLongDisplay(DateTime date) {
    return _longDateFormatter.format(date);
  }

  /// Format time for display using AppConstants.timeFormat (HH:mm)
  String formatTimeForDisplay(DateTime dateTime) {
    return _timeFormatter.format(dateTime);
  }

  /// Format date and time for display using AppConstants.dateTimeFormat
  String formatDateTimeForDisplay(DateTime dateTime) {
    return _dateTimeFormatter.format(dateTime);
  }

  /// Format date and time separately for display
  String formatDateTimeForDisplaySeparate(DateTime dateTime) {
    return '${formatDateForDisplay(dateTime)} ${formatTimeForDisplay(dateTime)}';
  }

  /// Get date range for roster queries
  Map<String, String> getDateRangeForRoster({int daysFromNow = 0, int daysRange = 7}) {
    final startDate = DateTime.now().add(Duration(days: daysFromNow));
    final endDate = startDate.add(Duration(days: daysRange));
    
    return {
      'fromDate': formatDateForApi(startDate),
      'toDate': formatDateForApi(endDate),
    };
  }

  /// Check if date is today
  bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// Check if date is in the future
  bool isFuture(DateTime date) {
    return date.isAfter(DateTime.now());
  }

  /// Check if date is in the past
  bool isPast(DateTime date) {
    return date.isBefore(DateTime.now());
  }

  /// Get relative time description
  String getRelativeTimeDescription(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      // Past
      final absDifference = difference.abs();
      if (absDifference.inMinutes < 60) {
        return '${absDifference.inMinutes} minutes ago';
      } else if (absDifference.inHours < 24) {
        return '${absDifference.inHours} hours ago';
      } else {
        return '${absDifference.inDays} days ago';
      }
    } else {
      // Future
      if (difference.inMinutes < 60) {
        return 'in ${difference.inMinutes} minutes';
      } else if (difference.inHours < 24) {
        return 'in ${difference.inHours} hours';
      } else {
        return 'in ${difference.inDays} days';
      }
    }
  }

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

  /// Get formatted date range string
  String getFormattedDateRange(DateTime startDate, DateTime endDate) {
    if (isToday(startDate) && isToday(endDate)) {
      return 'Today';
    } else if (startDate.year == endDate.year && 
               startDate.month == endDate.month && 
               startDate.day == endDate.day) {
      return formatDateForDisplay(startDate);
    } else {
      return '${formatDateForDisplay(startDate)} - ${formatDateForDisplay(endDate)}';
    }
  }

  /// Get current timestamp in API format
  String getCurrentApiTimestamp() {
    return _dateTimeFormatter.format(DateTime.now());
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
}