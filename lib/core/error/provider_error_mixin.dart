import 'dart:developer';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';
import 'data_layer_error_handler.dart';

/// Mixin for providers to provide standardized HTTP error handling
mixin ProviderErrorMixin {
  
  /// Safely execute HTTP operation with comprehensive error handling using ApiConstants timeout
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
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= AppConstants.maxRetryAttempts; attempt++) {
      try {
        return await safeHttpCallWithTimeout(httpCall, operation, customTimeout: customTimeout);
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        
        if (attempt < AppConstants.maxRetryAttempts) {
          final delay = DataLayerErrorHandler.getRetryDelay(attempt);
          log('HTTP operation $operation failed (attempt $attempt), retrying in ${delay}ms');
          await Future.delayed(Duration(milliseconds: delay));
        }
      }
    }
    
    throw lastException ?? Exception(AppConstants.unknownErrorMessage);
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
      ApiConstants.acceptHeader: ApiConstants.contentType,
    };
    
    if (token != null) {
      headers[ApiConstants.authorizationHeader] = '${ApiConstants.bearerPrefix}$token';
    }
    
    return headers;
  }

  /// Build POST/PATCH headers using ApiConstants
  Map<String, String> buildPostHeaders({String? token}) {
    final headers = buildStandardHeaders(token: token);
    headers[ApiConstants.contentTypeHeader] = ApiConstants.contentType;
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
    if (response.statusCode >= ApiConstants.validationErrorCode) {
      log('Error response body: ${response.body}');
    }
  }

  /// Check if response indicates success using ApiConstants
  bool isSuccessResponse(http.Response response) {
    return response.statusCode >= ApiConstants.successCode && 
           response.statusCode < ApiConstants.successCode + 100;
  }

  /// Check if response indicates client error using ApiConstants
  bool isClientError(http.Response response) {
    return response.statusCode >= ApiConstants.validationErrorCode && 
           response.statusCode < ApiConstants.serverErrorCode;
  }

  /// Check if response indicates server error using ApiConstants
  bool isServerError(http.Response response) {
    return response.statusCode >= ApiConstants.serverErrorCode;
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
}