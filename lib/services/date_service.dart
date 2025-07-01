class DateService {
  static final DateService _instance = DateService._internal();
  factory DateService() => _instance;
  DateService._internal();

  /// Get today's date in dd-MM-yyyy format (API format)
  String getTodayFormattedDate() {
    final today = DateTime.now();
    return formatDateForApi(today);
  }

  /// Format date for API (dd-MM-yyyy)
  String formatDateForApi(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  /// Format date for display (dd/MM/yyyy)
  String formatDateForDisplay(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Format time for display (HH:mm)
  String formatTimeForDisplay(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format date and time for display
  String formatDateTimeForDisplay(DateTime dateTime) {
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
}