import 'package:slates_app_wear/core/errors/exceptions.dart';
import 'package:slates_app_wear/domain/repositories/user_repository.dart';
import 'package:slates_app_wear/presentation/blocs/user/login_event.dart';
import 'package:slates_app_wear/presentation/blocs/user/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final UserRepository userRepository;

  LoginBloc({required this.userRepository}) : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());

    try {
      await userRepository.loginUser(event.employeeId, event.password);
      emit(LoginSuccess());
    } catch (e) {
      if (e is ServerException) {
        emit(LoginFailure(error: e.message));
      } else {
        emit(LoginFailure(
            error: 'Unexpected error occurred. Please try again.'));
      }
    }
  }
}
