import 'dart:developer';
import 'dart:io';
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
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

    // Determine error type based on status code
    switch (error.statusCode) {
      case 401:
        errorType = ErrorType.authentication;
        break;
      case 403:
        errorType = ErrorType.authorization;
        break;
      case 404:
        errorType = ErrorType.notFound;
        break;
      case 422:
        errorType = ErrorType.validation;
        break;
      case 429:
        errorType = ErrorType.rateLimited;
        canRetry = true;
        break;
      case 500:
      case 502:
      case 503:
      case 504:
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
      statusCode: error.statusCode,
      canRetry: false,
      isNetworkError: false,
      errorCode: error.statusCode?.toString(),
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
      statusCode: error.statusCode,
      canRetry: false,
      isNetworkError: false,
      validationErrors:
          validationMessages.isNotEmpty ? validationMessages : null,
      errorCode: error.statusCode?.toString(),
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
      errorCode: error.statusCode?.toString(),
    );
  }

  /// Handle server exceptions
  static BlocErrorInfo _handleServerException(ServerException error) {
    return BlocErrorInfo(
      type: ErrorType.server,
      message: _getHumanReadableMessage(error.message, ErrorType.server),
      originalError: error,
      statusCode: error.statusCode,
      canRetry: true,
      isNetworkError: false,
      errorCode: error.statusCode?.toString(),
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
        return AppConstants.unauthorizedMessage;
      case ErrorType.notFound:
        return 'The requested resource was not found.';
      case ErrorType.timeout:
        return 'Request timed out. Please check your connection and try again.';
      case ErrorType.rateLimited:
        return 'Too many requests. Please wait a moment and try again.';
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
        errorInfo.statusCode == 401;
  }

  /// Check if error indicates session expiry
  static bool isSessionExpired(BlocErrorInfo errorInfo) {
    return isAuthError(errorInfo) &&
        (errorInfo.message.toLowerCase().contains('expired') ||
            errorInfo.message.toLowerCase().contains('invalid token'));
  }

  /// Get retry delay in milliseconds based on error type
  static int getRetryDelay(ErrorType errorType, int attemptNumber) {
    switch (errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
        return (1000 * attemptNumber * 2)
            .clamp(1000, 10000); // Exponential backoff
      case ErrorType.server:
        return (2000 * attemptNumber).clamp(2000, 15000);
      case ErrorType.rateLimited:
        return 5000 * attemptNumber; // Fixed delay for rate limits
      default:
        return 1000;
    }
  }
}

/// Enumeration of error types
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

/// Standardized error information for BLoCs
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
    this.canRetry = false,
    this.isNetworkError = false,
    this.validationErrors,
    this.errorCode,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

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
    return isNetworkError || type == ErrorType.network;
  }

  /// Check if this error should logout user
  bool shouldLogoutUser() {
    return type == ErrorType.authentication &&
        (message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('invalid'));
  }
}
