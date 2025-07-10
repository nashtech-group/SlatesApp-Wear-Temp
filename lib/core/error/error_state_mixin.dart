// lib/core/error/error_state_mixin.dart
import 'error_handler.dart';

/// Mixin to provide common error state functionality
/// Eliminates duplicate convenience getters across all error states
mixin ErrorStateMixin {
  BlocErrorInfo get errorInfo;

  // Convenience getters for backward compatibility
  String get message => errorInfo.message;
  String? get errorCode => errorInfo.errorCode;
  bool get canRetry => errorInfo.canRetry;
  bool get isNetworkError => errorInfo.isNetworkError;
  ErrorType get errorType => errorInfo.type;
  List<String>? get validationErrors => errorInfo.validationErrors;
  int? get statusCode => errorInfo.statusCode;
  
  // Enhanced getters for UI
  String get userMessage => errorInfo.toUserMessage();
  bool get shouldTriggerOfflineMode => errorInfo.shouldTriggerOfflineMode();
  bool get shouldLogoutUser => errorInfo.shouldLogoutUser();
  bool get isAuthError => ErrorHandler.isAuthError(errorInfo);
  bool get isSessionExpired => ErrorHandler.isSessionExpired(errorInfo);
  bool get isOfflineError => ErrorHandler.isOfflineError(errorInfo);
}