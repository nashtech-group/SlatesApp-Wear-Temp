// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';
import '../constants/app_constants.dart';
import '../constants/api_constants.dart';
import 'exceptions.dart';

/// Base abstract class for all failures in the domain layer
/// Follows clean architecture principles and provides common behavior
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final dynamic data;
  final DateTime timestamp;

  const Failure({
    required this.message,
    this.statusCode,
    this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? const DateTime.now();

  @override
  List<Object?> get props => [message, statusCode, data, timestamp];

  /// Get user-friendly message using constants
  String get userMessage => _getUserFriendlyMessage();

  /// Check if this failure is retryable
  bool get isRetryable => _isRetryable();

  /// Check if this failure indicates network issues
  bool get isNetworkRelated => _isNetworkRelated();

  /// Check if this failure should trigger offline mode
  bool get shouldTriggerOfflineMode => _shouldTriggerOfflineMode();

  /// Check if this failure should logout user
  bool get shouldLogoutUser => _shouldLogoutUser();

  /// Get error category for logging/analytics
  String get errorCategory => _getErrorCategory();

  /// Get retry delay in milliseconds
  int getRetryDelay(int attemptNumber) {
    return AppConstants.getRetryDelay(attemptNumber);
  }

  /// Convert to corresponding exception
  AppException toException();

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
    return this is NetworkFailure || this is TimeoutFailure || this is ServerFailure;
  }

  bool _isNetworkRelated() {
    return this is NetworkFailure || this is TimeoutFailure;
  }

  bool _shouldTriggerOfflineMode() {
    return isNetworkRelated || (statusCode != null && ApiConstants.isServerError(statusCode!));
  }

  bool _shouldLogoutUser() {
    return this is AuthFailure && 
           (statusCode == ApiConstants.unauthorizedCode || 
            message.toLowerCase().contains('expired') ||
            message.toLowerCase().contains('invalid token'));
  }

  String _getErrorCategory() {
    if (this is NetworkFailure) return 'Network';
    if (this is AuthFailure) return 'Authentication';
    if (this is ValidationFailure) return 'Validation';
    if (this is ServerFailure) return 'Server';
    if (this is CacheFailure) return 'Cache';
    if (this is TimeoutFailure) return 'Timeout';
    return 'Unknown';
  }
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.serverErrorMessage,
        );

  @override
  AppException toException() => ServerException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.networkErrorMessage,
        );

  @override
  AppException toException() => NetworkException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.cacheErrorMessage,
        );

  @override
  AppException toException() => CacheException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Validation-related failures
class ValidationFailure extends Failure {
  final Map<String, List<String>>? validationErrors;

  const ValidationFailure({
    String? message,
    super.statusCode,
    super.data,
    this.validationErrors,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.validationErrorMessage,
        );

  @override
  List<Object?> get props => [message, statusCode, data, validationErrors, timestamp];

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

  @override
  AppException toException() => ValidationException(
        message: message,
        statusCode: statusCode,
        data: data,
        validationErrors: validationErrors,
        timestamp: timestamp,
      );
}

/// Authentication and authorization related failures
class AuthFailure extends Failure {
  const AuthFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.unauthorizedMessage,
        );

  @override
  AppException toException() => AuthException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Specific authentication failures with predefined messages from constants
class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.unauthorizedMessage,
          statusCode: ApiConstants.unauthorizedCode,
        );

  @override
  AppException toException() => UnauthorizedException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

class ForbiddenFailure extends AuthFailure {
  const ForbiddenFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.forbiddenMessage,
          statusCode: ApiConstants.forbiddenCode,
        );

  @override
  AppException toException() => ForbiddenException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

class SessionExpiredFailure extends AuthFailure {
  const SessionExpiredFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.sessionExpiredMessage,
          statusCode: ApiConstants.unauthorizedCode,
        );

  @override
  AppException toException() => SessionExpiredException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

class AccountLockedFailure extends AuthFailure {
  const AccountLockedFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.accountLockedMessage,
          statusCode: ApiConstants.forbiddenCode,
        );

  @override
  AppException toException() => AccountLockedException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Resource not found failure
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.notFoundMessage,
          statusCode: ApiConstants.notFoundCode,
        );

  @override
  AppException toException() => NotFoundException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Timeout-related failures
class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.connectionTimeoutMessage,
          statusCode: null,
        );

  @override
  AppException toException() => TimeoutException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Rate limiting failure
class RateLimitFailure extends ServerFailure {
  const RateLimitFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.tooManyRequestsMessage,
          statusCode: ApiConstants.tooManyRequestsCode,
        );

  @override
  AppException toException() => RateLimitException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Maintenance mode failure
class MaintenanceFailure extends ServerFailure {
  const MaintenanceFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.maintenanceModeMessage,
          statusCode: ApiConstants.serviceUnavailableCode,
        );

  @override
  AppException toException() => MaintenanceException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Location/GPS related failures
class LocationFailure extends Failure {
  const LocationFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.locationPermissionMessage,
        );

  @override
  AppException toException() => LocationException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class GeofenceViolationFailure extends LocationFailure {
  const GeofenceViolationFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.geofenceViolationMessage,
        );

  @override
  AppException toException() => GeofenceViolationException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Offline data related failures
class OfflineDataFailure extends Failure {
  const OfflineDataFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.noOfflineDataMessage,
        );

  @override
  AppException toException() => OfflineDataException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class ExpiredOfflineDataFailure extends OfflineDataFailure {
  const ExpiredOfflineDataFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.expiredOfflineDataMessage,
        );

  @override
  AppException toException() => ExpiredOfflineDataException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Device/Hardware related failures
