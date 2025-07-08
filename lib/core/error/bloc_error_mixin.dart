import 'package:flutter_bloc/flutter_bloc.dart';
import 'error_handler.dart';

/// Mixin for BLoCs to provide standardized error handling
mixin BlocErrorMixin<Event, State> on Bloc<Event, State> {
  
  /// Handle error and emit appropriate error state
  void handleError(
    dynamic error,
    Emitter<State> emit, {
    String? context,
    Map<String, dynamic>? additionalData,
    State Function(BlocErrorInfo errorInfo)? customErrorState,
  }) {
    final errorInfo = ErrorHandler.handleError(
      error,
      context: context ?? runtimeType.toString(),
      additionalData: additionalData,
    );

    // Use custom error state if provided, otherwise use default
    if (customErrorState != null) {
      emit(customErrorState(errorInfo));
    } else {
      emit(createDefaultErrorState(errorInfo));
    }
  }

  /// Create default error state - should be overridden by implementing BLoCs
  State createDefaultErrorState(BlocErrorInfo errorInfo);

  /// Handle error with custom error state creation
  void handleErrorWithState(
    dynamic error,
    Emitter<State> emit,
    State Function(BlocErrorInfo errorInfo) errorStateCreator, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    final errorInfo = ErrorHandler.handleError(
      error,
      context: context ?? runtimeType.toString(),
      additionalData: additionalData,
    );

    emit(errorStateCreator(errorInfo));
  }

  /// Handle error and return error info without emitting state
  BlocErrorInfo processError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
  }) {
    return ErrorHandler.handleError(
      error,
      context: context ?? runtimeType.toString(),
      additionalData: additionalData,
    );
  }

  /// Check if should trigger offline mode
  bool shouldTriggerOfflineMode(dynamic error) {
    final errorInfo = processError(error);
    return errorInfo.shouldTriggerOfflineMode();
  }

  /// Check if should logout user
  bool shouldLogoutUser(dynamic error) {
    final errorInfo = processError(error);
    return errorInfo.shouldLogoutUser();
  }
}
