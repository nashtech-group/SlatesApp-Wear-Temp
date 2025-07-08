class ApiConstants {
  // ====================
  // BASE CONFIGURATION
  // ====================
  static const String baseUrl = 'http://api.slatesapp.slatestech.com/api/v1';
  static const String contentType = 'application/json';
  static const int timeoutDuration = 30; // in seconds
  
  // ====================
  // AUTH ENDPOINTS
  // ====================
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  static const String refreshEndpoint = '/refresh';
  static const String userProfileEndpoint = '/user/profile';
  
  // ====================
  // GUARD DUTY ENDPOINTS
  // ====================
  static const String comprehensiveGuardDutyEndpoint = '/roster/comprehensive-guard-duty';
  static const String rosterEndpoint = '/roster';
  static const String movementsEndpoint = '/movements';
  static const String perimeterChecksEndpoint = '/perimeter-checks';
  
  // ====================
  // HTTP HEADERS
  // ====================
  static const String acceptHeader = 'Accept';
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String userAgentHeader = 'User-Agent';
  static const String xRequestedWithHeader = 'X-Requested-With';
  static const String bearerPrefix = 'Bearer ';
  static const String basicPrefix = 'Basic ';
  
  // ====================
  // HTTP STATUS CODES - SUCCESS
  // ====================
  static const int successCode = 200; // OK
  static const int createdCode = 201; // Created
  static const int acceptedCode = 202; // Accepted
  static const int noContentCode = 204; // No Content
  
  // ====================
  // HTTP STATUS CODES - CLIENT ERRORS
  // ====================
  static const int badRequestCode = 400; // Bad Request
  static const int unauthorizedCode = 401; // Unauthorized
  static const int forbiddenCode = 403; // Forbidden
  static const int notFoundCode = 404; // Not Found
  static const int methodNotAllowedCode = 405; // Method Not Allowed
  static const int conflictCode = 409; // Conflict
  static const int validationErrorCode = 422; // Unprocessable Entity
  static const int tooManyRequestsCode = 429; // Too Many Requests
  
  // ====================
  // HTTP STATUS CODES - SERVER ERRORS
  // ====================
  static const int serverErrorCode = 500; // Internal Server Error
  static const int notImplementedCode = 501; // Not Implemented
  static const int badGatewayCode = 502; // Bad Gateway
  static const int serviceUnavailableCode = 503; // Service Unavailable
  static const int gatewayTimeoutCode = 504; // Gateway Timeout
  
  // ====================
  // API RESPONSE KEYS
  // ====================
  static const String statusKey = 'status';
  static const String messageKey = 'message';
  static const String dataKey = 'data';
  static const String errorsKey = 'errors';
  static const String userKey = 'user';
  static const String accessTokenKey = 'accessToken';
  static const String refreshTokenKey = 'refreshToken';
  static const String tokenTypeKey = 'tokenType';
  static const String expiresInKey = 'expiresIn';
  static const String timestampKey = 'timestamp';
  static const String requestIdKey = 'requestId';
  
  // ====================
  // API STATUS VALUES
  // ====================
  static const String successStatus = 'success';
  static const String errorStatus = 'error';
  static const String failStatus = 'fail';
  static const String warningStatus = 'warning';
  
  // ====================
  // CONTENT TYPES
  // ====================
  static const String jsonContentType = 'application/json';
  static const String formContentType = 'application/x-www-form-urlencoded';
  static const String multipartContentType = 'multipart/form-data';
  static const String textContentType = 'text/plain';
  
  // ====================
  // RETRY CONFIGURATION
  // ====================
  static const List<int> retryableStatusCodes = [
    tooManyRequestsCode,
    serverErrorCode,
    badGatewayCode,
    serviceUnavailableCode,
    gatewayTimeoutCode,
  ];
  
  static const List<int> authenticationStatusCodes = [
    unauthorizedCode,
    forbiddenCode,
  ];
  
  static const List<int> clientErrorStatusCodes = [
    badRequestCode,
    unauthorizedCode,
    forbiddenCode,
    notFoundCode,
    methodNotAllowedCode,
    conflictCode,
    validationErrorCode,
    tooManyRequestsCode,
  ];
  
  static const List<int> serverErrorStatusCodes = [
    serverErrorCode,
    notImplementedCode,
    badGatewayCode,
    serviceUnavailableCode,
    gatewayTimeoutCode,
  ];
  
  // ====================
  // HELPER METHODS
  // ====================
  
  /// Check if status code indicates success
  static bool isSuccessStatusCode(int statusCode) {
    return statusCode >= 200 && statusCode < 300;
  }
  
  /// Check if status code indicates client error
  static bool isClientError(int statusCode) {
    return statusCode >= 400 && statusCode < 500;
  }
  
  /// Check if status code indicates server error
  static bool isServerError(int statusCode) {
    return statusCode >= 500 && statusCode < 600;
  }
  
  /// Check if status code is retryable
  static bool isRetryableStatusCode(int statusCode) {
    return retryableStatusCodes.contains(statusCode);
  }
  
  /// Check if status code requires authentication
  static bool requiresAuthentication(int statusCode) {
    return authenticationStatusCodes.contains(statusCode);
  }
  
  /// Get error category for status code
  static String getErrorCategory(int statusCode) {
    if (isClientError(statusCode)) {
      return 'Client Error';
    } else if (isServerError(statusCode)) {
      return 'Server Error';
    } else if (isSuccessStatusCode(statusCode)) {
      return 'Success';
    } else {
      return 'Unknown';
    }
  }
}