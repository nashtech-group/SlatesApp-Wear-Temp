import 'package:slates_app_wear/domain/use_cases/attempt_login.dart';
import 'package:slates_app_wear/domain/use_cases/login_user.dart';
import 'package:slates_app_wear/presentation/blocs/login_event.dart';
import 'package:slates_app_wear/presentation/blocs/login_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUser loginUser;
  final AttemptLogin attemptLogin;

  LoginBloc({required this.loginUser, required this.attemptLogin})
      : super(LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
  }

  Future<void> _onLoginSubmitted(
      LoginSubmitted event, Emitter<LoginState> emit) async {
    emit(LoginLoading());
    try {
      final success = await attemptLogin.call(event.employeeId, event.password);
      if (success) {
        emit(LoginSuccess());
      } else {
        emit(LoginFailure(error: 'Login failed. Please try again later'));
      }
    } catch (e) {
      emit(LoginFailure(error: e.toString()));
    }
  }
}
