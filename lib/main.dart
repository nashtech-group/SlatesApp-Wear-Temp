import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_repositories.dart';
import 'app_blocs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/route_constants.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();
  
  // Set preferred orientations for wearable
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Configure system UI for wearable
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  
  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const SlatesApp(),
    ),
  );
}

class SlatesApp extends StatelessWidget {
  const SlatesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AppRepositories(
          appBlocs: AppBlocs(
            app: MaterialApp(
              title: 'SlatesApp Wear',
              debugShowCheckedModeBanner: false,
              
              // Theme configuration
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeProvider.themeMode,
              
              // Navigation
              initialRoute: RouteConstants.splash,
              onGenerateRoute: AppRoutes.generateRoute,
              
              // Builder for global configurations
              builder: (context, child) {
                // Configure text scale factor for wearable
                return MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
                  ),
                  child: child!,
                );
              },
            ),
          ),
        );
      },
    );
  }
}