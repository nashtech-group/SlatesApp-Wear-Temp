import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/utils/responsive_utils.dart';

class ErrorScreen extends StatelessWidget {
  final String title;
  final String message;
  final String? errorCode;
  final IconData? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onGoHome;
  final String? actionButtonText;
  final VoidCallback? onCustomAction;

  const ErrorScreen({
    super.key,
    required this.title,
    required this.message, 
    this.errorCode,
    this.icon,
    this.onRetry,
    this.onGoHome,
    this.actionButtonText,
    this.onCustomAction,
  });

  // Predefined error screens for common cases
  static const ErrorScreen notFound = ErrorScreen(
    title: 'Page Not Found',
    message: 'The page you are looking for does not exist.',
    icon: Icons.search_off,
  );

  static const ErrorScreen unauthorized = ErrorScreen(
    title: 'Unauthorized',
    message: 'You are not authorized to access this page.',
    icon: Icons.lock_outline,
  );

  static const ErrorScreen serverError = ErrorScreen(
    title: 'Server Error',
    message: 'Something went wrong. Please try again later.',
    icon: Icons.error_outline,
  );

  static ErrorScreen networkError({VoidCallback? onRetry}) => ErrorScreen(
    title: 'Network Error',
    message: AppConstants.networkErrorMessage,
    icon: Icons.wifi_off,
    onRetry: onRetry,
  );

  static ErrorScreen sessionExpired({VoidCallback? onLogin}) => ErrorScreen(
    title: 'Session Expired',
    message: AppConstants.sessionExpiredMessage,
    icon: Icons.timer_off,
    actionButtonText: 'Login Again',
    onCustomAction: onLogin,
  );

