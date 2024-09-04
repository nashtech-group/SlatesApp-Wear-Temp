import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/utils/logger.dart';
import 'dart:convert';
import '../../core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../../core/errors/exceptions.dart';

class UserProvider {
  final http.Client client;

  UserProvider({required this.client});

  Future<User> getUser(String employeeId) async {
    final response = await client.get(
      Uri.parse('${ApiConstants.baseUrl}/v1/user/$employeeId'),
      headers: {'Accept': ApiConstants.contentType},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw ServerException(message: 'Failed to load user data.');
    }
  }

  Future<User> loginUser(String employeeId, String password) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/v1/login'),
      headers: {
        'Accept': ApiConstants.contentType,
        'Content-Type': ApiConstants.contentType
      },
      body: json.encode(
          {'identifier': employeeId.trim(), 'password': password.trim()}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw ServerException(message: 'Failed to login.');
    }
  }

  Future<void> logoutUser() async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/v1/logout'),
      headers: {'Accept': ApiConstants.contentType},
    );

    if (response.statusCode != 200) {
      throw ServerException(message: 'Failed to logout.');
    }
  }
}
