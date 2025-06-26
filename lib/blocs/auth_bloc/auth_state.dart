// lib/bloc/auth_bloc/auth_state.dart
part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String token;
  final bool isOffline;

  const AuthAuthenticated({
    required this.user,
    required this.token,
    this.isOffline = false,
  });

  @override
  List<Object?> get props => [user, token, isOffline];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  final String? errorCode;

  const AuthError({
    required this.message,
    this.errorCode,
  });

  @override
  List<Object?> get props => [message, errorCode];
}

class AuthSessionExpired extends AuthState {
  final String message;

  const AuthSessionExpired({
    this.message = 'Your session has expired. Please login again.',
  });

  @override
  List<Object?> get props => [message];
}

class AuthRefreshing extends AuthState {
  const AuthRefreshing();
}

class AuthOfflineMode extends AuthState {
  final UserModel user;
  final String message;

  const AuthOfflineMode({
    required this.user,
    this.message = 'You are in offline mode',
  });

  @override
  List<Object?> get props => [user, message];
}