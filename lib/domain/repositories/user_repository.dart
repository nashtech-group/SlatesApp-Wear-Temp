import '../entities/user.dart';

abstract class UserRepository {
  Future<User> getUser(String employeeId);
  Future<void> loginUser(String employeeId, String password);
  Future<void> logoutUser();
}