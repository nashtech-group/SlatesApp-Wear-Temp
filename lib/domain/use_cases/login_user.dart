// domain/use_cases/login_user.dart
import '../repositories/user_repository.dart';

class LoginUser {
  final UserRepository repository;

  LoginUser(this.repository);

  Future<void> call(String employeeId, String password) async {
    return await repository.loginUser(employeeId, password);
  }
}
