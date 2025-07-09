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
    return await executeWithCacheFallback(
      () => _performOnlineLogin(loginModel),
      () => _attemptOfflineLogin(loginModel),
      'login',
    );
  }

  /// Perform online login
  Future<LoginResponseModel> _performOnlineLogin(LoginModel loginModel) async {
    return await safeRepositoryCall(
      () async {
        final responseData = await authProvider.login(loginModel);
        log('Login response received');
        
        final decodedData = jsonDecode(responseData);
        
        // Check for API errors using constants
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
      'onlineLogin',
    );
  }

  /// Logout user with comprehensive error handling
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
              
              // Log server logout error but don't throw - we still want to clear local data
              final error = ApiErrorModel.fromJson(decodedData);
              log('Server logout failed: ${error.message}');
            }
          }
        } catch (e) {
          // Log server logout failure but continue with local cleanup
          log('Server logout failed: ${getUserFriendlyMessage(e)}');
        } finally {
          // Always clear local authentication data
          await AuthManager().clear();
          await _clearOfflineLoginData();
        }
      },
      'logout',
    );
  }

  /// Refresh authentication token with smart error handling
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
      // If refresh fails and it's an authentication error, clear auth data
      if (isAuthenticationError(error)) {
        await AuthManager().clear();
        log('Authentication data cleared due to refresh failure');
      }
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

  /// Get current user with fallback
  Future<UserModel?> getCurrentUser() async {
    return await safeRepositoryCall(
      () async {
        return await AuthManager().getUserData();
      },
      'getCurrentUser',
      fallbackValue: null,
    );
  }

  /// Auto-login for guards using offline data with smart retry
  Future<LoginResponseModel?> autoLogin(String employeeId) async {
    return await executeWithSmartRetry(
      () => _performAutoLogin(employeeId),
      'autoLogin',
      fallbackValue: null,
      getCachedData: () => _getOfflineLoginData(employeeId),
    );
  }

  /// Perform auto-login logic
  Future<LoginResponseModel> _performAutoLogin(String employeeId) async {
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
            // If refresh fails, log but continue with existing token
            log('Token refresh failed during auto-login: ${getUserFriendlyMessage(e)}');
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
    final offlineData = await _getOfflineLoginData(employeeId);
    if (offlineData != null) {
      return offlineData;
    }

    throw const AuthException(
      message: AppConstants.noOfflineDataMessage,
      statusCode: ApiConstants.notFoundCode,
    );
  }

  /// Check if user session is expired (renamed to avoid mixin conflict)
  Future<bool> checkUserSessionExpiry() async {
    return await safeRepositoryCall(
      () async {
        final isAuth = await AuthManager().isAuthenticated();
        if (!isAuth) return true;

        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        return timeUntilExpiry == null || timeUntilExpiry.isNegative;
      },
      'checkUserSessionExpiry',
      fallbackValue: true,
    );
  }

  /// Get time until token expiry
  Future<Duration?> getTimeUntilExpiry() async {
    return await safeRepositoryCall(
      () async {
        return await AuthManager().getTimeUntilExpiry();
      },
      'getTimeUntilExpiry',
      fallbackValue: null,
    );
  }

  /// Check if auto token refresh is needed
  Future<bool> needsTokenRefresh() async {
    return await safeRepositoryCall(
      () async {
        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        return timeUntilExpiry != null && 
               timeUntilExpiry.inMinutes < AppConstants.tokenRefreshThresholdMinutes;
      },
      'needsTokenRefresh',
      fallbackValue: false,
    );
  }

  /// Validate offline login credentials
  Future<bool> validateOfflineCredentials(LoginModel loginModel) async {
    return await safeRepositoryCall(
      () async {
        if (!_isGuardEmployeeId(loginModel.identifier)) {
          return false;
        }

        final offlineData = await _getOfflineLoginData(loginModel.identifier);
        return offlineData != null;
      },
      'validateOfflineCredentials',
      fallbackValue: false,
    );
  }

  /// Clear authentication data
  Future<void> clearAuthData() async {
    return await safeRepositoryCall(
      () async {
        await AuthManager().clear();
        await _clearOfflineLoginData();
      },
      'clearAuthData',
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
      log('Offline login data saved for guard: ${loginModel.identifier}');
    } catch (e) {
      log('Failed to save offline login data: ${getUserFriendlyMessage(e)}');
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
      log('Failed to get offline login data: ${getUserFriendlyMessage(e)}');
      return null;
    }
  }

  /// Clear offline login data
  Future<void> _clearOfflineLoginData() async {
    try {
      // Additional cleanup for offline data would go here
      // For now, AuthManager().clear() handles this
      log('Offline login data cleared');
    } catch (e) {
      log('Failed to clear offline login data: ${getUserFriendlyMessage(e)}');
    }
  }

  /// Check if identifier is a guard employee ID (format: ABC-123)
  bool _isGuardEmployeeId(String identifier) {
    final guardIdRegex = RegExp(r'^[A-Z]{3}-\d{3}$');
    return guardIdRegex.hasMatch(identifier);
  }

  /// Get authentication status details
  Future<Map<String, dynamic>> getAuthStatus() async {
    return await safeRepositoryCall(
      () async {
        final isAuth = await AuthManager().isAuthenticated();
        final user = await AuthManager().getUserData();
        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        
        return {
          'isAuthenticated': isAuth,
          'hasUser': user != null,
          'userRole': user?.role ?? 'unknown',
          'isGuard': user?.isGuard ?? false,
          'timeUntilExpiry': timeUntilExpiry?.inMinutes ?? 0,
          'needsRefresh': timeUntilExpiry != null && 
                         timeUntilExpiry.inMinutes < AppConstants.tokenRefreshThresholdMinutes,
          'isExpired': timeUntilExpiry?.isNegative ?? true,
        };
      },
      'getAuthStatus',
      fallbackValue: {
        'isAuthenticated': false,
        'hasUser': false,
        'userRole': 'unknown',
        'isGuard': false,
        'timeUntilExpiry': 0,
        'needsRefresh': false,
        'isExpired': true,
      },
    );
  }

  /// Validate current authentication state
  Future<bool> validateAuthState() async {
    return await safeRepositoryCall(
      () async {
        final isAuth = await AuthManager().isAuthenticated();
        if (!isAuth) return false;

        final user = await AuthManager().getUserData();
        final token = await AuthManager().getToken();
        
        if (user == null || token == null) {
          await AuthManager().clear();
          return false;
        }

        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        if (timeUntilExpiry == null || timeUntilExpiry.isNegative) {
          await AuthManager().clear();
          return false;
        }

        return true;
      },
      'validateAuthState',
      fallbackValue: false,
    );
  }

  /// Handle authentication errors consistently
  Future<void> handleAuthenticationError(dynamic error) async {
    if (isAuthenticationError(error) || isSessionExpired(error)) {
      await clearAuthData();
      log('Authentication data cleared due to auth error: ${getUserFriendlyMessage(error)}');
    }
  }

  /// Check if user can use offline login
  bool canUseOfflineLogin(String identifier) {
    return _isGuardEmployeeId(identifier);
  }

  /// Get login options for identifier
  Map<String, bool> getLoginOptions(String identifier) {
    return {
      'canLoginOnline': true,
      'canLoginOffline': canUseOfflineLogin(identifier),
      'isGuardIdentifier': _isGuardEmployeeId(identifier),
    };
  }
}