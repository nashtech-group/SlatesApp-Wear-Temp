import 'package:equatable/equatable.dart';
import 'error_handler.dart';

/// Base error state that can be extended by specific BLoCs
abstract class BaseErrorState extends Equatable {
  final BlocErrorInfo errorInfo;

  const BaseErrorState({required this.errorInfo});

  @override
  List<Object?> get props => [errorInfo];

  // Convenience getters
  String get message => errorInfo.message;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
  List<String>? get validationErrors => errorInfo.validationErrors;
  String? get errorCode => errorInfo.errorCode;
  int? get statusCode => errorInfo.statusCode;
}

/// Generic error state for simple BLoCs
class GenericErrorState extends BaseErrorState {
  const GenericErrorState({required super.errorInfo});
}

/// Network error state
class NetworkErrorState extends BaseErrorState {
  const NetworkErrorState({required super.errorInfo});
}

/// Authentication error state
class AuthenticationErrorState extends BaseErrorState {
  const AuthenticationErrorState({required super.errorInfo});
}

/// Validation error state
class ValidationErrorState extends BaseErrorState {
  const ValidationErrorState({required super.errorInfo});
}

/// Server error state
class ServerErrorState extends BaseErrorState {
  const ServerErrorState({required super.errorInfo});
}