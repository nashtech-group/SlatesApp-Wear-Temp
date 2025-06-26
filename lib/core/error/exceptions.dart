// lib/core/error/exceptions.dart
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
    required super.message,
    super.statusCode,
    super.data,
  });

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({
    required super.message,
    super.statusCode,
    super.data,
  });

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
    super.message = 'Unauthorized access',
    super.statusCode = 401,
    super.data,
  });
}

class ForbiddenException extends AuthException {
  const ForbiddenException({
    super.message = 'Access forbidden',
    super.statusCode = 403,
    super.data,
  });
}

class NotFoundException extends AppException {
  const NotFoundException({
    super.message = 'Resource not found',
    super.statusCode = 404,
    super.data,
  });
}

class TimeoutException extends NetworkException {
  const TimeoutException({
    super.message = 'Request timeout',
    super.statusCode,
    super.data,
  });
}