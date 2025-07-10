import 'dart:developer';
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart'; // Added ApiConstants import
import '../../data/models/api_error_model.dart';
import 'exceptions.dart';

class ErrorHandler {
  static const String _logTag = 'ErrorHandler';

  /// Process any error/exception and return a standardized BlocErrorInfo
  static BlocErrorInfo handleError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
    bool shouldLog = true,
  }) {
    if (shouldLog) {
      _logError(error, context, additionalData);
    }

    // Handle different types of errors
    if (error is ApiErrorModel) {
      return _handleApiError(error);
    } else if (error is AuthException) {
      return _handleAuthException(error);
    } else if (error is ValidationException) {
      return _handleValidationException(error);
    } else if (error is NetworkException) {
      return _handleNetworkException(error);
    } else if (error is ServerException) {
      return _handleServerException(error);
    } else if (error is SocketException) {
      return _handleSocketException(error);
    } else if (error is HttpException) {
      return _handleHttpException(error);
    } else if (error is FormatException) {
      return _handleFormatException(error);
    } else if (error is TimeoutException) {
      return _handleTimeoutException(error);
    } else if (error is Exception) {
      return _handleGenericException(error);
    } else {
      return _handleUnknownError(error);
    }
  }

  /// Handle API errors from ApiErrorModel
  static BlocErrorInfo _handleApiError(ApiErrorModel error) {
    ErrorType errorType;
    bool canRetry = false;
    bool isNetworkError = false;

    // Use ApiConstants instead of hardcoded status codes
    switch (error.statusCode) {
      case ApiConstants.unauthorizedCode:
        errorType = ErrorType.authentication;
        break;
      case ApiConstants.forbiddenCode:
        errorType = ErrorType.authorization;
        break;
      case ApiConstants.notFoundCode:
        errorType = ErrorType.notFound;
        break;
      case ApiConstants.validationErrorCode:
        errorType = ErrorType.validation;
        break;
      case ApiConstants.tooManyRequestsCode:
        errorType = ErrorType.rateLimited;
        canRetry = true;
        break;
      case ApiConstants.serverErrorCode:
      case ApiConstants.badGatewayCode:
      case ApiConstants.serviceUnavailableCode:
      case ApiConstants.gatewayTimeoutCode:
        errorType = ErrorType.server;
        canRetry = true;
        break;
      default:
        if (error.message.toLowerCase().contains('network') ||
            error.message.toLowerCase().contains('connection')) {
          errorType = ErrorType.network;
          isNetworkError = true;
          canRetry = true;
        } else {
          errorType = ErrorType.unknown;
        }
    }

    // Use ApiConstants helper methods for better logic
    if (error.statusCode != null) {
      canRetry = canRetry || ApiConstants.isRetryableStatusCode(error.statusCode!);
      isNetworkError = isNetworkError || 
          (ApiConstants.isServerError(error.statusCode!) && 
           [ApiConstants.badGatewayCode, ApiConstants.gatewayTimeoutCode]
               .contains(error.statusCode));
    }

    return BlocErrorInfo(
      type: errorType,
      message: _getHumanReadableMessage(error.message, errorType),
      originalError: error,
      statusCode: error.statusCode,
      canRetry: canRetry,
      isNetworkError: isNetworkError,
      validationErrors:
          error.hasValidationErrors ? error.validationMessages : null,
      errorCode: error.statusCode?.toString(),
    );
  }

  /// Handle authentication exceptions
  static BlocErrorInfo _handleAuthException(AuthException error) {
    return BlocErrorInfo(
      type: ErrorType.authentication,
      message:
          _getHumanReadableMessage(error.message, ErrorType.authentication),
      originalError: error,
      statusCode: error.statusCode ?? ApiConstants.unauthorizedCode, // Use ApiConstants default
      canRetry: false,
      isNetworkError: false,
      errorCode: error.statusCode?.toString() ?? ApiConstants.unauthorizedCode.toString(),
    );
  }

  /// Handle validation exceptions
  static BlocErrorInfo _handleValidationException(ValidationException error) {
    List<String> validationMessages = [];
    if (error.validationErrors != null) {
      error.validationErrors!.forEach((field, messages) {
        validationMessages.addAll(messages);
      });
    }

    return BlocErrorInfo(
      type: ErrorType.validation,
      message: validationMessages.isNotEmpty
          ? validationMessages.first
          : _getHumanReadableMessage(error.message, ErrorType.validation),
      originalError: error,
      statusCode: error.statusCode ?? ApiConstants.validationErrorCode, // Use ApiConstants default
      canRetry: false,
      isNetworkError: false,
      validationErrors:
          validationMessages.isNotEmpty ? validationMessages : null,
      errorCode: error.statusCode?.toString() ?? ApiConstants.validationErrorCode.toString(),
    );
  }

  /// Handle network exceptions
  static BlocErrorInfo _handleNetworkException(NetworkException error) {
    return BlocErrorInfo(
      type: ErrorType.network,
      message: _getHumanReadableMessage(error.message, ErrorType.network),
      originalError: error,
      statusCode: error.statusCode,
      canRetry: true,
      isNetworkError: true,
      errorCode: error.statusCode?.toString() ?? 'NETWORK_ERROR',
    );
  }

  /// Handle server exceptions
  static BlocErrorInfo _handleServerException(ServerException error) {
    final statusCode = error.statusCode ?? ApiConstants.serverErrorCode;
    
    return BlocErrorInfo(
      type: ErrorType.server,
      message: _getHumanReadableMessage(error.message, ErrorType.server),
      originalError: error,
      statusCode: statusCode,
      canRetry: ApiConstants.isRetryableStatusCode(statusCode), // Use ApiConstants logic
      isNetworkError: false,
      errorCode: statusCode.toString(),
    );
  }

  /// Handle socket exceptions (network connectivity)
  static BlocErrorInfo _handleSocketException(SocketException error) {
    return BlocErrorInfo(
      type: ErrorType.network,
      message: AppConstants.networkErrorMessage,
      originalError: error,
      canRetry: true,
      isNetworkError: true,
      errorCode: 'SOCKET_ERROR',
    );
  }

  /// Handle HTTP exceptions
  static BlocErrorInfo _handleHttpException(HttpException error) {
    return BlocErrorInfo(
      type: ErrorType.network,
      message: _getHumanReadableMessage(error.message, ErrorType.network),
      originalError: error,
      canRetry: true,
      isNetworkError: true,
      errorCode: 'HTTP_ERROR',
    );
  }

  /// Handle format exceptions
  static BlocErrorInfo _handleFormatException(FormatException error) {
    return BlocErrorInfo(
      type: ErrorType.parsing,
      message: 'Invalid data format received. Please try again.',
      originalError: error,
      canRetry: true,
      isNetworkError: false,
      errorCode: 'FORMAT_ERROR',
    );
  }

  /// Handle timeout exceptions
  static BlocErrorInfo _handleTimeoutException(TimeoutException error) {
    return BlocErrorInfo(
      type: ErrorType.timeout,
      message: 'Request timed out. Please check your connection and try again.',
      originalError: error,
      canRetry: true,
      isNetworkError: true,
      errorCode: 'TIMEOUT_ERROR',
    );
  }

  /// Handle generic exceptions
  static BlocErrorInfo _handleGenericException(Exception error) {
    String message = error.toString();
    ErrorType type = ErrorType.unknown;
    bool isNetworkError = false;
    bool canRetry = false;

    // Try to determine error type from message
    if (message.toLowerCase().contains('connection') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('internet')) {
      type = ErrorType.network;
      isNetworkError = true;
      canRetry = true;
      message = AppConstants.networkErrorMessage;
    } else if (message.toLowerCase().contains('timeout')) {
      type = ErrorType.timeout;
      isNetworkError = true;
      canRetry = true;
      message = 'Request timed out. Please try again.';
    } else if (message.toLowerCase().contains('server')) {
      type = ErrorType.server;
      canRetry = true;
      message = AppConstants.serverErrorMessage;
    } else {
      message = AppConstants.unknownErrorMessage;
    }

    return BlocErrorInfo(
      type: type,
      message: message,
      originalError: error,
      canRetry: canRetry,
      isNetworkError: isNetworkError,
      errorCode: 'GENERIC_ERROR',
    );
  }

  /// Handle unknown errors
  static BlocErrorInfo _handleUnknownError(dynamic error) {
    return BlocErrorInfo(
      type: ErrorType.unknown,
      message: AppConstants.unknownErrorMessage,
      originalError: error,
      canRetry: false,
      isNetworkError: false,
      errorCode: 'UNKNOWN_ERROR',
    );
  }

  /// Get human-readable error message based on error type
  static String _getHumanReadableMessage(
      String originalMessage, ErrorType type) {
    switch (type) {
      case ErrorType.network:
        return AppConstants.networkErrorMessage;
      case ErrorType.server:
        return AppConstants.serverErrorMessage;
      case ErrorType.authentication:
        return AppConstants.unauthorizedMessage;
      case ErrorType.validation:
        return originalMessage.isNotEmpty
            ? originalMessage
            : AppConstants.validationErrorMessage;
      case ErrorType.authorization:
        return AppConstants.forbiddenMessage; // Use from AppConstants
      case ErrorType.notFound:
        return AppConstants.notFoundMessage; // Use from AppConstants
      case ErrorType.timeout:
        return AppConstants.connectionTimeoutMessage; // Use from AppConstants
      case ErrorType.rateLimited:
        return AppConstants.tooManyRequestsMessage; // Use from AppConstants
      case ErrorType.parsing:
        return 'Invalid data received. Please try again.';
      case ErrorType.unknown:
        return originalMessage.isNotEmpty
            ? originalMessage
            : AppConstants.unknownErrorMessage;
    }
  }

  /// Log error details for debugging
  static void _logError(
    dynamic error,
    String? context,
    Map<String, dynamic>? additionalData,
  ) {
    final logMessage = StringBuffer();
    logMessage.writeln('[$_logTag] Error occurred');

    if (context != null) {
      logMessage.writeln('Context: $context');
    }

    logMessage.writeln('Error Type: ${error.runtimeType}');
    logMessage.writeln('Error Message: $error');

    if (error is ApiErrorModel) {
      logMessage.writeln('Status Code: ${error.statusCode}');
      logMessage.writeln('API Status: ${error.status}');
      
      // Use ApiConstants for categorization
      if (error.statusCode != null) {
        logMessage.writeln('Error Category: ${ApiConstants.getErrorCategory(error.statusCode!)}');
        logMessage.writeln('Is Retryable: ${ApiConstants.isRetryableStatusCode(error.statusCode!)}');
        logMessage.writeln('Requires Auth: ${ApiConstants.requiresAuthentication(error.statusCode!)}');
      }
      
      if (error.hasValidationErrors) {
        logMessage.writeln('Validation Errors: ${error.errors}');
      }
    }

    if (additionalData != null && additionalData.isNotEmpty) {
      logMessage.writeln('Additional Data: $additionalData');
    }

    log(logMessage.toString());
  }

  /// Check if error indicates offline/network issues
  static bool isOfflineError(BlocErrorInfo errorInfo) {
    return errorInfo.isNetworkError ||
        errorInfo.type == ErrorType.network ||
        errorInfo.type == ErrorType.timeout;
  }

  /// Check if error indicates authentication issues
  static bool isAuthError(BlocErrorInfo errorInfo) {
    return errorInfo.type == ErrorType.authentication ||
        (errorInfo.statusCode != null && 
         ApiConstants.requiresAuthentication(errorInfo.statusCode!)); // Use ApiConstants
  }

  /// Check if error indicates session expiry
  static bool isSessionExpired(BlocErrorInfo errorInfo) {
    return isAuthError(errorInfo) &&
        (errorInfo.message.toLowerCase().contains('expired') ||
            errorInfo.message.toLowerCase().contains('invalid token'));
  }

  /// Get retry delay in milliseconds based on error type and status code
  static int getRetryDelay(ErrorType errorType, int attemptNumber, {int? statusCode}) {
    // Use ApiConstants to determine base delay for specific status codes
    int baseDelay = 1000;
    
    if (statusCode != null) {
      switch (statusCode) {
        case ApiConstants.tooManyRequestsCode:
          baseDelay = 5000; // Longer delay for rate limits
          break;
        case ApiConstants.serviceUnavailableCode:
          baseDelay = 10000; // Longer delay for service unavailable
          break;
        case ApiConstants.badGatewayCode:
        case ApiConstants.gatewayTimeoutCode:
          baseDelay = 3000; // Medium delay for gateway issues
          break;
        default:
          if (ApiConstants.isServerError(statusCode)) {
            baseDelay = 2000; // Standard server error delay
          }
      }
    } else {
      // Fallback to error type-based delays
      switch (errorType) {
        case ErrorType.network:
        case ErrorType.timeout:
          baseDelay = 1000;
          break;
        case ErrorType.server:
          baseDelay = 2000;
          break;
        case ErrorType.rateLimited:
          baseDelay = 5000;
          break;
        default:
          baseDelay = 1000;
      }
    }

    // Exponential backoff with max limit
    final delay = (baseDelay * attemptNumber * 2).clamp(baseDelay, 15000);
    return delay;
  }
}

