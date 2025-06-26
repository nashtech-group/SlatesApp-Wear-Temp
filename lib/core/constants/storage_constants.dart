// lib/core/constants/storage_constants.dart
class StorageConstants {
  // ====================
  // SECURE STORAGE KEYS
  // ====================
  
  // Authentication tokens
  static const String bearerToken = 'bearer_token';
  static const String refreshToken = 'refresh_token';
  static const String tokenExpiry = 'token_expiry';
  
  // User data
  static const String userId = 'user_id';
  static const String userData = 'user_data';
  static const String userRole = 'user_role';
  
  // Login preferences
  static const String loginType = 'login_type';
  static const String lastEmployeeId = 'last_employee_id';
  static const String rememberDevice = 'remember_device';
  
  // Offline data
  static const String offlineLoginData = 'offline_login_data';
  static const String offlineUserData = 'offline_user_data';
  static const String lastOnlineSync = 'last_online_sync';
  
  // Session management
  static const String sessionStartTime = 'session_start_time';
  static const String lastActivityTime = 'last_activity_time';
  static const String sessionExtended = 'session_extended';
  
  // Device specific
  static const String deviceId = 'device_id';
  static const String deviceFingerprint = 'device_fingerprint';
  
  // Guard duty data
  static const String pendingMovements = 'pending_movements';
  static const String pendingPerimeterChecks = 'pending_perimeter_checks';
  static const String pendingRosterUpdates = 'pending_roster_updates';
  static const String lastDutySync = 'last_duty_sync';
  
  // App security
  static const String appLockEnabled = 'app_lock_enabled';
  static const String biometricAuthEnabled = 'biometric_auth_enabled';
  static const String pinAuthEnabled = 'pin_auth_enabled';
  static const String autoLockTimeout = 'auto_lock_timeout';
  
  // ====================
  // SHARED PREFERENCES KEYS
  // ====================
  
  // App preferences
  static const String isFirstLaunch = 'is_first_launch';
  static const String appLanguage = 'app_language';
  static const String themeMode = 'theme_mode';
  static const String appVersion = 'app_version';
  
  // User preferences
  static const String notificationsEnabled = 'notifications_enabled';
  static const String soundEnabled = 'sound_enabled';
  static const String vibrationEnabled = 'vibration_enabled';
  static const String autoLoginEnabled = 'auto_login_enabled';
  static const String rememberLastUser = 'remember_last_user';
  
  // Wearable specific
  static const String keepScreenOn = 'keep_screen_on';
  static const String hapticFeedbackEnabled = 'haptic_feedback_enabled';
  static const String alwaysOnDisplay = 'always_on_display';
  static const String quickActionsEnabled = 'quick_actions_enabled';
  
  // Location & GPS
  static const String locationPermissionGranted = 'location_permission_granted';
  static const String gpsEnabled = 'gps_enabled';
  static const String locationAccuracy = 'location_accuracy';
  static const String backgroundLocationEnabled = 'background_location_enabled';
  
  // Guard duty preferences
  static const String autoSyncEnabled = 'auto_sync_enabled';
  static const String syncInterval = 'sync_interval';
  static const String offlineModeEnabled = 'offline_mode_enabled';
  static const String autoCheckIn = 'auto_check_in';
  static const String movementTrackingEnabled = 'movement_tracking_enabled';
  
  // Data usage
  static const String wifiOnlySync = 'wifi_only_sync';
  static const String dataCompressionEnabled = 'data_compression_enabled';
  static const String lowDataMode = 'low_data_mode';
  
  // ====================
  // CACHE KEYS
  // ====================
  
  // User cache
  static const String userCache = 'user_cache';
  static const String userProfileCache = 'user_profile_cache';
  static const String userPermissionsCache = 'user_permissions_cache';
  static const String userPreferencesCache = 'user_preferences_cache';
  
