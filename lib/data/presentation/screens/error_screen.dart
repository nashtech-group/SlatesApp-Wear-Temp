import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';
import 'package:slates_app_wear/core/error/common_error_states.dart';
import 'package:slates_app_wear/core/error/error_state_factory.dart' hide VoidCallback;
import 'package:slates_app_wear/core/error/error_handler.dart';
import 'package:slates_app_wear/core/error/exceptions.dart';
import 'package:slates_app_wear/core/error/failures.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';
import 'package:slates_app_wear/core/auth_manager.dart';
import 'package:slates_app_wear/services/connectivity_service.dart';

/// Production-ready error screen that integrates with the comprehensive error handling system
/// Follows DRY principles and uses centralized error management
class ErrorScreen extends StatefulWidget {
  final BaseErrorState errorState;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final VoidCallback? onCustomAction;
  final String? customActionText;
  final bool showAppBar;
  final bool canPop;
  final ErrorStateConfig? config;

  const ErrorScreen({
    super.key,
    required this.errorState,
    this.onRetry,
    this.onGoHome,
    this.onCustomAction,
    this.customActionText,
    this.showAppBar = true,
    this.canPop = true,
    this.config,
  });

  // ====================
  // FACTORY CONSTRUCTORS FOR COMMON ERROR SCENARIOS
  // ====================

  /// Create ErrorScreen from exception
  static ErrorScreen fromException(
    AppException exception, {
    VoidCallback? onRetry,
    VoidCallback? onGoHome,
    VoidCallback? onCustomAction,
    String? customActionText,
    bool showAppBar = true,
    bool canPop = true,
    ErrorStateConfig? config,
  }) {
    final errorState = ErrorStateFactory.createFromException(exception);
    return ErrorScreen(
      errorState: errorState,
      onRetry: onRetry,
      onGoHome: onGoHome,
      onCustomAction: onCustomAction,
      customActionText: customActionText,
      showAppBar: showAppBar,
      canPop: canPop,
      config: config,
    );
  }

  /// Create ErrorScreen from failure
  static ErrorScreen fromFailure(
    Failure failure, {
    VoidCallback? onRetry,
    VoidCallback? onGoHome,
    VoidCallback? onCustomAction,
    String? customActionText,
    bool showAppBar = true,
    bool canPop = true,
    ErrorStateConfig? config,
  }) {
    final errorState = ErrorStateFactory.createFromFailure(failure);
    return ErrorScreen(
      errorState: errorState,
      onRetry: onRetry,
      onGoHome: onGoHome,
      onCustomAction: onCustomAction,
      customActionText: customActionText,
      showAppBar: showAppBar,
      canPop: canPop,
      config: config,
    );
  }

  /// Create ErrorScreen from dynamic error
  static ErrorScreen fromDynamicError(
    dynamic error, {
    String? context,
    Map<String, dynamic>? additionalData,
    VoidCallback? onRetry,
    VoidCallback? onGoHome,
    VoidCallback? onCustomAction,
    String? customActionText,
    bool showAppBar = true,
    bool canPop = true,
    ErrorStateConfig? config,
  }) {
    final errorState = ErrorStateFactory.createFromDynamicError(
      error,
      context: context,
      additionalData: additionalData,
    );
    return ErrorScreen(
      errorState: errorState,
      onRetry: onRetry,
      onGoHome: onGoHome,
      onCustomAction: onCustomAction,
      customActionText: customActionText,
      showAppBar: showAppBar,
      canPop: canPop,
      config: config,
    );
  }

  // ====================
  // PREDEFINED ERROR SCREENS
  // ====================

