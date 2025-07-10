import 'package:slates_app_wear/core/error/error_handler.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/error/error_state_factory.dart';

mixin ErrorStateMixin {
  /// The error info that all error states should have
  BlocErrorInfo get errorInfo;

  // ====================
  // CONVENIENCE GETTERS
  // ====================

  /// Get user-friendly error message
  String get message => errorInfo.toUserMessage();

  /// Get error code if available
  String? get errorCode => errorInfo.errorCode;

  /// Get HTTP status code if available
  int? get statusCode => errorInfo.statusCode;

  /// Check if error can be retried
  bool get canRetry => errorInfo.canRetry;

  /// Check if error is network-related
  bool get isNetworkError => errorInfo.isNetworkError;

  /// Get error type
  ErrorType get errorType => errorInfo.type;

  /// Get validation errors if available
  List<String>? get validationErrors => errorInfo.validationErrors;

  /// Get original error object
  dynamic get originalError => errorInfo.originalError;

  /// Get timestamp when error occurred
  DateTime get timestamp => errorInfo.timestamp;

  // ====================
  // ERROR CLASSIFICATION
  // ====================

  /// Check if error indicates authentication issues
  bool get isAuthError => ErrorHandler.isAuthError(errorInfo);

  /// Check if error indicates session expiry
  bool get isSessionExpired => ErrorHandler.isSessionExpired(errorInfo);

  /// Check if error indicates offline/network issues
  bool get isOfflineError => ErrorHandler.isOfflineError(errorInfo);

  /// Check if error should trigger offline mode
  bool get shouldTriggerOfflineMode => errorInfo.shouldTriggerOfflineMode();

  /// Check if error should logout user
  bool get shouldLogoutUser => errorInfo.shouldLogoutUser();

  /// Get error category using ApiConstants
  String get errorCategory => errorInfo.errorCategory;

  /// Check if error requires authentication using ApiConstants
  bool get requiresAuthentication => errorInfo.requiresAuthentication;

  // ====================
  // ERROR STATE HELPERS
  // ====================

  /// Check if this is a specific error type
  bool isType(ErrorType type) => errorInfo.isType(type);

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

  // ====================
  // RETRY LOGIC
  // ====================

  /// Get retry delay in milliseconds for next attempt
  int getRetryDelay(int attemptNumber) {
    return ErrorHandler.getRetryDelay(errorType, attemptNumber, statusCode: statusCode);
  }

  /// Check if error should be logged to analytics
  bool get shouldLogToAnalytics {
    // Don't log validation errors or client-side errors
    return errorType != ErrorType.validation && 
           !isRecent && // Avoid duplicate logging
           statusCode != ApiConstants.badRequestCode && // Bad request
           statusCode != ApiConstants.validationErrorCode; // Validation error
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
      case ErrorType.timeout:
      case ErrorType.rateLimited:
      case ErrorType.parsing:
      case ErrorType.unknown:
        return ErrorPriority.medium;
    }
  }

  /// Get error severity based on impact to user experience
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
        return ErrorSeverity.error;
    }
  }

  // ====================
  // ERROR CONTEXT HELPERS
  // ====================

  /// Get user-friendly error title
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
        return 'error';
    }
  }

  // ====================
  // ERROR ACTIONS
  // ====================

  /// Get suggested actions for this error
  List<ErrorAction> get suggestedActions {
    final actions = <ErrorAction>[];

    // Add retry action if retryable
    if (canRetry) {
      actions.add(ErrorAction.retry);
    }

    // Add specific actions based on error type
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
        actions.addAll([
          ErrorAction.checkConnection,
          ErrorAction.tryOfflineMode,
        ]);
        break;
      case ErrorType.authentication:
        actions.add(ErrorAction.login);
        break;
      case ErrorType.validation:
        actions.add(ErrorAction.correctInput);
        break;
      case ErrorType.server:
        if (statusCode == ApiConstants.serviceUnavailableCode) {
          actions.add(ErrorAction.waitAndRetry);
        }
        break;
      case ErrorType.authorization:
      case ErrorType.notFound:
      case ErrorType.rateLimited:
      case ErrorType.parsing:
      case ErrorType.unknown:
        actions.add(ErrorAction.contactSupport);
        break;
    }

    // Always add dismiss option
    actions.add(ErrorAction.dismiss);

    return actions;
  }

  /// Check if specific action is available for this error
  bool hasAction(ErrorAction action) => suggestedActions.contains(action);

  /// Get action label for UI display
  String getActionLabel(ErrorAction action) => action.label;

  /// Get action description for UI display
  String getActionDescription(ErrorAction action) => action.description;
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