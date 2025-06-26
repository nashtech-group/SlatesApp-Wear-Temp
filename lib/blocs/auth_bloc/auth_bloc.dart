import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import '../../core/auth_manager.dart';
import '../../data/models/api_error_model.dart';
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

  /// Handle login event
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
    } on ApiErrorModel catch (apiError) {
      String errorMessage = apiError.message;
      
      // Handle specific error cases
      if (errorMessage.toLowerCase().contains('validation')) {
        errorMessage = 'Invalid credentials. Please check your ID and PIN.';
      } else if (errorMessage.toLowerCase().contains('unauthorized')) {
        errorMessage = 'Invalid credentials. Please try again.';
      }

      emit(AuthError(
        message: errorMessage,
        errorCode: apiError.statusCode?.toString(),
      ));
      
      log('Login failed: $errorMessage');
    } catch (e) {
      // Check if this is a network error and try offline login
      if (e.toString().contains('No internet connection') || 
          e.toString().contains('Network error')) {
        try {
          final offlineResponse = await authRepository.autoLogin(event.identifier);
          if (offlineResponse != null) {
            emit(AuthOfflineMode(
              user: offlineResponse.user,
              message: 'Logged in offline. Connect to internet for full features.',
            ));
            return;
          }
        } catch (offlineError) {
          log('Offline login failed: $offlineError');
        }
        
        emit(const AuthError(
          message: 'No internet connection. Please connect to login or try offline mode.',
        ));
      } else {
        emit(AuthError(
          message: 'Login failed: ${e.toString()}',
        ));
      }
      
      log('Login error: $e');
    }
  }

  /// Handle logout event
  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      await authRepository.logout();
      emit(const AuthUnauthenticated());
      log('Logout successful');
    } catch (e) {
      // Even if server logout fails, clear local data
      await AuthManager().clear();
      emit(const AuthUnauthenticated());
      log('Logout completed with errors: $e');
    }
  }

  /// Handle token refresh event
  Future<void> _onRefreshToken(RefreshTokenEvent event, Emitter<AuthState> emit) async {
    final currentState = state;
    
    // Only refresh if currently authenticated
    if (currentState is! AuthAuthenticated) {
      emit(const AuthError(message: 'Not authenticated'));
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
    } catch (e) {
      // If refresh fails, user needs to login again
      await AuthManager().clear();
      emit(const AuthSessionExpired());
      log('Token refresh failed: $e');
    }
  }

  /// Handle auto-login event
  Future<void> _onAutoLogin(AutoLoginEvent event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      // Check if user is already authenticated
      final isAuthenticated = await authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        final token = await AuthManager().getToken();
        
        if (user != null && token != null) {
          // Check if token is close to expiry and refresh if needed
          final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
          
          if (timeUntilExpiry != null && timeUntilExpiry.inMinutes < 30) {
            // Try to refresh token
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

      // Try auto-login for guards with offline data
      if (event.employeeId != null) {
        final autoLoginResponse = await authRepository.autoLogin(event.employeeId!);
        
        if (autoLoginResponse != null) {
          emit(AuthAuthenticated(
            user: autoLoginResponse.user,
            token: autoLoginResponse.accessToken,
            isOffline: true,
          ));
          return;
        }
      }

      // No valid authentication found
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(const AuthUnauthenticated());
      log('Auto-login failed: $e');
    }
  }

  /// Handle check authentication status event
  Future<void> _onCheckAuthStatus(CheckAuthStatusEvent event, Emitter<AuthState> emit) async {
    try {
      final isAuthenticated = await authRepository.isAuthenticated();
      
      if (isAuthenticated) {
        final user = await authRepository.getCurrentUser();
        final token = await AuthManager().getToken();
        
        if (user != null && token != null) {
          emit(AuthAuthenticated(
            user: user,
            token: token,
            isOffline: false,
          ));
        } else {
          emit(const AuthUnauthenticated());
        }
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      emit(const AuthUnauthenticated());
      log('Auth status check failed: $e');
    }
  }

  /// Handle clear auth error event
  Future<void> _onClearAuthError(ClearAuthErrorEvent event, Emitter<AuthState> emit) async {
    if (state is AuthError || state is AuthSessionExpired) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Helper method to get current user if authenticated
  UserModel? get currentUser {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.user;
    } else if (currentState is AuthOfflineMode) {
      return currentState.user;
    }
    return null;
  }

  /// Helper method to check if user is authenticated
  bool get isAuthenticated {
    return state is AuthAuthenticated || state is AuthOfflineMode;
  }

  /// Helper method to check if in offline mode
  bool get isOfflineMode {
    return state is AuthOfflineMode;
  }

  /// Helper method to get current token
  String? get currentToken {
    final currentState = state;
    if (currentState is AuthAuthenticated) {
      return currentState.token;
    }
    return null;
  }
}