  static ErrorScreen offlineMode({VoidCallback? onGoHome}) => ErrorScreen(
    title: 'Offline Mode',
    message: 'Some features are limited in offline mode.',
    icon: Icons.cloud_off,
    onGoHome: onGoHome,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    
    return Scaffold(
      appBar: responsive.isWearable ? null : AppBar(
        title: const Text(AppConstants.appTitle),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: _shouldShowBackButton(context),
      ),
      body: SafeArea(
        child: _buildResponsiveLayout(context, theme, responsive),
      ),
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
          // Compact error icon
          _buildErrorIcon(theme, responsive),
          
          responsive.largeSpacer,
          
          // Error title
          _buildErrorTitle(theme, responsive),
          
          responsive.mediumSpacer,
          
          // Error message
          _buildErrorMessage(theme, responsive),
          
          // Error code (if provided)
          if (errorCode != null) ...[
            responsive.smallSpacer,
            _buildErrorCode(theme, responsive),
          ],
          
          responsive.largeSpacer,
          
          // Action buttons
          _buildActionButtons(context, responsive),
          
          responsive.mediumSpacer,
          
          // Compact support info
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
          // Error Icon
          _buildErrorIcon(theme, responsive),
          
          responsive.extraLargeSpacer,
          
          // Error Title
          _buildErrorTitle(theme, responsive),
          
          responsive.mediumSpacer,
          
          // Error Message
          _buildErrorMessage(theme, responsive),
          
          // Error Code (if provided)
          if (errorCode != null) ...[
            responsive.smallSpacer,
            _buildErrorCode(theme, responsive),
          ],
          
          SizedBox(height: responsive.extraLargeSpacing * 1.2),
          
          // Action Buttons
          _buildActionButtons(context, responsive),
          
          responsive.largeSpacer,
          
          // Support Information
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
        icon ?? Icons.error_outline,
        size: iconSize,
        color: _getIconColor(theme),
      ),
    );
  }

  Widget _buildErrorTitle(ThemeData theme, ResponsiveUtils responsive) {
    return Text(
      title,
      style: responsive.getHeadlineStyle(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildErrorMessage(ThemeData theme, ResponsiveUtils responsive) {
    return Text(
      message,
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
        'Error Code: $errorCode',
        style: responsive.getCaptionStyle(
          color: theme.colorScheme.error,
        )?.copyWith(fontFamily: 'monospace'),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ResponsiveUtils responsive) {
    return Column(
      children: [
        // Primary Action Button
        if (onRetry != null || onCustomAction != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCustomAction ?? onRetry,
              icon: Icon(
                _getPrimaryActionIcon(),
                size: responsive.iconSize,
              ),
              label: Text(
                actionButtonText ?? 
                (onRetry != null ? 'Try Again' : 'Continue'),
                style: responsive.getBodyStyle(),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  vertical: responsive.isWearable ? 12 : 16,
                  horizontal: responsive.padding,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
              ),
            ),
          ),
        
        // Secondary Action Button
        if (onGoHome != null || _shouldShowGoHomeButton(context)) ...[
          responsive.smallSpacer,
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: onGoHome ?? () => _goToHome(context),
              icon: Icon(
                Icons.home_outlined,
                size: responsive.iconSize,
              ),
              label: Text(
                'Go to Home',
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
          ),
        ],
        
        // Back Button (if no custom actions)
        if (onRetry == null && 
            onCustomAction == null && 
            onGoHome == null &&
            _shouldShowBackButton(context)) ...[
          responsive.smallSpacer,
          SizedBox(
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
          ),
        ],
      ],
    );
  }

  Widget _buildSupportInfo(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      padding: responsive.formPadding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: responsive.largeIconSize,
            color: theme.colorScheme.onSurfaceVariant,
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
        ],
      ),
    );
  }

  Widget _buildCompactSupportInfo(BuildContext context, ThemeData theme, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.padding * 0.75),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: responsive.iconSize,
            color: theme.colorScheme.onSurfaceVariant,
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

  Color _getIconBackgroundColor(ThemeData theme) {
    switch (title.toLowerCase()) {
      case 'unauthorized':
        return theme.colorScheme.errorContainer.withValues(alpha: 0.1);
      case 'network error':
        return theme.colorScheme.primaryContainer.withValues(alpha: 0.1);
      case 'offline mode':
        return theme.colorScheme.secondaryContainer.withValues(alpha: 0.1);
      default:
        return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3);
    }
  }

  Color _getIconColor(ThemeData theme) {
    switch (title.toLowerCase()) {
      case 'unauthorized':
      case 'server error':
        return theme.colorScheme.error;
      case 'network error':
        return theme.colorScheme.primary;
      case 'offline mode':
        return theme.colorScheme.secondary;
      default:
        return theme.colorScheme.onSurfaceVariant;
    }
  }

  IconData _getPrimaryActionIcon() {
    if (onRetry != null) return Icons.refresh;
    if (actionButtonText?.toLowerCase().contains('login') == true) {
      return Icons.login;
    }
    return Icons.arrow_forward;
  }

  bool _shouldShowBackButton(BuildContext context) {
    return Navigator.of(context).canPop();
  }

  bool _shouldShowGoHomeButton(BuildContext context) {
    // Show go home button for error screens that don't have custom actions
    return onRetry == null && onCustomAction == null;
  }

  void _goToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/home',
      (Route<dynamic> route) => false,
    );
  }

  // Factory methods for common error scenarios
  factory ErrorScreen.custom({
    required String title,
    required String message,
    IconData? icon,
    String? errorCode,
    VoidCallback? onRetry,
    VoidCallback? onGoHome,
    String? actionButtonText,
    VoidCallback? onCustomAction,
  }) {
    return ErrorScreen(
      title: title,
      message: message,
      icon: icon,
      errorCode: errorCode,
      onRetry: onRetry,
      onGoHome: onGoHome,
      actionButtonText: actionButtonText,
      onCustomAction: onCustomAction,
    );
  }

  factory ErrorScreen.fromApiError(
    String apiErrorMessage, {
    String? errorCode,
    VoidCallback? onRetry,
  }) {
    String title = 'Error';
    String message = apiErrorMessage;
    IconData icon = Icons.error_outline;

    // Determine error type from message
    if (apiErrorMessage.toLowerCase().contains('network') ||
        apiErrorMessage.toLowerCase().contains('connection')) {
      title = 'Network Error';
      icon = Icons.wifi_off;
    } else if (apiErrorMessage.toLowerCase().contains('unauthorized')) {
      title = 'Unauthorized';
      icon = Icons.lock_outline;
    } else if (apiErrorMessage.toLowerCase().contains('server')) {
      title = 'Server Error';
      icon = Icons.error_outline;
    } else if (apiErrorMessage.toLowerCase().contains('validation')) {
      title = 'Validation Error';
      icon = Icons.warning_outlined;
    }

    return ErrorScreen(
      title: title,
      message: message,
      icon: icon,
      errorCode: errorCode,
      onRetry: onRetry,
    );
  }

  // Static method to show error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String? errorCode,
    VoidCallback? onRetry,
  }) {
    final responsive = context.responsive;
    final theme = Theme.of(context);
    
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
                title,
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
              message,
              style: responsive.getBodyStyle(),
            ),
            if (errorCode != null) ...[
              responsive.smallSpacer,
              Container(
                padding: EdgeInsets.all(responsive.padding * 0.5),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive.borderRadius),
                ),
                child: Text(
                  'Error Code: $errorCode',
                  style: responsive.getCaptionStyle()?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (onRetry != null)
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
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'OK',
              style: responsive.getBodyStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // Static method to show error snackbar
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final responsive = context.responsive;
    
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
                message,
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
}