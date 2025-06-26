// lib/core/error/failures.dart
import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;
  final dynamic data;

  const Failure({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  List<Object?> get props => [message, statusCode, data];
}

class ServerFailure extends Failure {
  const ServerFailure({
    required super.message,
    super.statusCode,
    super.data,
  });
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required super.message,
    super.statusCode,
    super.data,
  });
}

class CacheFailure extends Failure {
  const CacheFailure({
    required super.message,
    super.statusCode,
    super.data,
  });
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? validationErrors;

  const ValidationFailure({
    required super.message,
    super.statusCode,
    super.data,
    this.validationErrors,
  });

  @override
  List<Object?> get props => [message, statusCode, data, validationErrors];
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.statusCode,
    super.data,
  });
}

class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure({
    super.message = 'Unauthorized access',
    super.statusCode = 401,
    super.data,
  });
}

class ForbiddenFailure extends AuthFailure {
  const ForbiddenFailure({
    super.message = 'Access forbidden',
    super.statusCode = 403,
    super.data,
  });
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    super.message = 'Resource not found',
    super.statusCode = 404,
    super.data,
  });
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    super.message = 'Request timeout',
    super.statusCode,
    super.data,
  });
}