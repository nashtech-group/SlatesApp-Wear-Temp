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
    if (response.statusCode >= ApiConstants.successCode && 
        response.statusCode < ApiConstants.successCode + 100) {
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

    // Handle by status code using ApiConstants
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
        message: 'Invalid response format received from server.',
        statusCode: null,
        data: {'operation': operation, 'type': 'format_exception'},
      );
    }

    if (error is TimeoutException) {
      return NetworkException(
        message: 'Request timed out. Please check your connection and try again.',
        statusCode: 408,
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
    if (error.toString().toLowerCase().contains('no internet connection') ||
        error.toString().toLowerCase().contains('network')) {
      return NetworkException(
        message: AppConstants.networkErrorMessage,
        data: {'operation': operation},
      );
    }

    if (error.toString().toLowerCase().contains('authentication') ||
        error.toString().toLowerCase().contains('unauthorized')) {
      return AuthException(
        message: AppConstants.unauthorizedMessage,
        statusCode: ApiConstants.unauthorizedCode,
        data: {'operation': operation},
      );
    }

    return ServerException(
      message: AppConstants.unknownErrorMessage,
      data: {'operation': operation},
    );
  }

  /// Convert ApiErrorModel to appropriate AppException using existing constants
  static AppException _convertApiErrorToException(ApiErrorModel apiError) {
    switch (apiError.statusCode) {
      case ApiConstants.validationErrorCode: // 400 or 422
        return ValidationException(
          message: apiError.message.isNotEmpty ? apiError.message : AppConstants.validationErrorMessage,
          statusCode: apiError.statusCode,
          validationErrors: apiError.hasValidationErrors 
              ? _parseValidationErrors(apiError.errors!) 
              : null,
        );
      case ApiConstants.unauthorizedCode: // 401
        return UnauthorizedException(
          message: apiError.message.isNotEmpty ? apiError.message : AppConstants.unauthorizedMessage,
          statusCode: apiError.statusCode,
        );
      case ApiConstants.forbiddenCode: // 403
        return ForbiddenException(
          message: apiError.message.isNotEmpty ? apiError.message : AppConstants.unauthorizedMessage,
          statusCode: apiError.statusCode,
        );
      case ApiConstants.notFoundCode: // 404
        return NotFoundException(
          message: apiError.message.isNotEmpty ? apiError.message : 'Resource not found',
          statusCode: apiError.statusCode,
        );
      case 429: // Rate limiting
        return ServerException(
          message: 'Too many requests. Please wait a moment and try again.',
          statusCode: apiError.statusCode,
        );
      case ApiConstants.serverErrorCode: // 500
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: AppConstants.serverErrorMessage,
          statusCode: apiError.statusCode,
        );
      default:
        if (apiError.message.toLowerCase().contains('network') ||
            apiError.message.toLowerCase().contains('connection')) {
          return NetworkException(
            message: AppConstants.networkErrorMessage,
            statusCode: apiError.statusCode,
          );
        }
        return ServerException(
          message: apiError.message.isNotEmpty ? apiError.message : AppConstants.serverErrorMessage,
          statusCode: apiError.statusCode,
        );
    }
  }

  /// Create exception from HTTP status code using ApiConstants
  static AppException _createExceptionFromStatusCode(
    int statusCode,
    String responseBody,
    String operation,
  ) {
    switch (statusCode) {
      case ApiConstants.validationErrorCode: // 422
        return ValidationException(
          message: AppConstants.validationErrorMessage,
          statusCode: statusCode,
        );
      case ApiConstants.unauthorizedCode: // 401
        return UnauthorizedException(
          message: AppConstants.unauthorizedMessage,
          statusCode: statusCode,
        );
      case ApiConstants.forbiddenCode: // 403
        return ForbiddenException(
          message: AppConstants.unauthorizedMessage,
          statusCode: statusCode,
        );
      case ApiConstants.notFoundCode: // 404
        return NotFoundException(
          message: 'Resource not found',
          statusCode: statusCode,
        );
      case 429:
        return ServerException(
          message: 'Too many requests. Please wait and try again.',
          statusCode: statusCode,
        );
      case ApiConstants.serverErrorCode: // 500
      case 502:
      case 503:
      case 504:
        return ServerException(
          message: AppConstants.serverErrorMessage,
          statusCode: statusCode,
        );
      default:
        return ServerException(
          message: AppConstants.unknownErrorMessage,
          statusCode: statusCode,
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
      }
    });
    
    return validationErrors;
  }

  /// Safely execute HTTP operation with error handling using ApiConstants timeout
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

  /// Get retry delay using AppConstants
  static int getRetryDelay(int attemptNumber) {
    return (1000 * attemptNumber * 2).clamp(1000, AppConstants.networkTimeoutSeconds * 1000);
  }

  /// Check if should retry based on AppConstants
  static bool shouldRetry(int attemptNumber, AppException exception) {
    if (attemptNumber >= AppConstants.maxRetryAttempts) return false;
    
    // Retry for network and server errors
    return exception is NetworkException || 
           exception is ServerException ||
           exception is TimeoutException;
  }
}