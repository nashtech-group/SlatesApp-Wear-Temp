import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import '../../data/models/api_error_model.dart';
import 'exceptions.dart';

class DataLayerErrorHandler {
  static const String _logTag = 'DataLayerErrorHandler';

  /// Handle HTTP response and convert to appropriate exception
  static void handleHttpResponse(http.Response response, String operation) {
    if (ApiConstants.isSuccessStatusCode(response.statusCode)) {
      return; // Success, no error to handle
    }

    log('[$_logTag] HTTP Error in $operation: ${response.statusCode} - ${response.body}');

    try {
      final decodedBody = jsonDecode(response.body);
      
      // Try to create ApiErrorModel from response
      if (decodedBody is Map<String, dynamic>) {
        final apiError = ApiErrorModel.fromJson({
          ...decodedBody,
          ApiConstants.statusKey: response.statusCode.toString(),
        });
        throw _convertApiErrorToException(apiError);
      }
    } catch (e) {
      if (e is AppException) rethrow;
      // If JSON parsing fails, create error based on status code
    }

    // Handle by status code using constants
    throw _createExceptionFromStatusCode(
      response.statusCode, 
      response.body, 
      operation
    );
  }

  /// Handle HTTP exceptions and network errors
  static AppException handleHttpException(dynamic error, String operation) {
    log('[$_logTag] Exception in $operation: $error');

    if (error is SocketException) {
      return NetworkException(
        message: AppConstants.networkErrorMessage,
        statusCode: null,
        data: {'operation': operation, 'type': 'socket_exception'},
      );
    }

    if (error is HttpException) {
      return NetworkException(
        message: AppConstants.networkErrorMessage,
        statusCode: null,
        data: {'operation': operation, 'type': 'http_exception'},
      );
    }

    if (error is FormatException) {
      return ServerException(
        message: AppConstants.validationErrorMessage,
        statusCode: null,
        data: {'operation': operation, 'type': 'format_exception'},
      );
    }

    if (error is TimeoutException) {
      return TimeoutException(
        message: AppConstants.connectionTimeoutMessage,
        statusCode: 408, // Request Timeout
        data: {'operation': operation, 'type': 'timeout_exception'},
      );
    }

    // Generic exception
    return ServerException(
      message: AppConstants.unknownErrorMessage,
      statusCode: null,
      data: {'operation': operation, 'type': 'unknown_exception'},
    );
  }

  /// Handle repository-level errors
  static AppException handleRepositoryError(dynamic error, String operation) {
    log('[$_logTag] Repository error in $operation: $error');

    if (error is ApiErrorModel) {
      return _convertApiErrorToException(error);
    }

    if (error is AppException) {
      return error;
    }

    // Convert string errors or other types using AppConstants
    final errorString = error.toString().toLowerCase();
    
    if (errorString.contains('no internet connection') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return NetworkException(
        message: AppConstants.networkErrorMessage,
        data: {'operation': operation},
      );
    }

    if (errorString.contains('authentication') ||
        errorString.contains('unauthorized')) {
      return AuthException(
        message: AppConstants.unauthorizedMessage,
        statusCode: ApiConstants.unauthorizedCode,
        data: {'operation': operation},
      );
    }

    if (errorString.contains('timeout')) {
      return TimeoutException(
        message: AppConstants.timeoutErrorMessage,
        data: {'operation': operation},
      );
    }

    return ServerException(
      message: AppConstants.unknownErrorMessage,
      data: {'operation': operation},
    );
  }

