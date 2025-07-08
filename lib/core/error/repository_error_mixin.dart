import 'dart:developer';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'data_layer_error_handler.dart';
import 'exceptions.dart';
import '../../data/models/api_error_model.dart';

/// Mixin for repositories to provide standardized error handling
mixin RepositoryErrorMixin {
  
  /// Handle errors in repository operations using existing constants
  T handleRepositoryError<T>(
    dynamic error,
    String operation, {
    T? fallbackValue,
    bool rethrow = true,
  }) {
    final handledException = DataLayerErrorHandler.handleRepositoryError(error, operation);
    
    log('Repository error in $operation: ${handledException.message}');
    
    if (fallbackValue != null && !rethrow) {
      return fallbackValue;
    }
    
    throw handledException;
  }

  /// Safely execute repository operation with error handling
  Future<T> safeRepositoryCall<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
  }) async {
    try {
      return await DataLayerErrorHandler.safeRepositoryCall(operation, operationName);
    } catch (e) {
      if (fallbackValue != null) {
        log('Repository operation $operationName failed, using fallback: $e');
        return fallbackValue;
      }
      rethrow;
    }
  }

  /// Execute with retry logic using AppConstants
  Future<T> safeRepositoryCallWithRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
  }) async {
    AppException? lastException;
    
    for (int attempt = 1; attempt <= AppConstants.maxRetryAttempts; attempt++) {
      try {
        return await safeRepositoryCall(operation, operationName);
      } catch (e) {
        if (e is AppException) {
          lastException = e;
          
          if (!DataLayerErrorHandler.shouldRetry(attempt, e)) {
            break;
          }
          
          if (attempt < AppConstants.maxRetryAttempts) {
            final delay = DataLayerErrorHandler.getRetryDelay(attempt);
            log('Repository operation $operationName failed (attempt $attempt), retrying in ${delay}ms');
            await Future.delayed(Duration(milliseconds: delay));
          }
        } else {
          throw handleRepositoryError(e, operationName);
        }
      }
    }
    
    if (fallbackValue != null) {
      log('Repository operation $operationName failed after ${AppConstants.maxRetryAttempts} attempts, using fallback');
      return fallbackValue;
    }
    
    throw lastException ?? ServerException(
      message: AppConstants.unknownErrorMessage,
      data: {'operation': operationName},
    );
  }

  /// Check if error should trigger offline mode using existing logic
  bool shouldTriggerOfflineMode(dynamic error) {
    if (error is NetworkException) return true;
    if (error is ApiErrorModel && error.message.toLowerCase().contains('connection')) return true;
    if (error.toString().toLowerCase().contains('no internet connection')) return true;
    if (error.toString().toLowerCase().contains('network error')) return true;
    return false;
  }

  /// Check if error should logout user using ApiConstants
  bool shouldLogoutUser(dynamic error) {
    if (error is UnauthorizedException) return true;
    if (error is AuthException && error.message.toLowerCase().contains('expired')) return true;
    if (error is ApiErrorModel && error.statusCode == ApiConstants.unauthorizedCode) return true;
    return false;
  }

  /// Get user-friendly error message using AppConstants
  String getUserFriendlyMessage(dynamic error) {
    if (error is AppException) {
      return error.message;
    }
    if (error is ApiErrorModel) {
      return error.message.isNotEmpty ? error.message : _getDefaultMessageForStatusCode(error.statusCode);
    }
    return AppConstants.unknownErrorMessage;
  }

  /// Get default message for status code using existing constants
  String _getDefaultMessageForStatusCode(int? statusCode) {
    switch (statusCode) {
      case ApiConstants.unauthorizedCode:
        return AppConstants.unauthorizedMessage;
      case ApiConstants.forbiddenCode:
        return AppConstants.unauthorizedMessage;
      case ApiConstants.notFoundCode:
        return 'Resource not found';
      case ApiConstants.validationErrorCode:
        return AppConstants.validationErrorMessage;
      case ApiConstants.serverErrorCode:
        return AppConstants.serverErrorMessage;
      default:
        return AppConstants.unknownErrorMessage;
    }
  }

  /// Check if error indicates session expiry
  bool isSessionExpired(dynamic error) {
    return shouldLogoutUser(error) && 
           (error.toString().toLowerCase().contains('expired') ||
            error.toString().toLowerCase().contains('session') ||
            error.toString().toLowerCase().contains('invalid token'));
  }

  /// Check if operation should use cached data
  bool shouldUseCachedData(dynamic error) {
    return shouldTriggerOfflineMode(error) || 
           (error is ServerException && error.statusCode != null && error.statusCode! >= 500);
  }
}