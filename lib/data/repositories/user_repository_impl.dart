// data/repositories/user_repository_impl.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:slates_app_wear/core/constants/api_constants.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/utils/network_info.dart';
import '../../core/utils/secure_storage.dart';

class UserRepositoryImpl implements UserRepository {
  final http.Client client;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({required this.client, required this.networkInfo});

  @override
  Future<User> getUser(String employeeId) async {
    if (await networkInfo.isConnected) {
      final response = await client.get(
        Uri.parse('${ApiConstants.baseUrl}/v1/user/$employeeId'),
        headers: {'Accept': ApiConstants.contentType},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        User user = User.fromJson(data);
        await saveUserData(user); 
        return user;
      } else {
        throw Exception('Failed to load user');
      }
    } else {
      User? user = await loadUserData();
      if (user != null && user.employeeId == employeeId) {
        return user;
      } else {
        throw Exception('No offline data available');
      }
    }
  }

  @override
  Future<void> loginUser(String employeeId, String password) async {
    if (await networkInfo.isConnected) {
      final response = await client.post(
        Uri.parse('${ApiConstants.baseUrl}/v1/login'),
        headers: {'Accept': ApiConstants.contentType},
        body: json.encode({
          'identifier': employeeId,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        User user = User.fromJson(data);
        await saveUserData(user);  // Save user data for offline use
      } else {
        throw Exception('Failed to login');
      }
    } else {
      throw Exception('No internet connection for login');
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
     await storage.deleteAll();
  }

  @override
  Future<bool> attemptLogin(String employeeId, String password) async {
    if (await networkInfo.isConnected) {
      // Try online login
      await loginUser(employeeId, password);
      return true;
    } else {
      // Attempt offline login
      User? user = await loadUserData();
      if (user != null && user.employeeId == employeeId) {
        return true; 
      }
      return false; 
    }
  }

  @override
  Future<void> saveUserData(User user) async {
    await storage.write(key: 'user', value: jsonEncode(user.toJson()));
    await storage.write(key: 'authorization', value: jsonEncode(user.authorization.toJson()));
  }

  @override
  Future<User?> loadUserData() async {
    String? userData = await storage.read(key: 'user');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
}
