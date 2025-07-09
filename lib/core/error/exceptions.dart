// lib/core/error/exceptions.dart
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';

/// Base interface for all application exceptions
/// Provides common properties and behavior
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final DateTime timestamp;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const DateTime.now();

  @override
  String toString() => 'AppException: $message';

  /// Get user-friendly message using constants
  String get userMessage => _getUserFriendlyMessage();

  /// Check if this exception is retryable
  bool get isRetryable => _isRetryable();

  /// Check if this exception indicates network issues
  bool get isNetworkRelated => _isNetworkRelated();

  /// Check if this exception should trigger offline mode
  bool get shouldTriggerOfflineMode => _shouldTriggerOfflineMode();

  /// Check if this exception should logout user
  bool get shouldLogoutUser => _shouldLogoutUser();

  /// Get error category for logging/analytics
  String get errorCategory => _getErrorCategory();

  /// Private helper methods
  String _getUserFriendlyMessage() {
    if (statusCode != null) {
      return AppConstants.getErrorMessageForStatusCode(statusCode!);
    }
    return message.isNotEmpty ? message : AppConstants.unknownErrorMessage;
  }

  bool _isRetryable() {
    if (statusCode != null) {
      return ApiConstants.isRetryableStatusCode(statusCode!);
    }
    return this is NetworkException || this is TimeoutException || this is ServerException;
  }

  bool _isNetworkRelated() {
    return this is NetworkException || this is TimeoutException;
  }

  bool _shouldTriggerOfflineMode() {
    return isNetworkRelated || (statusCode != null && ApiConstants.isServerError(statusCode!));
  }

  bool _shouldLogoutUser() {
    return this is AuthException && 
           (statusCode == ApiConstants.unauthorizedCode || 
            message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('invalid token'));
  }

  String _getErrorCategory() {
    if (this is NetworkException) return 'Network';
    if (this is AuthException) return 'Authentication';
    if (this is ValidationException) return 'Validation';
    if (this is ServerException) return 'Server';
    if (this is CacheException) return 'Cache';
    if (this is TimeoutException) return 'Timeout';
    return 'Unknown';
  }
}

/// Server-related exceptions
class ServerException extends AppException {
  const ServerException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.serverErrorMessage,
        );

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Network-related exceptions
class NetworkException extends AppException {
  const NetworkException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.networkErrorMessage,
        );

  @override
  String toString() => 'NetworkException: $message';
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.cacheErrorMessage,
        );

  @override
  String toString() => 'CacheException: $message';
}

/// Validation-related exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? validationErrors;

  const ValidationException({
    String? message,
    super.statusCode,
    super.data,
    this.validationErrors,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.validationErrorMessage,
        );

  @override
  String toString() => 'ValidationException: $message';

  /// Get first validation error message
  String? get firstValidationError {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      final firstFieldErrors = validationErrors!.values.first;
      return firstFieldErrors.isNotEmpty ? firstFieldErrors.first : null;
    }
    return null;
  }

  /// Get all validation messages as a single string
  String get allValidationMessages {
    if (validationErrors == null || validationErrors!.isEmpty) {
      return message;
    }
    
    final messages = <String>[];
    validationErrors!.forEach((field, fieldErrors) {
      messages.addAll(fieldErrors);
    });
    
    return messages.isNotEmpty ? messages.join(', ') : message;
  }

  /// Check if has validation errors for specific field
  bool hasErrorsForField(String field) {
    return validationErrors?.containsKey(field) == true &&
           validationErrors![field]!.isNotEmpty;
  }

  /// Get validation errors for specific field
  List<String>? getErrorsForField(String field) {
    return validationErrors?[field];
  }
}

/// Authentication and authorization related exceptions
class AuthException extends AppException {
  const AuthException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.unauthorizedMessage,
        );

  @override
  String toString() => 'AuthException: $message';
}

/// Specific authentication exceptions with predefined messages from constants
class UnauthorizedException extends AuthException {
  const UnauthorizedException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.unauthorizedMessage,
          statusCode: ApiConstants.unauthorizedCode,
        );
}

class ForbiddenException extends AuthException {
  const ForbiddenException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.forbiddenMessage,
          statusCode: ApiConstants.forbiddenCode,
        );
}

class SessionExpiredException extends AuthException {
  const SessionExpiredException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.sessionExpiredMessage,
          statusCode: ApiConstants.unauthorizedCode,
        );
}

class AccountLockedException extends AuthException {
  const AccountLockedException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.accountLockedMessage,
          statusCode: ApiConstants.forbiddenCode,
        );
}

