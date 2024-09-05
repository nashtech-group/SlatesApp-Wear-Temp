import '../entities/user/user.dart';

abstract class UserRepository {
  Future<User> getUser(String employeeId);
  Future<void> loginUser(String employeeId, String password);
  Future<void> logoutUser();
  Future<bool> attemptLogin(String employeeId, String password);
  Future<void> saveUserData(User user);  
  Future<User?> loadUserData();
}