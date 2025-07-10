import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/data/models/user/user_model.dart';
import 'constants/storage_constants.dart';
import 'constants/app_constants.dart';

class AuthManager {
  static final AuthManager _instance = AuthManager._internal();
  factory AuthManager() => _instance;
  AuthManager._internal();

  final _secureStorage = const FlutterSecureStorage();

  // ====================
  // TOKEN MANAGEMENT
  // ====================

  /// Save authentication token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: StorageConstants.bearerToken, value: token);
  }

  /// Get authentication token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: StorageConstants.bearerToken);
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String refreshToken) async {
    await _secureStorage.write(
        key: StorageConstants.refreshToken, value: refreshToken);
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: StorageConstants.refreshToken);
  }

  /// Save token expiry time
  Future<void> saveTokenExpiry(DateTime expiryTime) async {
    await _secureStorage.write(
      key: StorageConstants.tokenExpiry,
      value: expiryTime.toIso8601String(),
    );
  }

  /// Get token expiry time
  Future<DateTime?> getTokenExpiry() async {
    try {
      final expiryString =
          await _secureStorage.read(key: StorageConstants.tokenExpiry);
      if (expiryString != null) {
        return DateTime.parse(expiryString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get authorization header value
  Future<String?> getAuthorizationHeader() async {
    final token = await getToken();
    if (token != null) {
      return '${ApiConstants.bearerPrefix}$token';
    }
    return null;
  }

  // ====================
  // USER DATA MANAGEMENT
  // ====================

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: StorageConstants.userId, value: userId);
  }

  /// Get user ID
  Future<String?> getUserId() async {
    return await _secureStorage.read(key: StorageConstants.userId);
  }

  /// Get current user role
  Future<String?> getUserRole() async {
    final user = await getUserData();
    return user?.role;
  }

  /// Check if current user is a guard
  Future<bool> isGuard() async {
    final user = await getUserData();
    return user?.isGuard ?? false;
  }

  /// Check if current user is an admin
  Future<bool> isAdmin() async {
    final user = await getUserData();
    return user?.isAdmin ?? false;
  }

  /// Check if current user is a manager
  Future<bool> isManager() async {
    final user = await getUserData();
    return user?.isManager ?? false;
  }

  /// Get user's full name
  Future<String?> getUserName() async {
    final user = await getUserData();
    return user?.fullName;
  }

  /// Get user's employee ID
  Future<String?> getEmployeeId() async {
    final user = await getUserData();
    return user?.employeeId;
  }

  /// Save complete user data
  Future<void> saveUserData(UserModel user) async {
    final userJson = jsonEncode(user.toJson());
    await _secureStorage.write(key: StorageConstants.userData, value: userJson);
    await saveUserId(user.id.toString());

    // Save last employee ID for guards
    if (user.isGuard) {
      await _secureStorage.write(
          key: StorageConstants.lastEmployeeId, value: user.employeeId);
    }
  }

  /// Get complete user data
  Future<UserModel?> getUserData() async {
    try {
      final userJson =
          await _secureStorage.read(key: StorageConstants.userData);
      if (userJson != null) {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        return UserModel.fromJson(userMap);
      }
      return null;
    } catch (e) {
      // If there's an error parsing user data, clear it
      await clearUserData();
      return null;
    }
  }

  /// Save login type (guard/admin/manager)
  Future<void> saveLoginType(String loginType) async {
    await _secureStorage.write(
        key: StorageConstants.loginType, value: loginType);
  }

  /// Get login type
  Future<String?> getLoginType() async {
    return await _secureStorage.read(key: StorageConstants.loginType);
  }

  /// Get last employee ID for guards
  Future<String?> getLastEmployeeId() async {
    return await _secureStorage.read(key: StorageConstants.lastEmployeeId);
  }

  // ====================
  // SESSION MANAGEMENT
  // ====================

  /// Save session start time
  Future<void> saveSessionStartTime(DateTime startTime) async {
    await _secureStorage.write(
      key: StorageConstants.sessionStartTime,
      value: startTime.toIso8601String(),
    );
  }

  /// Get session start time
  Future<DateTime?> getSessionStartTime() async {
    try {
      final timeString =
          await _secureStorage.read(key: StorageConstants.sessionStartTime);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save last activity time
  Future<void> saveLastActivityTime(DateTime activityTime) async {
    await _secureStorage.write(
      key: StorageConstants.lastActivityTime,
      value: activityTime.toIso8601String(),
    );
  }

  /// Get last activity time
  Future<DateTime?> getLastActivityTime() async {
    try {
      final timeString =
          await _secureStorage.read(key: StorageConstants.lastActivityTime);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Save last online sync time
  Future<void> saveLastOnlineSync(DateTime syncTime) async {
    await _secureStorage.write(
      key: StorageConstants.lastOnlineSync,
      value: syncTime.toIso8601String(),
    );
  }

  /// Get last online sync time
  Future<DateTime?> getLastOnlineSync() async {
    try {
      final timeString =
          await _secureStorage.read(key: StorageConstants.lastOnlineSync);
      if (timeString != null) {
        return DateTime.parse(timeString);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // ====================
  // DEVICE MANAGEMENT
  // ====================

  /// Save device ID
  Future<void> saveDeviceId(String deviceId) async {
    await _secureStorage.write(key: StorageConstants.deviceId, value: deviceId);
  }

  /// Get device ID
  Future<String?> getDeviceId() async {
    return await _secureStorage.read(key: StorageConstants.deviceId);
  }

  /// Save device fingerprint
  Future<void> saveDeviceFingerprint(String fingerprint) async {
    await _secureStorage.write(
        key: StorageConstants.deviceFingerprint, value: fingerprint);
  }

  /// Get device fingerprint
  Future<String?> getDeviceFingerprint() async {
    return await _secureStorage.read(key: StorageConstants.deviceFingerprint);
  }

  /// Save remember device preference
  Future<void> saveRememberDevice(bool remember) async {
    await _secureStorage.write(
      key: StorageConstants.rememberDevice,
      value: remember.toString(),
    );
  }

  /// Get remember device preference
  Future<bool> getRememberDevice() async {
    final value =
        await _secureStorage.read(key: StorageConstants.rememberDevice);
    return value?.toLowerCase() == 'true';
  }

  // ====================
  // BASIC OFFLINE LOGIN DATA (Guards Only)
  // ====================

  /// Save basic offline login data for guards (authentication only)
  Future<void> saveBasicOfflineLoginData(Map<String, dynamic> data) async {
    final dataJson = jsonEncode(data);
    await _secureStorage.write(
        key: StorageConstants.offlineLoginData, value: dataJson);
  }

  /// Get basic offline login data for guards
  Future<Map<String, dynamic>?> getBasicOfflineLoginData() async {
    try {
      final dataJson =
          await _secureStorage.read(key: StorageConstants.offlineLoginData);
      if (dataJson != null) {
        return jsonDecode(dataJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Check if basic offline login is available for guards
  Future<bool> hasBasicOfflineLoginData(String employeeId) async {
    try {
      final offlineData = await getBasicOfflineLoginData();
      if (offlineData == null) return false;

      final userData = offlineData['user'] as Map<String, dynamic>?;
      if (userData == null) return false;

      final user = UserModel.fromJson(userData);

      // Check if it's the same employee and if data is still valid
      if (user.employeeId == employeeId) {
        final loginTimeStr = offlineData['loginTime'] as String?;
        if (loginTimeStr != null) {
          final loginTime = DateTime.parse(loginTimeStr);
          final daysSinceLogin = DateTime.now().difference(loginTime).inDays;
          return daysSinceLogin <= AppConstants.offlineLoginValidityDays;
        }
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  /// Get offline user data if available and valid
  Future<UserModel?> getOfflineUserData(String employeeId) async {
    try {
      final hasOfflineData = await hasBasicOfflineLoginData(employeeId);
      if (!hasOfflineData) return null;

      final offlineData = await getBasicOfflineLoginData();
      if (offlineData == null) return null;

      final userData = offlineData['user'] as Map<String, dynamic>?;
      if (userData == null) return null;

      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // ====================
  // AUTHENTICATION STATUS
  // ====================

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    final expiry = await getTokenExpiry();

    if (token == null || token.isEmpty) {
      return false;
    }

    // Check if token is expired
    if (expiry != null && DateTime.now().isAfter(expiry)) {
      await clear(); // Clear expired token
      return false;
    }

    return true;
  }

  /// Check if token is expired
  Future<bool> isTokenExpired() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return true;

    return DateTime.now().isAfter(expiry);
  }

  /// Get time until token expires
  Future<Duration?> getTimeUntilExpiry() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return null;

    final now = DateTime.now();
    if (now.isAfter(expiry)) return Duration.zero;

    return expiry.difference(now);
  }

  /// Check if token needs refresh (within threshold minutes of expiry)
  Future<bool> needsTokenRefresh() async {
    final timeUntilExpiry = await getTimeUntilExpiry();
    if (timeUntilExpiry == null) return true;

    return timeUntilExpiry.inMinutes <
        AppConstants.tokenRefreshThresholdMinutes;
  }

  /// Check if device should remember user (for guards)
  Future<bool> shouldRememberDevice() async {
    final lastEmployeeId = await getLastEmployeeId();
    final loginType = await getLoginType();
    final rememberDevice = await getRememberDevice();
    return lastEmployeeId != null &&
        loginType == AppConstants.guardLoginType &&
        rememberDevice;
  }

  // ====================
  // COMPREHENSIVE AUTH DATA MANAGEMENT
  // ====================

  /// Save complete authentication data from login response
  Future<void> saveAuthData({
    required String token,
    required UserModel user,
    required int expiresIn,
    String? refreshToken,
  }) async {
    final now = DateTime.now();

    await saveToken(token);
    await saveUserData(user);
    await saveSessionStartTime(now);
    await saveLastActivityTime(now);

    final expiryTime = now.add(Duration(seconds: expiresIn));
    await saveTokenExpiry(expiryTime);

    if (refreshToken != null) {
      await saveRefreshToken(refreshToken);
    }

    // Save login type based on user role
    if (user.isGuard) {
      await saveLoginType(AppConstants.guardLoginType);

      // Save basic offline login data for guards (authentication only)
      final basicOfflineData = {
        'user': user.toJson(),
        'token': token,
        'expiresAt': expiryTime.toIso8601String(),
        'loginTime': now.toIso8601String(),
      };
      await saveBasicOfflineLoginData(basicOfflineData);
    } else if (user.isAdmin) {
      await saveLoginType(AppConstants.adminLoginType);
    } else if (user.isManager) {
      await saveLoginType(AppConstants.managerLoginType);
    }

    // Update last online sync time
    await saveLastOnlineSync(now);
  }

  // ====================
  // SESSION MANAGEMENT ADVANCED
  // ====================

  /// Session timeout management
  Future<void> extendSession() async {
    final expiry = await getTokenExpiry();
    if (expiry != null) {
      // Extend session by the specified hours
      final newExpiry = DateTime.now().add(
        const Duration(hours: AppConstants.sessionExtensionHours),
      );
      await saveTokenExpiry(newExpiry);
      await _secureStorage.write(
        key: StorageConstants.sessionExtended,
        value: DateTime.now().toIso8601String(),
      );
    }
  }

  /// Check session activity and auto-logout if inactive
  Future<bool> checkSessionActivity() async {
    final expiry = await getTokenExpiry();
    if (expiry == null) return false;

    final now = DateTime.now();
    if (now.isAfter(expiry)) {
      await clear();
      return false;
    }

    // Auto-extend session if user is active and close to expiry
    if (expiry.difference(now).inHours < AppConstants.sessionExtensionHours) {
      await extendSession();
    }

    // Update last activity time
    await saveLastActivityTime(now);

    return true;
  }

  /// Get session duration
  Future<Duration?> getSessionDuration() async {
    final sessionStart = await getSessionStartTime();
    if (sessionStart == null) return null;

    return DateTime.now().difference(sessionStart);
  }

  /// Check if session was extended
  Future<bool> wasSessionExtended() async {
    final extendedTime =
        await _secureStorage.read(key: StorageConstants.sessionExtended);
    return extendedTime != null;
  }

  // ====================
  // UTILITY METHODS
  // ====================

  /// Validate token format (basic validation)
  bool isValidTokenFormat(String? token) {
    if (token == null || token.isEmpty) return false;

    // Basic token format validation for Laravel Sanctum tokens: "1|randomstring"
    return token.contains('|') && token.length > 10;
  }

  /// Update user data (useful after profile updates)
  Future<void> updateUserData(UserModel user) async {
    await saveUserData(user);
    await saveLastActivityTime(DateTime.now());
  }

  /// Check if stored data exists
  Future<bool> hasStoredAuthData() async {
    final token = await getToken();
    final userId = await getUserId();
    return token != null && userId != null;
  }

  /// Get basic auth info for debugging/UI
  Future<Map<String, dynamic>> getAuthInfo() async {
    final token = await getToken();
    final user = await getUserData();
    final expiry = await getTokenExpiry();
    final isExpired = await isTokenExpired();
    final loginType = await getLoginType();
    final lastEmployeeId = await getLastEmployeeId();
    final sessionStart = await getSessionStartTime();
    final lastActivity = await getLastActivityTime();

    return {
      'hasToken': token != null,
      'hasUser': user != null,
      'isExpired': isExpired,
      'expiresAt': expiry?.toIso8601String(),
      'userId': user?.id,
      'userRole': user?.role,
      'userEmail': user?.email,
      'loginType': loginType,
      'lastEmployeeId': lastEmployeeId,
      'shouldRememberDevice': await shouldRememberDevice(),
      'sessionStartTime': sessionStart?.toIso8601String(),
      'lastActivityTime': lastActivity?.toIso8601String(),
      'hasOfflineData': await hasBasicOfflineLoginData(lastEmployeeId ?? ''),
    };
  }

  /// Force refresh of stored data
  Future<void> refreshStoredData() async {
    final user = await getUserData();
    if (user != null) {
      await saveUserData(user);
    }
    await saveLastActivityTime(DateTime.now());
  }

  /// Get user-specific storage key
  String getUserSpecificKey(String baseKey) {
    return StorageConstants.getUserKey(baseKey, 'current');
  }

  /// Save user-specific data
  Future<void> saveUserSpecificData(String key, String value) async {
    final userSpecificKey = getUserSpecificKey(key);
    await _secureStorage.write(key: userSpecificKey, value: value);
  }

  /// Get user-specific data
  Future<String?> getUserSpecificData(String key) async {
    final userSpecificKey = getUserSpecificKey(key);
    return await _secureStorage.read(key: userSpecificKey);
  }

  /// Backup current auth data
  Future<void> backupAuthData() async {
    final authData = await getAuthInfo();
    final backupKey = StorageConstants.getBackupKey('auth_data');
    await _secureStorage.write(key: backupKey, value: jsonEncode(authData));
  }

  /// Get all stored keys (for debugging)
  Future<Map<String, String?>> getAllStoredData() async {
    final Map<String, String?> allData = {};

    for (final key in StorageConstants.secureStorageKeys) {
      allData[key] = await _secureStorage.read(key: key);
    }

    return allData;
  }

  // ====================
  // CLEANUP METHODS
  // ====================

  /// Clear specific storage keys
  Future<void> _clearKey(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clear authentication token
  Future<void> clearToken() async {
    await _clearKey(StorageConstants.bearerToken);
  }

  /// Clear user ID
  Future<void> clearUserId() async {
    await _clearKey(StorageConstants.userId);
  }

  /// Clear user data
  Future<void> clearUserData() async {
    await _clearKey(StorageConstants.userData);
  }

  /// Clear token expiry
  Future<void> clearTokenExpiry() async {
    await _clearKey(StorageConstants.tokenExpiry);
  }

  /// Clear refresh token
  Future<void> clearRefreshToken() async {
    await _clearKey(StorageConstants.refreshToken);
  }

  /// Clear login type
  Future<void> clearLoginType() async {
    await _clearKey(StorageConstants.loginType);
  }

  /// Clear last employee ID
  Future<void> clearLastEmployeeId() async {
    await _clearKey(StorageConstants.lastEmployeeId);
  }

  /// Clear session data
  Future<void> clearSessionData() async {
    await Future.wait([
      _clearKey(StorageConstants.sessionStartTime),
      _clearKey(StorageConstants.lastActivityTime),
      _clearKey(StorageConstants.sessionExtended),
    ]);
  }

  /// Clear device data
  Future<void> clearDeviceData() async {
    await Future.wait([
      _clearKey(StorageConstants.deviceId),
      _clearKey(StorageConstants.deviceFingerprint),
      _clearKey(StorageConstants.rememberDevice),
    ]);
  }

  /// Clear basic offline login data
  Future<void> clearBasicOfflineLoginData() async {
    await _clearKey(StorageConstants.offlineLoginData);
  }

  /// Clear all authentication data (call on logout)
  Future<void> clear() async {
    await Future.wait([
      clearToken(),
      clearUserId(),
      clearUserData(),
      clearTokenExpiry(),
      clearRefreshToken(),
      clearLoginType(),
      clearSessionData(),
      // Note: We keep lastEmployeeId and basic offline data unless explicitly cleared
    ]);
  }

  /// Complete clear including basic offline data (when user chooses to clear saved data)
  Future<void> clearAll() async {
    // Clear all auth-related keys
    final futures = StorageConstants.authKeys.map((key) => _clearKey(key));
    await Future.wait(futures);

    // Also clear device and session data
    await clearDeviceData();
    await clearSessionData();
  }

  /// Clear only basic offline data
  Future<void> clearOfflineData() async {
    await clearBasicOfflineLoginData();
  }
}