/// Resource not found exception
class NotFoundException extends AppException {
  const NotFoundException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.notFoundMessage,
          statusCode: ApiConstants.notFoundCode,
        );

  @override
  String toString() => 'NotFoundException: $message';
}

/// Timeout-related exceptions
class TimeoutException extends NetworkException {
  const TimeoutException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.connectionTimeoutMessage,
          statusCode: null,
        );

  @override
  String toString() => 'TimeoutException: $message';
}

/// Rate limiting exception
class RateLimitException extends ServerException {
  const RateLimitException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.tooManyRequestsMessage,
          statusCode: ApiConstants.tooManyRequestsCode,
        );
}

/// Maintenance mode exception
class MaintenanceException extends ServerException {
  const MaintenanceException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.maintenanceModeMessage,
          statusCode: ApiConstants.serviceUnavailableCode,
        );
}

/// Location/GPS related exceptions
class LocationException extends AppException {
  const LocationException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.locationPermissionMessage,
        );

  @override
  String toString() => 'LocationException: $message';
}

class GeofenceViolationException extends LocationException {
  const GeofenceViolationException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.geofenceViolationMessage,
        );
}

/// Offline data related exceptions
class OfflineDataException extends AppException {
  const OfflineDataException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.noOfflineDataMessage,
        );

  @override
  String toString() => 'OfflineDataException: $message';
}

class ExpiredOfflineDataException extends OfflineDataException {
  const ExpiredOfflineDataException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.expiredOfflineDataMessage,
        );
}

/// Device/Hardware related exceptions
class DeviceException extends AppException {
  const DeviceException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Device error occurred',
        );

  @override
  String toString() => 'DeviceException: $message';
}

class UntrustedDeviceException extends DeviceException {
  const UntrustedDeviceException({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.deviceNotTrustedMessage,
        );
}

/// Data synchronization exceptions
class SyncException extends AppException {
  const SyncException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.dataSyncFailedMessage,
        );

  @override
  String toString() => 'SyncException: $message';
}

/// Business logic exceptions for guard duty specific operations
class GuardDutyException extends AppException {
  const GuardDutyException({
    required super.message,
    super.statusCode,
    super.data,
    super.timestamp,
  });

  @override
  String toString() => 'GuardDutyException: $message';
}

class RosterException extends GuardDutyException {
  const RosterException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Roster operation failed',
        );
}

class MovementException extends GuardDutyException {
  const MovementException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Movement tracking error',
        );
}

class PerimeterCheckException extends GuardDutyException {
  const PerimeterCheckException({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Perimeter check failed',
        );
}

/// Exception factory for creating exceptions from error codes/messages
class ExceptionFactory {
  /// Create exception from status code using constants
  static AppException fromStatusCode(
    int statusCode, {
    String? message,
    dynamic data,
  }) {
    final defaultMessage = AppConstants.getErrorMessageForStatusCode(statusCode);
    final finalMessage = message ?? defaultMessage;

    switch (statusCode) {
      case ApiConstants.badRequestCode:
        return ValidationException(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      case ApiConstants.unauthorizedCode:
        return UnauthorizedException(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.forbiddenCode:
        return ForbiddenException(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.notFoundCode:
        return NotFoundException(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.validationErrorCode:
        return ValidationException(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      case ApiConstants.tooManyRequestsCode:
        return RateLimitException(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.serverErrorCode:
      case ApiConstants.badGatewayCode:
      case ApiConstants.serviceUnavailableCode:
      case ApiConstants.gatewayTimeoutCode:
        return ServerException(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      default:
        if (ApiConstants.isClientError(statusCode)) {
          return ValidationException(
            message: finalMessage,
            statusCode: statusCode,
            data: data,
          );
        } else if (ApiConstants.isServerError(statusCode)) {
          return ServerException(
            message: finalMessage,
            statusCode: statusCode,
            data: data,
          );
        }
        return ServerException(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// Create exception from error type string
  static AppException fromErrorType(
    String errorType, {
    String? message,
    int? statusCode,
    dynamic data,
  }) {
    switch (errorType.toLowerCase()) {
      case 'network':
      case 'connection':
        return NetworkException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'timeout':
        return TimeoutException(
          message: message,
          data: data,
        );
      case 'authentication':
      case 'auth':
        return AuthException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'validation':
        return ValidationException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'server':
        return ServerException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'cache':
        return CacheException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'location':
        return LocationException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      default:
        return ServerException(
          message: message ?? AppConstants.unknownErrorMessage,
          statusCode: statusCode,
          data: data,
        );
    }
  }
}