class DeviceFailure extends Failure {
  const DeviceFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Device error occurred',
        );

  @override
  AppException toException() => DeviceException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class UntrustedDeviceFailure extends DeviceFailure {
  const UntrustedDeviceFailure({
    String? message,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.deviceNotTrustedMessage,
        );

  @override
  AppException toException() => UntrustedDeviceException(
        message: message,
        data: data,
        timestamp: timestamp,
      );
}

/// Data synchronization failures
class SyncFailure extends Failure {
  const SyncFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? AppConstants.dataSyncFailedMessage,
        );

  @override
  AppException toException() => SyncException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Business logic failures for guard duty specific operations
class GuardDutyFailure extends Failure {
  const GuardDutyFailure({
    required super.message,
    super.statusCode,
    super.data,
    super.timestamp,
  });

  @override
  AppException toException() => GuardDutyException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class RosterFailure extends GuardDutyFailure {
  const RosterFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Roster operation failed',
        );

  @override
  AppException toException() => RosterException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class MovementFailure extends GuardDutyFailure {
  const MovementFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Movement tracking error',
        );

  @override
  AppException toException() => MovementException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

class PerimeterCheckFailure extends GuardDutyFailure {
  const PerimeterCheckFailure({
    String? message,
    super.statusCode,
    super.data,
    super.timestamp,
  }) : super(
          message: message ?? 'Perimeter check failed',
        );

  @override
  AppException toException() => PerimeterCheckException(
        message: message,
        statusCode: statusCode,
        data: data,
        timestamp: timestamp,
      );
}

/// Failure factory for creating failures from exceptions or error codes
class FailureFactory {
  /// Create failure from exception
  static Failure fromException(AppException exception) {
    if (exception is ValidationException) {
      return ValidationFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        validationErrors: exception.validationErrors,
        timestamp: exception.timestamp,
      );
    } else if (exception is UnauthorizedException) {
      return UnauthorizedFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is ForbiddenException) {
      return ForbiddenFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is SessionExpiredException) {
      return SessionExpiredFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is AccountLockedException) {
      return AccountLockedFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is AuthException) {
      return AuthFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is NotFoundException) {
      return NotFoundFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is TimeoutException) {
      return TimeoutFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is RateLimitException) {
      return RateLimitFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is MaintenanceException) {
      return MaintenanceFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is NetworkException) {
      return NetworkFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is ServerException) {
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is CacheException) {
      return CacheFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is LocationException) {
      return LocationFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is GeofenceViolationException) {
      return GeofenceViolationFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is OfflineDataException) {
      return OfflineDataFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is ExpiredOfflineDataException) {
      return ExpiredOfflineDataFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is DeviceException) {
      return DeviceFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is UntrustedDeviceException) {
      return UntrustedDeviceFailure(
        message: exception.message,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is SyncException) {
      return SyncFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is RosterException) {
      return RosterFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is MovementException) {
      return MovementFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is PerimeterCheckException) {
      return PerimeterCheckFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else if (exception is GuardDutyException) {
      return GuardDutyFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    } else {
      // Default to ServerFailure for unknown exceptions
      return ServerFailure(
        message: exception.message,
        statusCode: exception.statusCode,
        data: exception.data,
        timestamp: exception.timestamp,
      );
    }
  }

  /// Create failure from status code using constants
  static Failure fromStatusCode(
    int statusCode, {
    String? message,
    dynamic data,
  }) {
    final defaultMessage = AppConstants.getErrorMessageForStatusCode(statusCode);
    final finalMessage = message ?? defaultMessage;

    switch (statusCode) {
      case ApiConstants.badRequestCode:
        return ValidationFailure(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      case ApiConstants.unauthorizedCode:
        return UnauthorizedFailure(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.forbiddenCode:
        return ForbiddenFailure(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.notFoundCode:
        return NotFoundFailure(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.validationErrorCode:
        return ValidationFailure(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      case ApiConstants.tooManyRequestsCode:
        return RateLimitFailure(
          message: finalMessage,
          data: data,
        );
      case ApiConstants.serverErrorCode:
      case ApiConstants.badGatewayCode:
      case ApiConstants.serviceUnavailableCode:
      case ApiConstants.gatewayTimeoutCode:
        return ServerFailure(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
      default:
        if (ApiConstants.isClientError(statusCode)) {
          return ValidationFailure(
            message: finalMessage,
            statusCode: statusCode,
            data: data,
          );
        } else if (ApiConstants.isServerError(statusCode)) {
          return ServerFailure(
            message: finalMessage,
            statusCode: statusCode,
            data: data,
          );
        }
        return ServerFailure(
          message: finalMessage,
          statusCode: statusCode,
          data: data,
        );
    }
  }

  /// Create failure from error type string
  static Failure fromErrorType(
    String errorType, {
    String? message,
    int? statusCode,
    dynamic data,
  }) {
    switch (errorType.toLowerCase()) {
      case 'network':
      case 'connection':
        return NetworkFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'timeout':
        return TimeoutFailure(
          message: message,
          data: data,
        );
      case 'authentication':
      case 'auth':
        return AuthFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'validation':
        return ValidationFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'server':
        return ServerFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'cache':
        return CacheFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      case 'location':
        return LocationFailure(
          message: message,
          statusCode: statusCode,
          data: data,
        );
      default:
        return ServerFailure(
          message: message ?? AppConstants.unknownErrorMessage,
          statusCode: statusCode,
          data: data,
        );
    }
  }
}