  // App data cache
  static const String rosterCache = 'roster_cache';
  static const String sitesCache = 'sites_cache';
  static const String checkpointsCache = 'checkpoints_cache';
  static const String movementsCache = 'movements_cache';
  static const String perimeterChecksCache = 'perimeter_checks_cache';
  static const String dutyScheduleCache = 'duty_schedule_cache';
  
  // API cache
  static const String apiResponseCache = 'api_response_cache';
  static const String tokenCache = 'token_cache';
  static const String configCache = 'config_cache';
  
  // Sync cache
  static const String lastSyncTime = 'last_sync_time';
  static const String syncStatus = 'sync_status';
  static const String pendingSyncItems = 'pending_sync_items';
  static const String failedSyncItems = 'failed_sync_items';
  
  // Configuration cache
  static const String appConfigCache = 'app_config_cache';
  static const String serverConfigCache = 'server_config_cache';
  static const String featureFlagsCache = 'feature_flags_cache';
  
  // ====================
  // STORAGE PREFIXES
  // ====================
  
  // Prefix for user-specific data
  static const String userPrefix = 'user_';
  
  // Prefix for guard-specific data
  static const String guardPrefix = 'guard_';
  
  // Prefix for admin-specific data
  static const String adminPrefix = 'admin_';
  
  // Prefix for temporary data
  static const String tempPrefix = 'temp_';
  
  // Prefix for backup data
  static const String backupPrefix = 'backup_';
  
  // Prefix for cache data
  static const String cachePrefix = 'cache_';
  
  // Prefix for encrypted data
  static const String encryptedPrefix = 'encrypted_';
  
  // ====================
  // HELPER METHODS
  // ====================
  
  /// Get user-specific key
  static String getUserKey(String baseKey, String userId) {
    return '${userPrefix}${userId}_$baseKey';
  }
  
  /// Get guard-specific key
  static String getGuardKey(String baseKey, String guardId) {
    return '${guardPrefix}${guardId}_$baseKey';
  }
  
  /// Get admin-specific key
  static String getAdminKey(String baseKey, String adminId) {
    return '${adminPrefix}${adminId}_$baseKey';
  }
  
