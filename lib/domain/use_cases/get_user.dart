import '../entities/user/user.dart';
import '../repositories/user_repository.dart';

class GetUser {
  final UserRepository repository;

  GetUser(this.repository);

  Future<User> call(String employeeId) async {
    return await repository.getUser(employeeId);
  }
}
