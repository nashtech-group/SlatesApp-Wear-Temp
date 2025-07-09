import 'package:equatable/equatable.dart';
import '../constants/api_constants.dart';
import '../constants/app_constants.dart';

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
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class ValidationFailure extends Failure {
  final Map<String, List<String>>? validationErrors;

  const ValidationFailure({
    required String message,
    int? statusCode,
    dynamic data,
    this.validationErrors,
  }) : super(message: message, statusCode: statusCode, data: data);

  @override
  List<Object?> get props => [message, statusCode, data, validationErrors];
}

class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class UnauthorizedFailure extends AuthFailure {
  const UnauthorizedFailure({
    String message = AppConstants.unauthorizedMessage,
    int statusCode = ApiConstants.unauthorizedCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class ForbiddenFailure extends AuthFailure {
  const ForbiddenFailure({
    String message = AppConstants.forbiddenMessage,
    int statusCode = ApiConstants.forbiddenCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    String message = AppConstants.notFoundMessage,
    int statusCode = ApiConstants.notFoundCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}

class TimeoutFailure extends NetworkFailure {
  const TimeoutFailure({
    String message = AppConstants.connectionTimeoutMessage,
    int? statusCode,
    dynamic data,
  }) : super(message: message, statusCode: statusCode, data: data);
}