  /// Get temporary key with timestamp
  static String getTempKey(String baseKey) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${tempPrefix}${timestamp}_$baseKey';
  }
  
  /// Get backup key with timestamp
  static String getBackupKey(String baseKey) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${backupPrefix}${timestamp}_$baseKey';
  }
  
  /// Get cache key with prefix
  static String getCacheKey(String baseKey) {
    return '$cachePrefix$baseKey';
  }
  
  /// Get encrypted data key
  static String getEncryptedKey(String baseKey) {
    return '$encryptedPrefix$baseKey';
  }
  
  /// Get versioned key for data migration
  static String getVersionedKey(String baseKey, int version) {
    return '${baseKey}_v$version';
  }
  
  /// Get time-based key for expiring data
  static String getTimeBasedKey(String baseKey, Duration validity) {
    final expiryTime = DateTime.now().add(validity).millisecondsSinceEpoch;
    return '${baseKey}_expires_$expiryTime';
  }
  
  // ====================
  // STORAGE CATEGORIES
  // ====================
  
  /// All secure storage keys
  static const List<String> secureStorageKeys = [
    bearerToken,
    refreshToken,
    tokenExpiry,
    userId,
    userData,
    userRole,
    loginType,
    lastEmployeeId,
    rememberDevice,
    offlineLoginData,
    offlineUserData,
    lastOnlineSync,
    sessionStartTime,
    lastActivityTime,
    sessionExtended,
    deviceId,
    deviceFingerprint,
    pendingMovements,
    pendingPerimeterChecks,
    pendingRosterUpdates,
    lastDutySync,
    appLockEnabled,
    biometricAuthEnabled,
    pinAuthEnabled,
    autoLockTimeout,
  ];
  
  /// All shared preferences keys
  static const List<String> sharedPreferencesKeys = [
    isFirstLaunch,
    appLanguage,
    themeMode,
    appVersion,
    notificationsEnabled,
    soundEnabled,
    vibrationEnabled,
    autoLoginEnabled,
    rememberLastUser,
    keepScreenOn,
    hapticFeedbackEnabled,
    alwaysOnDisplay,
    quickActionsEnabled,
    locationPermissionGranted,
    gpsEnabled,
    locationAccuracy,
    backgroundLocationEnabled,
    autoSyncEnabled,
    syncInterval,
    offlineModeEnabled,
    autoCheckIn,
    movementTrackingEnabled,
    wifiOnlySync,
    dataCompressionEnabled,
    lowDataMode,
  ];
  
  /// All cache keys
  static const List<String> cacheKeys = [
    userCache,
    userProfileCache,
    userPermissionsCache,
    userPreferencesCache,
    rosterCache,
    sitesCache,
    checkpointsCache,
    movementsCache,
    perimeterChecksCache,
    dutyScheduleCache,
    apiResponseCache,
    tokenCache,
    configCache,
    lastSyncTime,
    syncStatus,
    pendingSyncItems,
    failedSyncItems,
    appConfigCache,
    serverConfigCache,
    featureFlagsCache,
  ];
  
  /// Auth-related keys
  static const List<String> authKeys = [
    bearerToken,
    refreshToken,
    tokenExpiry,
    userId,
    userData,
    userRole,
    loginType,
    lastEmployeeId,
    offlineLoginData,
    sessionStartTime,
    lastActivityTime,
    deviceId,
    deviceFingerprint,
  ];
  
  /// Offline-related keys
  static const List<String> offlineKeys = [
    offlineLoginData,
    offlineUserData,
    lastOnlineSync,
    pendingMovements,
    pendingPerimeterChecks,
    pendingRosterUpdates,
    lastDutySync,
    offlineModeEnabled,
    pendingSyncItems,
    failedSyncItems,
  ];
  
  /// Guard duty related keys
  static const List<String> guardDutyKeys = [
    pendingMovements,
    pendingPerimeterChecks,
    pendingRosterUpdates,
    lastDutySync,
    movementTrackingEnabled,
    autoCheckIn,
    dutyScheduleCache,
    movementsCache,
    perimeterChecksCache,
  ];
  
  /// Security related keys
  static const List<String> securityKeys = [
    appLockEnabled,
    biometricAuthEnabled,
    pinAuthEnabled,
    autoLockTimeout,
    deviceFingerprint,
    sessionStartTime,
    lastActivityTime,
    sessionExtended,
  ];
  
  /// Wearable specific keys
  static const List<String> wearableKeys = [
    keepScreenOn,
    hapticFeedbackEnabled,
    alwaysOnDisplay,
    quickActionsEnabled,
    soundEnabled,
    vibrationEnabled,
  ];
  
  // ====================
  // VALIDATION METHODS
  // ====================
  
  /// Check if key is a secure storage key
  static bool isSecureStorageKey(String key) {
    return secureStorageKeys.contains(key);
  }
  
  /// Check if key is a shared preferences key
  static bool isSharedPreferencesKey(String key) {
    return sharedPreferencesKeys.contains(key);
  }
  
  /// Check if key is a cache key
  static bool isCacheKey(String key) {
    return cacheKeys.contains(key);
  }
  
  /// Check if key is auth-related
  static bool isAuthKey(String key) {
    return authKeys.contains(key);
  }
  
  /// Check if key is offline-related
  static bool isOfflineKey(String key) {
    return offlineKeys.contains(key);
  }
  
  /// Get all keys in a category
  static List<String> getKeysByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'secure':
        return secureStorageKeys;
      case 'preferences':
        return sharedPreferencesKeys;
      case 'cache':
        return cacheKeys;
      case 'auth':
        return authKeys;
      case 'offline':
        return offlineKeys;
      case 'guard':
        return guardDutyKeys;
      case 'security':
        return securityKeys;
      case 'wearable':
        return wearableKeys;
      default:
        return [];
    }
  }
}