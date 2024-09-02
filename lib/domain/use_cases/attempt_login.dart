// domain/use_cases/login_user.dart
import '../repositories/user_repository.dart';

class AttemptLogin {
  final UserRepository repository;

  AttemptLogin(this.repository);

  Future<bool> call(String employeeId, String password) async {
    return await repository.attemptLogin(employeeId, password);
  }
}
