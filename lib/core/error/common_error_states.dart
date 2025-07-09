// lib/core/error/common_error_states.dart
import 'package:equatable/equatable.dart';
import 'error_handler.dart';
import '../constants/app_constants.dart';

/// Base error state that can be extended by specific BLoCs
/// Provides common properties and methods for all error states
abstract class BaseErrorState extends Equatable {
  final BlocErrorInfo errorInfo;
  final DateTime timestamp;

  BaseErrorState({
    required this.errorInfo,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [errorInfo, timestamp];

  // Convenience getters for easier access to error information
  String get message => errorInfo.message;
  String get userMessage => errorInfo.toUserMessage();
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
  List<String>? get validationErrors => errorInfo.validationErrors;
  String? get errorCode => errorInfo.errorCode;
  int? get statusCode => errorInfo.statusCode;
  dynamic get originalError => errorInfo.originalError;

  /// Get retry delay in milliseconds
  int getRetryDelay(int attemptNumber) {
    return ErrorHandler.getRetryDelay(errorType, attemptNumber);
  }

  /// Check if this error indicates authentication issues
  bool get isAuthError => ErrorHandler.isAuthError(errorInfo);

  /// Check if this error indicates session expiry
  bool get isSessionExpired => ErrorHandler.isSessionExpired(errorInfo);

  /// Check if this error indicates offline/network issues
  bool get isOfflineError => ErrorHandler.isOfflineError(errorInfo);

  /// Get user-friendly title for error dialogs
  String get errorTitle {
    switch (errorType) {
      case ErrorType.network:
        return 'Connection Error';
      case ErrorType.server:
        return 'Server Error';
      case ErrorType.authentication:
        return 'Authentication Required';
      case ErrorType.authorization:
        return 'Access Denied';
      case ErrorType.validation:
        return 'Invalid Input';
      case ErrorType.notFound:
        return 'Not Found';
      case ErrorType.timeout:
        return 'Request Timeout';
      case ErrorType.rateLimited:
        return 'Too Many Requests';
      case ErrorType.parsing:
        return 'Data Error';
      case ErrorType.unknown:
      default:
        return 'Error Occurred';
    }
  }

  /// Get icon name for error display
  String get errorIcon {
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
        return 'wifi_off';
      case ErrorType.server:
        return 'error_outline';
      case ErrorType.authentication:
      case ErrorType.authorization:
        return 'lock';
      case ErrorType.validation:
        return 'warning';
      case ErrorType.notFound:
        return 'search_off';
      case ErrorType.rateLimited:
        return 'hourglass_empty';
      case ErrorType.parsing:
        return 'data_usage';
      case ErrorType.unknown:
      default:
        return 'error';
    }
  }

  /// Copy method for immutability
  BaseErrorState copyWith({BlocErrorInfo? errorInfo});
}

/// Generic error state for simple BLoCs
class GenericErrorState extends BaseErrorState {
  GenericErrorState({required super.errorInfo, super.timestamp});

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return GenericErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Network-related error states
class NetworkErrorState extends BaseErrorState {
  NetworkErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Connection Problem';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return NetworkErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class TimeoutErrorState extends BaseErrorState {
  TimeoutErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Request Timed Out';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return TimeoutErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Authentication-related error states
class AuthenticationErrorState extends BaseErrorState {
  AuthenticationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Authentication Required';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return AuthenticationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class SessionExpiredErrorState extends AuthenticationErrorState {
  SessionExpiredErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Session Expired';

  @override
  String get userMessage => AppConstants.sessionExpiredMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return SessionExpiredErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class AuthorizationErrorState extends BaseErrorState {
  AuthorizationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Access Denied';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return AuthorizationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class ForbiddenErrorState extends AuthorizationErrorState {
  ForbiddenErrorState({required super.errorInfo, super.timestamp});

  @override
  String get userMessage => AppConstants.forbiddenMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ForbiddenErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Validation-related error states
class ValidationErrorState extends BaseErrorState {
  ValidationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Validation Error';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ValidationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class FieldValidationErrorState extends ValidationErrorState {
  final Map<String, List<String>> fieldErrors;

  FieldValidationErrorState({
    required super.errorInfo,
    required this.fieldErrors,
    super.timestamp,
  });

  @override
  List<Object?> get props => [errorInfo, fieldErrors, timestamp];

  /// Get errors for a specific field
  List<String>? getFieldErrors(String fieldName) {
    return fieldErrors[fieldName];
  }

  /// Get first error for a specific field
  String? getFirstFieldError(String fieldName) {
    final errors = getFieldErrors(fieldName);
    return errors?.isNotEmpty == true ? errors!.first : null;
  }

  /// Check if field has errors
  bool hasFieldErrors(String fieldName) {
    return fieldErrors.containsKey(fieldName) && 
           fieldErrors[fieldName]!.isNotEmpty;
  }

  /// Get all error messages as a flat list
  List<String> get allErrorMessages {
    final messages = <String>[];
    fieldErrors.values.forEach(messages.addAll);
    return messages;
  }

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return FieldValidationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      fieldErrors: fieldErrors,
      timestamp: timestamp,
    );
  }
}

/// Server-related error states
class ServerErrorState extends BaseErrorState {
  ServerErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Server Error';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ServerErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class RateLimitErrorState extends ServerErrorState {
  RateLimitErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Too Many Requests';

