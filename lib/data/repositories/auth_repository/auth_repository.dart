import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/data/models/api_error_model.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';
import 'package:slates_app_wear/data/models/user/login_response_model.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'package:slates_app_wear/data/repositories/auth_repository/auth_provider.dart';
import '../../../core/error/repository_error_mixin.dart';
import '../../../core/error/exceptions.dart';


class AuthRepository with RepositoryErrorMixin {
  final AuthProvider authProvider;

  AuthRepository({required this.authProvider});

  /// Login with support for both online and offline
  Future<LoginResponseModel> login(LoginModel loginModel) async {
    return await safeRepositoryCall(
      () async {
        // Try online login first
        final responseData = await authProvider.login(loginModel);
        log('Login response: $responseData');
        
        final decodedData = jsonDecode(responseData);
        
        // Check for errors in response using ApiConstants
        if (decodedData.containsKey(ApiConstants.errorsKey) || 
            (decodedData.containsKey(ApiConstants.statusKey) && 
             decodedData[ApiConstants.statusKey] != ApiConstants.successStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final loginResponse = LoginResponseModel.fromJson(decodedData);
        
        // Save authentication data
        await AuthManager().saveAuthData(
          token: loginResponse.accessToken,
          user: loginResponse.user,
          expiresIn: loginResponse.expiresIn,
        );

        // For guards, save offline login data for future offline access
        if (loginResponse.user.isGuard) {
          await _saveOfflineLoginData(loginModel, loginResponse);
        }

        return loginResponse;
      },
      'login',
    ).catchError((error) async {
      // If online login fails and user is a guard, try offline login
      if (shouldTriggerOfflineMode(error)) {
        try {
          return await _attemptOfflineLogin(loginModel);
        } catch (offlineError) {
          // If offline login also fails, throw the original error
          throw handleRepositoryError(error, 'login');
        }
      }
      throw handleRepositoryError(error, 'login');
    });
  }

  /// Logout user
  Future<void> logout() async {
    return await safeRepositoryCall(
      () async {
        try {
          final token = await AuthManager().getToken();
          
          if (token != null) {
            // Try to logout from server
            final responseData = await authProvider.logout(token);
            final decodedData = jsonDecode(responseData);
            
            if (decodedData.containsKey(ApiConstants.errorsKey) || 
                (decodedData.containsKey(ApiConstants.statusKey) && 
                 decodedData[ApiConstants.statusKey] != ApiConstants.successStatus)) {
              throw ApiErrorModel.fromJson(decodedData);
            }
          }
        } catch (e) {
          // Continue with local logout even if server logout fails
          log('Server logout failed: $e');
        } finally {
          // Always clear local authentication data
          await AuthManager().clear();
          await _clearOfflineLoginData();
        }
      },
      'logout',
    );
  }

  /// Refresh authentication token
  Future<LoginResponseModel> refreshToken() async {
    return await safeRepositoryCall(
      () async {
        final token = await AuthManager().getToken();
        
        if (token == null) {
          throw const AuthException(
            message: AppConstants.sessionExpiredMessage,
            statusCode: ApiConstants.unauthorizedCode,
          );
        }

        final responseData = await authProvider.refreshToken(token);
        final decodedData = jsonDecode(responseData);
        
        if (decodedData.containsKey(ApiConstants.errorsKey) || 
            (decodedData.containsKey(ApiConstants.statusKey) && 
             decodedData[ApiConstants.statusKey] != ApiConstants.successStatus)) {
          throw ApiErrorModel.fromJson(decodedData);
        }

        final loginResponse = LoginResponseModel.fromJson(decodedData);
        
        // Update stored authentication data
        await AuthManager().saveAuthData(
          token: loginResponse.accessToken,
          user: loginResponse.user,
          expiresIn: loginResponse.expiresIn,
        );

        return loginResponse;
      },
      'refreshToken',
    ).catchError((error) async {
      // If refresh fails, clear authentication data
      await AuthManager().clear();
      throw handleRepositoryError(error, 'refreshToken');
    });
  }

  /// Check if user is authenticated and token is valid
  Future<bool> isAuthenticated() async {
    return await safeRepositoryCall(
      () async {
        return await AuthManager().isAuthenticated();
      },
      'isAuthenticated',
      fallbackValue: false,
    );
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    return await safeRepositoryCall(
      () async {
        return await AuthManager().getUserData();
      },
      'getCurrentUser',
      fallbackValue: null,
    );
  }

  /// Auto-login for guards using offline data
  Future<LoginResponseModel?> autoLogin(String employeeId) async {
    return await safeRepositoryCall(
      () async {
        // First check if we have valid authentication data
        final isAuth = await AuthManager().isAuthenticated();
        if (isAuth) {
          final user = await AuthManager().getUserData();
          final token = await AuthManager().getToken();
          
          if (user != null && token != null) {
            // Try to refresh token if close to expiry using AppConstants
            final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
            if (timeUntilExpiry != null && 
                timeUntilExpiry.inMinutes < AppConstants.tokenRefreshThresholdMinutes) {
              try {
                return await refreshToken();
              } catch (e) {
                // If refresh fails, continue with existing token
                log('Token refresh failed during auto-login: $e');
              }
            }
            
            return LoginResponseModel(
              status: ApiConstants.successStatus,
              message: AppConstants.loginSuccessMessage,
              user: user,
              accessToken: token,
              tokenType: 'Bearer',
              expiresIn: timeUntilExpiry?.inSeconds ?? 0,
            );
          }
        }

        // If no valid auth data, try offline login for guards
        return await _getOfflineLoginData(employeeId);
      },
      'autoLogin',
      fallbackValue: null,
    );
  }

  /// Save offline login data for guards
  Future<void> _saveOfflineLoginData(LoginModel loginModel, LoginResponseModel response) async {
    try {
      final offlineData = {
        'loginModel': loginModel.toJson(),
        'loginResponse': response.toJson(),
        'loginTime': DateTime.now().toIso8601String(),
      };
      
      // Save to secure storage with employeeId as key
      await AuthManager().saveUserData(response.user);
      
      // Additional offline storage implementation would go here
      // For now, we're using the AuthManager's secure storage
    } catch (e) {
      log('Failed to save offline login data: $e');
    }
  }

  /// Attempt offline login for guards
  Future<LoginResponseModel> _attemptOfflineLogin(LoginModel loginModel) async {
    // Check if this is a guard login (employeeId format)
    if (!_isGuardEmployeeId(loginModel.identifier)) {
      throw const AuthException(
        message: AppConstants.offlineLoginUnavailable,
        statusCode: ApiConstants.forbiddenCode,
      );
    }

    final offlineData = await _getOfflineLoginData(loginModel.identifier);
    
    if (offlineData == null) {
      throw const AuthException(
        message: AppConstants.noOfflineDataMessage,
        statusCode: ApiConstants.notFoundCode,
      );
    }

    return offlineData;
  }

  /// Get offline login data
  Future<LoginResponseModel?> _getOfflineLoginData(String employeeId) async {
    try {
      final user = await AuthManager().getUserData();
      final token = await AuthManager().getToken();
      
      if (user != null && user.employeeId == employeeId && token != null) {
        // Check if offline data is still valid using AppConstants
        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        if (timeUntilExpiry != null && 
            timeUntilExpiry.inDays > -AppConstants.offlineLoginValidityDays) {
          return LoginResponseModel(
            status: ApiConstants.successStatus,
            message: AppConstants.offlineLoginSuccessMessage,
            user: user,
            accessToken: token,
            tokenType: 'Bearer',
            expiresIn: timeUntilExpiry.inSeconds,
          );
        } else {
          throw const AuthException(
            message: AppConstants.expiredOfflineDataMessage,
            statusCode: ApiConstants.unauthorizedCode,
          );
        }
      }
      
      return null;
    } catch (e) {
      log('Failed to get offline login data: $e');
      return null;
    }
  }

  /// Clear offline login data
  Future<void> _clearOfflineLoginData() async {
    // Additional cleanup for offline data would go here
    // For now, AuthManager().clear() handles this
  }

  /// Check if identifier is a guard employee ID (format: ABC-123)
   bool _isGuardEmployeeId(String identifier) {
    final guardIdRegex = RegExp(r'^[A-Z]{3}-\d{3}$');
    return guardIdRegex.hasMatch(identifier);
  }
}