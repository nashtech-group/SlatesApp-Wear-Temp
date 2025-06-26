// lib/core/constants/api_constants.dart
class ApiConstants {
  static const String baseUrl = 'http://api.slatesapp.slatestech.com/api/v1';
  static const String contentType = 'application/json';
  static const int timeoutDuration = 30; // in seconds
  
  // Auth endpoints
  static const String loginEndpoint = '/login';
  static const String logoutEndpoint = '/logout';
  static const String refreshEndpoint = '/refresh';
  static const String userProfileEndpoint = '/user/profile';
  
  // Guard duty endpoints
  static const String comprehensiveGuardDutyEndpoint = '/roster/comprehensive-guard-duty';
  static const String rosterEndpoint = '/roster';
  static const String movementsEndpoint = '/movements';
  static const String perimeterChecksEndpoint = '/perimeter-checks';
  
  // HTTP Headers
  static const String acceptHeader = 'Accept';
  static const String contentTypeHeader = 'Content-Type';
  static const String authorizationHeader = 'Authorization';
  static const String bearerPrefix = 'Bearer ';
  
  // HTTP Status Codes
  static const int successCode = 200;
  static const int createdCode = 201;
  static const int unauthorizedCode = 401;
  static const int forbiddenCode = 403;
  static const int notFoundCode = 404;
  static const int validationErrorCode = 422;
  static const int serverErrorCode = 500;
  
  // API Response Keys
  static const String statusKey = 'status';
  static const String messageKey = 'message';
  static const String dataKey = 'data';
  static const String errorsKey = 'errors';
  static const String userKey = 'user';
  static const String accessTokenKey = 'accessToken';
  static const String tokenTypeKey = 'tokenType';
  static const String expiresInKey = 'expiresIn';
  
  // API Status Values
  static const String successStatus = 'success';
  static const String errorStatus = 'error';
  static const String failStatus = 'fail';
}


