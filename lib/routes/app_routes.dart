import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:slates_app_wear/blocs/auth_bloc/auth_bloc.dart';
import 'package:slates_app_wear/core/constants/route_constants.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/constants/api_constants.dart';
import 'package:slates_app_wear/core/error/common_error_states.dart';
import 'package:slates_app_wear/core/error/error_handler.dart';
import 'package:slates_app_wear/data/presentation/screens/auth/login_screen.dart';
import 'package:slates_app_wear/data/presentation/screens/error_screen.dart';
import 'package:slates_app_wear/data/presentation/screens/home_screen.dart';
import 'package:slates_app_wear/data/presentation/screens/notifications/notification_center_page.dart';
import 'package:slates_app_wear/data/presentation/screens/splash_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteConstants.splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case RouteConstants.login:
        return MaterialPageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );

      case RouteConstants.home:
        return MaterialPageRoute(
          builder: (context) => BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              if (state is AuthAuthenticated || state is AuthOfflineMode) {
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
          settings: settings,
        );

      case RouteConstants.notifications:
        return MaterialPageRoute(
          builder: (_) => const NotificationCenterPage(),
          settings: settings,
        );

      // case RouteConstants.notificationSettings:
      //   return MaterialPageRoute(
      //     builder: (_) => const NotificationSettingsPage(),
      //     settings: settings,
      //   );

      case RouteConstants.unauthorized:
        return MaterialPageRoute(
          builder: (context) => ErrorScreen(
            errorState: AuthenticationErrorState(
              errorInfo: BlocErrorInfo(
                type: ErrorType.authentication,
                message: AppConstants.unauthorizedMessage,
                statusCode: ApiConstants.unauthorizedCode,
              ),
            ),
            onCustomAction: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteConstants.login,
                (Route<dynamic> route) => false,
              );
            },
            customActionText: 'Login',
          ),
          settings: settings,
        );

      case RouteConstants.serverError:
        return MaterialPageRoute(
          builder: (context) => ErrorScreen(
            errorState: ServerErrorState(
              errorInfo: BlocErrorInfo(
                type: ErrorType.server,
                message: AppConstants.serverErrorMessage,
                statusCode: ApiConstants.serverErrorCode,
                canRetry: ApiConstants.isRetryableStatusCode(ApiConstants.serverErrorCode),
              ),
            ),
            onRetry: () {
              // Refresh the current route or navigate back
              Navigator.of(context).pop();
            },
          ),
          settings: settings,
        );

      case RouteConstants.notFound:
      default:
        return MaterialPageRoute(
          builder: (context) => ErrorScreen(
            errorState: NotFoundErrorState(
              errorInfo: BlocErrorInfo(
                type: ErrorType.notFound,
                message: AppConstants.notFoundMessage,
                statusCode: ApiConstants.notFoundCode,
              ),
            ),
            onGoHome: () {
              Navigator.of(context).pushNamedAndRemoveUntil(
                RouteConstants.home,
                (Route<dynamic> route) => false,
              );
            },
          ),
          settings: settings,
        );
    }
  }

  /// Helper method to navigate and clear stack
  static void navigateAndClearStack(BuildContext context, String routeName) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
    );
  }

  /// Helper method to navigate and replace current route
  static void navigateAndReplace(BuildContext context, String routeName) {
    Navigator.of(context).pushReplacementNamed(routeName);
  }

  /// Helper method to check if user can access route based on authentication
  static bool canAccessRoute(String routeName, AuthState authState) {
    // Public routes that don't require authentication
    const publicRoutes = [
      RouteConstants.splash,
      RouteConstants.login,
      RouteConstants.notFound,
      RouteConstants.unauthorized,
      RouteConstants.serverError,
    ];

    if (publicRoutes.contains(routeName)) {
      return true;
    }

    // Protected routes require authentication
    return authState is AuthAuthenticated || authState is AuthOfflineMode;
  }
}