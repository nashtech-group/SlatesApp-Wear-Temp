import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../../core/utils/network_info.dart';
import '../../core/utils/secure_storage.dart';
import '../../core/errors/exceptions.dart';
import '../providers/user_provider.dart';
import '../../core/utils/logger.dart';

class UserRepositoryImpl implements UserRepository {
  final UserProvider userProvider;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({required this.userProvider, required this.networkInfo});

  @override
  Future<User> getUser(String employeeId) async {
    Logger.log('Fetching user for $employeeId');
    if (await networkInfo.isConnected) {
      try {
        final user = await userProvider.getUser(employeeId);
        await saveUserData(user);
        return user;
      } catch (e) {
        Logger.error('Failed to load user: $e');
        throw ServerException(message: 'Failed to load user.');
      }
    } else {
      final user = await loadUserData();
      if (user != null && user.employeeId == employeeId) {
        return user;
      } else {
        throw CacheException(message: 'No offline data available.');
      }
    }
  }

  @override
  Future<void> loginUser(String employeeId, String password) async {
    Logger.log('Logging in user $employeeId');
    if (await networkInfo.isConnected) {
      try {
        final user = await userProvider.loginUser(employeeId, password);
        await saveUserData(user); 
      } catch (e) {
        Logger.error('Login failed: $e');
        throw ServerException(message: 'Failed to login.');
      }
    } else {
      throw ServerException(message: 'No internet connection.');
    }
  }

  @override
  Future<void> logoutUser() async {
    Logger.log('Logging out user');
    try {
      await userProvider.logoutUser();
      await SecureStorage().clear();
    } catch (e) {
      Logger.error('Logout failed: $e');
      throw ServerException(message: 'Failed to logout.');
    }
  }

  @override
  Future<bool> attemptLogin(String employeeId, String password) async {
    Logger.log('Attempting offline login for $employeeId');
    if (await networkInfo.isConnected) {
      await loginUser(employeeId, password);
      return true;
    } else {
      final user = await loadUserData();
      if (user != null && user.employeeId == employeeId) {
        return true;
      }
      return false;
    }
  }

  @override
  Future<void> saveUserData(User user) async {
    await SecureStorage().saveData('user', jsonEncode(user.toJson()));
  }

  @override
  Future<User?> loadUserData() async {
    String? userData = await SecureStorage().loadData('user');
    if (userData != null) {
      return User.fromJson(jsonDecode(userData));
    }
    return null;
  }
}
