import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

abstract class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const AppException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'AppException: $message';
}

class ServerException extends AppException {
  const ServerException({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);

  @override
  String toString() => 'NetworkException: $message';
}

class CacheException extends AppException {
  const CacheException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'CacheException: $message';
}

class ValidationException extends AppException {
  final Map<String, List<String>>? validationErrors;

  const ValidationException({
    required super.message,
    super.statusCode,
    super.data,
    this.validationErrors,
  });

  @override
  String toString() => 'ValidationException: $message';
}

class AuthException extends AppException {
  const AuthException({
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'AuthException: $message';
}

class UnauthorizedException extends AuthException {
  const UnauthorizedException({
    super.message = AppConstants.unauthorizedMessage,
    int super.statusCode = ApiConstants.unauthorizedCode,
    super.data,
  });
}

class ForbiddenException extends AuthException {
  const ForbiddenException({
    super.message = AppConstants.forbiddenMessage,
    int super.statusCode = ApiConstants.forbiddenCode,
    super.data,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = AppConstants.notFoundMessage,
    int super.statusCode = ApiConstants.notFoundCode,
    super.data,
  });
}

class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = AppConstants.connectionTimeoutMessage,
    super.statusCode,
    super.data,
  });
}