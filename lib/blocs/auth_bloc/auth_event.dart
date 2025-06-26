part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginEvent extends AuthEvent {
  final String identifier;
  final String password;

  const LoginEvent({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class RefreshTokenEvent extends AuthEvent {
  const RefreshTokenEvent();
}

class AutoLoginEvent extends AuthEvent {
  final String? employeeId;

  const AutoLoginEvent({this.employeeId});

  @override
  List<Object?> get props => [employeeId];
}

class CheckAuthStatusEvent extends AuthEvent {
  const CheckAuthStatusEvent();
}

class ClearAuthErrorEvent extends AuthEvent {
  const ClearAuthErrorEvent();
}