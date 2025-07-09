import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/error/provider_error_mixin.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';

class AuthProvider with ProviderErrorMixin {
  final http.Client client;

  AuthProvider({http.Client? client}) : client = client ?? http.Client();

  /// Login user with credentials
  Future<String> login(LoginModel loginModel) async {
    const operation = 'login';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    final headers = buildPostHeaders();
    
    return await executeHttpOperation(
      () => client.post(
        uri,
        headers: headers,
        body: jsonEncode(loginModel.toJson()),
      ),
      'POST',
      uri.toString(),
      operation,
      headers: headers,
      timeout: getTimeoutForOperation('api'),
      enableRetry: true,
    ).then((response) => extractResponseBody(response, operation));
  }

  /// Logout user with token
  Future<String> logout(String token) async {
    const operation = 'logout';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}');
    final headers = buildStandardHeaders(token: token);
    
    return await executeHttpOperation(
      () => client.post(uri, headers: headers),
      'POST',
      uri.toString(),
      operation,
      headers: headers,
      timeout: getTimeoutForOperation('api'),
      enableRetry: false, // Don't retry logout operations
    ).then((response) => extractResponseBody(response, operation));
  }

  /// Refresh authentication token
  Future<String> refreshToken(String token) async {
    const operation = 'refreshToken';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}');
    final headers = buildPostHeaders(token: token);
    
    return await executeHttpOperation(
      () => client.post(uri, headers: headers),
      'POST',
      uri.toString(),
      operation,
      headers: headers,
      timeout: getTimeoutForOperation('api'),
      enableRetry: true,
      maxAttempts: 2, // Limited retries for token refresh
    ).then((response) => extractResponseBody(response, operation));
  }
}