  @override
  String get userMessage => AppConstants.tooManyRequestsMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return RateLimitErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class MaintenanceErrorState extends ServerErrorState {
  MaintenanceErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Maintenance Mode';

  @override
  String get userMessage => AppConstants.maintenanceModeMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return MaintenanceErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class ServiceUnavailableErrorState extends ServerErrorState {
  ServiceUnavailableErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Service Unavailable';

  @override
  String get userMessage => AppConstants.serviceUnavailableMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ServiceUnavailableErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Resource-related error states
class NotFoundErrorState extends BaseErrorState {
  NotFoundErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Not Found';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return NotFoundErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Data-related error states
class ParsingErrorState extends BaseErrorState {
  ParsingErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Data Error';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ParsingErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Location-related error states
class LocationErrorState extends BaseErrorState {
  LocationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Location Error';

  @override
  String get errorIcon => 'location_off';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return LocationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class GeofenceViolationErrorState extends LocationErrorState {
  GeofenceViolationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Location Violation';

  @override
  String get userMessage => AppConstants.geofenceViolationMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return GeofenceViolationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Offline data error states
class OfflineDataErrorState extends BaseErrorState {
  OfflineDataErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Offline Data Error';

  @override
  String get errorIcon => 'cloud_off';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return OfflineDataErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class ExpiredOfflineDataErrorState extends OfflineDataErrorState {
  ExpiredOfflineDataErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Offline Data Expired';

  @override
  String get userMessage => AppConstants.expiredOfflineDataMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return ExpiredOfflineDataErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Device-related error states
class DeviceErrorState extends BaseErrorState {
  DeviceErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Device Error';

  @override
  String get errorIcon => 'phonelink_erase';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return DeviceErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class UntrustedDeviceErrorState extends DeviceErrorState {
  UntrustedDeviceErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Device Not Trusted';

  @override
  String get userMessage => AppConstants.deviceNotTrustedMessage;

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return UntrustedDeviceErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Guard duty specific error states
class GuardDutyOperationErrorState extends BaseErrorState {
  GuardDutyOperationErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Guard Duty Error';

  @override
  String get errorIcon => 'security';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return GuardDutyOperationErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class RosterErrorState extends GuardDutyOperationErrorState {
  RosterErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Roster Error';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return RosterErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class MovementErrorState extends GuardDutyOperationErrorState {
  MovementErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Movement Tracking Error';

  @override
  String get errorIcon => 'directions_walk';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return MovementErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

class PerimeterCheckErrorState extends GuardDutyOperationErrorState {
  PerimeterCheckErrorState({required super.errorInfo, super.timestamp});

  @override
  String get errorTitle => 'Perimeter Check Error';

  @override
  String get errorIcon => 'border_outer';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return PerimeterCheckErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      timestamp: timestamp,
    );
  }
}

/// Retryable error states with retry functionality
abstract class RetryableErrorState extends BaseErrorState {
  final VoidCallback? onRetry;
  final int maxRetries;
  final int currentAttempt;

  RetryableErrorState({
    required super.errorInfo,
    this.onRetry,
    this.maxRetries = 3,
    this.currentAttempt = 0,
    super.timestamp,
  });

  @override
  List<Object?> get props => [
        errorInfo,
        maxRetries,
        currentAttempt,
        timestamp,
      ];

  /// Check if more retry attempts are available
  bool get hasRetriesLeft => currentAttempt < maxRetries;

  /// Get remaining retry attempts
  int get retriesLeft => maxRetries - currentAttempt;

  /// Execute retry if callback is provided and retries are available
  void retry() {
    if (hasRetriesLeft && onRetry != null) {
      onRetry!();
    }
  }

  /// Get retry delay for next attempt
  int get nextRetryDelay => getRetryDelay(currentAttempt + 1);
}

class RetryableNetworkErrorState extends RetryableErrorState {
  RetryableNetworkErrorState({
    required super.errorInfo,
    super.onRetry,
    super.maxRetries,
    super.currentAttempt,
    super.timestamp,
  });

  @override
  String get errorTitle => 'Connection Problem';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return RetryableNetworkErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      onRetry: onRetry,
      maxRetries: maxRetries,
      currentAttempt: currentAttempt,
      timestamp: timestamp,
    );
  }
}

class RetryableServerErrorState extends RetryableErrorState {
  RetryableServerErrorState({
    required super.errorInfo,
    super.onRetry,
    super.maxRetries,
    super.currentAttempt,
    super.timestamp,
  });

  @override
  String get errorTitle => 'Server Error';

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return RetryableServerErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      onRetry: onRetry,
      maxRetries: maxRetries,
      currentAttempt: currentAttempt,
      timestamp: timestamp,
    );
  }
}

class RetryableGenericErrorState extends RetryableErrorState {
  RetryableGenericErrorState({
    required super.errorInfo,
    super.onRetry,
    super.maxRetries,
    super.currentAttempt,
    super.timestamp,
  });

  @override
  BaseErrorState copyWith({BlocErrorInfo? errorInfo}) {
    return RetryableGenericErrorState(
      errorInfo: errorInfo ?? this.errorInfo,
      onRetry: onRetry,
      maxRetries: maxRetries,
      currentAttempt: currentAttempt,
      timestamp: timestamp,
    );
  }
}

/// Callback type for retry functionality
typedef VoidCallback = void Function();

/// Extension methods for BaseErrorState
extension BaseErrorStateExtension on BaseErrorState {
  /// Check if error occurred recently (within last 5 seconds)
  bool get isRecent {
    final now = DateTime.now();
    return now.difference(timestamp).inSeconds <= 5;
  }

  /// Check if error is stale (older than 30 seconds)
  bool get isStale {
    final now = DateTime.now();
    return now.difference(timestamp).inSeconds > 30;
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Check if this error should be logged to analytics
  bool get shouldLogToAnalytics {
    // Don't log validation errors or client-side errors
    return errorType != ErrorType.validation && 
           !isRecent && // Avoid duplicate logging
           statusCode != 400 && // Bad request
           statusCode != 422; // Validation error
  }

  /// Get priority level for error handling
  ErrorPriority get priority {
    switch (errorType) {
      case ErrorType.authentication:
      case ErrorType.authorization:
        return ErrorPriority.high;
      case ErrorType.server:
      case ErrorType.network:
        return ErrorPriority.medium;
      case ErrorType.validation:
      case ErrorType.notFound:
        return ErrorPriority.low;
      default:
        return ErrorPriority.medium;
    }
  }
}

/// Error priority enumeration
enum ErrorPriority {
  low,
  medium,
  high,
  critical,
}

/// Error severity based on impact to user experience
enum ErrorSeverity {
  /// User can continue with limited functionality
  warning,
  /// User experience is degraded but app is functional
  error,
  /// Critical functionality is broken
  critical,
  /// App is unusable
  fatal,
}

/// Extension for getting error severity
extension ErrorSeverityExtension on BaseErrorState {
  ErrorSeverity get severity {
    switch (errorType) {
      case ErrorType.authentication:
        return ErrorSeverity.critical;
      case ErrorType.authorization:
        return ErrorSeverity.error;
      case ErrorType.network:
        return isOfflineError ? ErrorSeverity.warning : ErrorSeverity.error;
      case ErrorType.server:
        return canRetry ? ErrorSeverity.error : ErrorSeverity.critical;
      case ErrorType.validation:
        return ErrorSeverity.warning;
      case ErrorType.timeout:
        return ErrorSeverity.warning;
      case ErrorType.notFound:
        return ErrorSeverity.warning;
      case ErrorType.rateLimited:
        return ErrorSeverity.warning;
      case ErrorType.parsing:
        return ErrorSeverity.error;
      case ErrorType.unknown:
      default:
        return ErrorSeverity.error;
    }
  }
}