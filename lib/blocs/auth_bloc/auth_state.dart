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
  final BlocErrorInfo errorInfo;

  const AuthError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  String? get errorCode => errorInfo.errorCode;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
  List<String>? get validationErrors => errorInfo.validationErrors;
  int? get statusCode => errorInfo.statusCode;
}

class AuthSessionExpired extends AuthState {
  final BlocErrorInfo errorInfo;

  AuthSessionExpired({BlocErrorInfo? errorInfo})
      : errorInfo = errorInfo ??
            BlocErrorInfo(
              type: ErrorType.authentication,
              message: 'Your session has expired. Please login again.',
              errorCode: 'SESSION_EXPIRED',
            );

  @override
  List<Object?> get props => [errorInfo];

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  String? get errorCode => errorInfo.errorCode;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
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
