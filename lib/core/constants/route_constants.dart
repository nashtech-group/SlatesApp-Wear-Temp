class RouteConstants {
  // Auth routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  
  // Main app routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String profile = '/profile';
  static const String settings = '/settings';
  
  // Guard duty routes
  static const String dutyDashboard = '/duty';
  static const String movements = '/movements';
  static const String perimeterChecks = '/perimeter-checks';
  static const String roster = '/roster';
  
  // Management routes (admin/manager only)
  static const String userManagement = '/users';
  static const String siteManagement = '/sites';
  static const String reports = '/reports';
  static const String schedules = '/schedules';
  
  // Error routes
  static const String notFound = '/404';
  static const String unauthorized = '/unauthorized';
  static const String serverError = '/error';
}