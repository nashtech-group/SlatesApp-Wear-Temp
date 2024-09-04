class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';
  static const String apiKey = '';
  static const String contentType = 'application/json';
  static const int timeoutDuration = 30; // in seconds

  // Endpoints
  static const String loginEndpoint = '/auth/login';
  static const String userEndpoint = '/user/profile';
  static const String customersEndpoint = '/posts';

  // Query Parameters
  static const String page = 'page';
  static const String limit = '15';
}
