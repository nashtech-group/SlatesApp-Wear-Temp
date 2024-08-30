import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final http.Client client;

  UserRepositoryImpl({required this.client});

  @override
  Future<User> getUser(String employeeId) async {
    final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/v1/user/$employeeId'),
        headers: {'Accept': ApiConstants.contentType});

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load user');
    }
  }

  @override
  Future<void> loginUser(String employeeId, String password) async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/v1/login'),
      headers: {'Accept': ApiConstants.contentType},
      body: json.encode({
        'identifier': employeeId,
        'password': password,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to login');
    }
  }

  @override
  Future<void> logoutUser() async {
    final response = await client.post(
      Uri.parse('${ApiConstants.baseUrl}/v1/logout'),
      headers: {'Accept': ApiConstants.contentType},
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to logout');
    }
  }
}