  /// Convert ApiErrorModel to appropriate AppException using constants
  static AppException _convertApiErrorToException(ApiErrorModel apiError) {
    final statusCode = apiError.statusCode;
    final message = apiError.message.isNotEmpty 
        ? apiError.message 
        : AppConstants.getErrorMessageForStatusCode(statusCode ?? 500);

    switch (statusCode) {
      case ApiConstants.badRequestCode: // 400
        return ValidationException(
          message: message,
          statusCode: statusCode,
          validationErrors: apiError.hasValidationErrors 
              ? _parseValidationErrors(apiError.errors!) 
              : null,
        );
        
      case ApiConstants.unauthorizedCode: // 401
        return UnauthorizedException(
          message: message,

        );
        
      case ApiConstants.forbiddenCode: // 403
        return ForbiddenException(
          message: message,
      
        );
        
      case ApiConstants.notFoundCode: // 404
        return NotFoundException(
          message: message,
      
        );
        
      case ApiConstants.conflictCode: // 409
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
        
      case ApiConstants.validationErrorCode: // 422
        return ValidationException(
          message: message,
          statusCode: statusCode,
          validationErrors: apiError.hasValidationErrors 
              ? _parseValidationErrors(apiError.errors!) 
              : null,
        );
        
      case ApiConstants.tooManyRequestsCode: // 429
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
        
      case ApiConstants.serverErrorCode: // 500
      case ApiConstants.notImplementedCode: // 501
      case ApiConstants.badGatewayCode: // 502
      case ApiConstants.serviceUnavailableCode: // 503
      case ApiConstants.gatewayTimeoutCode: // 504
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
        
      default:
        // Handle based on error category
        if (statusCode != null) {
          if (ApiConstants.isClientError(statusCode)) {
            return ValidationException(
              message: message,
              statusCode: statusCode,
            );
          } else if (ApiConstants.isServerError(statusCode)) {
            return ServerException(
              message: message,
              statusCode: statusCode,
            );
          }
        }
        
        // Check message content for network issues
        if (apiError.message.toLowerCase().contains('network') ||
            apiError.message.toLowerCase().contains('connection')) {
          return NetworkException(
            message: message,
            statusCode: statusCode,
          );
        }
        
        return ServerException(
          message: message,
          statusCode: statusCode,
        );
    }
  }

