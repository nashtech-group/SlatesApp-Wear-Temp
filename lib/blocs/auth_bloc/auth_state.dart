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

  /// Create copy with updated properties
  AuthAuthenticated copyWith({
    UserModel? user,
    String? token,
    bool? isOffline,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      token: token ?? this.token,
      isOffline: isOffline ?? this.isOffline,
    );
  }
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Generic auth error state with DRY convenience getters
class AuthError extends AuthState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  const AuthError({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  /// Create copy with updated error info
  AuthError copyWith({BlocErrorInfo? errorInfo}) {
    return AuthError(errorInfo: errorInfo ?? this.errorInfo);
  }
}

/// Specific session expired state with enhanced messaging
class AuthSessionExpired extends AuthState with ErrorStateMixin {
  @override
  final BlocErrorInfo errorInfo;

  AuthSessionExpired({BlocErrorInfo? errorInfo})
      : errorInfo = errorInfo ??
            BlocErrorInfo(
              type: ErrorType.authentication,
              message: AppConstants.sessionExpiredMessage,
              errorCode: 'SESSION_EXPIRED',
              canRetry: false,
              isNetworkError: false,
            );

  @override
  List<Object?> get props => [errorInfo];

  /// Always indicates session expired regardless of error info
  @override
  bool get isSessionExpired => true;

  /// Create copy with updated error info
  AuthSessionExpired copyWith({BlocErrorInfo? errorInfo}) {
    return AuthSessionExpired(errorInfo: errorInfo ?? this.errorInfo);
  }
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

  /// Create copy with updated properties
  AuthOfflineMode copyWith({
    UserModel? user,
    String? message,
  }) {
    return AuthOfflineMode(
      user: user ?? this.user,
      message: message ?? this.message,
    );
  }
}