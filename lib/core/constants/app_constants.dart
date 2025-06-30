class AppConstants {
  // ====================
  // APP INFORMATION
  // ====================
  static const String appTitle = 'SlatesApp Wear';
  static const String appSubtitle = 'Security Operations Platform';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String defaultLanguage = 'en';
  static const String supportEmail = 'support@slatestech.com';
  static const String companyName = 'SlatesTech';

  // ====================
  // UI/UX CONSTANTS
  // ====================
  static const int splashScreenDuration = 3; // in seconds
  static const String dateFormat = 'dd-MM-yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd-MM-yyyy HH:mm';
  static const String shortDateFormat = 'dd/MM';
  static const String longDateFormat = 'EEEE, MMMM dd, yyyy';

  // Animation durations
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 300; // milliseconds
  static const int longAnimationDuration = 500; // milliseconds

  // ====================
  // USER ROLES & PERMISSIONS
  // ====================

  // Primary roles
  static const String guardRole = 'guard';
  static const String adminRole = 'admin';
  static const String managerRole = 'manager';
  static const String supervisorRole = 'supervisor';

  // Extended roles (if needed for future expansion)
  static const String executiveRole = 'executive';
  static const String managementRole = 'management';
  static const String lowerManagementRole = 'lower-management';
  static const String generalRole = 'general';

  // Login types
  static const String guardLoginType = 'guard';
  static const String adminLoginType = 'admin';
  static const String managerLoginType = 'manager';

  // ====================
  // SECURITY & AUTHENTICATION
  // ====================

  // Session management
  static const int offlineLoginValidityDays = 7;
  static const int sessionExtensionHours = 2;
  static const int tokenRefreshThresholdMinutes = 30;
  static const int maxLoginAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int sessionTimeoutMinutes = 60;
  static const int autoLockTimeoutSeconds = 300; // 5 minutes

  // PIN & Password validation
  static const int pinLength = 4;
  static const int minPasswordLength = 4;
  static const int maxPasswordLength = 4; // PIN is exactly 4 digits
  static const int maxIdentifierLength = 20;

  // Device security
  static const int maxDevicesPerUser = 3;
  static const bool requireDeviceVerification = true;
  static const int deviceTrustDurationDays = 30;

  // ====================
  // NETWORK & API
  // ====================

  // Retry & timeout settings
  static const int maxRetryAttempts = 3;
  static const int networkTimeoutSeconds = 30;
  static const int apiTimeoutSeconds = 60;
  static const int uploadTimeoutSeconds = 120;
  static const int downloadTimeoutSeconds = 300;

  // Cache settings
  static const int cacheExpirationHours = 24;
  static const int maxCacheSize = 50; // MB
  static const int imageCacheExpirationDays = 7;

  // ====================
  // LOCATION & GPS
  // ====================
  static const int locationUpdateIntervalSeconds = 30;
  static const double geofenceRadiusMeters = 100.0;
  static const double highAccuracyThreshold = 10.0; // meters
  static const double mediumAccuracyThreshold = 50.0; // meters
  static const int locationTimeoutSeconds = 30;
  static const int maxLocationAge = 60; // seconds

  // Movement tracking
  static const double minimumMovementDistance = 5.0; // meters
  static const int movementUpdateInterval = 15; // seconds
  static const double walkingSpeedThreshold = 1.4; // m/s
  static const double runningSpeedThreshold = 3.0; // m/s

  // ====================
  // GUARD DUTY SETTINGS
  // ====================

  // Batch processing limits
  static const int maxMovementsPerBatch = 200;
  static const int maxPerimeterChecksPerBatch = 50;
  static const int maxRosterUpdatesPerBatch = 100;
  static const int maxTotalOperationsPerBatch = 300;

  // Sync settings
  static const int autoSyncIntervalMinutes = 15;
  static const int offlineSyncRetryAttempts = 5;
  static const int syncBatchSize = 25;
  static const int maxOfflineDataAgeHours = 24;

  // Check-in settings
  static const int checkInReminderMinutes = 15;
  static const int missedCheckInTimeoutMinutes = 30;
  static const int emergencyAlertTimeoutMinutes = 5;

  // ====================
  // STATUS VALUES
  // ====================

  // Roster status
  static const int presentStatus = 1;
  static const int absentStatus = 0;
  static const int pendingStatus = -1;
  static const int presentButLeftEarlyStatus = 2;
  static const int absentWithoutPermissionStatus = -2;
  static const int presentButLateStatus = 3;
  static const int presentButLateAndLeftEarlyStatus = 4;

  // User status
  static const String activeStatus = 'active';
  static const String inactiveStatus = 'inactive';
  static const String suspendedStatus = 'suspended';
  static const String pendingApprovalStatus = 'pending';

  // ====================
  // MOVEMENT TYPES
  // ====================
  static const String patrolMovement = 'patrol';
  static const String checkpointMovement = 'checkpoint';
  static const String breakMovement = 'break';
  static const String emergencyMovement = 'emergency';
  static const String idleMovement = 'idle';
  static const String transitMovement = 'transit';
  static const String shiftStartMovement = 'shift_start';
  static const String shiftEndMovement = 'shift_end';

  // ====================
  // NOTIFICATION TYPES
  // ====================
  static const String dutyReminderNotification = 'duty_reminder';
  static const String checkInReminderNotification = 'checkin_reminder';
  static const String emergencyAlertNotification = 'emergency_alert';
  static const String systemUpdateNotification = 'system_update';
  static const String batteryLowNotification = 'battery_low';
  static const String offlineModeNotification = 'offline_mode';

  // ====================
  // ERROR MESSAGES
  // ====================
  static const String networkErrorMessage =
      'Please check your internet connection and try again';
  static const String serverErrorMessage =
      'Something went wrong on our end. Please try again later';
  static const String unauthorizedMessage =
      'You are not authorized to perform this action';
  static const String validationErrorMessage =
      'Please check your input and try again';
  static const String unknownErrorMessage =
      'An unexpected error occurred. Please contact support';
  static const String offlineLoginUnavailable =
      'Offline login is only available for security guards';
  static const String noOfflineDataMessage =
      'No offline login data found. Please connect to internet to login';
  static const String expiredOfflineDataMessage =
      'Offline data has expired. Please connect to internet to continue';
  static const String sessionExpiredMessage =
      'Your session has expired. Please login again';
  static const String accountLockedMessage =
      'Account temporarily locked due to multiple failed attempts';
  static const String deviceNotTrustedMessage =
      'This device is not trusted. Please verify your identity';
  static const String locationPermissionMessage =
      'Location permission is required for guard duties';
  static const String gpsNotAvailableMessage =
      'GPS is not available. Please enable location services';

  // ====================
  // SUCCESS MESSAGES
  // ====================
  static const String loginSuccessMessage = 'Login successful';
  static const String logoutSuccessMessage = 'Logout successful';
  static const String profileUpdatedMessage = 'Profile updated successfully';
  static const String offlineLoginSuccessMessage =
      'Logged in using offline mode';
  static const String datasClearedMessage = 'Saved data cleared successfully';
  static const String syncSuccessMessage = 'Data synchronized successfully';
  static const String checkInSuccessMessage = 'Check-in recorded successfully';
  static const String movementRecordedMessage =
      'Movement recorded successfully';
  static const String dutyStartedMessage = 'Duty started successfully';
  static const String dutyEndedMessage = 'Duty ended successfully';

  // ====================
  // WEARABLE SPECIFIC
  // ====================

  // Screen settings
  static const bool defaultKeepScreenOn = true;
  static const bool defaultAlwaysOnDisplay = true;
  static const int screenBrightness = 80; // percentage

  // Haptic feedback
  static const bool defaultHapticEnabled = true;
  static const int lightHapticDuration = 10; // milliseconds
  static const int mediumHapticDuration = 20; // milliseconds
  static const int strongHapticDuration = 30; // milliseconds

  // Quick actions
  static const int maxQuickActions = 4;
  static const bool defaultQuickActionsEnabled = true;

  // Battery optimization
  static const int lowBatteryThreshold = 20; // percentage
  static const int criticalBatteryThreshold = 10; // percentage
  static const bool enableBatterySaverMode = true;

  // ====================
  // DATA LIMITS & VALIDATION
  // ====================

  // File upload limits
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 50;
  static const int maxDocumentSizeMB = 10;

  // Text limits
  static const int maxNotesLength = 500;
  static const int maxCommentLength = 250;
  static const int maxNameLength = 50;
  static const int maxEmailLength = 100;

  // Data retention
  static const int movementDataRetentionDays = 90;
  static const int logDataRetentionDays = 30;
  static const int cacheDataRetentionDays = 7;

  // ====================
  // FEATURE FLAGS
  // ====================
  static const bool enableBiometricAuth = true;
  static const bool enableOfflineMode = true;
  static const bool enableLocationTracking = true;
  static const bool enablePushNotifications = true;
  static const bool enableDataCompression = true;
  static const bool enableCrashReporting = true;
  static const bool enableAnalytics = false; // Privacy-focused default

  // ====================
  // HELPER METHODS
  // ====================

  /// Get all available roles
  static List<String> getAllRoles() {
    return [
      guardRole,
      adminRole,
      managerRole,
      supervisorRole,
    ];
  }

  /// Get all movement types
  static List<String> getAllMovementTypes() {
    return [
      patrolMovement,
      checkpointMovement,
      breakMovement,
      emergencyMovement,
      idleMovement,
      transitMovement,
      shiftStartMovement,
      shiftEndMovement,
    ];
  }

  /// Get all status values
  static List<int> getAllStatusValues() {
    return [
      presentStatus,
      absentStatus,
      pendingStatus,
      presentButLeftEarlyStatus,
      absentWithoutPermissionStatus,
      presentButLateStatus,
      presentButLateAndLeftEarlyStatus,
    ];
  }

  /// Check if role has admin privileges
  static bool hasAdminPrivileges(String role) {
    return [adminRole, managerRole, supervisorRole]
        .contains(role.toLowerCase());
  }

  /// Check if role is guard
  static bool isGuardRole(String role) {
    return role.toLowerCase() == guardRole;
  }

  /// Get display name for role
  static String getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
      case guardRole:
        return 'Security Guard';
      case adminRole:
        return 'Administrator';
      case managerRole:
        return 'Manager';
      case supervisorRole:
        return 'Supervisor';
      default:
        return role
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
            .join(' ');
    }
  }

  /// Get status display name
  static String getStatusDisplayName(int status) {
    switch (status) {
      case presentStatus:
        return 'Present';
      case absentStatus:
        return 'Absent';
      case pendingStatus:
        return 'Pending';
      case presentButLeftEarlyStatus:
        return 'Present (Left Early)';
      case absentWithoutPermissionStatus:
        return 'Absent Without Permission';
      case presentButLateStatus:
        return 'Present (Late)';
      case presentButLateAndLeftEarlyStatus:
        return 'Present (Late & Left Early)';
      default:
        return 'Unknown';
    }
  }

  /// Get movement type display name
  static String getMovementTypeDisplayName(String movementType) {
    switch (movementType.toLowerCase()) {
      case patrolMovement:
        return 'Patrol';
      case checkpointMovement:
        return 'Checkpoint';
      case breakMovement:
        return 'Break';
      case emergencyMovement:
        return 'Emergency';
      case idleMovement:
        return 'Idle';
      case transitMovement:
        return 'Transit';
      case shiftStartMovement:
        return 'Shift Start';
      case shiftEndMovement:
        return 'Shift End';
      default:
        return movementType
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? word[0].toUpperCase() + word.substring(1).toLowerCase()
                : '')
            .join(' ');
    }
  }

  /// Check if app version is compatible
  static bool isCompatibleVersion(String version) {
    // Simple version compatibility check
    // In production, implement proper semantic versioning comparison
    return version == appVersion;
  }

  /// Get formatted app version
  static String getFormattedVersion() {
    return '$appVersion ($buildNumber)';
  }
}
