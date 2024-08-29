class ApiConstants {
  static const String baseUrl = 'https://api.example.com';
  static const String apiKey = 'YOUR_API_KEY_HERE';
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
