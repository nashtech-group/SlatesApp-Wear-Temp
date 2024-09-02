import 'package:flutter/material.dart';
import 'package:slates_app_wear/presentation/screens/login_screen.dart';
import 'package:slates_app_wear/presentation/screens/menu_screen.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/menu':
        return MaterialPageRoute(builder: (_) => MenuScreen());
      default:
        return MaterialPageRoute(
            builder: (_) => Scaffold(
                  body: Center(
                    child: Text('No route defins for ${settings.name}'),
                  ),
                ));
    }
  }
}
