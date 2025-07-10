import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:slates_app_wear/core/error/error_state_mixin.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import '../../core/auth_manager.dart';
import '../../core/error/error_handler.dart';
import '../../core/error/error_state_factory.dart';
import '../../core/constants/app_constants.dart';
import '../../data/repositories/auth_repository/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<LoginEvent>(_onLogin);
    on<LogoutEvent>(_onLogout);
    on<RefreshTokenEvent>(_onRefreshToken);
    on<AutoLoginEvent>(_onAutoLogin);
    on<CheckAuthStatusEvent>(_onCheckAuthStatus);
    on<ClearAuthErrorEvent>(_onClearAuthError);
  }

  /// Centralized error handling for auth operations
  AuthState _handleAuthError(
    dynamic error, {
    required String context,
    Map<String, dynamic>? additionalData,
  }) {
    final errorInfo = ErrorHandler.handleError(
      error,
      context: 'AuthBloc.$context',
      additionalData: additionalData,
    );

    // Use ErrorStateFactory to determine UI behavior
    final uiBehavior = ErrorStateFactory.getErrorUIBehavior(errorInfo);

    // Create appropriate auth state based on error type and UI behavior
    switch (uiBehavior) {
      case ErrorUIBehavior.logout:
      case ErrorUIBehavior.redirectToLogin:
        return AuthSessionExpired(errorInfo: errorInfo);
      case ErrorUIBehavior.enableOfflineMode:
        // Modify error message for offline context
        return AuthError(
          errorInfo: errorInfo.copyWith(
            message:
                'No internet connection. Try offline login or connect to internet.',
          ),
        );
      default:
        return AuthError(errorInfo: errorInfo);
    }
  }

  /// Handle login event with enhanced error handling
  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final loginModel = LoginModel(
        identifier: event.identifier,
        password: event.password,
      );

      final loginResponse = await authRepository.login(loginModel);

      emit(AuthAuthenticated(
        user: loginResponse.user,
        token: loginResponse.accessToken,
        isOffline: false,
      ));

      log('Login successful for user: ${loginResponse.user.fullName}');
    } catch (error) {
      final errorInfo = ErrorHandler.handleError(
        error,
        context: 'AuthBloc.login',
        additionalData: {'identifier': event.identifier},
      );

      // Check if should trigger offline mode and try offline login
      if (errorInfo.shouldTriggerOfflineMode()) {
        final offlineResult = await _attemptOfflineLogin(event.identifier);
        if (offlineResult != null) {
          emit(offlineResult);
          return;
        }
      }

      emit(_handleAuthError(
        error,
        context: 'login',
        additionalData: {'identifier': event.identifier},
      ));
    }
  }

  /// Attempt offline login with error handling
  Future<AuthState?> _attemptOfflineLogin(String identifier) async {
    try {
      final offlineResponse = await authRepository.autoLogin(identifier);
      if (offlineResponse != null) {
        log('Offline login successful for: $identifier');
        return AuthOfflineMode(
          user: offlineResponse.user,
          message: AppConstants.offlineLoginSuccessMessage,
        );
      }
    } catch (offlineError) {
      log('Offline login failed for $identifier: $offlineError');
    }
    return null;
  }

  /// Handle logout event with comprehensive cleanup
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      await authRepository.logout();
      emit(const AuthUnauthenticated());
      log('Logout successful');
    } catch (error) {
      // Even if server logout fails, clear local data and proceed
      await authRepository.clearAuthData();
      emit(const AuthUnauthenticated());
      log('Logout completed with server errors (local data cleared): $error');
    }
  }

  /// Handle token refresh with smart error handling
  Future<void> _onRefreshToken(
      RefreshTokenEvent event, Emitter<AuthState> emit) async {
    final currentState = state;

    // Validate current state
    if (currentState is! AuthAuthenticated) {
      emit(AuthError(
        errorInfo: BlocErrorInfo(
          type: ErrorType.authentication,
          message: 'Cannot refresh token: Not authenticated',
          errorCode: 'NOT_AUTHENTICATED',
        ),
      ));
      return;
    }

    emit(const AuthRefreshing());

    try {
      final refreshResponse = await authRepository.refreshToken();

      emit(AuthAuthenticated(
        user: refreshResponse.user,
        token: refreshResponse.accessToken,
        isOffline: false,
      ));

      log('Token refresh successful');
    } catch (error) {
      // Clear auth data on refresh failure
      await authRepository.clearAuthData();

      final errorInfo = ErrorHandler.handleError(
        error,
        context: 'AuthBloc.refreshToken',
      );

      // Always treat refresh failure as session expired
      emit(AuthSessionExpired(errorInfo: errorInfo));
    }
  }

  /// Handle auto-login with improved validation
  Future<void> _onAutoLogin(
      AutoLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      // Check current authentication status
      final authStatus = await authRepository.getAuthStatus();

      if (authStatus['isAuthenticated'] == true) {
        final user = await authRepository.getCurrentUser();
        final token = await AuthManager().getToken();

        if (user != null && token != null) {
          // Check if token needs refresh
          if (authStatus['needsRefresh'] == true) {
            add(const RefreshTokenEvent());
            return;
          }

          emit(AuthAuthenticated(
            user: user,
            token: token,
            isOffline: false,
          ));
          return;
        }
      }

      // Try offline auto-login for guards
      if (event.employeeId != null) {
        final offlineState = await _attemptOfflineLogin(event.employeeId!);
        if (offlineState != null) {
          emit(offlineState);
          return;
        }
      }

      // No valid authentication found
      emit(const AuthUnauthenticated());
    } catch (error) {
      // Auto-login failures should silently fall back to unauthenticated
      emit(const AuthUnauthenticated());
      log('Auto-login failed: ${ErrorHandler.handleError(error).message}');
    }
  }

  /// Handle authentication status check
  Future<void> _onCheckAuthStatus(
      CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    try {
      final isValid = await authRepository.validateAuthState();

      if (isValid) {
        final user = await authRepository.getCurrentUser();
        final token = await AuthManager().getToken();

        if (user != null && token != null) {
          emit(AuthAuthenticated(
            user: user,
            token: token,
            isOffline: false,
          ));
          return;
        }
      }

      emit(const AuthUnauthenticated());
    } catch (error) {
      emit(const AuthUnauthenticated());
      log('Auth status check failed: ${ErrorHandler.handleError(error).message}');
    }
  }

  /// Handle clear auth error
  Future<void> _onClearAuthError(
      ClearAuthErrorEvent event, Emitter<AuthState> emit) async {
    if (state is AuthError || state is AuthSessionExpired) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Check if in offline mode
  bool get isOfflineMode => state is AuthOfflineMode;

  /// Check if current state is error
  bool get hasError => state is AuthError || state is AuthSessionExpired;

  /// Get current error info if in error state
  BlocErrorInfo? get currentError {
    return switch (state) {
      AuthError(:final errorInfo) => errorInfo,
      AuthSessionExpired(:final errorInfo) => errorInfo,
      _ => null,
    };
  }

  /// Check if can retry current operation
  bool get canRetry {
    final error = currentError;
    return error?.canRetry ?? false;
  }
}
