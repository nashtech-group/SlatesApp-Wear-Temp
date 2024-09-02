import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoginEmployeeIdChanged extends LoginEvent {
  final String employeeId;

  LoginEmployeeIdChanged(this.employeeId);

  @override
  List<Object> get props => [employeeId];
}

class LoginPasswordChanged extends LoginEvent {
  final String password;

  LoginPasswordChanged(this.password);

  @override
  List<Object> get props => [password];
}

class LoginSubmitted extends LoginEvent {
  final String password;
  final String employeeId;

  LoginSubmitted({required this.password, required this.employeeId});

  @override
  List<Object> get props => [employeeId, password];
}