  static ErrorScreen notFound({
    VoidCallback? onGoHome,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: NotFoundErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.notFound,
            message: AppConstants.notFoundMessage,
            statusCode: ApiConstants.notFoundCode,
          ),
        ),
        onGoHome: onGoHome,
        showAppBar: showAppBar,
      );

  static ErrorScreen unauthorized({
    VoidCallback? onLogin,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: AuthenticationErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.authentication,
            message: AppConstants.unauthorizedMessage,
            statusCode: ApiConstants.unauthorizedCode,
          ),
        ),
        onCustomAction: onLogin,
        customActionText: 'Login',
        showAppBar: showAppBar,
      );

  static ErrorScreen serverError({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: ServerErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.server,
            message: AppConstants.serverErrorMessage,
            statusCode: ApiConstants.serverErrorCode,
            canRetry: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
      );

  static ErrorScreen networkError({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: NetworkErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.network,
            message: AppConstants.networkErrorMessage,
            canRetry: true,
            isNetworkError: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
        config: ErrorStateConfig.network,
      );

  static ErrorScreen sessionExpired({
    VoidCallback? onLogin,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: SessionExpiredErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.authentication,
            message: AppConstants.sessionExpiredMessage,
            statusCode: ApiConstants.unauthorizedCode,
          ),
        ),
        onCustomAction: onLogin,
        customActionText: 'Login Again',
        showAppBar: showAppBar,
        config: ErrorStateConfig.auth,
      );

  static ErrorScreen offlineMode({
    VoidCallback? onGoHome,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: OfflineDataErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.network,
            message: AppConstants.noOfflineDataMessage,
            isNetworkError: true,
          ),
        ),
        onGoHome: onGoHome,
        showAppBar: showAppBar,
      );

  static ErrorScreen forbidden({
    VoidCallback? onGoHome,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: ForbiddenErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.authorization,
            message: AppConstants.forbiddenMessage,
            statusCode: ApiConstants.forbiddenCode,
          ),
        ),
        onGoHome: onGoHome,
        showAppBar: showAppBar,
      );

  static ErrorScreen rateLimited({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: RateLimitErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.rateLimited,
            message: AppConstants.tooManyRequestsMessage,
            statusCode: ApiConstants.tooManyRequestsCode,
            canRetry: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
      );

  static ErrorScreen maintenance({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: MaintenanceErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.server,
            message: AppConstants.maintenanceModeMessage,
            statusCode: ApiConstants.serviceUnavailableCode,
            canRetry: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
      );

  static ErrorScreen badGateway({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: ServiceUnavailableErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.server,
            message: AppConstants.badGatewayMessage,
            statusCode: ApiConstants.badGatewayCode,
            canRetry: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
      );

  static ErrorScreen gatewayTimeout({
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: ServiceUnavailableErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.timeout,
            message: AppConstants.gatewayTimeoutMessage,
            statusCode: ApiConstants.gatewayTimeoutCode,
            canRetry: true,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
      );

  static ErrorScreen validation({
    List<String>? validationErrors,
    VoidCallback? onRetry,
    bool showAppBar = true,
  }) =>
      ErrorScreen(
        errorState: ValidationErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.validation,
            message: AppConstants.validationErrorMessage,
            statusCode: ApiConstants.validationErrorCode,
            validationErrors: validationErrors,
          ),
        ),
        onRetry: onRetry,
        showAppBar: showAppBar,
        config: ErrorStateConfig.validation,
      );

  /// Create ErrorScreen from HTTP status code using ApiConstants
  static ErrorScreen fromStatusCode(
    int statusCode, {
    String? message,
    dynamic data,
    VoidCallback? onRetry,
    VoidCallback? onGoHome,
    bool showAppBar = true,
  }) {
    // Use ApiConstants to determine error type and get appropriate message
    final errorMessage = message ?? AppConstants.getErrorMessageForStatusCode(statusCode);
    
    if (ApiConstants.isClientError(statusCode)) {
      switch (statusCode) {
        case ApiConstants.unauthorizedCode:
          return ErrorScreen.unauthorized(showAppBar: showAppBar);
        case ApiConstants.forbiddenCode:
          return ErrorScreen.forbidden(onGoHome: onGoHome, showAppBar: showAppBar);
        case ApiConstants.notFoundCode:
          return ErrorScreen.notFound(onGoHome: onGoHome, showAppBar: showAppBar);
        case ApiConstants.validationErrorCode:
          return ErrorScreen.validation(showAppBar: showAppBar);
        case ApiConstants.tooManyRequestsCode:
          return ErrorScreen.rateLimited(onRetry: onRetry, showAppBar: showAppBar);
        default:
          return ErrorScreen(
            errorState: ValidationErrorState(
              errorInfo: BlocErrorInfo(
                type: ErrorType.validation,
                message: errorMessage,
                statusCode: statusCode,
                canRetry: ApiConstants.isRetryableStatusCode(statusCode),
              ),
            ),
            onRetry: onRetry,
            onGoHome: onGoHome,
            showAppBar: showAppBar,
          );
      }
    } else if (ApiConstants.isServerError(statusCode)) {
      switch (statusCode) {
        case ApiConstants.serviceUnavailableCode:
          return ErrorScreen.maintenance(onRetry: onRetry, showAppBar: showAppBar);
        case ApiConstants.badGatewayCode:
          return ErrorScreen.badGateway(onRetry: onRetry, showAppBar: showAppBar);
        case ApiConstants.gatewayTimeoutCode:
          return ErrorScreen.gatewayTimeout(onRetry: onRetry, showAppBar: showAppBar);
        default:
          return ErrorScreen.serverError(onRetry: onRetry, showAppBar: showAppBar);
      }
    } else {
      // Unknown status code - create generic error
      return ErrorScreen(
        errorState: GenericErrorState(
          errorInfo: BlocErrorInfo(
            type: ErrorType.unknown,
            message: errorMessage,
            statusCode: statusCode,
            canRetry: ApiConstants.isRetryableStatusCode(statusCode),
          ),
        ),
        onRetry: onRetry,
        onGoHome: onGoHome,
        showAppBar: showAppBar,
      );
    }
  }

  // ====================
  // STATIC UTILITY METHODS - PROPERLY PLACED IN MAIN CLASS
  // ====================

  /// Show error dialog using the error handling system
  static Future<void> showErrorDialog(
    BuildContext context, {
    BaseErrorState? errorState,
    AppException? exception,
    Failure? failure,
    dynamic error,
    VoidCallback? onRetry,
    VoidCallback? onDismiss,
  }) {
    final responsive = context.responsive;
    final theme = Theme.of(context);

    // Determine error state
    BaseErrorState finalErrorState;
    if (errorState != null) {
      finalErrorState = errorState;
    } else if (exception != null) {
      finalErrorState = ErrorStateFactory.createFromException(exception);
    } else if (failure != null) {
      finalErrorState = ErrorStateFactory.createFromFailure(failure);
    } else if (error != null) {
      finalErrorState = ErrorStateFactory.createFromDynamicError(error);
    } else {
      finalErrorState = GenericErrorState(
        errorInfo: BlocErrorInfo(
          type: ErrorType.unknown,
          message: AppConstants.unknownErrorMessage,
        ),
      );
    }
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        contentPadding: responsive.formPadding,
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: responsive.largeIconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                finalErrorState.errorTitle,
                style: responsive.getTitleStyle(),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              finalErrorState.userMessage,
              style: responsive.getBodyStyle(),
            ),
            if (finalErrorState.errorCode != null) ...[
              responsive.smallSpacer,
              Container(
                padding: EdgeInsets.all(responsive.padding * 0.5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Text(
                  'Error Code: ${finalErrorState.errorCode}',
                  style: responsive.getCaptionStyle()?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null && finalErrorState.canRetry)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRetry();
              },
              child: Text(
                'Try Again',
                style: responsive.getBodyStyle(),
              ),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDismiss?.call();
            },
            style: AppTheme.responsivePrimaryButtonStyle(context),
            child: Text(
              'OK',
              style: responsive.getBodyStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// Show error snackbar using the error handling system
  static void showErrorSnackBar(
    BuildContext context, {
    BaseErrorState? errorState,
    String? message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    
    final finalMessage = message ?? 
        errorState?.userMessage ?? 
        AppConstants.unknownErrorMessage;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onError,
              size: responsive.iconSize,
            ),
            responsive.smallHorizontalSpacer,
            Expanded(
              child: Text(
                finalMessage,
                style: responsive.getCaptionStyle(
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.borderRadius),
        ),
        margin: responsive.containerPadding,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                textColor: theme.colorScheme.onError,
                onPressed: onRetry,
              )
            : null,
        duration: duration,
      ),
    );
  }

  @override
  State<ErrorScreen> createState() => _ErrorScreenState();
}

class _ErrorScreenState extends State<ErrorScreen> {
  bool _isRetrying = false;
  late final ErrorUIBehavior _uiBehavior;
  late final List<ErrorAction> _errorActions;

  @override
  void initState() {
    super.initState();
    _uiBehavior = ErrorStateFactory.getErrorUIBehavior(widget.errorState.errorInfo);
    _errorActions = ErrorStateFactory.getErrorActions(widget.errorState.errorInfo);
    _handleSpecialBehaviors();
  }

  void _handleSpecialBehaviors() {
    // Handle behaviors that require immediate action
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (_uiBehavior) {
        case ErrorUIBehavior.logout:
          _handleLogout();
          break;
        case ErrorUIBehavior.redirectToLogin:
          _handleRedirectToLogin();
          break;
        case ErrorUIBehavior.enableOfflineMode:
          _handleEnableOfflineMode();
          break;
        default:
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    
    return Scaffold(
      appBar: widget.showAppBar && !responsive.isWearable ? _buildAppBar(theme) : null,
      body: SafeArea(
        child: _buildResponsiveLayout(context, theme, responsive),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: Text(AppConstants.appTitle),
      backgroundColor: theme.appBarTheme.backgroundColor,
      foregroundColor: theme.appBarTheme.foregroundColor,
      elevation: 0,
      automaticallyImplyLeading: widget.canPop && Navigator.of(context).canPop(),
    );
  }

  Widget _buildResponsiveLayout(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    if (responsive.isWearable) {
      return _buildWearableLayout(context, theme, responsive);
    }
    return _buildMobileLayout(context, theme, responsive);
  }

  Widget _buildWearableLayout(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return SingleChildScrollView(
      padding: responsive.containerPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorIcon(theme, responsive),
          responsive.mediumSpacer,
          _buildErrorTitle(theme, responsive),
          responsive.smallSpacer,
          _buildErrorMessage(theme, responsive),
          if (widget.errorState.errorCode != null) ...[
            responsive.smallSpacer,
            _buildErrorCode(theme, responsive),
          ],
          responsive.largeSpacer,
          _buildActionButtons(context, responsive),
          responsive.mediumSpacer,
          _buildCompactSupportInfo(context, theme, responsive),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return Padding(
      padding: responsive.containerPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildErrorIcon(theme, responsive),
          responsive.extraLargeSpacer,
          _buildErrorTitle(theme, responsive),
          responsive.mediumSpacer,
          _buildErrorMessage(theme, responsive),
          if (widget.errorState.errorCode != null) ...[
            responsive.smallSpacer,
            _buildErrorCode(theme, responsive),
          ],
          if (widget.errorState.validationErrors != null) ...[
            responsive.mediumSpacer,
            _buildValidationErrors(theme, responsive),
          ],
          SizedBox(height: responsive.extraLargeSpacing * 1.2),
          _buildActionButtons(context, responsive),
          responsive.largeSpacer,
          _buildSupportInfo(context, theme, responsive),
        ],
      ),
    );
  }

  Widget _buildErrorIcon(ThemeData theme, ResponsiveUtils responsive) {
    final iconContainerSize = responsive.getResponsiveValue(
      wearable: 80.0,
      smallMobile: 100.0,
      mobile: 120.0,
      tablet: 140.0,
    );

    final iconSize = responsive.getResponsiveValue(
      wearable: 40.0,
      smallMobile: 48.0,
      mobile: 64.0,
      tablet: 72.0,
    );

    return Container(
      width: iconContainerSize,
      height: iconContainerSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getIconBackgroundColor(theme),
      ),
      child: Icon(
        _getIconData(),
        size: iconSize,
        color: _getIconColor(theme),
        semanticLabel: widget.errorState.errorTitle,
      ),
    );
  }

  Widget _buildErrorTitle(ThemeData theme, ResponsiveUtils responsive) {
    return Text(
      widget.errorState.errorTitle,
      style: responsive.getHeadlineStyle(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
      semanticsLabel: 'Error: ${widget.errorState.errorTitle}',
    );
  }

  Widget _buildErrorMessage(ThemeData theme, ResponsiveUtils responsive) {
    return Text(
      widget.errorState.userMessage,
      style: responsive.getBodyStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
      )?.copyWith(height: 1.5),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorCode(ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.padding * 0.6,
        vertical: responsive.smallSpacing,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        'Error Code: ${widget.errorState.errorCode}',
        style: responsive.getCaptionStyle(
          color: theme.colorScheme.error,
        )?.copyWith(fontFamily: 'monospace'),
        semanticsLabel: 'Error code ${widget.errorState.errorCode}',
      ),
    );
  }

  Widget _buildValidationErrors(ThemeData theme, ResponsiveUtils responsive) {
    final validationErrors = widget.errorState.validationErrors;
    if (validationErrors == null || validationErrors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Validation Errors:',
            style: responsive.getTitleStyle(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          responsive.smallSpacer,
          ...validationErrors.map((error) => Padding(
                padding: EdgeInsets.only(bottom: responsive.smallSpacing * 0.5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: responsive.iconSize,
                      color: theme.colorScheme.error,
                    ),
                    SizedBox(width: responsive.smallSpacing),
                    Expanded(
                      child: Text(
                        error,
                        style: responsive.getCaptionStyle(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ResponsiveUtils responsive) {
    final allowedActions = widget.config?.allowedActions ?? _errorActions;
    final buttons = <Widget>[];

    // Primary action button
    if (_shouldShowPrimaryAction(allowedActions)) {
      buttons.add(_buildPrimaryActionButton(context, responsive));
    }

    // Secondary action buttons
    for (final action in allowedActions) {
      if (_shouldShowSecondaryAction(action)) {
        buttons.add(_buildSecondaryActionButton(context, responsive, action));
      }
    }

    // Default back button if no actions available
    if (buttons.isEmpty && _shouldShowBackButton(context)) {
      buttons.add(_buildBackButton(context, responsive));
    }

    return Column(
      children: buttons
          .map((button) => [
                button,
                if (button != buttons.last) responsive.smallSpacer,
              ])
          .expand((e) => e)
          .toList(),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context, ResponsiveUtils responsive) {
    final action = _getPrimaryAction();
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isRetrying ? null : () => _handleAction(action),
        icon: _isRetrying
            ? SizedBox(
                width: responsive.iconSize,
                height: responsive.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.getResponsiveLoadingSpinnerColor(
                    context,
                    isDisabled: true,
                  ),
                ),
              )
            : Icon(
                _getActionIcon(action),
                size: responsive.iconSize,
              ),
        label: Text(
          _isRetrying ? 'Retrying...' : _getActionLabel(action),
          style: responsive.getBodyStyle(),
        ),
        style: AppTheme.responsivePrimaryButtonStyle(context),
      ),
    );
  }

  Widget _buildSecondaryActionButton(
    BuildContext context,
    ResponsiveUtils responsive,
    ErrorAction action,
  ) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => _handleAction(action),
        icon: Icon(
          _getActionIcon(action),
          size: responsive.iconSize,
        ),
        label: Text(
          _getActionLabel(action),
          style: responsive.getBodyStyle(),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: responsive.isWearable ? 12 : 16,
            horizontal: responsive.padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context, ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pop(),
        icon: Icon(
          Icons.arrow_back,
          size: responsive.iconSize,
        ),
        label: Text(
          'Go Back',
          style: responsive.getBodyStyle(),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            vertical: responsive.isWearable ? 12 : 16,
            horizontal: responsive.padding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(responsive.borderRadius),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfo(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      padding: responsive.formPadding,
      decoration: AppTheme.getResponsiveCardDecoration(
        context,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: responsive.largeIconSize,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: 'Support',
          ),
          responsive.smallSpacer,
          Text(
            'Need Help?',
            style: responsive.getTitleStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.smallSpacing * 0.5),
          Text(
            'Contact support at ${AppConstants.supportEmail}',
            style: responsive.getCaptionStyle(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.errorState.errorCode != null) ...[
            SizedBox(height: responsive.smallSpacing * 0.5),
            Text(
              'Please include error code: ${widget.errorState.errorCode}',
              style: responsive.getCaptionStyle(
                color: theme.colorScheme.onSurfaceVariant,
              )?.copyWith(fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSupportInfo(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.padding * 0.75),
      decoration: AppTheme.getResponsiveCardDecoration(
        context,
        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: responsive.iconSize,
            color: theme.colorScheme.onSurfaceVariant,
            semanticLabel: 'Support',
          ),
          SizedBox(height: responsive.smallSpacing * 0.5),
          Text(
            'Need Help?',
            style: responsive.getCaptionStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.smallSpacing * 0.25),
          Text(
            AppConstants.supportEmail,
            style: responsive.getCaptionStyle(
              color: theme.colorScheme.onSurfaceVariant,
            )?.copyWith(fontSize: responsive.isWearable ? 8 : 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ====================
  // HELPER METHODS
  // ====================

  IconData _getIconData() {
    switch (widget.errorState.errorType) {
      case ErrorType.network:
      case ErrorType.timeout:
        return Icons.wifi_off;
      case ErrorType.server:
        return Icons.error_outline;
      case ErrorType.authentication:
      case ErrorType.authorization:
        return Icons.lock_outline;
      case ErrorType.validation:
        return Icons.warning_outlined;
      case ErrorType.notFound:
        return Icons.search_off;
      case ErrorType.rateLimited:
        return Icons.hourglass_empty;
      case ErrorType.parsing:
        return Icons.data_usage;
      case ErrorType.unknown:
      default:
        return Icons.error;
    }
  }

  Color _getIconBackgroundColor(ThemeData theme) {
    switch (widget.errorState.errorType) {
      case ErrorType.authentication:
      case ErrorType.authorization:
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      case ErrorType.network:
      case ErrorType.timeout:
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
      case ErrorType.server:
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      default:
        return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (widget.errorState.errorType) {
      case ErrorType.authentication:
      case ErrorType.authorization:
      case ErrorType.server:
        return theme.colorScheme.error;
      case ErrorType.network:
      case ErrorType.timeout:
        return theme.colorScheme.primary;
      case ErrorType.validation:
        return theme.colorScheme.tertiary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  ErrorAction _getPrimaryAction() {
    if (widget.onCustomAction != null) {
      return ErrorAction.login; // Default for custom actions
    }
    if (widget.onRetry != null || widget.errorState.canRetry) {
      return ErrorAction.retry;
    }
    return ErrorAction.dismiss;
  }

  bool _shouldShowPrimaryAction(List<ErrorAction> allowedActions) {
    final primaryAction = _getPrimaryAction();
    return allowedActions.contains(primaryAction) ||
           widget.onCustomAction != null ||
           (widget.onRetry != null && widget.errorState.canRetry);
  }

  bool _shouldShowSecondaryAction(ErrorAction action) {
    final primaryAction = _getPrimaryAction();
    if (action == primaryAction) return false;
    
    switch (action) {
      case ErrorAction.checkConnection:
        return widget.errorState.isNetworkError;
      case ErrorAction.tryOfflineMode:
        return widget.errorState.isOfflineError;
      case ErrorAction.contactSupport:
        return true;
      case ErrorAction.dismiss:
        return widget.onGoHome != null;
      default:
        return false;
    }
  }

  bool _shouldShowBackButton(BuildContext context) {
    return widget.canPop && Navigator.of(context).canPop();
  }

  String _getActionLabel(ErrorAction action) {
    if (action == ErrorAction.login && widget.customActionText != null) {
      return widget.customActionText!;
    }
    return action.label;
  }

  IconData _getActionIcon(ErrorAction action) {
    switch (action) {
      case ErrorAction.retry:
        return Icons.refresh;
      case ErrorAction.login:
        return Icons.login;
      case ErrorAction.logout:
        return Icons.logout;
      case ErrorAction.checkConnection:
        return Icons.wifi;
      case ErrorAction.tryOfflineMode:
        return Icons.cloud_off;
      case ErrorAction.correctInput:
        return Icons.edit;
      case ErrorAction.contactSupport:
        return Icons.support_agent;
      case ErrorAction.waitAndRetry:
        return Icons.schedule;
      case ErrorAction.dismiss:
        return Icons.home;
    }
  }

  Future<void> _handleAction(ErrorAction action) async {
    switch (action) {
      case ErrorAction.retry:
        await _handleRetry();
        break;
      case ErrorAction.login:
        _handleLogin();
        break;
      case ErrorAction.logout:
        _handleLogout();
        break;
      case ErrorAction.checkConnection:
        _handleCheckConnection();
        break;
      case ErrorAction.tryOfflineMode:
        _handleTryOfflineMode();
        break;
      case ErrorAction.correctInput:
        _handleCorrectInput();
        break;
      case ErrorAction.contactSupport:
        _handleContactSupport();
        break;
      case ErrorAction.waitAndRetry:
        await _handleWaitAndRetry();
        break;
      case ErrorAction.dismiss:
        _handleDismiss();
        break;
    }
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    
    setState(() {
      _isRetrying = true;
    });

    try {
      if (widget.onRetry != null) {
        widget.onRetry!();
      }
      
      // Simulate retry delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _handleLogin() {
    if (widget.onCustomAction != null) {
      widget.onCustomAction!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  void _handleLogout() {
    // Implement logout logic
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  void _handleRedirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  void _handleEnableOfflineMode() {
    // Use AuthManager and ConnectivityService for proper offline mode handling
    _showOfflineModeDialog();
  }

  void _showOfflineModeDialog() async {
    final context = this.context;
    final authManager = AuthManager();
    final connectivityService = ConnectivityService();
    
    // Check if offline data is available
    final lastEmployeeId = await authManager.getLastEmployeeId();
    final hasOfflineData = lastEmployeeId != null 
        ? await authManager.hasBasicOfflineLoginData(lastEmployeeId)
        : false;

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(context.responsive.borderRadius),
        ),
        title: Row(
          children: [
            Icon(
              Icons.cloud_off,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            const Text('Offline Mode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You appear to be offline. Choose how to proceed:',
            ),
            const SizedBox(height: 16),
            if (hasOfflineData) ...[
              ListTile(
                leading: const Icon(Icons.offline_pin),
                title: const Text('Use Offline Login'),
                subtitle: Text('Login with saved data for $lastEmployeeId'),
                onTap: () {
                  Navigator.of(context).pop();
                  _navigateToOfflineLogin(lastEmployeeId!);
                },
              ),
              const Divider(),
            ],
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Check Connection'),
              subtitle: const Text('Try to reconnect to the internet'),
              onTap: () {
                Navigator.of(context).pop();
                _checkConnectivity();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Go to Home'),
              subtitle: const Text('Return to home screen'),
              onTap: () {
                Navigator.of(context).pop();
                _handleDismiss();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _navigateToOfflineLogin(String employeeId) {
    // Navigate to login screen with offline mode enabled
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
      arguments: {'offlineMode': true, 'employeeId': employeeId},
    );
  }

  Future<void> _checkConnectivity() async {
    final connectivityService = ConnectivityService();
    
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Check connectivity using the service
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog

      if (isConnected) {
        ErrorScreen.showErrorSnackBar(
          context,
          message: 'Connection restored! You can now use online features.',
        );
        // Optionally refresh the current screen or navigate back
        if (widget.onRetry != null) {
          widget.onRetry!();
        }
      } else {
        ErrorScreen.showErrorSnackBar(
          context,
          message: 'Still offline. Please check your internet connection.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // Close loading dialog
      
      ErrorScreen.showErrorSnackBar(
        context,
        message: 'Failed to check connectivity. Please try again.',
      );
    }
  }

  void _handleCheckConnection() {
    ErrorScreen.showErrorSnackBar(
      context,
      message: 'Please check your internet connection and try again',
      onRetry: widget.onRetry,
    );
  }

  void _handleTryOfflineMode() {
    ErrorScreen.showErrorSnackBar(
      context,
      message: 'Switching to offline mode with cached data',
    );
  }

  void _handleCorrectInput() {
    Navigator.of(context).pop();
  }

  void _handleContactSupport() {
    // Implement support contact logic (email, in-app chat, etc.)
    ErrorScreen.showErrorSnackBar(
      context,
      message: 'Please contact ${AppConstants.supportEmail} for assistance',
    );
  }

  Future<void> _handleWaitAndRetry() async {
    await Future.delayed(const Duration(seconds: 3));
    await _handleRetry();
  }

  void _handleDismiss() {
    if (widget.onGoHome != null) {
      widget.onGoHome!();
    } else {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/home',
        (Route<dynamic> route) => false,
      );
    }
  }
}