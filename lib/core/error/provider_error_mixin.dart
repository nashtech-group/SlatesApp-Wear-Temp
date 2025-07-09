import 'dart:developer';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'data_layer_error_handler.dart';

/// Mixin for providers to provide standardized HTTP error handling
mixin ProviderErrorMixin {
  
  /// Safely execute HTTP operation with comprehensive error handling
  Future<http.Response> safeHttpCall(
    Future<http.Response> Function() httpCall,
    String operation,
  ) async {
    return await DataLayerErrorHandler.safeHttpCall(httpCall, operation);
  }

  /// Execute HTTP call with automatic timeout using ApiConstants
  Future<http.Response> safeHttpCallWithTimeout(
    Future<http.Response> Function() httpCall,
    String operation, {
    Duration? customTimeout,
  }) async {
    final timeout = customTimeout ?? const Duration(seconds: ApiConstants.timeoutDuration);
    
    return await safeHttpCall(
      () => httpCall().timeout(timeout),
      operation,
    );
  }

  /// Execute HTTP call with retry logic using AppConstants
  Future<http.Response> safeHttpCallWithRetry(
    Future<http.Response> Function() httpCall,
    String operation, {
    Duration? customTimeout,
    int? maxAttempts,
  }) async {
    final attempts = maxAttempts ?? AppConstants.maxRetryAttempts;
    Exception? lastException;
    
    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        return await safeHttpCallWithTimeout(httpCall, operation, customTimeout: customTimeout);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        // Check if we should retry based on error type
        if (attempt < attempts && _shouldRetryHttpError(e)) {
          final delay = DataLayerErrorHandler.getRetryDelay(attempt);
          log('HTTP operation $operation failed (attempt $attempt), retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          break;
        }
      }
    }
    
    throw lastException ?? Exception(AppConstants.unknownErrorMessage);
  }

  /// Check if HTTP error should be retried
  bool _shouldRetryHttpError(dynamic error) {
    // Use DataLayerErrorHandler for consistency
    return DataLayerErrorHandler.isNetworkError(error) ||
           error.toString().toLowerCase().contains('timeout') ||
           error.toString().toLowerCase().contains('connection');
  }

  /// Execute HTTP call with smart retry based on response status
  Future<http.Response> safeHttpCallWithSmartRetry(
    Future<http.Response> Function() httpCall,
    String operation, {
    Duration? customTimeout,
    int? maxAttempts,
  }) async {
    final attempts = maxAttempts ?? AppConstants.maxRetryAttempts;
    http.Response? lastResponse;
    Exception? lastException;
    
    for (int attempt = 1; attempt <= attempts; attempt++) {
      try {
        final response = await safeHttpCallWithTimeout(httpCall, operation, customTimeout: customTimeout);
        
        // Check if response indicates we should retry
        if (attempt < attempts && _shouldRetryResponse(response)) {
          lastResponse = response;
          final delay = _getRetryDelayForResponse(response, attempt);
          log('HTTP operation $operation returned ${response.statusCode} (attempt $attempt), retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
          continue;
        }
        
        return response;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < attempts && _shouldRetryHttpError(e)) {
          final delay = DataLayerErrorHandler.getRetryDelay(attempt);
          log('HTTP operation $operation failed (attempt $attempt), retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        } else {
          break;
        }
      }
    }
    
    // If we have a response (even error), return it for proper error handling
    if (lastResponse != null) {
      return lastResponse;
    }
    
    throw lastException ?? Exception(AppConstants.unknownErrorMessage);
  }

  /// Check if HTTP response should trigger a retry
  bool _shouldRetryResponse(http.Response response) {
    return ApiConstants.isRetryableStatusCode(response.statusCode);
  }

  /// Get retry delay based on response status code
  int _getRetryDelayForResponse(http.Response response, int attempt) {
    // Use longer delay for rate limiting
    if (response.statusCode == ApiConstants.tooManyRequestsCode) {
      return AppConstants.baseRetryDelayMs * (1 << attempt); // Exponential backoff for rate limiting
    }
    
    return DataLayerErrorHandler.getRetryDelay(attempt);
  }

  /// Extract response body safely with error handling
  String extractResponseBody(http.Response response, String operation) {
    try {
      DataLayerErrorHandler.handleHttpResponse(response, operation);
      return response.body;
    } catch (e) {
      log('Error extracting response body for $operation: $e');
      rethrow;
    }
  }

  /// Build standard headers using ApiConstants
  Map<String, String> buildStandardHeaders({String? token}) {
    final headers = <String, String>{
      ApiConstants.acceptHeader: ApiConstants.jsonContentType,
    };
    
    if (token != null) {
      headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
    }
    
    return headers;
  }

  /// Build POST/PATCH headers using ApiConstants
  Map<String, String> buildPostHeaders({String? token}) {
    final headers = buildStandardHeaders(token: token);
    headers[ApiConstants.contentTypeHeader] = ApiConstants.jsonContentType;
    return headers;
  }

  /// Build multipart headers for file uploads
  Map<String, String> buildMultipartHeaders({String? token}) {
    final headers = <String, String>{
      ApiConstants.acceptHeader: ApiConstants.jsonContentType,
    };
    
    if (token != null) {
      headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
    }
    
    // Note: Don't set Content-Type for multipart, let http package handle it
    return headers;
  }

  /// Log HTTP request details for debugging (security-aware)
  void logHttpRequest(String method, String url, Map<String, String>? headers) {
    log('HTTP $method: $url');
    if (headers != null) {
      // Log headers but mask sensitive information
      final safeHeaders = <String, String>{};
      headers.forEach((key, value) {
        if (key.toLowerCase() == ApiConstants.authorizationHeader.toLowerCase()) {
          safeHeaders[key] = '${ApiConstants.bearerPrefix}***';
        } else {
          safeHeaders[key] = value;
        }
      });
      log('Headers: ${safeHeaders.keys.join(', ')}');
    }
  }

  /// Log HTTP response details for debugging
  void logHttpResponse(http.Response response, String operation) {
    log('HTTP Response for $operation: ${response.statusCode}');
    if (!ApiConstants.isSuccessStatusCode(response.statusCode)) {
      log('Error response body: ${response.body}');
    }
  }

  /// Check if response indicates success using ApiConstants
  bool isSuccessResponse(http.Response response) {
    return ApiConstants.isSuccessStatusCode(response.statusCode);
  }

  /// Check if response indicates client error using ApiConstants
  bool isClientError(http.Response response) {
    return ApiConstants.isClientError(response.statusCode);
  }

  /// Check if response indicates server error using ApiConstants
  bool isServerError(http.Response response) {
    return ApiConstants.isServerError(response.statusCode);
  }

  /// Check if response requires authentication
  bool requiresAuthentication(http.Response response) {
    return ApiConstants.requiresAuthentication(response.statusCode);
  }

  /// Get appropriate timeout for operation type using AppConstants
  Duration getTimeoutForOperation(String operationType) {
    switch (operationType.toLowerCase()) {
      case 'upload':
        return const Duration(seconds: AppConstants.uploadTimeoutSeconds);
      case 'download':
        return const Duration(seconds: AppConstants.downloadTimeoutSeconds);
      case 'api':
        return const Duration(seconds: AppConstants.apiTimeoutSeconds);
      default:
        return const Duration(seconds: ApiConstants.timeoutDuration);
    }
  }

  /// Get error category from HTTP response
  String getErrorCategoryFromResponse(http.Response response) {
    if (isClientError(response)) {
      if (requiresAuthentication(response)) {
        return 'Authentication';
      }
      return 'Client Error';
    } else if (isServerError(response)) {
      return 'Server Error';
    }
    return 'Unknown';
  }

  /// Get user-friendly message from HTTP response
  String getUserFriendlyMessageFromResponse(http.Response response) {
    return DataLayerErrorHandler.extractErrorMessage(response.body, response.statusCode);
  }

  /// Check if response indicates rate limiting
  bool isRateLimited(http.Response response) {
    return response.statusCode == ApiConstants.tooManyRequestsCode;
  }

  /// Check if response is retryable
  bool isRetryableResponse(http.Response response) {
    return ApiConstants.isRetryableStatusCode(response.statusCode);
  }

  /// Execute HTTP operation with comprehensive error handling and logging
  Future<http.Response> executeHttpOperation(
    Future<http.Response> Function() httpCall,
    String method,
    String url,
    String operation, {
    Map<String, String>? headers,
    Duration? timeout,
    bool enableRetry = true,
    int? maxAttempts,
  }) async {
    // Log request
    logHttpRequest(method, url, headers);
    
    try {
      http.Response response;
      
      if (enableRetry) {
        response = await safeHttpCallWithSmartRetry(
          httpCall,
          operation,
          customTimeout: timeout,
          maxAttempts: maxAttempts,
        );
      } else {
        response = await safeHttpCallWithTimeout(
          httpCall,
          operation,
          customTimeout: timeout,
        );
      }
      
      // Log response
      logHttpResponse(response, operation);
      
      return response;
    } catch (e) {
      log('HTTP operation $operation failed: $e');
      rethrow;
    }
  }
}