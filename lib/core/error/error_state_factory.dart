// lib/core/error/error_state_factory.dart
import 'dart:developer';
import 'error_handler.dart';
import 'common_error_states.dart';
import 'exceptions.dart';
import 'failures.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';

/// Comprehensive factory for creating appropriate error states for presentation layer
/// Follows DRY principles and provides centralized error state creation logic
class ErrorStateFactory {
  static const String _logTag = 'ErrorStateFactory';

  /// Create error state from BlocErrorInfo (primary method)
  static BaseErrorState createErrorState(BlocErrorInfo errorInfo) {
    _logErrorState(errorInfo);

    switch (errorInfo.type) {
      case ErrorType.network:
        return _createNetworkErrorState(errorInfo);
      case ErrorType.timeout:
        return _createTimeoutErrorState(errorInfo);
      case ErrorType.authentication:
        return _createAuthenticationErrorState(errorInfo);
      case ErrorType.authorization:
        return _createAuthorizationErrorState(errorInfo);
      case ErrorType.validation:
        return _createValidationErrorState(errorInfo);
      case ErrorType.server:
        return _createServerErrorState(errorInfo);
      case ErrorType.notFound:
        return _createNotFoundErrorState(errorInfo);
      case ErrorType.rateLimited:
        return _createRateLimitErrorState(errorInfo);
      case ErrorType.parsing:
        return _createParsingErrorState(errorInfo);
      case ErrorType.unknown:
      default:
        return _createGenericErrorState(errorInfo);
    }
  }

  /// Create error state from exception
  static BaseErrorState createFromException(AppException exception) {
    final errorInfo = ErrorHandler.handleError(exception);
    return createErrorState(errorInfo);
  }

  /// Create error state from failure
  static BaseErrorState createFromFailure(Failure failure) {
    final exception = failure.toException();
    return createFromException(exception);
  }

