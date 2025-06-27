// lib/data/presentation/pages/error_screen.dart
import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/theme/app_theme.dart';

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
    Key? key,
    required this.title,
    required this.message,
    this.errorCode,
    this.icon,
    this.onRetry,
    this.onGoHome,
    this.actionButtonText,
    this.onCustomAction,
  }) : super(key: key);

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
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appTitle),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        automaticallyImplyLeading: _shouldShowBackButton(context),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _getIconBackgroundColor(theme),
                ),
                child: Icon(
                  icon ?? Icons.error_outline,
                  size: 64,
                  color: _getIconColor(theme),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Error Title
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Error Message
              Text(
                message,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha:0.7),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Error Code (if provided)
              if (errorCode != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    'Error Code: $errorCode',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 48),
              
              // Action Buttons
              Column(
                children: [
                  // Primary Action Button
                  if (onRetry != null || onCustomAction != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onCustomAction ?? onRetry,
                        icon: Icon(_getPrimaryActionIcon()),
                        label: Text(
                          actionButtonText ?? 
                          (onRetry != null ? 'Try Again' : 'Continue'),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  // Secondary Action Button
                  if (onGoHome != null || _shouldShowGoHomeButton(context)) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: onGoHome ?? () => _goToHome(context),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Go to Home'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Support Information
              _buildSupportInfo(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportInfo(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha:0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha:0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.support_agent,
            size: 24,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'Need Help?',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Contact support at ${AppConstants.supportEmail}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getIconBackgroundColor(ThemeData theme) {
    switch (title.toLowerCase()) {
      case 'unauthorized':
        return theme.colorScheme.errorContainer.withValues(alpha:0.1);
      case 'network error':
        return theme.colorScheme.primaryContainer.withValues(alpha:0.1);
      case 'offline mode':
        return theme.colorScheme.secondaryContainer.withValues(alpha:0.1);
      default:
        return theme.colorScheme.surfaceVariant.withValues(alpha:0.3);
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
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (errorCode != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error Code: $errorCode',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
              child: const Text('Try Again'),
            ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.onError,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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