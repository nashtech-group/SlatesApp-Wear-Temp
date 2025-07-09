import 'error_handler.dart';
import 'common_error_states.dart';

/// Factory for creating appropriate error states
class ErrorStateFactory {
  /// Create error state based on error type
  static BaseErrorState createErrorState(BlocErrorInfo errorInfo) {
    switch (errorInfo.type) {
      case ErrorType.network:
      case ErrorType.timeout:
        return NetworkErrorState(errorInfo: errorInfo);
      case ErrorType.authentication:
        return AuthenticationErrorState(errorInfo: errorInfo);
      case ErrorType.validation:
        return ValidationErrorState(errorInfo: errorInfo);
      case ErrorType.server:
        return ServerErrorState(errorInfo: errorInfo);
      default:
        return GenericErrorState(errorInfo: errorInfo);
    }
  }
}