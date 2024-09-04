import 'package:flutter/material.dart';
import 'package:slates_app_wear/core/constants/app_constants.dart';
import 'package:slates_app_wear/core/di/app_blocs.dart';
import 'package:slates_app_wear/core/di/app_repositories.dart';
import 'package:slates_app_wear/presentation/routes/routes.dart';
import 'package:slates_app_wear/presentation/themes/themes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppRepositories(
      appBlocs: AppBlocs(
        app: MaterialApp(
          title: AppConstants.appTitle,
          theme: AppTheme.lightTheme,
          onGenerateRoute: AppRoutes.generateRoute,
          initialRoute: '/',
        ),
      ),
    );
  }
}