// Enumeration of error types (unchanged)
enum ErrorType {
  network,
  server,
  authentication,
  authorization,
  validation,
  notFound,
  timeout,
  rateLimited,
  parsing,
  unknown,
}

// BlocErrorInfo class remains the same but with enhanced constructor
class BlocErrorInfo extends Equatable {
  final ErrorType type;
  final String message;
  final dynamic originalError;
  final int? statusCode;
  final bool canRetry;
  final bool isNetworkError;
  final List<String>? validationErrors;
  final String? errorCode;
  final DateTime timestamp;

  BlocErrorInfo({
    required this.type,
    required this.message,
    this.originalError,
    this.statusCode,
    bool? canRetry,
    this.isNetworkError = false,
    this.validationErrors,
    this.errorCode,
    DateTime? timestamp,
  }) : canRetry = canRetry ?? 
           (statusCode != null ? ApiConstants.isRetryableStatusCode(statusCode) : false), // Smart retry detection
       timestamp = timestamp ?? DateTime.now();

  @override
  List<Object?> get props => [
        type,
        message,
        statusCode,
        canRetry,
        isNetworkError,
        validationErrors,
        errorCode,
        timestamp,
      ];

  /// Create a copy with updated properties
  BlocErrorInfo copyWith({
    ErrorType? type,
    String? message,
    dynamic originalError,
    int? statusCode,
    bool? canRetry,
    bool? isNetworkError,
    List<String>? validationErrors,
    String? errorCode,
    DateTime? timestamp,
  }) {
    return BlocErrorInfo(
      type: type ?? this.type,
      message: message ?? this.message,
      originalError: originalError ?? this.originalError,
      statusCode: statusCode ?? this.statusCode,
      canRetry: canRetry ?? this.canRetry,
      isNetworkError: isNetworkError ?? this.isNetworkError,
      validationErrors: validationErrors ?? this.validationErrors,
      errorCode: errorCode ?? this.errorCode,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Convert to user-friendly error message
  String toUserMessage() {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      return validationErrors!.first;
    }
    return message;
  }

  /// Check if this is a specific error type
  bool isType(ErrorType type) => this.type == type;

  /// Check if this error should trigger offline mode
  bool shouldTriggerOfflineMode() {
    return isNetworkError || 
           type == ErrorType.network ||
           (statusCode != null && 
            [ApiConstants.badGatewayCode, ApiConstants.gatewayTimeoutCode]
                .contains(statusCode));
  }

  /// Check if this error should logout user
  bool shouldLogoutUser() {
    return type == ErrorType.authentication &&
        (message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('invalid'));
  }

  /// Get error category using ApiConstants
  String get errorCategory {
    if (statusCode != null) {
      return ApiConstants.getErrorCategory(statusCode!);
    }
    return type.toString().split('.').last;
  }

  /// Check if this error requires authentication using ApiConstants
  bool get requiresAuthentication {
    return statusCode != null && ApiConstants.requiresAuthentication(statusCode!);
  }
}