  /// Create exception from HTTP status code using constants
  static AppException _createExceptionFromStatusCode(
    int statusCode,
    String responseBody,
    String operation,
  ) {
    final message = AppConstants.getErrorMessageForStatusCode(statusCode);
    final data = {
      'operation': operation,
      'statusCode': statusCode,
      'responseBody': responseBody,
    };

    switch (statusCode) {
      case ApiConstants.badRequestCode: // 400
        return ValidationException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.unauthorizedCode: // 401
        return UnauthorizedException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.forbiddenCode: // 403
        return ForbiddenException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.notFoundCode: // 404
        return NotFoundException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.methodNotAllowedCode: // 405
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.conflictCode: // 409
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.validationErrorCode: // 422
        return ValidationException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.tooManyRequestsCode: // 429
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      case ApiConstants.serverErrorCode: // 500
      case ApiConstants.notImplementedCode: // 501
      case ApiConstants.badGatewayCode: // 502
      case ApiConstants.serviceUnavailableCode: // 503
      case ApiConstants.gatewayTimeoutCode: // 504
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
        
      default:
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// Parse validation errors from API response
  static Map<String, List<String>> _parseValidationErrors(Map<String, dynamic> errors) {
    final Map<String, List<String>> validationErrors = {};
    
    errors.forEach((field, fieldErrors) {
      if (fieldErrors is List) {
        validationErrors[field] = fieldErrors.cast<String>();
      } else if (fieldErrors is String) {
        validationErrors[field] = [fieldErrors];
      } else {
        validationErrors[field] = [fieldErrors.toString()];
      }
    });
    
    return validationErrors;
  }

  /// Safely execute HTTP operation with error handling
  static Future<http.Response> safeHttpCall(
    Future<http.Response> Function() httpCall,
    String operation,
  ) async {
    try {
      final response = await httpCall();
      handleHttpResponse(response, operation);
      return response;
    } catch (e) {
      if (e is AppException) rethrow;
      throw handleHttpException(e, operation);
    }
  }

  /// Safely execute repository operation with error handling
  static Future<T> safeRepositoryCall<T>(
    Future<T> Function() repositoryCall,
    String operation,
  ) async {
    try {
      return await repositoryCall();
    } catch (e) {
      throw handleRepositoryError(e, operation);
    }
  }

  /// Get retry delay using AppConstants with exponential backoff
  static int getRetryDelay(int attemptNumber) {
    return AppConstants.getRetryDelay(attemptNumber);
  }

  /// Check if should retry based on AppConstants and error type
  static bool shouldRetry(int attemptNumber, AppException exception) {
    if (attemptNumber >= AppConstants.maxRetryAttempts) return false;
    
    // Check if error type is retryable
    if (exception is NetworkException || 
        exception is TimeoutException) {
      return true;
    }
    
    // Check if status code is retryable
    if (exception.statusCode != null) {
      return ApiConstants.isRetryableStatusCode(exception.statusCode!);
    }
    
    // Don't retry validation or authentication errors
    if (exception is ValidationException || 
        exception is AuthException ||
        exception is UnauthorizedException ||
        exception is ForbiddenException) {
      return false;
    }
    
    // Retry server exceptions
    return exception is ServerException;
  }

  /// Check if error indicates network connectivity issues
  static bool isNetworkError(dynamic error) {
    if (error is NetworkException) return true;
    if (error is SocketException) return true;
    if (error is HttpException) return true;
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('connection') ||
           errorString.contains('network') ||
           errorString.contains('internet') ||
           errorString.contains('socket');
  }

  /// Check if error indicates authentication issues
  static bool isAuthenticationError(dynamic error) {
    if (error is UnauthorizedException) return true;
    if (error is ForbiddenException) return true;
    if (error is AuthException) return true;
    
    if (error is AppException && error.statusCode != null) {
      return ApiConstants.requiresAuthentication(error.statusCode!);
    }
    
    final errorString = error.toString().toLowerCase();
    return errorString.contains('unauthorized') ||
           errorString.contains('forbidden') ||
           errorString.contains('authentication') ||
           errorString.contains('token') ||
           errorString.contains('session');
  }

  /// Check if error indicates validation issues
  static bool isValidationError(dynamic error) {
    if (error is ValidationException) return true;
    
    if (error is AppException && error.statusCode != null) {
      final statusCode = error.statusCode!;
      return statusCode == ApiConstants.badRequestCode ||
             statusCode == ApiConstants.validationErrorCode;
    }
    
    return false;
  }

  /// Get error category for better error handling
  static String getErrorCategory(dynamic error) {
    if (isNetworkError(error)) return 'Network';
    if (isAuthenticationError(error)) return 'Authentication';
    if (isValidationError(error)) return 'Validation';
    if (error is TimeoutException) return 'Timeout';
    if (error is ServerException) return 'Server';
    if (error is CacheException) return 'Cache';
    return 'Unknown';
  }

  /// Get user-friendly error message using constants
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    
    if (error is ApiErrorModel) {
      return error.message.isNotEmpty 
          ? error.message 
          : AppConstants.getErrorMessageForStatusCode(error.statusCode ?? 500);
    }
    
    if (isNetworkError(error)) {
      return AppConstants.networkErrorMessage;
    }
    
    if (isAuthenticationError(error)) {
      return AppConstants.unauthorizedMessage;
    }
    
    return AppConstants.unknownErrorMessage;
  }

  /// Check if error should trigger offline mode
  static bool shouldTriggerOfflineMode(dynamic error) {
    if (isNetworkError(error)) return true;
    
    if (error is AppException && error.statusCode != null) {
      // Server errors might indicate service unavailability
      return ApiConstants.isServerError(error.statusCode!);
    }
    
    return false;
  }

  /// Check if error should logout user
  static bool shouldLogoutUser(dynamic error) {
    return isAuthenticationError(error);
  }

  /// Extract error message from response body
  static String extractErrorMessage(String responseBody, int statusCode) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        // Try different common error message keys
        final messageKeys = [
          ApiConstants.messageKey,
          'error',
          'error_description',
          'detail',
          'title',
        ];
        
        for (final key in messageKeys) {
          if (decoded.containsKey(key) && decoded[key] is String) {
            final message = decoded[key] as String;
            if (message.isNotEmpty) {
              return message;
            }
          }
        }
        
        // Check for errors array
        if (decoded.containsKey(ApiConstants.errorsKey)) {
          final errors = decoded[ApiConstants.errorsKey];
          if (errors is List && errors.isNotEmpty) {
            return errors.first.toString();
          }
          if (errors is Map) {
            final firstError = errors.values.first;
            if (firstError is List && firstError.isNotEmpty) {
              return firstError.first.toString();
            }
            return firstError.toString();
          }
        }
      }
      
      if (decoded is String && decoded.isNotEmpty) {
        return decoded;
      }
    } catch (e) {
      log('[$_logTag] Error parsing response body: $e');
    }
    
    return AppConstants.getErrorMessageForStatusCode(statusCode);
  }
}