import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:slates_app_wear/services/battery_monitor_service.dart';
import 'app_repositories.dart';
import 'app_blocs.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/constants/route_constants.dart';
import 'core/utils/responsive_utils.dart';
import 'routes/app_routes.dart';
import 'services/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize timezone data
  tz.initializeTimeZones();

  // Initialize AudioService for guard functionality
  await AudioService().initialize();

  // Start battery monitoring for wearable devices
  BatteryMonitorService().startMonitoring();

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

class SlatesApp extends StatefulWidget {
  const SlatesApp({super.key});

  @override
  State<SlatesApp> createState() => _SlatesAppState();
}

class _SlatesAppState extends State<SlatesApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Clean up AudioService when app is disposed
    AudioService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
        // App goes to background - stop non-emergency audio
        AudioService().stopAll();
        break;
      case AppLifecycleState.resumed:
        // App returns to foreground - audio service is ready
        break;
      case AppLifecycleState.detached:
        // App is being terminated - cleanup audio
        AudioService().dispose();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return AppRepositories(
          appBlocs: AppBlocs(
            app: Builder(
              builder: (context) {
                return MaterialApp(
                  title: 'SlatesApp Wear',
                  debugShowCheckedModeBanner: false,
                  
                  // Theme configuration 
                  theme: AppTheme.lightTheme(context),
                  darkTheme: AppTheme.darkTheme(context),
                  themeMode: themeProvider.themeMode,
                  
                  // Navigation
                  initialRoute: RouteConstants.splash,
                  onGenerateRoute: AppRoutes.generateRoute,
                  
                  builder: (context, child) {
                    // Get device-specific text scaling constraints
                    final constraints = context.responsive.textScaleConstraints;
                    
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(
                        textScaler: MediaQuery.of(context).textScaler.clamp(
                          minScaleFactor: constraints.min,
                          maxScaleFactor: constraints.max,
                        ),
                      ),
                      child: child!,
                    );
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}