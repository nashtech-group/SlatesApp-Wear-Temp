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
    bool shouldRethrow = true,
  }) {
    final handledException = DataLayerErrorHandler.handleRepositoryError(error, operation);
    
    log('Repository error in $operation: ${handledException.message}');
    
    if (fallbackValue != null && !shouldRethrow) {
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

  /// Check if error should trigger offline mode
  bool shouldTriggerOfflineMode(dynamic error) {
    return DataLayerErrorHandler.shouldTriggerOfflineMode(error);
  }

  /// Check if error should logout user
  bool shouldLogoutUser(dynamic error) {
    return DataLayerErrorHandler.shouldLogoutUser(error);
  }

  /// Get user-friendly error message using DataLayerErrorHandler
  String getUserFriendlyMessage(dynamic error) {
    return DataLayerErrorHandler.getUserFriendlyMessage(error);
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
           (error is ServerException && error.statusCode != null && 
            ApiConstants.isServerError(error.statusCode!));
  }

  /// Check if error is retryable based on status code
  bool isRetryableError(dynamic error) {
    if (DataLayerErrorHandler.isNetworkError(error)) return true;
    if (error is TimeoutException) return true;
    
    int? statusCode;
    if (error is AppException) {
      statusCode = error.statusCode;
    } else if (error is ApiErrorModel) {
      statusCode = error.statusCode;
    }
    
    if (statusCode == null) return false;
    
    // Use ApiConstants to check if retryable
    return ApiConstants.isRetryableStatusCode(statusCode);
  }

  /// Get retry delay based on error type and attempt number
  int getRetryDelay(int attempt, dynamic error) {
    // Use exponential backoff for rate limiting
    if (error is ApiErrorModel && error.statusCode == ApiConstants.tooManyRequestsCode) {
      return AppConstants.baseRetryDelayMs * (1 << attempt); // Fixed bit shift operation
    }
    
    if (error is AppException && error.statusCode == ApiConstants.tooManyRequestsCode) {
      return AppConstants.baseRetryDelayMs * (1 << attempt); // Fixed bit shift operation
    }
    
    // Standard retry delay for other errors
    return DataLayerErrorHandler.getRetryDelay(attempt);
  }

  /// Get error category for better handling
  String getErrorCategory(dynamic error) {
    return DataLayerErrorHandler.getErrorCategory(error);
  }

  /// Check if error is network-related
  bool isNetworkError(dynamic error) {
    return DataLayerErrorHandler.isNetworkError(error);
  }

  /// Check if error is authentication-related
  bool isAuthenticationError(dynamic error) {
    return DataLayerErrorHandler.isAuthenticationError(error);
  }

  /// Check if error is validation-related
  bool isValidationError(dynamic error) {
    return DataLayerErrorHandler.isValidationError(error);
  }

  /// Execute operation with fallback data from cache
  Future<T> executeWithCacheFallback<T>(
    Future<T> Function() operation,
    Future<T> Function() getCachedData,
    String operationName,
  ) async {
    try {
      return await safeRepositoryCall(operation, operationName);
    } catch (e) {
      if (shouldUseCachedData(e)) {
        log('Using cached data for $operationName due to error: ${getUserFriendlyMessage(e)}');
        return await getCachedData();
      }
      rethrow;
    }
  }

  /// Execute operation with smart retry and caching
  Future<T> executeWithSmartRetry<T>(
    Future<T> Function() operation,
    String operationName, {
    T? fallbackValue,
    Future<T> Function()? getCachedData,
    int? maxAttempts,
  }) async {
    final attempts = maxAttempts ?? AppConstants.maxRetryAttempts;
    AppException? lastException;
    
    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await safeRepositoryCall(operation, operationName);
      } catch (e) {
        if (e is AppException) {
          lastException = e;
          
          // Check if we should use cached data immediately for certain errors
          if (shouldUseCachedData(e) && getCachedData != null) {
            log('Using cached data for $operationName due to error: ${e.message}');
            return await getCachedData();
          }
          
          // Check if we should retry
          if (!DataLayerErrorHandler.shouldRetry(attempt, e) || attempt >= attempts) {
            break;
          }
          
          final delay = getRetryDelay(attempt, e);
          log('Repository operation $operationName failed (attempt $attempt), retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          throw handleRepositoryError(e, operationName);
        }
      }
    }
    
    // Try cached data if available
    if (getCachedData != null && shouldUseCachedData(lastException!)) {
      log('Using cached data for $operationName after retry exhaustion');
      return await getCachedData();
    }
    
    // Use fallback value if available
    if (fallbackValue != null) {
      log('Repository operation $operationName failed after $attempts attempts, using fallback');
      return fallbackValue;
    }
    
    throw lastException ?? ServerException(
      message: AppConstants.unknownErrorMessage,
      data: {'operation': operationName},
    );
  }
}