  /// Create error state from dynamic error (fallback method)
  static BaseErrorState createFromDynamicError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    final errorInfo = ErrorHandler.handleError(
      error,
      context: context,
      additionalData: additionalData,
    );
    return createErrorState(errorInfo);
  }

  /// Create specific error states for guard duty operations
  static BaseErrorState createGuardDutyErrorState(
    GuardDutyException exception,
  ) {
    if (exception is RosterException) {
      return RosterErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else if (exception is MovementException) {
      return MovementErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else if (exception is PerimeterCheckException) {
      return PerimeterCheckErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else {
      return GuardDutyOperationErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    }
  }

  /// Create location-specific error states
  static BaseErrorState createLocationErrorState(
    LocationException exception,
  ) {
    if (exception is GeofenceViolationException) {
      return GeofenceViolationErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else {
      return LocationErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    }
  }

  /// Create offline data error states
  static BaseErrorState createOfflineDataErrorState(
    OfflineDataException exception,
  ) {
    if (exception is ExpiredOfflineDataException) {
      return ExpiredOfflineDataErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else {
      return OfflineDataErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    }
  }

  /// Create device-specific error states
  static BaseErrorState createDeviceErrorState(
    DeviceException exception,
  ) {
    if (exception is UntrustedDeviceException) {
      return UntrustedDeviceErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    } else {
      return DeviceErrorState(
        errorInfo: ErrorHandler.handleError(exception),
      );
    }
  }

  /// Create appropriate error state based on status code
  static BaseErrorState createFromStatusCode(
    int statusCode, {
    String? message,
    dynamic data,
    String? context,
  }) {
    final exception = ExceptionFactory.fromStatusCode(
      statusCode,
      message: message,
      data: data,
    );
    return createFromException(exception);
  }

  /// Create error state with retry functionality
  static BaseErrorState createRetryableErrorState(
    BlocErrorInfo errorInfo, {
    VoidCallback? onRetry,
    int? maxRetries,
    int? currentAttempt,
  }) {
    if (!errorInfo.canRetry) {
      return createErrorState(errorInfo);
    }

    switch (errorInfo.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return RetryableNetworkErrorState(
          errorInfo: errorInfo,
          onRetry: onRetry,
          maxRetries: maxRetries ?? AppConstants.maxRetryAttempts,
          currentAttempt: currentAttempt ?? 0,
        );
      case ErrorType.server:
        return RetryableServerErrorState(
          errorInfo: errorInfo,
          onRetry: onRetry,
          maxRetries: maxRetries ?? AppConstants.maxRetryAttempts,
          currentAttempt: currentAttempt ?? 0,
        );
      default:
        return RetryableGenericErrorState(
          errorInfo: errorInfo,
          onRetry: onRetry,
          maxRetries: maxRetries ?? AppConstants.maxRetryAttempts,
          currentAttempt: currentAttempt ?? 0,
        );
    }
  }

  /// Check if error should trigger specific UI behavior
  static ErrorUIBehavior getErrorUIBehavior(BlocErrorInfo errorInfo) {
    // Check for logout requirement
    if (errorInfo.shouldLogoutUser()) {
      return ErrorUIBehavior.logout;
    }

    // Check for offline mode
    if (errorInfo.shouldTriggerOfflineMode()) {
      return ErrorUIBehavior.enableOfflineMode;
    }

    // Check for specific error types
    switch (errorInfo.type) {
      case ErrorType.authentication:
        return ErrorUIBehavior.redirectToLogin;
      case ErrorType.validation:
        return ErrorUIBehavior.showValidationErrors;
      case ErrorType.network:
        return ErrorUIBehavior.showNetworkError;
      case ErrorType.server:
        return errorInfo.canRetry 
            ? ErrorUIBehavior.showRetryableError 
            : ErrorUIBehavior.showGenericError;
      default:
        return ErrorUIBehavior.showGenericError;
    }
  }

  /// Get user action suggestions based on error type
  static List<ErrorAction> getErrorActions(BlocErrorInfo errorInfo) {
    final actions = <ErrorAction>[];

    // Add retry action if retryable
    if (errorInfo.canRetry) {
      actions.add(ErrorAction.retry);
    }

    // Add specific actions based on error type
    switch (errorInfo.type) {
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
        if (errorInfo.statusCode == ApiConstants.serviceUnavailableCode) {
          actions.add(ErrorAction.waitAndRetry);
        }
        break;
      default:
        actions.add(ErrorAction.contactSupport);
    }

    // Always add dismiss option
    actions.add(ErrorAction.dismiss);

    return actions;
  }

  /// Private helper methods for creating specific error states

  static NetworkErrorState _createNetworkErrorState(BlocErrorInfo errorInfo) {
    return NetworkErrorState(errorInfo: errorInfo);
  }

  static TimeoutErrorState _createTimeoutErrorState(BlocErrorInfo errorInfo) {
    return TimeoutErrorState(errorInfo: errorInfo);
  }

  static AuthenticationErrorState _createAuthenticationErrorState(BlocErrorInfo errorInfo) {
    // Check for specific auth error types
    if (errorInfo.message.toLowerCase().contains('expired') ||
        errorInfo.message.toLowerCase().contains('invalid token')) {
      return SessionExpiredErrorState(errorInfo: errorInfo);
    }
    
    if (errorInfo.statusCode == ApiConstants.forbiddenCode) {
      return ForbiddenErrorState(errorInfo: errorInfo);
    }

    return AuthenticationErrorState(errorInfo: errorInfo);
  }

  static AuthorizationErrorState _createAuthorizationErrorState(BlocErrorInfo errorInfo) {
    return AuthorizationErrorState(errorInfo: errorInfo);
  }

  static ValidationErrorState _createValidationErrorState(BlocErrorInfo errorInfo) {
    if (errorInfo.validationErrors != null && errorInfo.validationErrors!.isNotEmpty) {
      return FieldValidationErrorState(
        errorInfo: errorInfo,
        fieldErrors: _parseFieldErrors(errorInfo.validationErrors!),
      );
    }
    return ValidationErrorState(errorInfo: errorInfo);
  }

  static ServerErrorState _createServerErrorState(BlocErrorInfo errorInfo) {
    // Check for specific server error types
    switch (errorInfo.statusCode) {
      case ApiConstants.tooManyRequestsCode:
        return RateLimitErrorState(errorInfo: errorInfo);
      case ApiConstants.serviceUnavailableCode:
        return MaintenanceErrorState(errorInfo: errorInfo);
      case ApiConstants.badGatewayCode:
      case ApiConstants.gatewayTimeoutCode:
        return ServiceUnavailableErrorState(errorInfo: errorInfo);
      default:
        return ServerErrorState(errorInfo: errorInfo);
    }
  }

  static NotFoundErrorState _createNotFoundErrorState(BlocErrorInfo errorInfo) {
    return NotFoundErrorState(errorInfo: errorInfo);
  }

  static RateLimitErrorState _createRateLimitErrorState(BlocErrorInfo errorInfo) {
    return RateLimitErrorState(errorInfo: errorInfo);
  }

  static ParsingErrorState _createParsingErrorState(BlocErrorInfo errorInfo) {
    return ParsingErrorState(errorInfo: errorInfo);
  }

  static GenericErrorState _createGenericErrorState(BlocErrorInfo errorInfo) {
    return GenericErrorState(errorInfo: errorInfo);
  }

  /// Parse validation errors into field-specific errors
  static Map<String, List<String>> _parseFieldErrors(List<String> validationErrors) {
    final fieldErrors = <String, List<String>>{};
    
    for (final error in validationErrors) {
      // Try to extract field name from error message
      // This is a simple implementation, you might need to adjust based on your API format
      final parts = error.split(':');
      if (parts.length > 1) {
        final field = parts[0].trim();
        final message = parts.sublist(1).join(':').trim();
        fieldErrors.putIfAbsent(field, () => []).add(message);
      } else {
        fieldErrors.putIfAbsent('general', () => []).add(error);
      }
    }
    
    return fieldErrors;
  }

  /// Log error state creation for debugging
  static void _logErrorState(BlocErrorInfo errorInfo) {
    log(
      '[$_logTag] Creating error state: ${errorInfo.type} - ${errorInfo.message}',
      name: _logTag,
    );
  }
}

/// Callback type for retry functionality
typedef VoidCallback = void Function();

/// Enumeration for error UI behaviors
enum ErrorUIBehavior {
  showGenericError,
  showNetworkError,
  showValidationErrors,
  showRetryableError,
  redirectToLogin,
  logout,
  enableOfflineMode,
  showMaintenanceMessage,
}

/// Enumeration for error actions
enum ErrorAction {
  retry,
  login,
  logout,
  checkConnection,
  tryOfflineMode,
  correctInput,
  contactSupport,
  waitAndRetry,
  dismiss,
}

/// Extension for getting user-friendly action labels
extension ErrorActionExtension on ErrorAction {
  String get label {
    switch (this) {
      case ErrorAction.retry:
        return 'Retry';
      case ErrorAction.login:
        return 'Login';
      case ErrorAction.logout:
        return 'Logout';
      case ErrorAction.checkConnection:
        return 'Check Connection';
      case ErrorAction.tryOfflineMode:
        return 'Try Offline Mode';
      case ErrorAction.correctInput:
        return 'Correct Input';
      case ErrorAction.contactSupport:
        return 'Contact Support';
      case ErrorAction.waitAndRetry:
        return 'Wait & Retry';
      case ErrorAction.dismiss:
        return 'Dismiss';
    }
  }

  String get description {
    switch (this) {
      case ErrorAction.retry:
        return 'Try the operation again';
      case ErrorAction.login:
        return 'Sign in to continue';
      case ErrorAction.logout:
        return 'Sign out and login again';
      case ErrorAction.checkConnection:
        return 'Verify your internet connection';
      case ErrorAction.tryOfflineMode:
        return 'Use cached data';
      case ErrorAction.correctInput:
        return 'Fix the input errors';
      case ErrorAction.contactSupport:
        return 'Get help from support team';
      case ErrorAction.waitAndRetry:
        return 'Wait a moment and try again';
      case ErrorAction.dismiss:
        return 'Close this message';
    }
  }
}

/// Error state configuration for different BLoC types
class ErrorStateConfig {
  final bool showRetryButton;
  final bool showDismissButton;
  final bool logToAnalytics;
  final Duration? autoRetryDelay;
  final List<ErrorAction> allowedActions;

  const ErrorStateConfig({
    this.showRetryButton = true,
    this.showDismissButton = true,
    this.logToAnalytics = true,
    this.autoRetryDelay,
    this.allowedActions = const [],
  });

  /// Default config for authentication BLoCs
  static const auth = ErrorStateConfig(
    showRetryButton: false,
    allowedActions: [ErrorAction.login, ErrorAction.dismiss],
  );

  /// Default config for network operations
  static const network = ErrorStateConfig(
    showRetryButton: true,
    autoRetryDelay: Duration(seconds: 3),
    allowedActions: [
      ErrorAction.retry,
      ErrorAction.checkConnection,
      ErrorAction.tryOfflineMode,
      ErrorAction.dismiss,
    ],
  );

  /// Default config for data operations
  static const data = ErrorStateConfig(
    showRetryButton: true,
    allowedActions: [
      ErrorAction.retry,
      ErrorAction.contactSupport,
      ErrorAction.dismiss,
    ],
  );

  /// Default config for validation errors
  static const validation = ErrorStateConfig(
    showRetryButton: false,
    allowedActions: [
      ErrorAction.correctInput,
      ErrorAction.dismiss,
    ],
  );
}