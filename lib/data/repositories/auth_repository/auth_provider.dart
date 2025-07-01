import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';

class AuthProvider {
  final http.Client client;

  AuthProvider({http.Client? client}) : client = client ?? http.Client();

  Future<String> login(LoginModel loginModel) async {
    try {
      final response = await client
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: {
              ApiConstants.acceptHeader: ApiConstants.contentType,
              ApiConstants.contentTypeHeader: ApiConstants.contentType,
            },
            body: jsonEncode(loginModel.toJson()),
          )
          .timeout(
            const Duration(seconds: ApiConstants.timeoutDuration),
          );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<String> logout(String token) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.logoutEndpoint}'),
        headers: {
          ApiConstants.acceptHeader: ApiConstants.contentType,
          ApiConstants.authorizationHeader:
              '${ApiConstants.bearerPrefix}$token',
        },
      ).timeout(
        const Duration(seconds: ApiConstants.timeoutDuration),
      );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  Future<String> refreshToken(String token) async {
    try {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.refreshEndpoint}'),
        headers: {
          ApiConstants.acceptHeader: ApiConstants.contentType,
          ApiConstants.contentTypeHeader: ApiConstants.contentType,
          ApiConstants.authorizationHeader:
              '${ApiConstants.bearerPrefix}$token',
        },
      ).timeout(
        const Duration(seconds: ApiConstants.timeoutDuration),
      );

      return response.body;
    } on SocketException {
      throw Exception('No internet connection');
    } on HttpException {
      throw Exception('Network error occurred');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }
}
