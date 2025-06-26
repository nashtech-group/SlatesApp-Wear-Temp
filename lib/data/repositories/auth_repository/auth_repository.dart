import 'dart:convert';
import 'dart:developer';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/data/models/api_error_model.dart';
import 'package:slates_app_wear/data/models/user/login_model.dart';
import 'package:slates_app_wear/data/models/user/login_response_model.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';

import 'auth_provider.dart';

class AuthRepository {
  final AuthProvider authProvider;

  AuthRepository({required this.authProvider});

  /// Login with support for both online and offline
  Future<LoginResponseModel> login(LoginModel loginModel) async {
    try {
      // Try online login first
      final responseData = await authProvider.login(loginModel);
      log('Login response: $responseData');
      
      final decodedData = jsonDecode(responseData);
      
      // Check for errors in response
      if (decodedData.containsKey("errors") || 
          (decodedData.containsKey("status") && decodedData["status"] != "success")) {
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
    } catch (e) {
      // If online login fails and user is a guard, try offline login
      if (e.toString().contains('No internet connection') || 
          e.toString().contains('Network error')) {
        return await _attemptOfflineLogin(loginModel);
      }
      rethrow;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      final token = await AuthManager().getToken();
      
      if (token != null) {
        // Try to logout from server
        final responseData = await authProvider.logout(token);
        final decodedData = jsonDecode(responseData);
        
        if (decodedData.containsKey('errors') || 
            (decodedData.containsKey('status') && decodedData['status'] != 'success')) {
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
  }

  /// Refresh authentication token
  Future<LoginResponseModel> refreshToken() async {
    final token = await AuthManager().getToken();
    
    if (token == null) {
      throw ApiErrorModel(
        status: 'error',
        message: 'No token available for refresh',
      );
    }

    try {
      final responseData = await authProvider.refreshToken(token);
      final decodedData = jsonDecode(responseData);
      
      if (decodedData.containsKey("errors") || 
          (decodedData.containsKey("status") && decodedData["status"] != "success")) {
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
    } catch (e) {
      // If refresh fails, clear authentication data
      await AuthManager().clear();
      rethrow;
    }
  }

  /// Check if user is authenticated and token is valid
  Future<bool> isAuthenticated() async {
    return await AuthManager().isAuthenticated();
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    return await AuthManager().getUserData();
  }

  /// Auto-login for guards using offline data
  Future<LoginResponseModel?> autoLogin(String employeeId) async {
    try {
      // First check if we have valid authentication data
      final isAuth = await AuthManager().isAuthenticated();
      if (isAuth) {
        final user = await AuthManager().getUserData();
        final token = await AuthManager().getToken();
        
        if (user != null && token != null) {
          // Try to refresh token if close to expiry
          final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
          if (timeUntilExpiry != null && timeUntilExpiry.inHours < 1) {
            try {
              return await refreshToken();
            } catch (e) {
              // If refresh fails, continue with existing token
              log('Token refresh failed during auto-login: $e');
            }
          }
          
          return LoginResponseModel(
            status: 'success',
            message: 'Auto-login successful',
            user: user,
            accessToken: token,
            tokenType: 'Bearer',
            expiresIn: timeUntilExpiry?.inSeconds ?? 0,
          );
        }
      }

      // If no valid auth data, try offline login for guards
      return await _getOfflineLoginData(employeeId);
    } catch (e) {
      log('Auto-login failed: $e');
      return null;
    }
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
      throw ApiErrorModel(
        status: 'error',
        message: 'Offline login is only available for security guards. Please connect to the internet.',
      );
    }

    final offlineData = await _getOfflineLoginData(loginModel.identifier);
    
    if (offlineData == null) {
      throw ApiErrorModel(
        status: 'error',
        message: 'No offline login data found. Please connect to the internet to login for the first time.',
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
        // Check if offline data is still valid (within 7 days)
        final timeUntilExpiry = await AuthManager().getTimeUntilExpiry();
        if (timeUntilExpiry != null && timeUntilExpiry.inDays > -7) {
          return LoginResponseModel(
            status: 'success',
            message: 'Offline login successful',
            user: user,
            accessToken: token,
            tokenType: 'Bearer',
            expiresIn: timeUntilExpiry.inSeconds,
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