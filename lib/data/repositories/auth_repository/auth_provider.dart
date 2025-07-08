import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/error/provider_error_mixin.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';

class AuthProvider with ProviderErrorMixin {
  final http.Client client;

  AuthProvider({http.Client? client}) : client = client ?? http.Client();

  Future<String> login(LoginModel loginModel) async {
    const operation = 'login';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}');
    final headers = buildPostHeaders();
    
    logHttpRequest('POST', uri.toString(), headers);

    final response = await safeHttpCallWithTimeout(
      () => client.post(
        uri,
        headers: headers,
        body: jsonEncode(loginModel.toJson()),
      ),
      operation,
      customTimeout: getTimeoutForOperation('api'),
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  Future<String> logout(String token) async {
    const operation = 'logout';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}');
    final headers = buildStandardHeaders(token: token);
    
    logHttpRequest('POST', uri.toString(), headers);

    final response = await safeHttpCallWithTimeout(
      () => client.post(uri, headers: headers),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }

  Future<String> refreshToken(String token) async {
    const operation = 'refreshToken';
    
    final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}');
    final headers = buildPostHeaders(token: token);
    
    logHttpRequest('POST', uri.toString(), headers);

    final response = await safeHttpCallWithTimeout(
      () => client.post(uri, headers: headers),
      operation,
    );

    logHttpResponse(response, operation);
    return extractResponseBody(response, operation);
  }
}